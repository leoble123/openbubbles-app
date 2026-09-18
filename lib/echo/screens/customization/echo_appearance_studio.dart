import 'dart:io';

import 'package:bluebubbles/echo/glass/echo_atmosphere.dart';
import 'package:bluebubbles/echo/glass/echo_overlays.dart';
import 'package:bluebubbles/echo/glass/glass_surface.dart';
import 'package:bluebubbles/echo/theme/echo_prefs.dart';
import 'package:bluebubbles/echo/theme/echo_tokens.dart';
import 'package:bluebubbles/echo/widgets/echo_bubble.dart';
import 'package:bluebubbles/services/services.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;

/// Chat Appearance — a small design studio rather than a list of toggles.
///
/// A live conversation preview sits at the top and every control below it
/// updates that preview immediately, because both read the same reactive
/// [EchoPrefs] the real conversation view reads.
///
/// When [chat] is given, the wallpaper and accent controls write a per-chat
/// override; otherwise they set the app-wide defaults.
class EchoAppearanceStudio extends StatefulWidget {
  const EchoAppearanceStudio({super.key, this.chatGuid, this.chatTitle});

  final String? chatGuid;
  final String? chatTitle;

  @override
  State<EchoAppearanceStudio> createState() => _EchoAppearanceStudioState();
}

class _EchoAppearanceStudioState extends State<EchoAppearanceStudio> {
  bool _pickingImage = false;

  bool get _perChat => widget.chatGuid != null;

  Color get _accent => echoPrefs.accentFor(widget.chatGuid);

  String? get _wallpaper => echoPrefs.wallpaperFor(widget.chatGuid);

  Future<void> _setAccent(Color color) async {
    if (_perChat) {
      await echoPrefs.setChatAccent(widget.chatGuid!, color);
    } else {
      await echoPrefs.setAccent(color);
    }
  }

  Future<void> _setWallpaper(String? path) async {
    if (_perChat) {
      await echoPrefs.setChatWallpaper(widget.chatGuid!, path);
    } else {
      await echoPrefs.setWallpaper(path);
    }
  }

  /// Copies the picked image into app storage, because the picker's own path
  /// lives in a cache the system is free to clear.
  Future<void> _pickWallpaper() async {
    if (_pickingImage) return;
    setState(() => _pickingImage = true);
    try {
      final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
      if (picked == null) return;

      final dir = Directory(p.join(fs.appDocDir.path, 'echo', 'wallpapers'));
      if (!await dir.exists()) await dir.create(recursive: true);
      final dest = p.join(
        dir.path,
        '${DateTime.now().millisecondsSinceEpoch}${p.extension(picked.path)}',
      );
      await File(picked.path).copy(dest);
      await _setWallpaper(dest);
    } catch (e) {
      if (!mounted) return;
      showEchoDialog(
        context: context,
        builder: (context) => _ErrorDialog(message: 'That image could not be used: $e'),
      );
    } finally {
      if (mounted) setState(() => _pickingImage = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return Obx(() {
      final accent = _accent;
      return EchoAtmosphere(
        wallpaperPath: _wallpaper,
        accent: accent,
        drift: echoPrefs.ambientMotion.value,
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: SafeArea(
            child: Column(
              children: [
                _StudioHeader(
                  title: 'Chat Appearance',
                  subtitle: _perChat ? widget.chatTitle : 'Applies everywhere',
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(
                      EchoTokens.space4,
                      0,
                      EchoTokens.space4,
                      EchoTokens.space6,
                    ),
                    children: [
                      _PreviewCard(accent: accent, wallpaper: _wallpaper),
                      const SizedBox(height: EchoTokens.space5),

                      const _SectionLabel('Background'),
                      _WallpaperRow(
                        current: _wallpaper,
                        busy: _pickingImage,
                        accent: accent,
                        onPick: _pickWallpaper,
                        onClear: () => _setWallpaper(null),
                      ),
                      const SizedBox(height: EchoTokens.space5),

                      const _SectionLabel('Accent'),
                      _AccentRow(selected: accent, onSelect: _setAccent),
                      if (_perChat) ...[
                        const SizedBox(height: EchoTokens.space2),
                        _ResetLink(
                          label: 'Use the app accent',
                          onTap: () => echoPrefs.setChatAccent(widget.chatGuid!, null),
                        ),
                      ],
                      const SizedBox(height: EchoTokens.space5),

                      const _SectionLabel('Bubble style'),
                      _Segmented<EchoBubbleStyle>(
                        values: EchoBubbleStyle.values,
                        selected: echoPrefs.bubbleStyle.value,
                        labelFor: (v) => v.label,
                        accent: accent,
                        onSelect: echoPrefs.setBubbleStyle,
                      ),
                      const SizedBox(height: EchoTokens.space5),

                      const _SectionLabel('Density'),
                      _Segmented<EchoDensity>(
                        values: EchoDensity.values,
                        selected: echoPrefs.density.value,
                        labelFor: (v) => v == EchoDensity.compact ? 'Compact' : 'Comfortable',
                        accent: accent,
                        onSelect: echoPrefs.setDensity,
                      ),
                      const SizedBox(height: EchoTokens.space5),

                      const _SectionLabel('Glass'),
                      GlassSurface(
                        level: 2,
                        padding: const EdgeInsets.fromLTRB(
                          EchoTokens.space4,
                          EchoTokens.space3,
                          EchoTokens.space4,
                          EchoTokens.space2,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text('Blur intensity', style: text.titleSmall),
                                ),
                                Text(
                                  echoPrefs.blur.value == 0
                                      ? 'Off'
                                      : '${(echoPrefs.blur.value * 100).round()}%',
                                  style: text.labelMedium?.copyWith(color: accent),
                                ),
                              ],
                            ),
                            Slider(
                              value: echoPrefs.blur.value,
                              onChanged: (v) => echoPrefs.setBlur(v),
                              activeColor: accent,
                            ),
                            Text(
                              'Lower this if scrolling ever feels less than smooth. '
                              'Surfaces stay readable — they become more opaque instead.',
                              style: text.labelSmall,
                            ),
                            const SizedBox(height: EchoTokens.space2),
                          ],
                        ),
                      ),
                      const SizedBox(height: EchoTokens.space5),

                      const _SectionLabel('Details'),
                      GlassSurface(
                        level: 2,
                        child: Column(
                          children: [
                            _SwitchRow(
                              label: 'Message timestamps',
                              value: echoPrefs.showTimestamps.value,
                              accent: accent,
                              onChanged: echoPrefs.setShowTimestamps,
                            ),
                            const Divider(height: 1),
                            _SwitchRow(
                              label: 'Contact photos',
                              value: echoPrefs.showContactPhotos.value,
                              accent: accent,
                              onChanged: echoPrefs.setShowContactPhotos,
                            ),
                            const Divider(height: 1),
                            _SwitchRow(
                              label: 'Ambient background motion',
                              value: echoPrefs.ambientMotion.value,
                              accent: accent,
                              onChanged: echoPrefs.setAmbientMotion,
                            ),
                            const Divider(height: 1),
                            _SwitchRow(
                              label: 'Increase contrast',
                              subtitle: 'Makes glass surfaces more opaque for readability.',
                              value: echoPrefs.highContrast.value,
                              accent: accent,
                              onChanged: echoPrefs.setHighContrast,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    });
  }
}

class _StudioHeader extends StatelessWidget {
  const _StudioHeader({required this.title, this.subtitle});

  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        EchoTokens.space2,
        EchoTokens.space2,
        EchoTokens.space4,
        EchoTokens.space3,
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 19),
            color: EchoTokens.textPrimary,
            tooltip: 'Back',
            onPressed: () => Navigator.of(context).pop(),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(title, style: text.headlineMedium),
                if (subtitle != null)
                  Text(subtitle!, style: text.labelSmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// The live preview. Reads the same preferences the real conversation view
/// reads, so what is shown here is what the conversation will look like.
class _PreviewCard extends StatelessWidget {
  const _PreviewCard({required this.accent, required this.wallpaper});

  final Color accent;
  final String? wallpaper;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final compact = echoPrefs.density.value == EchoDensity.compact;

    return ClipRRect(
      borderRadius: BorderRadius.circular(EchoTokens.radiusXl),
      child: SizedBox(
        height: 250,
        child: EchoAtmosphere(
          wallpaperPath: wallpaper,
          accent: accent,
          drift: false,
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: EchoTokens.space4,
              vertical: compact ? EchoTokens.space3 : EchoTokens.space4,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                EchoBubble(
                  text: 'This is what your chat will look like.',
                  fromMe: false,
                  accent: accent,
                  style: echoPrefs.bubbleStyle.value,
                  compact: compact,
                  timestamp: echoPrefs.showTimestamps.value ? '9:41' : null,
                ),
                SizedBox(height: compact ? 3 : EchoTokens.space2),
                EchoBubble(
                  text: 'You can change the background, bubble style and more.',
                  fromMe: true,
                  accent: accent,
                  style: echoPrefs.bubbleStyle.value,
                  compact: compact,
                  timestamp: echoPrefs.showTimestamps.value ? '9:41' : null,
                ),
                SizedBox(height: compact ? 3 : EchoTokens.space2),
                EchoBubble(
                  text: 'Looks good.',
                  fromMe: true,
                  accent: accent,
                  style: echoPrefs.bubbleStyle.value,
                  compact: compact,
                  timestamp: echoPrefs.showTimestamps.value ? '9:41' : null,
                ),
                const SizedBox(height: EchoTokens.space2),
                Text('Preview', style: text.labelSmall),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: EchoTokens.space2, bottom: EchoTokens.space2),
      child: Text(
        label.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(letterSpacing: 1.6),
      ),
    );
  }
}

class _WallpaperRow extends StatelessWidget {
  const _WallpaperRow({
    required this.current,
    required this.busy,
    required this.accent,
    required this.onPick,
    required this.onClear,
  });

  final String? current;
  final bool busy;
  final Color accent;
  final VoidCallback onPick;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final hasImage = current != null && current!.isNotEmpty && File(current!).existsSync();

    return SizedBox(
      height: 96,
      child: Row(
        children: [
          // Add from the photo library.
          GlassSurface(
            level: 2,
            width: 76,
            radius: EchoTokens.radiusLg,
            onTap: busy ? null : onPick,
            child: Center(
              child: busy
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Icon(Icons.add_photo_alternate_outlined, color: accent),
            ),
          ),
          const SizedBox(width: EchoTokens.space3),
          // The generated atmosphere — always available, no asset needed.
          _WallpaperTile(
            selected: !hasImage,
            accent: accent,
            onTap: onClear,
            label: 'Atmosphere',
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(-0.5, -0.85),
                  radius: 1.5,
                  colors: [
                    Color.lerp(const Color(0xFF1B2A44), accent, 0.45)!,
                    const Color(0xFF0C1019),
                    EchoTokens.voidBlack,
                  ],
                ),
              ),
              child: const SizedBox.expand(),
            ),
          ),
          if (hasImage) ...[
            const SizedBox(width: EchoTokens.space3),
            _WallpaperTile(
              selected: true,
              accent: accent,
              onTap: () {},
              label: 'Yours',
              child: Image.file(File(current!), fit: BoxFit.cover),
            ),
          ],
          const SizedBox(width: EchoTokens.space3),
          Expanded(
            child: Text(
              hasImage
                  ? 'Your image sits behind the conversation.'
                  : 'A generated background tinted by your accent.',
              style: text.labelSmall,
            ),
          ),
        ],
      ),
    );
  }
}

class _WallpaperTile extends StatelessWidget {
  const _WallpaperTile({
    required this.selected,
    required this.accent,
    required this.onTap,
    required this.label,
    required this.child,
  });

  final bool selected;
  final Color accent;
  final VoidCallback onTap;
  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 66,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(EchoTokens.radiusLg),
            border: Border.all(
              color: selected ? accent : Colors.white.withOpacity(0.12),
              width: selected ? 2 : 1,
            ),
            boxShadow: selected ? EchoTokens.glow(accent, strength: 0.5) : null,
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            fit: StackFit.expand,
            children: [
              child,
              if (selected)
                Align(
                  alignment: Alignment.bottomRight,
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Icon(Icons.check_circle_rounded, size: 15, color: accent),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AccentRow extends StatelessWidget {
  const _AccentRow({required this.selected, required this.onSelect});

  final Color selected;
  final ValueChanged<Color> onSelect;

  @override
  Widget build(BuildContext context) {
    final entries = EchoTokens.accentPresets.entries.toList();

    return SizedBox(
      height: 58,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: entries.length,
        separatorBuilder: (_, __) => const SizedBox(width: EchoTokens.space3),
        itemBuilder: (context, i) {
          final entry = entries[i];
          final isSelected = entry.value.value == selected.value;
          return Semantics(
            button: true,
            selected: isSelected,
            label: entry.key,
            child: GestureDetector(
              onTap: () => onSelect(entry.value),
              child: Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [entry.value, entry.value.withOpacity(0.55)],
                  ),
                  border: Border.all(
                    color: isSelected ? Colors.white : Colors.white.withOpacity(0.15),
                    width: isSelected ? 2.4 : 1,
                  ),
                  boxShadow: isSelected ? EchoTokens.glow(entry.value, strength: 0.7) : null,
                ),
                child: isSelected
                    ? const Icon(Icons.check_rounded, color: Colors.white, size: 21)
                    : null,
              ),
            ),
          );
        },
      ),
    );
  }
}

class _Segmented<T> extends StatelessWidget {
  const _Segmented({
    required this.values,
    required this.selected,
    required this.labelFor,
    required this.accent,
    required this.onSelect,
  });

  final List<T> values;
  final T selected;
  final String Function(T) labelFor;
  final Color accent;
  final ValueChanged<T> onSelect;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return GlassSurface(
      level: 1,
      radius: EchoTokens.radiusCapsule,
      padding: const EdgeInsets.all(4),
      lift: false,
      child: Row(
        children: values.map((v) {
          final isSelected = v == selected;
          return Expanded(
            child: GestureDetector(
              onTap: () => onSelect(v),
              child: AnimatedContainer(
                duration: EchoTokens.fast,
                padding: const EdgeInsets.symmetric(vertical: EchoTokens.space3),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(EchoTokens.radiusCapsule),
                  color: isSelected ? accent.withOpacity(0.24) : Colors.transparent,
                  border: Border.all(
                    color: isSelected ? accent : Colors.transparent,
                    width: 1,
                  ),
                ),
                child: Text(
                  labelFor(v),
                  textAlign: TextAlign.center,
                  style: text.labelMedium?.copyWith(
                    color: isSelected ? Colors.white : EchoTokens.textSecondary,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _SwitchRow extends StatelessWidget {
  const _SwitchRow({
    required this.label,
    required this.value,
    required this.accent,
    required this.onChanged,
    this.subtitle,
  });

  final String label;
  final String? subtitle;
  final bool value;
  final Color accent;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        EchoTokens.space4,
        EchoTokens.space3,
        EchoTokens.space3,
        EchoTokens.space3,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(label, style: text.titleSmall),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(subtitle!, style: text.labelSmall),
                ],
              ],
            ),
          ),
          Switch(value: value, onChanged: onChanged, activeColor: accent),
        ],
      ),
    );
  }
}

class _ResetLink extends StatelessWidget {
  const _ResetLink({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: TextButton(
        onPressed: onTap,
        style: TextButton.styleFrom(foregroundColor: EchoTokens.accentIce),
        child: Text(label),
      ),
    );
  }
}

class _ErrorDialog extends StatelessWidget {
  const _ErrorDialog({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.all(EchoTokens.space5),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline_rounded, color: EchoTokens.danger, size: 30),
          const SizedBox(height: EchoTokens.space3),
          Text("That didn't work", style: text.titleLarge),
          const SizedBox(height: EchoTokens.space2),
          Text(message, style: text.bodySmall, textAlign: TextAlign.center),
          const SizedBox(height: EchoTokens.space4),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
