import 'dart:io';

import 'package:bluebubbles/echo/theme/echo_tokens.dart';
import 'package:flutter/material.dart';

/// Depth level 0 — the atmospheric floor every Echo screen sits on.
///
/// Either a dark photographic wallpaper or the generated gradient atmosphere.
/// The image is deliberately painted once into a [RepaintBoundary] and never
/// animated per-frame; [drift] performs one very slow scale/translate so the
/// background feels alive without costing a repaint budget.
class EchoAtmosphere extends StatefulWidget {
  const EchoAtmosphere({
    super.key,
    required this.child,
    this.wallpaperPath,
    this.drift = true,
    this.dim = 0.0,
    this.accent,
  });

  final Widget child;

  /// Absolute path to a user-selected wallpaper. Falls back to the generated
  /// atmosphere when null or missing.
  final String? wallpaperPath;

  /// Very slow ambient movement. Disabled automatically when the platform
  /// reports reduced motion.
  final bool drift;

  /// Extra darkening painted over the background, 0–1. Used behind dense text.
  final double dim;

  /// Tints the generated atmosphere toward the active accent.
  final Color? accent;

  @override
  State<EchoAtmosphere> createState() => _EchoAtmosphereState();
}

class _EchoAtmosphereState extends State<EchoAtmosphere> with SingleTickerProviderStateMixin {
  late final AnimationController _drift = AnimationController(
    vsync: this,
    duration: EchoTokens.ambient,
  );

  @override
  void initState() {
    super.initState();
    if (widget.drift) _drift.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(EchoAtmosphere oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.drift && !_drift.isAnimating) {
      _drift.repeat(reverse: true);
    } else if (!widget.drift && _drift.isAnimating) {
      _drift.stop();
    }
  }

  @override
  void dispose() {
    _drift.dispose();
    super.dispose();
  }

  bool get _reducedMotion => MediaQuery.maybeOf(context)?.disableAnimations ?? false;

  @override
  Widget build(BuildContext context) {
    final file = widget.wallpaperPath;
    final hasImage = file != null && file.isNotEmpty && File(file).existsSync();
    final animate = widget.drift && !_reducedMotion;

    Widget background = hasImage
        ? Image.file(File(file), fit: BoxFit.cover, filterQuality: FilterQuality.medium)
        : DecoratedBox(
            decoration: BoxDecoration(
              gradient: widget.accent == null
                  ? EchoTokens.atmosphere
                  : RadialGradient(
                      center: const Alignment(-0.5, -0.85),
                      radius: 1.5,
                      colors: [
                        Color.lerp(const Color(0xFF1B2A44), widget.accent, 0.45)!,
                        const Color(0xFF0C1019),
                        EchoTokens.voidBlack,
                      ],
                      stops: const [0.0, 0.55, 1.0],
                    ),
            ),
            child: const SizedBox.expand(),
          );

    if (animate) {
      background = AnimatedBuilder(
        animation: _drift,
        builder: (context, child) {
          final t = Curves.easeInOut.transform(_drift.value);
          return Transform.scale(
            scale: 1.06 + t * 0.03,
            child: Transform.translate(
              offset: Offset(-6 + t * 12, -4 + t * 8),
              child: child,
            ),
          );
        },
        child: background,
      );
    }

    return ColoredBox(
      color: EchoTokens.voidBlack,
      child: Stack(
        fit: StackFit.expand,
        children: [
          RepaintBoundary(child: background),
          // Vignette: keeps the edges dark so floating glass stays legible.
          const IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.center,
                  radius: 1.1,
                  colors: [Colors.transparent, Color(0x99000000)],
                  stops: [0.55, 1.0],
                ),
              ),
            ),
          ),
          if (widget.dim > 0)
            IgnorePointer(
              child: ColoredBox(color: Colors.black.withOpacity(widget.dim.clamp(0.0, 1.0))),
            ),
          widget.child,
        ],
      ),
    );
  }
}
