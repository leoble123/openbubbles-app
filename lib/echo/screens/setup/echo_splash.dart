import 'package:bluebubbles/app/layouts/setup/setup_view.dart';
import 'package:bluebubbles/app/wrappers/titlebar_wrapper.dart';
import 'package:bluebubbles/echo/glass/echo_atmosphere.dart';
import 'package:bluebubbles/echo/theme/echo_tokens.dart';
import 'package:bluebubbles/echo/widgets/echo_wordmark.dart';
import 'package:flutter/material.dart';

/// Echo's launch screen.
///
/// Same contract as the splash it replaces: once [shouldNavigate] is true it
/// moves on to setup. The reveal animation never gates that — startup is not
/// delayed for the sake of the animation, so the transition begins as soon as
/// the app is genuinely ready.
class EchoSplash extends StatefulWidget {
  const EchoSplash({super.key, required this.shouldNavigate});

  final bool shouldNavigate;

  @override
  State<EchoSplash> createState() => _EchoSplashState();
}

class _EchoSplashState extends State<EchoSplash> with SingleTickerProviderStateMixin {
  late final AnimationController _reveal = AnimationController(
    vsync: this,
    duration: EchoTokens.slow,
  )..forward();

  bool _navigated = false;

  @override
  void didUpdateWidget(EchoSplash old) {
    super.didUpdateWidget(old);
    _maybeNavigate();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeNavigate());
  }

  void _maybeNavigate() {
    if (!widget.shouldNavigate || _navigated || !mounted) return;
    _navigated = true;
    Navigator.of(context).pushAndRemoveUntil(
      PageRouteBuilder(
        transitionDuration: EchoTokens.slow,
        pageBuilder: (_, __, ___) => TitleBarWrapper(child: SetupView()),
        transitionsBuilder: (context, animation, _, child) {
          // The foreground glass moves forward into onboarding rather than
          // cutting or cross-fading.
          final curved = CurvedAnimation(parent: animation, curve: EchoTokens.easeOut);
          return FadeTransition(
            opacity: curved,
            child: ScaleTransition(
              scale: Tween<double>(begin: 1.08, end: 1.0).animate(curved),
              child: child,
            ),
          );
        },
      ),
      (route) => route.isFirst,
    );
  }

  @override
  void dispose() {
    _reveal.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: EchoTokens.voidBlack,
      body: EchoAtmosphere(
        child: Center(
          child: AnimatedBuilder(
            animation: _reveal,
            builder: (context, child) {
              final t = EchoTokens.easeOut.transform(_reveal.value);
              return Opacity(
                opacity: t,
                child: Transform.scale(scale: 0.96 + t * 0.04, child: child),
              );
            },
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Hero(
                  tag: 'setup-icon',
                  child: Material(
                    color: Colors.transparent,
                    child: EchoWordmark(size: 62),
                  ),
                ),
                const SizedBox(height: EchoTokens.space3),
                Text(
                  'iMessage. Everywhere.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: EchoTokens.textSecondary,
                        letterSpacing: 2.4,
                      ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
