import 'package:bluebubbles/echo/glass/glass_surface.dart';
import 'package:bluebubbles/echo/theme/echo_tokens.dart';
import 'package:bluebubbles/services/services.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Bubble shapes offered by the customization studio.
enum EchoBubbleStyle { glass, rounded, pill, outline }

extension EchoBubbleStyleLabel on EchoBubbleStyle {
  String get label {
    switch (this) {
      case EchoBubbleStyle.glass:
        return 'Glass';
      case EchoBubbleStyle.rounded:
        return 'Rounded';
      case EchoBubbleStyle.pill:
        return 'Pill';
      case EchoBubbleStyle.outline:
        return 'Outline';
    }
  }
}

enum EchoDensity { comfortable, compact }

/// Echo's appearance preferences.
///
/// Persisted through the settings service's existing [SharedPreferences]
/// instance, so nothing new has to be wired into the database model. Values are
/// reactive, which is what lets the customization studio's preview update the
/// moment a control moves.
class EchoPrefs extends GetxService {
  static const _kAccent = 'echo-accent';
  static const _kWallpaper = 'echo-wallpaper';
  static const _kChatWallpaper = 'echo-wallpaper-';
  static const _kChatAccent = 'echo-accent-';
  static const _kBubble = 'echo-bubble-style';
  static const _kBlur = 'echo-blur';
  static const _kDensity = 'echo-density';
  static const _kTimestamps = 'echo-timestamps';
  static const _kPhotos = 'echo-contact-photos';
  static const _kContrast = 'echo-high-contrast';
  static const _kDrift = 'echo-ambient-motion';

  final Rx<Color> accent = Rx<Color>(EchoTokens.accent);
  final RxnString wallpaper = RxnString();
  final Rx<EchoBubbleStyle> bubbleStyle = EchoBubbleStyle.glass.obs;

  /// 0 disables blur entirely; 1 is the design default.
  final RxDouble blur = 1.0.obs;
  final Rx<EchoDensity> density = EchoDensity.comfortable.obs;
  final RxBool showTimestamps = true.obs;
  final RxBool showContactPhotos = true.obs;
  final RxBool highContrast = false.obs;
  final RxBool ambientMotion = true.obs;

  /// Per-chat overrides, kept in memory and mirrored to preferences.
  final RxMap<String, String> chatWallpapers = <String, String>{}.obs;
  final RxMap<String, int> chatAccents = <String, int>{}.obs;

  void load() {
    final p = ss.prefs;
    final accentValue = p.getInt(_kAccent);
    if (accentValue != null) accent.value = Color(accentValue);
    wallpaper.value = p.getString(_kWallpaper);
    final bubble = p.getInt(_kBubble);
    if (bubble != null && bubble >= 0 && bubble < EchoBubbleStyle.values.length) {
      bubbleStyle.value = EchoBubbleStyle.values[bubble];
    }
    blur.value = p.getDouble(_kBlur) ?? 1.0;
    final d = p.getInt(_kDensity);
    if (d != null && d >= 0 && d < EchoDensity.values.length) {
      density.value = EchoDensity.values[d];
    }
    showTimestamps.value = p.getBool(_kTimestamps) ?? true;
    showContactPhotos.value = p.getBool(_kPhotos) ?? true;
    highContrast.value = p.getBool(_kContrast) ?? false;
    ambientMotion.value = p.getBool(_kDrift) ?? true;

    for (final key in p.getKeys()) {
      if (key.startsWith(_kChatWallpaper)) {
        final path = p.getString(key);
        if (path != null) chatWallpapers[key.substring(_kChatWallpaper.length)] = path;
      } else if (key.startsWith(_kChatAccent)) {
        final value = p.getInt(key);
        if (value != null) chatAccents[key.substring(_kChatAccent.length)] = value;
      }
    }

    apply();
  }

  /// Pushes the values that live outside the widget tree into the glass layer.
  void apply() {
    EchoGlass.blurScale = blur.value.clamp(0.0, 1.0);
    EchoGlass.highContrast = highContrast.value;
  }

  Future<void> setAccent(Color color) async {
    accent.value = color;
    await ss.prefs.setInt(_kAccent, color.value);
  }

  Future<void> setWallpaper(String? path) async {
    wallpaper.value = path;
    if (path == null) {
      await ss.prefs.remove(_kWallpaper);
    } else {
      await ss.prefs.setString(_kWallpaper, path);
    }
  }

  Future<void> setBubbleStyle(EchoBubbleStyle style) async {
    bubbleStyle.value = style;
    await ss.prefs.setInt(_kBubble, style.index);
  }

  Future<void> setBlur(double value) async {
    blur.value = value.clamp(0.0, 1.0);
    apply();
    await ss.prefs.setDouble(_kBlur, blur.value);
  }

  Future<void> setDensity(EchoDensity value) async {
    density.value = value;
    await ss.prefs.setInt(_kDensity, value.index);
  }

  Future<void> setShowTimestamps(bool value) async {
    showTimestamps.value = value;
    await ss.prefs.setBool(_kTimestamps, value);
  }

  Future<void> setShowContactPhotos(bool value) async {
    showContactPhotos.value = value;
    await ss.prefs.setBool(_kPhotos, value);
  }

  Future<void> setHighContrast(bool value) async {
    highContrast.value = value;
    apply();
    await ss.prefs.setBool(_kContrast, value);
  }

  Future<void> setAmbientMotion(bool value) async {
    ambientMotion.value = value;
    await ss.prefs.setBool(_kDrift, value);
  }

  /// Wallpaper for a chat: its own override, else the global one.
  String? wallpaperFor(String? chatGuid) {
    if (chatGuid != null) {
      final override = chatWallpapers[chatGuid];
      if (override != null && override.isNotEmpty) return override;
    }
    return wallpaper.value;
  }

  Future<void> setChatWallpaper(String chatGuid, String? path) async {
    if (path == null || path.isEmpty) {
      chatWallpapers.remove(chatGuid);
      await ss.prefs.remove('$_kChatWallpaper$chatGuid');
    } else {
      chatWallpapers[chatGuid] = path;
      await ss.prefs.setString('$_kChatWallpaper$chatGuid', path);
    }
  }

  /// Accent for a chat: its own override, else the global accent.
  Color accentFor(String? chatGuid) {
    if (chatGuid != null) {
      final override = chatAccents[chatGuid];
      if (override != null) return Color(override);
    }
    return accent.value;
  }

  Future<void> setChatAccent(String chatGuid, Color? color) async {
    if (color == null) {
      chatAccents.remove(chatGuid);
      await ss.prefs.remove('$_kChatAccent$chatGuid');
    } else {
      chatAccents[chatGuid] = color.value;
      await ss.prefs.setInt('$_kChatAccent$chatGuid', color.value);
    }
  }
}

// ignore: non_constant_identifier_names
EchoPrefs echoPrefs = Get.isRegistered<EchoPrefs>() ? Get.find<EchoPrefs>() : Get.put(EchoPrefs());
