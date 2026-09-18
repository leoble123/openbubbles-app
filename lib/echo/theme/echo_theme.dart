import 'package:bluebubbles/echo/theme/echo_tokens.dart';
import 'package:bluebubbles/helpers/ui/theme_helpers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Echo's [ThemeData].
///
/// Echo is dark-first, so there is one theme rather than a light/dark pair.
/// The [BubbleColors] and [BubbleText] extensions are populated because shared
/// message-rendering helpers inherited from the OpenBubbles stack read them.
class EchoTheme {
  const EchoTheme._();

  static const String fontFamily = 'Roboto';

  static ThemeData build({Color accent = EchoTokens.accent}) {
    final scheme = ColorScheme.dark(
      primary: accent,
      onPrimary: const Color(0xFF04121F),
      primaryContainer: accent.withOpacity(0.22),
      onPrimaryContainer: EchoTokens.textPrimary,
      secondary: EchoTokens.accentIce,
      onSecondary: const Color(0xFF04121F),
      surface: EchoTokens.charcoalRaised,
      onSurface: EchoTokens.textPrimary,
      surfaceVariant: const Color(0xFF1A1F2C),
      onSurfaceVariant: EchoTokens.textSecondary,
      background: EchoTokens.charcoal,
      onBackground: EchoTokens.textPrimary,
      error: EchoTokens.danger,
      onError: Colors.white,
      outline: Colors.white.withOpacity(0.14),
      outlineVariant: Colors.white.withOpacity(0.08),
    );

    final text = _textTheme(scheme);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: scheme,
      fontFamily: fontFamily,
      textTheme: text,
      // Echo screens paint their own atmosphere and opt into a transparent
      // Scaffold themselves; screens inherited from the OpenBubbles stack still
      // get a solid charcoal floor so nothing renders over the void.
      scaffoldBackgroundColor: EchoTokens.charcoal,
      canvasColor: EchoTokens.charcoal,
      dialogBackgroundColor: Colors.transparent,
      splashFactory: InkSparkle.splashFactory,
      splashColor: accent.withOpacity(0.10),
      highlightColor: accent.withOpacity(0.06),
      dividerTheme: DividerThemeData(
        color: Colors.white.withOpacity(0.07),
        space: 1,
        thickness: 1,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        iconTheme: const IconThemeData(color: EchoTokens.textPrimary),
        titleTextStyle: text.titleLarge,
        systemOverlayStyle: SystemUiOverlayStyle.light.copyWith(
          statusBarColor: Colors.transparent,
          systemNavigationBarColor: Colors.transparent,
          systemNavigationBarDividerColor: Colors.transparent,
        ),
      ),
      iconTheme: const IconThemeData(color: EchoTokens.textPrimary, size: 22),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: accent,
        selectionColor: accent.withOpacity(0.32),
        selectionHandleColor: accent,
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: accent,
        inactiveTrackColor: Colors.white.withOpacity(0.12),
        thumbColor: Colors.white,
        overlayColor: accent.withOpacity(0.16),
        trackHeight: 3,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? Colors.white : const Color(0xFF8D94A5),
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? accent : Colors.white.withOpacity(0.10),
        ),
        trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: accent,
        linearTrackColor: Colors.white.withOpacity(0.10),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: EchoTokens.charcoalRaised,
        contentTextStyle: text.bodyMedium,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(EchoTokens.radiusMd)),
      ),
      extensions: <ThemeExtension<dynamic>>[
        BubbleColors(
          iMessageBubbleColor: accent,
          oniMessageBubbleColor: Colors.white,
          smsBubbleColor: EchoTokens.success,
          onSmsBubbleColor: Colors.white,
          receivedBubbleColor: const Color(0xFF1C2130),
          onReceivedBubbleColor: EchoTokens.textPrimary,
        ),
        BubbleText(bubbleText: text.bodyMedium!.copyWith(fontSize: 15, height: 1.32)),
      ],
    );
  }

  static TextTheme _textTheme(ColorScheme scheme) {
    const primary = EchoTokens.textPrimary;
    const secondary = EchoTokens.textSecondary;
    return const TextTheme(
      displayLarge: TextStyle(fontSize: 42, fontWeight: FontWeight.w700, color: primary, height: 1.1, letterSpacing: -0.8),
      displayMedium: TextStyle(fontSize: 34, fontWeight: FontWeight.w700, color: primary, height: 1.12, letterSpacing: -0.6),
      headlineLarge: TextStyle(fontSize: 28, fontWeight: FontWeight.w600, color: primary, letterSpacing: -0.4),
      headlineMedium: TextStyle(fontSize: 24, fontWeight: FontWeight.w600, color: primary, letterSpacing: -0.3),
      titleLarge: TextStyle(fontSize: 19, fontWeight: FontWeight.w600, color: primary, letterSpacing: -0.2),
      titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: primary),
      titleSmall: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: primary),
      bodyLarge: TextStyle(fontSize: 16, color: primary, height: 1.35),
      bodyMedium: TextStyle(fontSize: 14.5, color: primary, height: 1.35),
      bodySmall: TextStyle(fontSize: 13, color: secondary, height: 1.3),
      labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: primary),
      labelMedium: TextStyle(fontSize: 12.5, color: secondary, fontWeight: FontWeight.w500),
      labelSmall: TextStyle(fontSize: 11.5, color: EchoTokens.textTertiary, fontWeight: FontWeight.w500),
    );
  }
}
