import 'package:bluebubbles/echo/theme/echo_tokens.dart';
import 'package:flutter/material.dart';

/// Global knobs for how expensive Echo's glass is allowed to be.
///
/// The customization studio writes to this, and low-end devices or the
/// accessibility fallback can turn blur off entirely without any call site
/// needing to know.
class EchoGlass {
  EchoGlass._();

  /// Multiplier applied to every blur sigma. 0 disables real blur app-wide and
  /// falls back to a slightly more opaque fill, which reads similarly at a
  /// fraction of the cost.
  static double blurScale = 1.0;

  /// When true, surfaces raise their fill opacity so text stays readable even
  /// with transparency reduced.
  static bool highContrast = false;

  static double sigmaFor(int level) {
    final sigma = EchoTokens.depthBlur[level.clamp(0, 4)] * blurScale;
    return sigma < 0.5 ? 0.0 : sigma;
  }
}

/// The single glass primitive every Echo surface is built from.
///
/// [level] selects a rung of the depth system in [EchoTokens]:
///
///  * 0 — background. No glass; use [EchoAtmosphere] instead.
///  * 1 — translucent panels (headers, inert rows).
///  * 2 — interactive cards (conversation rows, setting cards).
///  * 3 — floating controls and sheets.
///  * 4 — active / focused elements, which also take an accent glow.
///
/// Blur is only applied when [blur] is true. Dense, repeated content — message
/// bubbles, list rows — should leave it false and rely on fill alone, per the
/// spec's rule against an expensive blur behind every row.
class GlassSurface extends StatelessWidget {
  const GlassSurface({
    super.key,
    required this.child,
    this.level = 2,
    this.blur = true,
    this.radius,
    this.borderRadius,
    this.padding,
    this.margin,
    this.tint,
    this.opaque = false,
    this.glowColor,
    this.glowStrength = 1.0,
    this.border = true,
    this.lift = true,
    this.onTap,
    this.onLongPress,
    this.width,
    this.height,
    this.clipBehavior = Clip.antiAlias,
  });

  final Widget child;
  final int level;
  final bool blur;
  final double? radius;
  final BorderRadius? borderRadius;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;

  /// Overrides the glass tint — used for per-chat accents and outgoing bubbles.
  final Color? tint;

  /// Forces the readable, higher-opacity fill.
  final bool opaque;

  /// When set, the surface carries an accent glow (depth level 4 behaviour).
  final Color? glowColor;
  final double glowStrength;

  final bool border;
  final bool lift;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final double? width;
  final double? height;
  final Clip clipBehavior;

  @override
  Widget build(BuildContext context) {
    final br = borderRadius ?? BorderRadius.circular(radius ?? EchoTokens.radiusLg);
    final sigma = blur ? EchoGlass.sigmaFor(level) : 0.0;
    final isOpaque = opaque || EchoGlass.highContrast || sigma == 0.0;

    Widget surface = DecoratedBox(
      decoration: BoxDecoration(
        color: EchoTokens.fillFor(level, opaque: isOpaque, tint: tint),
        borderRadius: br,
      ),
      child: Stack(
        fit: StackFit.passthrough,
        children: [
          // Specular sheen across the top-left edge — the detail that makes a
          // translucent panel read as glass rather than as flat transparency.
          Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: EchoTokens.edgeHighlight(level, tint: tint),
                  borderRadius: br,
                ),
              ),
            ),
          ),
          if (padding != null) Padding(padding: padding!, child: child) else child,
        ],
      ),
    );

    if (sigma > 0) {
      surface = BackdropFilter(filter: EchoBlur.of(sigma), child: surface);
    }

    surface = ClipRRect(borderRadius: br, clipBehavior: clipBehavior, child: surface);

    if (border) {
      surface = Container(
        decoration: BoxDecoration(
          borderRadius: br,
          border: Border.all(
            color: (glowColor ?? tint ?? Colors.white)
                .withOpacity(glowColor != null ? 0.55 : EchoTokens.depthEdge[level.clamp(0, 4)] * 0.9),
            width: glowColor != null ? 1.2 : 0.8,
          ),
        ),
        child: surface,
      );
    }

    if (glowColor != null || lift) {
      surface = DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: br,
          boxShadow: [
            if (lift) ...EchoTokens.lift(level),
            if (glowColor != null) ...EchoTokens.glow(glowColor!, strength: glowStrength),
          ],
        ),
        child: surface,
      );
    }

    if (onTap != null || onLongPress != null) {
      surface = Stack(
        children: [
          surface,
          Positioned.fill(
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: br,
                onTap: onTap,
                onLongPress: onLongPress,
                splashColor: (tint ?? EchoTokens.accent).withOpacity(0.10),
                highlightColor: (tint ?? EchoTokens.accent).withOpacity(0.06),
                child: const SizedBox.expand(),
              ),
            ),
          ),
        ],
      );
    }

    if (width != null || height != null) {
      surface = SizedBox(width: width, height: height, child: surface);
    }

    if (margin != null) {
      surface = Padding(padding: margin!, child: surface);
    }

    return surface;
  }
}

/// A capsule-shaped glass control — search fields, filter chips, floating
/// buttons.
class GlassCapsule extends StatelessWidget {
  const GlassCapsule({
    super.key,
    required this.child,
    this.level = 2,
    this.blur = true,
    this.padding = const EdgeInsets.symmetric(
      horizontal: EchoTokens.space4,
      vertical: EchoTokens.space3,
    ),
    this.onTap,
    this.selected = false,
    this.tint,
  });

  final Widget child;
  final int level;
  final bool blur;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final bool selected;
  final Color? tint;

  @override
  Widget build(BuildContext context) {
    final accent = tint ?? EchoTokens.accent;
    return GlassSurface(
      level: selected ? 4 : level,
      blur: blur,
      radius: EchoTokens.radiusCapsule,
      padding: padding,
      onTap: onTap,
      tint: selected ? accent : null,
      glowColor: selected ? accent : null,
      glowStrength: 0.6,
      lift: false,
      child: child,
    );
  }
}
