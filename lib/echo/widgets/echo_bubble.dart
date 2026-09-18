import 'package:bluebubbles/echo/glass/glass_surface.dart';
import 'package:bluebubbles/echo/theme/echo_prefs.dart';
import 'package:bluebubbles/echo/theme/echo_tokens.dart';
import 'package:flutter/material.dart';

/// Echo's message bubble.
///
/// Used by the appearance studio's live preview, and shaped by the same
/// [EchoBubbleStyle] the studio writes, so the preview is a truthful rendering
/// rather than a mock-up.
class EchoBubble extends StatelessWidget {
  const EchoBubble({
    super.key,
    required this.text,
    required this.fromMe,
    required this.accent,
    this.style = EchoBubbleStyle.glass,
    this.compact = false,
    this.timestamp,
  });

  final String text;
  final bool fromMe;
  final Color accent;
  final EchoBubbleStyle style;
  final bool compact;
  final String? timestamp;

  BorderRadius get _radius {
    switch (style) {
      case EchoBubbleStyle.pill:
        return BorderRadius.circular(EchoTokens.radiusCapsule);
      case EchoBubbleStyle.rounded:
        return BorderRadius.circular(EchoTokens.radiusMd);
      case EchoBubbleStyle.outline:
      case EchoBubbleStyle.glass:
        return BorderRadius.only(
          topLeft: const Radius.circular(EchoTokens.radiusLg),
          topRight: const Radius.circular(EchoTokens.radiusLg),
          bottomLeft: Radius.circular(fromMe ? EchoTokens.radiusLg : EchoTokens.radiusSm),
          bottomRight: Radius.circular(fromMe ? EchoTokens.radiusSm : EchoTokens.radiusLg),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final padding = EdgeInsets.symmetric(
      horizontal: compact ? EchoTokens.space3 : EchoTokens.space4,
      vertical: compact ? EchoTokens.space2 : EchoTokens.space3,
    );

    final body = Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          text,
          style: textTheme.bodyMedium?.copyWith(
            color: Colors.white,
            fontSize: compact ? 14 : 15,
          ),
        ),
        if (timestamp != null) ...[
          const SizedBox(height: 2),
          Text(
            timestamp!,
            style: textTheme.labelSmall?.copyWith(
              fontSize: 10.5,
              color: Colors.white.withOpacity(0.55),
            ),
          ),
        ],
      ],
    );

    Widget bubble;
    if (style == EchoBubbleStyle.outline) {
      bubble = Container(
        padding: padding,
        decoration: BoxDecoration(
          borderRadius: _radius,
          border: Border.all(
            color: fromMe ? accent : Colors.white.withOpacity(0.28),
            width: 1.3,
          ),
          color: fromMe ? accent.withOpacity(0.10) : Colors.white.withOpacity(0.04),
        ),
        child: body,
      );
    } else if (fromMe) {
      // Outgoing carries a restrained blue glass gradient.
      bubble = Container(
        padding: padding,
        decoration: BoxDecoration(
          borderRadius: _radius,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color.lerp(accent, EchoTokens.accentIce, 0.25)!,
              accent,
              Color.lerp(accent, EchoTokens.accentDeep, 0.55)!,
            ],
          ),
          border: Border.all(color: Colors.white.withOpacity(0.20)),
          boxShadow: EchoTokens.glow(accent, strength: 0.35),
        ),
        child: body,
      );
    } else {
      // Incoming is dark translucent glass. Blur stays off: message rows are
      // the densest content in the app and readability wins over effect.
      bubble = GlassSurface(
        level: 2,
        blur: false,
        opaque: true,
        borderRadius: _radius,
        padding: padding,
        lift: false,
        child: body,
      );
    }

    return Align(
      alignment: fromMe ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.72),
        child: bubble,
      ),
    );
  }
}
