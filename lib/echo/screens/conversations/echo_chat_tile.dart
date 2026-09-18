import 'package:bluebubbles/database/models.dart';
import 'package:bluebubbles/echo/glass/glass_surface.dart';
import 'package:bluebubbles/echo/theme/echo_tokens.dart';
import 'package:bluebubbles/echo/widgets/echo_avatar.dart';
import 'package:bluebubbles/helpers/helpers.dart';
import 'package:bluebubbles/services/services.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

/// One conversation row.
///
/// Deliberately not a heavy card: unread rows get a translucent glass surface
/// and the rest stay nearly transparent so the atmosphere behind the list can
/// breathe (spec §7). No row blurs — blur here would cost a frame on every
/// scroll, which the performance rules rank above the effect.
class EchoChatTile extends StatelessWidget {
  const EchoChatTile({
    super.key,
    required this.chat,
    required this.onTap,
    this.onLongPress,
    this.accent = EchoTokens.accent,
    this.compact = false,
  });

  final Chat chat;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final Color accent;
  final bool compact;

  static String _timestamp(DateTime? date) {
    if (date == null) return '';
    final now = DateTime.now();
    final local = date.toLocal();
    final sameDay = local.year == now.year && local.month == now.month && local.day == now.day;
    if (sameDay) return DateFormat.jm().format(local);

    final yesterday = now.subtract(const Duration(days: 1));
    if (local.year == yesterday.year && local.month == yesterday.month && local.day == yesterday.day) {
      return 'Yesterday';
    }
    if (now.difference(local).inDays < 7) return DateFormat.E().format(local);
    return DateFormat.yMd().format(local);
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return Obx(() {
      final unread = GlobalChatService.unreadState(chat.guid).value;
      final muted = GlobalChatService.muteState(chat.guid).value == 'mute';
      final pinned = chat.pinIndex != null;

      final message = chat.latestMessage;
      final preview = MessageHelper.getNotificationText(message, withSender: chat.isGroup);
      final title = chat.properTitle;

      final titleStyle = text.titleMedium!.copyWith(
        fontWeight: unread ? FontWeight.w700 : FontWeight.w600,
        color: EchoTokens.textPrimary,
      );
      final previewStyle = text.bodySmall!.copyWith(
        color: unread ? EchoTokens.textPrimary.withOpacity(0.86) : EchoTokens.textSecondary,
        fontWeight: unread ? FontWeight.w500 : FontWeight.w400,
      );

      return Padding(
        padding: EdgeInsets.symmetric(
          horizontal: EchoTokens.space3,
          vertical: compact ? 2 : EchoTokens.space1,
        ),
        child: GlassSurface(
          // Unread conversations sit one rung higher so they read as closer.
          level: unread ? 2 : 1,
          blur: false,
          border: unread,
          lift: false,
          radius: EchoTokens.radiusLg,
          tint: unread ? accent : null,
          onTap: onTap,
          onLongPress: onLongPress,
          padding: EdgeInsets.symmetric(
            horizontal: EchoTokens.space3,
            vertical: compact ? EchoTokens.space2 : EchoTokens.space3,
          ),
          child: Row(
            children: [
              EchoAvatar(
                chat: chat,
                size: compact ? 44 : 50,
                ring: unread,
                accent: accent,
              ),
              const SizedBox(width: EchoTokens.space3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        if (pinned) ...[
                          Icon(Icons.push_pin_rounded, size: 13, color: accent.withOpacity(0.9)),
                          const SizedBox(width: 4),
                        ],
                        Flexible(
                          child: Text(title, style: titleStyle, maxLines: 1, overflow: TextOverflow.ellipsis),
                        ),
                        if (muted) ...[
                          const SizedBox(width: 5),
                          const Icon(Icons.notifications_off_rounded,
                              size: 13, color: EchoTokens.textTertiary),
                        ],
                        const SizedBox(width: EchoTokens.space2),
                        Text(
                          _timestamp(message.dateCreated),
                          style: text.labelSmall!.copyWith(
                            color: unread ? accent : EchoTokens.textTertiary,
                            fontWeight: unread ? FontWeight.w600 : FontWeight.w500,
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
                            preview,
                            style: previewStyle,
                            maxLines: compact ? 1 : 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (unread) ...[
                          const SizedBox(width: EchoTokens.space2),
                          Padding(
                            padding: const EdgeInsets.only(top: 3),
                            child: _UnreadDot(accent: accent),
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
    });
  }
}

/// Luminous unread marker.
class _UnreadDot extends StatelessWidget {
  const _UnreadDot({required this.accent});

  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Unread',
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
    );
  }
}
