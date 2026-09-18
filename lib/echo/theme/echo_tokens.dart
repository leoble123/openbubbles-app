import 'dart:ui';

import 'package:flutter/material.dart';

/// Design tokens for Echo's dark cinematic / Liquid Glass direction.
///
/// Everything visual in Echo resolves back to these values so the whole app
/// reads as one system. Nothing here depends on the legacy BlueBubbles skins.
class EchoTokens {
  const EchoTokens._();

  // ---------------------------------------------------------------------------
  // Foundations — dark first.
  // ---------------------------------------------------------------------------

  /// Level 0. The floor of the app, behind any atmospheric imagery.
  static const Color voidBlack = Color(0xFF05060A);

  /// Near-black charcoal used when no wallpaper is showing.
  static const Color charcoal = Color(0xFF0B0D12);

  /// Slightly lifted charcoal for large inert regions.
  static const Color charcoalRaised = Color(0xFF121520);

  // ---------------------------------------------------------------------------
  // Accent — electric / icy blue.
  // ---------------------------------------------------------------------------

  /// Primary luminous accent.
  static const Color accent = Color(0xFF4EA8FF);

  /// Cooler, icier partner used for gradient ends and specular edges.
  static const Color accentIce = Color(0xFF7FD4FF);

  /// Deep accent used for the far end of outgoing bubble gradients.
  static const Color accentDeep = Color(0xFF1C5FD0);

  /// Accent wash for resting fills that must not shout.
  static Color get accentWash => accent.withOpacity(0.14);

  /// Alternate accent hues offered by the customization studio.
  static const Map<String, Color> accentPresets = {
    'Electric': accent,
    'Ice': Color(0xFF7FD4FF),
    'Violet': Color(0xFF9B7BFF),
    'Ember': Color(0xFFFF8A5B),
    'Mint': Color(0xFF4FE0B0),
    'Rose': Color(0xFFFF6F91),
  };

  // ---------------------------------------------------------------------------
  // Text.
  // ---------------------------------------------------------------------------

  static const Color textPrimary = Color(0xFFF2F5FA);
  static const Color textSecondary = Color(0xFFA6AEBF);
  static const Color textTertiary = Color(0xFF6E7687);
  static const Color danger = Color(0xFFFF5C5C);
  static const Color success = Color(0xFF4FE0B0);
  static const Color warning = Color(0xFFFFC46B);

  // ---------------------------------------------------------------------------
  // Depth system (spec §3).
  //
  // Each level is a fill opacity, a blur sigma and an edge treatment. Higher
  // levels are brighter, more blurred and more sharply lit — that contrast is
  // what makes the interface read as layered rather than flat.
  // ---------------------------------------------------------------------------

  /// Fill opacity of the glass at each depth level.
  static const List<double> depthFill = [0.0, 0.10, 0.18, 0.30, 0.38];

  /// Blur sigma at each depth level. Level 0 never blurs.
  ///
  /// These are deliberately modest: the spec's performance rules matter more
  /// than raw sigma, and blur cost scales with the blurred area.
  static const List<double> depthBlur = [0.0, 6.0, 10.0, 22.0, 24.0];

  /// Opacity of the specular top edge at each depth level.
  static const List<double> depthEdge = [0.0, 0.08, 0.14, 0.22, 0.30];

  /// Corner radii.
  static const double radiusSm = 12.0;
  static const double radiusMd = 18.0;
  static const double radiusLg = 26.0;
  static const double radiusXl = 34.0;
  static const double radiusCapsule = 999.0;

  /// Spacing scale.
  static const double space1 = 4.0;
  static const double space2 = 8.0;
  static const double space3 = 12.0;
  static const double space4 = 16.0;
  static const double space5 = 24.0;
  static const double space6 = 32.0;
  static const double space7 = 48.0;

  // ---------------------------------------------------------------------------
  // Motion (spec §15).
  // ---------------------------------------------------------------------------

  static const Duration fast = Duration(milliseconds: 140);
  static const Duration medium = Duration(milliseconds: 260);
  static const Duration slow = Duration(milliseconds: 420);
  static const Duration ambient = Duration(seconds: 18);

  /// Standard ease for surfaces entering and leaving.
  static const Curve easeOut = Curves.easeOutCubic;

  /// Short spring used by sheets rising from an edge.
  static const Curve spring = Curves.easeOutBack;

  /// Slow breathing curve for the QR scan target.
  static const Curve breathe = Curves.easeInOut;

  // ---------------------------------------------------------------------------
  // Glass helpers.
  // ---------------------------------------------------------------------------

  /// The tint painted over blurred content at [level].
  ///
  /// [opaque] raises the fill for surfaces sitting under body text, honouring
  /// the spec's rule that glass becomes more opaque when readability needs it.
  static Color fillFor(int level, {bool opaque = false, Color? tint}) {
    final base = tint ?? const Color(0xFF8FA6C8);
    final alpha = depthFill[level.clamp(0, 4)] * (opaque ? 1.9 : 1.0);
    return base.withOpacity(alpha.clamp(0.0, 0.92));
  }

  /// Specular highlight gradient for the top edge of a glass surface.
  static LinearGradient edgeHighlight(int level, {Color? tint}) {
    final o = depthEdge[level.clamp(0, 4)];
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        (tint ?? Colors.white).withOpacity(o),
        Colors.white.withOpacity(o * 0.25),
        Colors.transparent,
      ],
      stops: const [0.0, 0.38, 1.0],
    );
  }

  /// Accent glow used for focused / active elements (depth level 4).
  static List<BoxShadow> glow(Color color, {double strength = 1.0}) => [
        BoxShadow(
          color: color.withOpacity(0.34 * strength),
          blurRadius: 26 * strength,
          spreadRadius: -4,
        ),
        BoxShadow(
          color: color.withOpacity(0.16 * strength),
          blurRadius: 52 * strength,
          spreadRadius: -8,
        ),
      ];

  /// Ambient drop shadow that separates a floating surface from what's behind.
  static List<BoxShadow> lift(int level) => [
        BoxShadow(
          color: Colors.black.withOpacity(0.28 + level * 0.06),
          blurRadius: 18.0 + level * 8,
          offset: Offset(0, 4.0 + level * 2),
        ),
      ];

  /// Atmospheric background gradient used when no photographic wallpaper is set.
  static const RadialGradient atmosphere = RadialGradient(
    center: Alignment(-0.5, -0.85),
    radius: 1.5,
    colors: [
      Color(0xFF1B2A44),
      Color(0xFF0C1019),
      voidBlack,
    ],
    stops: [0.0, 0.55, 1.0],
  );
}

/// Image filter cache so repeated glass surfaces don't rebuild identical
/// filters every frame.
class EchoBlur {
  const EchoBlur._();

  static final Map<double, ImageFilter> _cache = {};

  static ImageFilter of(double sigma) =>
      _cache.putIfAbsent(sigma, () => ImageFilter.blur(sigmaX: sigma, sigmaY: sigma));
}
