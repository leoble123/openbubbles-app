import 'package:bluebubbles/echo/theme/echo_tokens.dart';
import 'package:flutter/material.dart';

/// The Echo wordmark: lowercase, tight, with a cool specular gradient running
/// across it. Used on the splash, the setup header and the conversation list.
class EchoWordmark extends StatelessWidget {
  const EchoWordmark({
    super.key,
    this.size = 46,
    this.accent = EchoTokens.accent,
    this.glow = true,
  });

  final double size;
  final Color accent;
  final bool glow;

  @override
  Widget build(BuildContext context) {
    final mark = ShaderMask(
      shaderCallback: (rect) => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Colors.white, EchoTokens.accentIce, accent],
        stops: const [0.0, 0.45, 1.0],
      ).createShader(rect),
      child: Text(
        'echo',
        style: TextStyle(
          fontSize: size,
          fontWeight: FontWeight.w700,
          letterSpacing: -size * 0.035,
          height: 1.0,
          color: Colors.white,
        ),
      ),
    );

    if (!glow) return mark;

    return Stack(
      alignment: Alignment.center,
      children: [
        // A soft bloom behind the mark rather than a hard drop shadow.
        Positioned.fill(
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                boxShadow: [
                  BoxShadow(color: accent.withOpacity(0.28), blurRadius: size * 0.9, spreadRadius: -size * 0.25),
                ],
              ),
            ),
          ),
        ),
        mark,
      ],
    );
  }
}
