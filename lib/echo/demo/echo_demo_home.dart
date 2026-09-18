import 'package:bluebubbles/echo/demo/echo_demo_data.dart';
import 'package:bluebubbles/echo/glass/echo_atmosphere.dart';
import 'package:bluebubbles/echo/glass/glass_surface.dart';
import 'package:bluebubbles/echo/screens/customization/echo_appearance_studio.dart';
import 'package:bluebubbles/echo/theme/echo_prefs.dart';
import 'package:bluebubbles/echo/theme/echo_tokens.dart';
import 'package:bluebubbles/echo/widgets/echo_bubble.dart';
import 'package:bluebubbles/echo/widgets/echo_wordmark.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Demo mode — a look around Echo without an account.
///
/// Everything shown is invented sample content held in memory. Demo mode never
/// reads or writes the message database, never touches account or setup state,
/// and never contacts a server. A banner says so on every screen, so the
/// preview can't be mistaken for a working connection.
class EchoDemoHome extends StatefulWidget {
  const EchoDemoHome({super.key});

  @override
  State<EchoDemoHome> createState() => _EchoDemoHomeState();
}

class _EchoDemoHomeState extends State<EchoDemoHome> {
  late final List<EchoDemoChat> _chats = buildEchoDemoChats();
  final TextEditingController _search = TextEditingController();
  String _query = '';
  int _filter = 0;

  static const _filters = ['All', 'Unread', 'Groups', 'Contacts'];

  @override
  void initState() {
    super.initState();
    _search.addListener(() {
      final q = _search.text.trim().toLowerCase();
      if (q != _query) setState(() => _query = q);
    });
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  List<EchoDemoChat> get _visible => _chats.where((c) {
        if (_filter == 1 && !c.unread) return false;
        if (_filter == 2 && !c.isGroup) return false;
        if (_filter == 3 && c.isGroup) return false;
        if (_query.isEmpty) return true;
        return c.title.toLowerCase().contains(_query);
      }).toList();

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return Obx(() {
      final accent = echoPrefs.accent.value;
      return EchoAtmosphere(
        accent: accent,
        wallpaperPath: echoPrefs.wallpaper.value,
        drift: echoPrefs.ambientMotion.value,
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: SafeArea(
            bottom: false,
            child: Column(
              children: [
                const EchoDemoBanner(),
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    EchoTokens.space4,
                    EchoTokens.space2,
                    EchoTokens.space4,
                    EchoTokens.space2,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          EchoWordmark(size: 34, accent: accent),
                          GlassSurface(
                            level: 3,
                            radius: EchoTokens.radiusCapsule,
                            padding: const EdgeInsets.all(EchoTokens.space3),
                            lift: false,
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => const EchoAppearanceStudio(),
                              ),
                            ),
                            child: Icon(Icons.palette_outlined, size: 20, color: accent),
                          ),
                        ],
                      ),
                      const SizedBox(height: EchoTokens.space3),
                      GlassSurface(
                        level: 2,
                        radius: EchoTokens.radiusCapsule,
                        lift: false,
                        padding: const EdgeInsets.symmetric(horizontal: EchoTokens.space4),
                        child: Row(
                          children: [
                            const Icon(Icons.search_rounded, size: 19, color: EchoTokens.textTertiary),
                            const SizedBox(width: EchoTokens.space2),
                            Expanded(
                              child: TextField(
                                controller: _search,
                                style: text.bodyMedium,
                                cursorColor: accent,
                                decoration: InputDecoration(
                                  isDense: true,
                                  border: InputBorder.none,
                                  hintText: 'Search conversations',
                                  hintStyle: text.bodyMedium!.copyWith(color: EchoTokens.textTertiary),
                                  contentPadding: const EdgeInsets.symmetric(vertical: EchoTokens.space3),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: EchoTokens.space3),
                      SizedBox(
                        height: 34,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: _filters.length,
                          separatorBuilder: (_, __) => const SizedBox(width: EchoTokens.space2),
                          itemBuilder: (context, i) => GlassCapsule(
                            selected: i == _filter,
                            blur: false,
                            tint: accent,
                            onTap: () => setState(() => _filter = i),
                            padding: const EdgeInsets.symmetric(
                              horizontal: EchoTokens.space4,
                              vertical: EchoTokens.space2,
                            ),
                            child: Text(
                              _filters[i],
                              style: text.labelMedium!.copyWith(
                                color: i == _filter ? Colors.white : EchoTokens.textSecondary,
                                fontWeight: i == _filter ? FontWeight.w700 : FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.only(
                      top: EchoTokens.space2,
                      bottom: EchoTokens.space7,
                    ),
                    physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
                    itemCount: _visible.length,
                    itemBuilder: (context, i) {
                      final chat = _visible[i];
                      return _DemoTile(
                        chat: chat,
                        accent: accent,
                        compact: echoPrefs.density.value == EchoDensity.compact,
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => EchoDemoConversation(chat: chat),
                          ),
                        ),
                      );
                    },
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

/// Persistent, unmissable marker that this is sample content.
class EchoDemoBanner extends StatelessWidget {
  const EchoDemoBanner({super.key, this.showExit = true});

  final bool showExit;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        EchoTokens.space4,
        EchoTokens.space2,
        EchoTokens.space4,
        0,
      ),
      child: GlassSurface(
        level: 2,
        radius: EchoTokens.radiusCapsule,
        tint: EchoTokens.warning,
        lift: false,
        padding: const EdgeInsets.symmetric(
          horizontal: EchoTokens.space4,
          vertical: EchoTokens.space2,
        ),
        child: Row(
          children: [
            const Icon(Icons.visibility_outlined, size: 15, color: EchoTokens.warning),
            const SizedBox(width: EchoTokens.space2),
            Expanded(
              child: Text(
                'Demo — sample conversations, not a real account',
                style: text.labelSmall?.copyWith(color: EchoTokens.warning),
              ),
            ),
            if (showExit)
              GestureDetector(
                onTap: () => Navigator.of(context).popUntil((r) => r.isFirst),
                child: Text(
                  'Exit',
                  style: text.labelSmall?.copyWith(
                    color: EchoTokens.warning,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _DemoTile extends StatelessWidget {
  const _DemoTile({
    required this.chat,
    required this.accent,
    required this.onTap,
    required this.compact,
  });

  final EchoDemoChat chat;
  final Color accent;
  final VoidCallback onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: EchoTokens.space3,
        vertical: compact ? 2 : EchoTokens.space1,
      ),
      child: GlassSurface(
        level: chat.unread ? 2 : 1,
        blur: false,
        border: chat.unread,
        lift: false,
        tint: chat.unread ? accent : null,
        onTap: onTap,
        padding: EdgeInsets.symmetric(
          horizontal: EchoTokens.space3,
          vertical: compact ? EchoTokens.space2 : EchoTokens.space3,
        ),
        child: Row(
          children: [
            DemoAvatar(chat: chat, size: compact ? 44 : 50, ring: chat.unread, accent: accent),
            const SizedBox(width: EchoTokens.space3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      if (chat.pinned) ...[
                        Icon(Icons.push_pin_rounded, size: 13, color: accent.withOpacity(0.9)),
                        const SizedBox(width: 4),
                      ],
                      Flexible(
                        child: Text(
                          chat.title,
                          style: text.titleMedium!.copyWith(
                            fontWeight: chat.unread ? FontWeight.w700 : FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (chat.muted) ...[
                        const SizedBox(width: 5),
                        const Icon(Icons.notifications_off_rounded,
                            size: 13, color: EchoTokens.textTertiary),
                      ],
                      const SizedBox(width: EchoTokens.space2),
                      Text(
                        chat.timeLabel,
                        style: text.labelSmall!.copyWith(
                          color: chat.unread ? accent : EchoTokens.textTertiary,
                          fontWeight: chat.unread ? FontWeight.w600 : FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          chat.preview,
                          style: text.bodySmall!.copyWith(
                            color: chat.unread
                                ? EchoTokens.textPrimary.withOpacity(0.86)
                                : EchoTokens.textSecondary,
                            fontWeight: chat.unread ? FontWeight.w500 : FontWeight.w400,
                          ),
                          maxLines: compact ? 1 : 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (chat.unread) ...[
                        const SizedBox(width: EchoTokens.space2),
                        Padding(
                          padding: const EdgeInsets.only(top: 3),
                          child: Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                colors: [EchoTokens.accentIce, accent],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              boxShadow: [
                                BoxShadow(color: accent.withOpacity(0.55), blurRadius: 10, spreadRadius: -1),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Initial-based avatar. Demo mode has no contacts to read from, and inventing
/// contact photos would misrepresent what the real app shows.
class DemoAvatar extends StatelessWidget {
  const DemoAvatar({
    super.key,
    required this.chat,
    required this.size,
    required this.accent,
    this.ring = false,
  });

  final EchoDemoChat chat;
  final double size;
  final Color accent;
  final bool ring;

  @override
  Widget build(BuildContext context) {
    final avatar = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [chat.color.withOpacity(0.85), chat.color.withOpacity(0.35)],
        ),
      ),
      child: Center(
        child: Text(
          chat.initials,
          style: TextStyle(
            fontSize: size * 0.38,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ),
    );

    if (!ring) return avatar;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: accent, width: 2),
        boxShadow: [BoxShadow(color: accent.withOpacity(0.38), blurRadius: 14, spreadRadius: -2)],
      ),
      child: Padding(padding: const EdgeInsets.all(2.5), child: avatar),
    );
  }
}

/// A sample thread. Typing appends locally so the composer can be judged; the
/// banner makes clear nothing is sent anywhere.
class EchoDemoConversation extends StatefulWidget {
  const EchoDemoConversation({super.key, required this.chat});

  final EchoDemoChat chat;

  @override
  State<EchoDemoConversation> createState() => _EchoDemoConversationState();
}

class _EchoDemoConversationState extends State<EchoDemoConversation> {
  final TextEditingController _composer = TextEditingController();
  final ScrollController _scroll = ScrollController();
  late final List<EchoDemoMessage> _messages = List.of(widget.chat.messages);

  @override
  void dispose() {
    _composer.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _send() {
    final value = _composer.text.trim();
    if (value.isEmpty) return;
    setState(() {
      _messages.add(EchoDemoMessage(text: value, fromMe: true, time: 'now'));
      _composer.clear();
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: EchoTokens.medium,
          curve: EchoTokens.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return Obx(() {
      final accent = echoPrefs.accent.value;
      final compact = echoPrefs.density.value == EchoDensity.compact;

      return EchoAtmosphere(
        accent: accent,
        wallpaperPath: echoPrefs.wallpaper.value,
        drift: false,
        child: Scaffold(
          backgroundColor: Colors.transparent,
          resizeToAvoidBottomInset: true,
          body: SafeArea(
            child: Column(
              children: [
                const EchoDemoBanner(showExit: false),
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    EchoTokens.space3,
                    EchoTokens.space2,
                    EchoTokens.space3,
                    0,
                  ),
                  child: GlassSurface(
                    level: 3,
                    radius: EchoTokens.radiusXl,
                    padding: const EdgeInsets.symmetric(
                      horizontal: EchoTokens.space2,
                      vertical: EchoTokens.space2,
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 19),
                          color: EchoTokens.textPrimary,
                          tooltip: 'Back',
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                        DemoAvatar(chat: widget.chat, size: 38, accent: accent),
                        const SizedBox(width: EchoTokens.space3),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(widget.chat.title, style: text.titleMedium),
                              if (widget.chat.isGroup)
                                Text(
                                  '${widget.chat.participants} people',
                                  style: text.labelSmall,
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    controller: _scroll,
                    padding: const EdgeInsets.fromLTRB(
                      EchoTokens.space4,
                      EchoTokens.space4,
                      EchoTokens.space4,
                      EchoTokens.space3,
                    ),
                    physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
                    itemCount: _messages.length,
                    itemBuilder: (context, i) {
                      final m = _messages[i];
                      final showSender = widget.chat.isGroup &&
                          !m.fromMe &&
                          m.sender != null &&
                          (i == 0 || _messages[i - 1].sender != m.sender || _messages[i - 1].fromMe);

                      return Padding(
                        padding: EdgeInsets.only(bottom: compact ? 3 : EchoTokens.space2),
                        child: Column(
                          crossAxisAlignment:
                              m.fromMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                          children: [
                            if (showSender)
                              Padding(
                                padding: const EdgeInsets.only(left: 14, bottom: 3),
                                child: Text(m.sender!, style: text.labelSmall),
                              ),
                            EchoBubble(
                              text: m.text,
                              fromMe: m.fromMe,
                              accent: accent,
                              style: echoPrefs.bubbleStyle.value,
                              compact: compact,
                              timestamp: echoPrefs.showTimestamps.value ? m.time : null,
                            ),
                            if (m.reaction != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 2, left: 12, right: 12),
                                child: Text(m.reaction!, style: const TextStyle(fontSize: 15)),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    EchoTokens.space3,
                    0,
                    EchoTokens.space3,
                    EchoTokens.space3,
                  ),
                  child: GlassSurface(
                    level: 3,
                    radius: EchoTokens.radiusLg,
                    padding: const EdgeInsets.symmetric(
                      horizontal: EchoTokens.space4,
                      vertical: EchoTokens.space1,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _composer,
                            style: text.bodyMedium,
                            cursorColor: accent,
                            minLines: 1,
                            maxLines: 4,
                            textInputAction: TextInputAction.send,
                            onSubmitted: (_) => _send(),
                            decoration: InputDecoration(
                              isDense: true,
                              border: InputBorder.none,
                              hintText: 'Message (stays on this device)',
                              hintStyle: text.bodyMedium!.copyWith(color: EchoTokens.textTertiary),
                              contentPadding: const EdgeInsets.symmetric(vertical: EchoTokens.space3),
                            ),
                          ),
                        ),
                        const SizedBox(width: EchoTokens.space2),
                        GestureDetector(
                          onTap: _send,
                          child: Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [EchoTokens.accentIce, accent],
                              ),
                              boxShadow: EchoTokens.glow(accent, strength: 0.6),
                            ),
                            child: const Icon(Icons.arrow_upward_rounded, size: 19, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
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
