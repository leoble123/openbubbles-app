import 'package:bluebubbles/app/components/avatars/contact_avatar_group_widget.dart';
import 'package:bluebubbles/database/models.dart';
import 'package:bluebubbles/echo/theme/echo_tokens.dart';
import 'package:flutter/material.dart';

/// A chat avatar wearing Echo's accent ring.
///
/// The avatar itself is the inherited [ContactAvatarGroupWidget], so contact
/// photos, group composites and colour assignment keep working exactly as they
/// do elsewhere in the app. Echo only adds the ring and glow.
class EchoAvatar extends StatelessWidget {
  const EchoAvatar({
    super.key,
    required this.chat,
    this.size = 50,
    this.ring = false,
    this.accent = EchoTokens.accent,
  });

  final Chat chat;
  final double size;

  /// Draws the luminous ring used for unread / active conversations.
  final bool ring;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final avatar = ContactAvatarGroupWidget(chat: chat, size: size, editable: false);

    if (!ring) {
      return SizedBox(width: size, height: size, child: avatar);
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: accent, width: 2),
        boxShadow: [
          BoxShadow(color: accent.withOpacity(0.38), blurRadius: 14, spreadRadius: -2),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(2.5),
        child: avatar,
      ),
    );
  }
}
