import 'package:bluebubbles/app/layouts/setup/setup_view.dart';
import 'package:bluebubbles/echo/glass/glass_surface.dart';
import 'package:bluebubbles/echo/theme/echo_tokens.dart';
import 'package:bluebubbles/services/services.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';

/// Echo's onboarding page: a premium product introduction rather than a form.
///
/// Sits inside the existing setup [PageView] and advances it the same way the
/// page it replaces did, including the Android 13+ notification permission
/// request, so the rest of the setup flow is unchanged.
class EchoWelcome extends StatefulWidget {
  const EchoWelcome({super.key});

  @override
  State<EchoWelcome> createState() => _EchoWelcomeState();
}

class _EchoWelcomeState extends State<EchoWelcome> with TickerProviderStateMixin {
  late final AnimationController _enter = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..forward();

  bool _advancing = false;

  @override
  void dispose() {
    _enter.dispose();
    super.dispose();
  }

  Animation<double> _stagger(double begin, double end) => CurvedAnimation(
        parent: _enter,
        curve: Interval(begin, end, curve: EchoTokens.easeOut),
      );

  Future<void> _next() async {
    if (_advancing) return;
    setState(() => _advancing = true);
    try {
      if ((fs.androidInfo?.version.sdkInt ?? 0) >= 33) {
        await Permission.notification.request();
      }
      if (!mounted) return;
      Get.find<SetupViewController>().pageController.nextPage(
            duration: EchoTokens.medium,
            curve: EchoTokens.easeOut,
          );
    } finally {
      if (mounted) setState(() => _advancing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final accent = Theme.of(context).colorScheme.primary;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        EchoTokens.space5,
        EchoTokens.space4,
        EchoTokens.space5,
        EchoTokens.space6,
      ),
      child: Column(
        children: [
          FadeTransition(
            opacity: _stagger(0.0, 0.55),
            child: const _LayeredGlassMotif(),
          ),
          const SizedBox(height: EchoTokens.space6),
          FadeTransition(
            opacity: _stagger(0.25, 0.8),
            child: SlideTransition(
              position: Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero)
                  .animate(_stagger(0.25, 0.8)),
              child: GlassSurface(
                level: 3,
                radius: EchoTokens.radiusXl,
                padding: const EdgeInsets.all(EchoTokens.space6),
                child: Column(
                  children: [
                    Text(
                      'Your iMessages.\nOn any device.',
                      style: text.displayMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: EchoTokens.space3),
                    Text(
                      'Secure, private, and seamless — wherever you are.',
                      style: text.bodyMedium?.copyWith(color: EchoTokens.textSecondary),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: EchoTokens.space6),
                    _GetStartedButton(
                      accent: accent,
                      busy: _advancing,
                      onTap: _next,
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: EchoTokens.space4),
          FadeTransition(
            opacity: _stagger(0.55, 1.0),
            child: Text(
              'Setup takes a couple of minutes.',
              style: text.labelSmall?.copyWith(color: EchoTokens.textTertiary),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}

class _GetStartedButton extends StatelessWidget {
  const _GetStartedButton({required this.accent, required this.busy, required this.onTap});

  final Color accent;
  final bool busy;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return Semantics(
      button: true,
      enabled: !busy,
      label: 'Get started',
      child: GestureDetector(
        onTap: busy ? null : onTap,
        child: AnimatedContainer(
          duration: EchoTokens.fast,
          height: 54,
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(EchoTokens.radiusCapsule),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [EchoTokens.accentIce, accent, EchoTokens.accentDeep],
            ),
            boxShadow: EchoTokens.glow(accent, strength: busy ? 0.5 : 1.0),
            border: Border.all(color: Colors.white.withOpacity(0.28)),
          ),
          child: Center(
            child: busy
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2.2, color: Colors.white),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Get Started',
                        style: text.titleMedium?.copyWith(color: Colors.white, fontSize: 17),
                      ),
                      const SizedBox(width: EchoTokens.space2),
                      const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 19),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

/// Abstract layered glass panes — depth without pretending to be a screenshot
/// of something the app cannot do yet.
class _LayeredGlassMotif extends StatelessWidget {
  const _LayeredGlassMotif();

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;

    return SizedBox(
      height: 150,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Transform.translate(
            offset: const Offset(-34, 14),
            child: Transform.rotate(
              angle: -0.16,
              child: const GlassSurface(
                level: 1,
                blur: false,
                width: 118,
                height: 84,
                radius: EchoTokens.radiusLg,
                child: SizedBox.shrink(),
              ),
            ),
          ),
          Transform.translate(
            offset: const Offset(36, -10),
            child: Transform.rotate(
              angle: 0.12,
              child: GlassSurface(
                level: 2,
                blur: false,
                width: 104,
                height: 76,
                radius: EchoTokens.radiusLg,
                tint: accent,
                child: const SizedBox.shrink(),
              ),
            ),
          ),
          GlassSurface(
            level: 4,
            blur: false,
            radius: EchoTokens.radiusCapsule,
            tint: accent,
            glowColor: accent,
            padding: const EdgeInsets.all(EchoTokens.space4),
            child: const Icon(Icons.forum_rounded, color: Colors.white, size: 30),
          ),
        ],
      ),
    );
  }
}
