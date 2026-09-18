import 'package:bluebubbles/database/models.dart';
import 'package:bluebubbles/echo/glass/echo_overlays.dart';
import 'package:bluebubbles/echo/screens/customization/echo_appearance_studio.dart';
import 'package:bluebubbles/echo/theme/echo_prefs.dart';
import 'package:bluebubbles/echo/theme/echo_tokens.dart';
import 'package:bluebubbles/echo/widgets/echo_avatar.dart';
import 'package:bluebubbles/services/services.dart';
import 'package:flutter/material.dart';

/// Contextual actions for a conversation, as a glass sheet rather than a
/// generic Android menu (spec §12).
///
/// Every action calls the same [Chat] method the rest of the app uses, so
/// nothing here is a display-only toggle.
Future<void> showEchoChatActions(BuildContext context, Chat chat) {
  return showEchoSheet(
    context: context,
    builder: (context) => _ChatActionsSheet(chat: chat),
  );
}

class _ChatActionsSheet extends StatefulWidget {
  const _ChatActionsSheet({required this.chat});

  final Chat chat;

  @override
  State<_ChatActionsSheet> createState() => _ChatActionsSheetState();
}

class _ChatActionsSheetState extends State<_ChatActionsSheet> {
  Chat get chat => widget.chat;

  void _act(VoidCallback action) {
    action();
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final accent = echoPrefs.accentFor(chat.guid);

    final pinned = chat.pinIndex != null;
    final muted = chat.muteType == 'mute';
    final unread = chat.hasUnreadMessage ?? false;
    final archived = chat.isArchived ?? false;

    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              EchoTokens.space5,
              EchoTokens.space2,
              EchoTokens.space5,
              EchoTokens.space4,
            ),
            child: Row(
              children: [
                EchoAvatar(chat: chat, size: 44, accent: accent),
                const SizedBox(width: EchoTokens.space3),
                Expanded(
                  child: Text(
                    chat.properTitle,
                    style: text.titleLarge,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          _Action(
            icon: pinned ? Icons.push_pin : Icons.push_pin_outlined,
            label: pinned ? 'Unpin' : 'Pin',
            accent: accent,
            active: pinned,
            onTap: () => _act(() => chat.togglePin(!pinned)),
          ),
          _Action(
            icon: unread ? Icons.mark_email_read_outlined : Icons.mark_email_unread_outlined,
            label: unread ? 'Mark as read' : 'Mark as unread',
            accent: accent,
            onTap: () => _act(() => chat.toggleHasUnread(!unread)),
          ),
          _Action(
            icon: muted ? Icons.notifications_active_outlined : Icons.notifications_off_outlined,
            label: muted ? 'Unmute' : 'Mute',
            accent: accent,
            active: muted,
            onTap: () => _act(() => chat.toggleMute(!muted)),
          ),
          _Action(
            icon: Icons.palette_outlined,
            label: 'Chat appearance',
            accent: accent,
            onTap: () {
              Navigator.of(context).pop();
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => EchoAppearanceStudio(
                    chatGuid: chat.guid,
                    chatTitle: chat.properTitle,
                  ),
                ),
              );
            },
          ),
          _Action(
            icon: archived ? Icons.unarchive_outlined : Icons.archive_outlined,
            label: archived ? 'Unarchive' : 'Archive',
            accent: accent,
            onTap: () {
              chat.toggleArchived(!archived);
              Navigator.of(context).pop();
            },
          ),
          const Divider(height: EchoTokens.space5, indent: 20, endIndent: 20),
          _Action(
            icon: Icons.delete_outline_rounded,
            label: 'Delete conversation',
            accent: EchoTokens.danger,
            destructive: true,
            onTap: () async {
              final confirmed = await showEchoDialog<bool>(
                context: context,
                builder: (context) => _ConfirmDelete(title: chat.properTitle),
              );
              if (confirmed != true) return;
              Chat.softDelete(chat);
              chats.removeChat(chat);
              if (context.mounted) Navigator.of(context).pop();
            },
          ),
          const SizedBox(height: EchoTokens.space3),
        ],
      ),
    );
  }
}

class _Action extends StatelessWidget {
  const _Action({
    required this.icon,
    required this.label,
    required this.accent,
    required this.onTap,
    this.active = false,
    this.destructive = false,
  });

  final IconData icon;
  final String label;
  final Color accent;
  final VoidCallback onTap;
  final bool active;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final color = destructive ? EchoTokens.danger : EchoTokens.textPrimary;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: EchoTokens.space5,
          vertical: EchoTokens.space3,
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: (active ? accent : Colors.white).withOpacity(active ? 0.22 : 0.06),
                border: active ? Border.all(color: accent.withOpacity(0.6)) : null,
              ),
              child: Icon(icon, size: 19, color: active ? accent : color),
            ),
            const SizedBox(width: EchoTokens.space4),
            Expanded(child: Text(label, style: text.titleSmall?.copyWith(color: color))),
          ],
        ),
      ),
    );
  }
}

class _ConfirmDelete extends StatelessWidget {
  const _ConfirmDelete({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.all(EchoTokens.space5),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: EchoTokens.danger.withOpacity(0.14),
              border: Border.all(color: EchoTokens.danger.withOpacity(0.5)),
            ),
            child: const Icon(Icons.delete_outline_rounded, color: EchoTokens.danger, size: 25),
          ),
          const SizedBox(height: EchoTokens.space4),
          Text('Delete conversation?', style: text.titleLarge, textAlign: TextAlign.center),
          const SizedBox(height: EchoTokens.space2),
          Text(
            'This removes "$title" and its messages from this device.',
            style: text.bodySmall?.copyWith(color: EchoTokens.textSecondary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: EchoTokens.space5),
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: EchoTokens.space3),
              Expanded(
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: EchoTokens.danger.withOpacity(0.85),
                    padding: const EdgeInsets.symmetric(vertical: EchoTokens.space3),
                  ),
                  child: const Text('Delete'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
