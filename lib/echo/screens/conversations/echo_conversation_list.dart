import 'package:bluebubbles/app/layouts/chat_creator/chat_creator.dart';
import 'package:bluebubbles/app/layouts/conversation_view/pages/conversation_view.dart';
import 'package:bluebubbles/app/layouts/settings/settings_page.dart';
import 'package:bluebubbles/database/models.dart';
import 'package:bluebubbles/echo/glass/echo_atmosphere.dart';
import 'package:bluebubbles/echo/glass/glass_surface.dart';
import 'package:bluebubbles/echo/screens/conversations/echo_chat_tile.dart';
import 'package:bluebubbles/echo/theme/echo_prefs.dart';
import 'package:bluebubbles/echo/theme/echo_tokens.dart';
import 'package:bluebubbles/services/services.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Which conversations the list is showing.
enum EchoChatFilter { all, unread, groups, contacts }

extension EchoChatFilterLabel on EchoChatFilter {
  String get label {
    switch (this) {
      case EchoChatFilter.all:
        return 'All';
      case EchoChatFilter.unread:
        return 'Unread';
      case EchoChatFilter.groups:
        return 'Groups';
      case EchoChatFilter.contacts:
        return 'Contacts';
    }
  }
}

/// Echo's conversation list.
///
/// Reads the live [ChatsService] list, so pinning, ordering, unread state and
/// incoming messages all behave exactly as they do in the rest of the app.
class EchoConversationList extends StatefulWidget {
  const EchoConversationList({super.key});

  @override
  State<EchoConversationList> createState() => _EchoConversationListState();
}

class _EchoConversationListState extends State<EchoConversationList> {
  final ScrollController _scroll = ScrollController();
  final TextEditingController _search = TextEditingController();
  final FocusNode _searchFocus = FocusNode();

  EchoChatFilter _filter = EchoChatFilter.all;
  String _query = '';

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
    _scroll.dispose();
    _search.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  Color get _accent => Theme.of(context).colorScheme.primary;

  List<Chat> _visible(List<Chat> all) {
    return all.where((chat) {
      switch (_filter) {
        case EchoChatFilter.unread:
          if (!GlobalChatService.unreadState(chat.guid).value) return false;
          break;
        case EchoChatFilter.groups:
          if (!chat.isGroup) return false;
          break;
        case EchoChatFilter.contacts:
          if (chat.isGroup) return false;
          break;
        case EchoChatFilter.all:
          break;
      }

      if (_query.isEmpty) return true;
      // Filters what is on screen. Full message-content search lives in the
      // dedicated search view; this never claims to search message bodies.
      final title = chat.properTitle.toLowerCase();
      if (title.contains(_query)) return true;
      return chat.participants.any((h) =>
          h.displayName.toLowerCase().contains(_query) ||
          h.address.toLowerCase().contains(_query));
    }).toList();
  }

  void _openChat(Chat chat) {
    ns.pushAndRemoveUntil(context, ConversationView(chat: chat), (route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() => EchoAtmosphere(
      accent: _accent,
      wallpaperPath: echoPrefs.wallpaper.value,
      drift: echoPrefs.ambientMotion.value,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              _Header(
                accent: _accent,
                searchController: _search,
                searchFocus: _searchFocus,
                filter: _filter,
                onFilter: (f) => setState(() => _filter = f),
                onCompose: () => ns.push(context, const ChatCreator()),
              ),
              Expanded(
                child: Obx(() {
                  final visible = _visible(chats.chats);

                  if (!chats.loadedChatBatch.value) {
                    return const Center(
                      child: SizedBox(
                        width: 26,
                        height: 26,
                        child: CircularProgressIndicator(strokeWidth: 2.4),
                      ),
                    );
                  }

                  if (visible.isEmpty) {
                    return _EmptyState(
                      filter: _filter,
                      searching: _query.isNotEmpty,
                      accent: _accent,
                      onCompose: () => ns.push(context, const ChatCreator()),
                    );
                  }

                  return ListView.builder(
                    controller: _scroll,
                    padding: const EdgeInsets.only(
                      top: EchoTokens.space2,
                      bottom: EchoTokens.space7 + EchoTokens.space6,
                    ),
                    physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
                    itemCount: visible.length,
                    itemBuilder: (context, index) {
                      final chat = visible[index];
                      return EchoChatTile(
                        key: ValueKey(chat.guid),
                        chat: chat,
                        accent: echoPrefs.accentFor(chat.guid),
                        compact: echoPrefs.density.value == EchoDensity.compact,
                        onTap: () => _openChat(chat),
                      );
                    },
                  );
                }),
              ),
            ],
          ),
        ),
        floatingActionButton: _ComposeButton(
          accent: _accent,
          onTap: () => ns.push(context, const ChatCreator()),
        ),
        bottomNavigationBar: _BottomBar(
          accent: _accent,
          onSettings: () => ns.push(context, SettingsPage()),
        ),
      ),
    ));
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.accent,
    required this.searchController,
    required this.searchFocus,
    required this.filter,
    required this.onFilter,
    required this.onCompose,
  });

  final Color accent;
  final TextEditingController searchController;
  final FocusNode searchFocus;
  final EchoChatFilter filter;
  final ValueChanged<EchoChatFilter> onFilter;
  final VoidCallback onCompose;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return Padding(
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
              ShaderMask(
                shaderCallback: (rect) => LinearGradient(
                  colors: [Colors.white, accent],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ).createShader(rect),
                child: Text(
                  'echo',
                  style: text.displayMedium!.copyWith(color: Colors.white, letterSpacing: -1.4),
                ),
              ),
              GlassSurface(
                level: 3,
                radius: EchoTokens.radiusCapsule,
                padding: const EdgeInsets.all(EchoTokens.space3),
                onTap: onCompose,
                lift: false,
                child: Icon(Icons.edit_outlined, size: 20, color: accent),
              ),
            ],
          ),
          const SizedBox(height: EchoTokens.space3),
          // Search: a glass capsule with a soft inner highlight.
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
                    controller: searchController,
                    focusNode: searchFocus,
                    style: text.bodyMedium,
                    cursorColor: accent,
                    textInputAction: TextInputAction.search,
                    decoration: InputDecoration(
                      isDense: true,
                      border: InputBorder.none,
                      hintText: 'Search conversations',
                      hintStyle: text.bodyMedium!.copyWith(color: EchoTokens.textTertiary),
                      contentPadding: const EdgeInsets.symmetric(vertical: EchoTokens.space3),
                    ),
                  ),
                ),
                ValueListenableBuilder<TextEditingValue>(
                  valueListenable: searchController,
                  builder: (context, value, _) => value.text.isEmpty
                      ? const SizedBox.shrink()
                      : GestureDetector(
                          onTap: () {
                            searchController.clear();
                            searchFocus.unfocus();
                          },
                          child: const Icon(Icons.close_rounded, size: 17, color: EchoTokens.textTertiary),
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
              itemCount: EchoChatFilter.values.length,
              separatorBuilder: (_, __) => const SizedBox(width: EchoTokens.space2),
              itemBuilder: (context, i) {
                final f = EchoChatFilter.values[i];
                final selected = f == filter;
                return GlassCapsule(
                  selected: selected,
                  blur: false,
                  tint: accent,
                  onTap: () => onFilter(f),
                  padding: const EdgeInsets.symmetric(
                    horizontal: EchoTokens.space4,
                    vertical: EchoTokens.space2,
                  ),
                  child: Text(
                    f.label,
                    style: text.labelMedium!.copyWith(
                      color: selected ? Colors.white : EchoTokens.textSecondary,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ComposeButton extends StatelessWidget {
  const _ComposeButton({required this.accent, required this.onTap});

  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GlassSurface(
      level: 4,
      radius: EchoTokens.radiusCapsule,
      tint: accent,
      glowColor: accent,
      padding: const EdgeInsets.all(EchoTokens.space4),
      onTap: onTap,
      child: const Icon(Icons.add_rounded, size: 26, color: Colors.white),
    );
  }
}

class _BottomBar extends StatelessWidget {
  const _BottomBar({required this.accent, required this.onSettings});

  final Color accent;
  final VoidCallback onSettings;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        EchoTokens.space5,
        0,
        EchoTokens.space5,
        EchoTokens.space3,
      ),
      child: SafeArea(
        top: false,
        child: GlassSurface(
          level: 3,
          radius: EchoTokens.radiusCapsule,
          padding: const EdgeInsets.symmetric(
            horizontal: EchoTokens.space5,
            vertical: EchoTokens.space3,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _NavItem(
                icon: Icons.forum_rounded,
                label: 'Chats',
                selected: true,
                accent: accent,
                onTap: () {},
              ),
              Obx(() {
                final count = GlobalChatService.unreadCount.value;
                return _NavItem(
                  icon: Icons.mark_chat_unread_rounded,
                  label: count > 0 ? 'Unread $count' : 'Unread',
                  selected: false,
                  accent: accent,
                  onTap: () {},
                  enabled: false,
                );
              }),
              _NavItem(
                icon: Icons.settings_rounded,
                label: 'Settings',
                selected: false,
                accent: accent,
                onTap: onSettings,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.accent,
    required this.onTap,
    this.enabled = true,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final Color accent;
  final VoidCallback onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final color = selected ? accent : EchoTokens.textTertiary;

    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: InkWell(
        borderRadius: BorderRadius.circular(EchoTokens.radiusCapsule),
        onTap: enabled ? onTap : null,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: EchoTokens.space3,
            vertical: EchoTokens.space1,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 21, color: color),
              const SizedBox(height: 3),
              Text(
                label,
                style: text.labelSmall!.copyWith(
                  color: color,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.filter,
    required this.searching,
    required this.accent,
    required this.onCompose,
  });

  final EchoChatFilter filter;
  final bool searching;
  final Color accent;
  final VoidCallback onCompose;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    final String headline;
    final String body;
    if (searching) {
      headline = 'Nothing matches';
      body = 'Try a different name or number.';
    } else {
      switch (filter) {
        case EchoChatFilter.unread:
          headline = 'All caught up';
          body = 'No unread conversations right now.';
          break;
        case EchoChatFilter.groups:
          headline = 'No group chats';
          body = 'Group conversations will show up here.';
          break;
        case EchoChatFilter.contacts:
          headline = 'No direct chats';
          body = 'One-to-one conversations will show up here.';
          break;
        case EchoChatFilter.all:
          headline = 'No conversations yet';
          body = 'Start one and it will appear here.';
          break;
      }
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(EchoTokens.space6),
        child: GlassSurface(
          level: 2,
          radius: EchoTokens.radiusXl,
          padding: const EdgeInsets.all(EchoTokens.space6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [accent.withOpacity(0.35), Colors.transparent],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  border: Border.all(color: accent.withOpacity(0.4)),
                ),
                child: Icon(
                  searching ? Icons.search_off_rounded : Icons.forum_outlined,
                  color: accent,
                  size: 26,
                ),
              ),
              const SizedBox(height: EchoTokens.space4),
              Text(headline, style: text.titleLarge, textAlign: TextAlign.center),
              const SizedBox(height: EchoTokens.space2),
              Text(
                body,
                style: text.bodySmall!.copyWith(color: EchoTokens.textSecondary),
                textAlign: TextAlign.center,
              ),
              if (!searching && filter == EchoChatFilter.all) ...[
                const SizedBox(height: EchoTokens.space5),
                GlassCapsule(
                  level: 4,
                  tint: accent,
                  selected: true,
                  onTap: onCompose,
                  padding: const EdgeInsets.symmetric(
                    horizontal: EchoTokens.space5,
                    vertical: EchoTokens.space3,
                  ),
                  child: Text('New Message', style: text.labelLarge!.copyWith(color: Colors.white)),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
