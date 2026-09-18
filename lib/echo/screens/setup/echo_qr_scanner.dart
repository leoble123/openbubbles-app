import 'dart:async';
import 'dart:convert';

import 'package:bluebubbles/echo/glass/glass_surface.dart';
import 'package:bluebubbles/echo/theme/echo_tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

/// Echo's QR pairing screen.
///
/// This is a drop-in replacement for the original `QRCodeScanner`: it pops the
/// same `Uint8List?` payload, so every existing caller — the rustpush hardware
/// setup, server credentials, the password editor — keeps its decoding and
/// activation logic untouched. Nothing about pairing is reimplemented here.
///
/// Everything the screen displays is driven by real scanner state. The sweep
/// only runs while the camera is genuinely running, and the success morph only
/// plays once a barcode has actually been decoded.
class EchoQrScanner extends StatefulWidget {
  const EchoQrScanner({
    super.key,
    this.title = 'Pair Your Devices',
    this.subtitle = 'Scan the QR code from your Mac to connect your iMessage account.',
    this.manualLabel = 'Enter Code Instead',
  });

  final String title;
  final String subtitle;

  /// Secondary action label. Selecting it pops null, which every caller already
  /// treats as "cancelled" and falls back to its manual entry field.
  final String manualLabel;

  @override
  State<EchoQrScanner> createState() => _EchoQrScannerState();
}

enum _ScanPhase { starting, scanning, detected, failed }

class _EchoQrScannerState extends State<EchoQrScanner> with TickerProviderStateMixin {
  final MobileScannerController _scanner = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    formats: const [BarcodeFormat.qrCode],
  );

  late final AnimationController _sweep = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2600),
  );

  late final AnimationController _success = AnimationController(
    vsync: this,
    duration: EchoTokens.medium,
  );

  _ScanPhase _phase = _ScanPhase.starting;
  String? _error;
  bool _handled = false;

  @override
  void initState() {
    super.initState();
    _scanner.addListener(_onScannerState);
  }

  void _onScannerState() {
    if (!mounted || _handled) return;
    final state = _scanner.value;

    if (state.error != null && _phase != _ScanPhase.failed) {
      setState(() {
        _phase = _ScanPhase.failed;
        _error = state.error!.errorDetails?.message ?? 'The camera could not be started.';
      });
      _sweep.stop();
      return;
    }

    final running = state.isInitialized && state.isRunning;
    if (running && _phase == _ScanPhase.starting) {
      setState(() => _phase = _ScanPhase.scanning);
      _sweep.repeat();
    } else if (!running && _phase == _ScanPhase.scanning) {
      // Camera genuinely stopped (lifecycle pause, permission revoked).
      setState(() => _phase = _ScanPhase.starting);
      _sweep.stop();
    }
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_handled || capture.barcodes.isEmpty) return;

    final barcode = capture.barcodes.first;
    // Prefer raw bytes: the OpenBubbles pairing payload is binary, and decoding
    // it as text would corrupt it. Fall back to UTF-8 for text-only codes,
    // which is exactly what the original scanner did.
    final Uint8List? payload = barcode.rawBytes ??
        (barcode.rawValue != null && barcode.rawValue!.isNotEmpty
            ? Uint8List.fromList(utf8.encode(barcode.rawValue!))
            : null);
    if (payload == null || payload.isEmpty) return;

    _handled = true;
    _sweep.stop();
    setState(() => _phase = _ScanPhase.detected);
    HapticFeedback.mediumImpact();

    // Stop camera processing immediately on success (spec §18).
    unawaited(_scanner.stop());

    await _success.forward();
    if (!mounted) return;
    Navigator.of(context).pop(payload);
  }

  @override
  void dispose() {
    _scanner.removeListener(_onScannerState);
    _sweep.dispose();
    _success.dispose();
    _scanner.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final windowSize = (media.size.shortestSide * 0.68).clamp(200.0, 320.0);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: EchoTokens.voidBlack,
        body: LayoutBuilder(
          builder: (context, constraints) {
            final center = Offset(
              constraints.maxWidth / 2,
              constraints.maxHeight / 2 - constraints.maxHeight * 0.04,
            );
            final window = Rect.fromCenter(
              center: center,
              width: windowSize.toDouble(),
              height: windowSize.toDouble(),
            );

            return Stack(
              fit: StackFit.expand,
              children: [
                if (_phase != _ScanPhase.failed)
                  MobileScanner(
                    controller: _scanner,
                    fit: BoxFit.cover,
                    // Restricting detection to the visible window is both more
                    // predictable for the user and cheaper per frame.
                    scanWindow: window,
                    onDetect: _onDetect,
                    errorBuilder: (context, error, child) => const SizedBox.expand(),
                    placeholderBuilder: (context, child) => const ColoredBox(color: EchoTokens.voidBlack),
                  ),

                // Dark scrim everywhere except the scan window.
                IgnorePointer(
                  child: CustomPaint(
                    painter: _ScrimPainter(window: window),
                    size: Size(constraints.maxWidth, constraints.maxHeight),
                  ),
                ),

                // Brackets, glass edge, sweep and success morph.
                IgnorePointer(
                  child: AnimatedBuilder(
                    animation: Listenable.merge([_sweep, _success]),
                    builder: (context, _) => CustomPaint(
                      painter: _ScanFramePainter(
                        window: window,
                        sweep: _phase == _ScanPhase.scanning ? _sweep.value : null,
                        success: _success.value,
                      ),
                      size: Size(constraints.maxWidth, constraints.maxHeight),
                    ),
                  ),
                ),

                _Header(
                  scanner: _scanner,
                  onClose: () => Navigator.of(context).pop(),
                ),

                _Footer(
                  window: window,
                  phase: _phase,
                  error: _error,
                  title: widget.title,
                  subtitle: widget.subtitle,
                  manualLabel: widget.manualLabel,
                  onManual: () => Navigator.of(context).pop(),
                  onRetry: () async {
                    setState(() {
                      _phase = _ScanPhase.starting;
                      _error = null;
                    });
                    await _scanner.start();
                  },
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.scanner, required this.onClose});

  final MobileScannerController scanner;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(EchoTokens.space4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _GlassIconButton(icon: Icons.close_rounded, onTap: onClose, tooltip: 'Cancel'),
            ValueListenableBuilder<MobileScannerState>(
              valueListenable: scanner,
              builder: (context, state, _) {
                final on = state.torchState == TorchState.on;
                return _GlassIconButton(
                  icon: on ? Icons.flashlight_on_rounded : Icons.flashlight_off_rounded,
                  active: on,
                  tooltip: on ? 'Turn off flashlight' : 'Turn on flashlight',
                  // Only offer the torch once the camera can actually honour it.
                  onTap: state.isInitialized ? () => scanner.toggleTorch() : null,
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _GlassIconButton extends StatelessWidget {
  const _GlassIconButton({
    required this.icon,
    required this.onTap,
    this.active = false,
    this.tooltip,
  });

  final IconData icon;
  final VoidCallback? onTap;
  final bool active;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final button = Opacity(
      opacity: onTap == null ? 0.4 : 1.0,
      child: GlassSurface(
        level: 3,
        radius: EchoTokens.radiusCapsule,
        padding: const EdgeInsets.all(EchoTokens.space3),
        onTap: onTap,
        glowColor: active ? EchoTokens.accent : null,
        glowStrength: 0.7,
        child: Icon(
          icon,
          size: 22,
          color: active ? EchoTokens.accentIce : EchoTokens.textPrimary,
        ),
      ),
    );
    return tooltip == null
        ? button
        : Tooltip(message: tooltip!, child: Semantics(button: true, label: tooltip, child: button));
  }
}

class _Footer extends StatelessWidget {
  const _Footer({
    required this.window,
    required this.phase,
    required this.error,
    required this.title,
    required this.subtitle,
    required this.manualLabel,
    required this.onManual,
    required this.onRetry,
  });

  final Rect window;
  final _ScanPhase phase;
  final String? error;
  final String title;
  final String subtitle;
  final String manualLabel;
  final VoidCallback onManual;
  final Future<void> Function() onRetry;

  String get _status {
    switch (phase) {
      case _ScanPhase.starting:
        return 'Starting camera…';
      case _ScanPhase.scanning:
        return 'Searching for a code';
      case _ScanPhase.detected:
        return 'Code detected';
      case _ScanPhase.failed:
        return error ?? 'Camera unavailable';
    }
  }

  Color get _statusColor {
    switch (phase) {
      case _ScanPhase.detected:
        return EchoTokens.success;
      case _ScanPhase.failed:
        return EchoTokens.danger;
      default:
        return EchoTokens.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return Positioned(
      left: 0,
      right: 0,
      top: window.bottom + EchoTokens.space6,
      bottom: 0,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: EchoTokens.space5),
          child: Column(
            children: [
              Text(title, style: text.headlineMedium, textAlign: TextAlign.center),
              const SizedBox(height: EchoTokens.space2),
              Text(
                subtitle,
                style: text.bodySmall?.copyWith(color: EchoTokens.textSecondary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: EchoTokens.space4),
              // Live scanner status — never a decorative claim of success.
              Semantics(
                liveRegion: true,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _StatusDot(color: _statusColor, pulse: phase == _ScanPhase.scanning),
                    const SizedBox(width: EchoTokens.space2),
                    Flexible(
                      child: Text(
                        _status,
                        style: text.labelMedium?.copyWith(color: _statusColor),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              if (phase == _ScanPhase.failed)
                GlassCapsule(
                  level: 3,
                  onTap: () => onRetry(),
                  padding: const EdgeInsets.symmetric(
                    horizontal: EchoTokens.space5,
                    vertical: EchoTokens.space3,
                  ),
                  child: Text('Try Again', style: text.labelLarge),
                ),
              if (phase != _ScanPhase.failed)
                TextButton(
                  onPressed: onManual,
                  style: TextButton.styleFrom(foregroundColor: EchoTokens.accentIce),
                  child: Text(manualLabel, style: text.labelLarge?.copyWith(color: EchoTokens.accentIce)),
                ),
              const SizedBox(height: EchoTokens.space4),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusDot extends StatefulWidget {
  const _StatusDot({required this.color, required this.pulse});

  final Color color;
  final bool pulse;

  @override
  State<_StatusDot> createState() => _StatusDotState();
}

class _StatusDotState extends State<_StatusDot> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  );

  @override
  void initState() {
    super.initState();
    if (widget.pulse) _c.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(_StatusDot old) {
    super.didUpdateWidget(old);
    if (widget.pulse && !_c.isAnimating) {
      _c.repeat(reverse: true);
    } else if (!widget.pulse && _c.isAnimating) {
      _c.stop();
      _c.value = 1.0;
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        final t = widget.pulse ? 0.45 + _c.value * 0.55 : 1.0;
        return Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: widget.color.withOpacity(t),
            boxShadow: [
              BoxShadow(color: widget.color.withOpacity(0.35 * t), blurRadius: 8, spreadRadius: 1),
            ],
          ),
        );
      },
    );
  }
}

/// Darkens everything outside the scan window using a single even-odd path.
class _ScrimPainter extends CustomPainter {
  const _ScrimPainter({required this.window});

  final Rect window;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..addRect(Offset.zero & size)
      ..addRRect(RRect.fromRectAndRadius(window, const Radius.circular(EchoTokens.radiusXl)))
      ..fillType = PathFillType.evenOdd;
    canvas.drawPath(path, Paint()..color = Colors.black.withOpacity(0.62));
  }

  @override
  bool shouldRepaint(_ScrimPainter old) => old.window != window;
}

/// Glass edge, corner brackets, light sweep and success morph.
///
/// [sweep] is null whenever the camera is not actually running, so the screen
/// can never imply it is scanning when it is not.
class _ScanFramePainter extends CustomPainter {
  const _ScanFramePainter({required this.window, required this.sweep, required this.success});

  final Rect window;
  final double? sweep;
  final double success;

  @override
  void paint(Canvas canvas, Size size) {
    final rrect = RRect.fromRectAndRadius(window, const Radius.circular(EchoTokens.radiusXl));
    final accent = Color.lerp(EchoTokens.accentIce, EchoTokens.success, success)!;

    // Soft blue illumination bleeding out from the scan area.
    canvas.drawRRect(
      rrect.inflate(2),
      Paint()
        ..color = accent.withOpacity(0.18 + success * 0.22)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 26 + success * 14),
    );

    // The glass pane itself: a faint wash so the code reads as sitting inside
    // glass rather than inside a flat white box.
    canvas.drawRRect(
      rrect,
      Paint()..color = Colors.white.withOpacity(0.03 + success * 0.05),
    );

    // Specular top edge.
    canvas.drawRRect(
      rrect.deflate(0.5),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.1
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withOpacity(0.38),
            Colors.white.withOpacity(0.06),
            Colors.transparent,
          ],
          stops: const [0.0, 0.45, 1.0],
        ).createShader(window),
    );

    // Sweep: a soft band of light travelling down the window while scanning.
    if (sweep != null) {
      final t = Curves.easeInOut.transform(sweep!);
      final y = window.top + window.height * t;
      final band = Rect.fromLTRB(window.left, y - 46, window.right, y + 6);
      canvas.save();
      canvas.clipRRect(rrect);
      canvas.drawRect(
        band,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              EchoTokens.accentIce.withOpacity(0.0),
              EchoTokens.accentIce.withOpacity(0.22),
              EchoTokens.accentIce.withOpacity(0.62),
            ],
          ).createShader(band),
      );
      canvas.drawLine(
        Offset(window.left, y),
        Offset(window.right, y),
        Paint()
          ..color = EchoTokens.accentIce.withOpacity(0.85)
          ..strokeWidth = 1.6
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
      );
      canvas.restore();
    }

    // Corner brackets — restrained, and they close inward on success.
    final bracket = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..color = accent.withOpacity(0.9);

    final len = window.width * (0.16 - success * 0.04);
    const inset = 6.0;
    final r = window.deflate(-inset + success * 10);

    void corner(Offset o, double dx, double dy) {
      canvas.drawLine(o, o.translate(dx * len, 0), bracket);
      canvas.drawLine(o, o.translate(0, dy * len), bracket);
    }

    corner(Offset(r.left, r.top + EchoTokens.radiusXl * 0.5), 0, 1);
    corner(Offset(r.left + EchoTokens.radiusXl * 0.5, r.top), 1, 0);
    corner(Offset(r.right, r.top + EchoTokens.radiusXl * 0.5), 0, 1);
    corner(Offset(r.right - EchoTokens.radiusXl * 0.5, r.top), -1, 0);
    corner(Offset(r.left, r.bottom - EchoTokens.radiusXl * 0.5), 0, -1);
    corner(Offset(r.left + EchoTokens.radiusXl * 0.5, r.bottom), 1, 0);
    corner(Offset(r.right, r.bottom - EchoTokens.radiusXl * 0.5), 0, -1);
    corner(Offset(r.right - EchoTokens.radiusXl * 0.5, r.bottom), -1, 0);

    // Success morph: the glass brightens and a check is struck through it.
    if (success > 0) {
      canvas.drawRRect(rrect, Paint()..color = EchoTokens.success.withOpacity(0.14 * success));
      final c = window.center;
      final s = window.width * 0.16;
      final check = Path()
        ..moveTo(c.dx - s, c.dy)
        ..lineTo(c.dx - s * 0.2, c.dy + s * 0.72)
        ..lineTo(c.dx + s, c.dy - s * 0.6);
      final metric = check.computeMetrics().first;
      canvas.drawPath(
        metric.extractPath(0, metric.length * Curves.easeOut.transform(success)),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 5
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..color = Colors.white.withOpacity(success),
      );
    }
  }

  @override
  bool shouldRepaint(_ScanFramePainter old) =>
      old.sweep != sweep || old.success != success || old.window != window;
}
