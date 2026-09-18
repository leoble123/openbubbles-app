import 'package:bluebubbles/app/layouts/conversation_details/conversation_details.dart';
import 'package:bluebubbles/app/layouts/conversation_view/widgets/header/header_widgets.dart';
import 'package:bluebubbles/echo/glass/glass_surface.dart';
import 'package:bluebubbles/echo/screens/customization/echo_appearance_studio.dart';
import 'package:bluebubbles/echo/theme/echo_tokens.dart';
import 'package:bluebubbles/echo/widgets/echo_avatar.dart';
import 'package:bluebubbles/services/services.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Echo's conversation header: a translucent glass bar floating over the
/// conversation wallpaper.
///
/// Actions come from the existing header widgets, so nothing is offered that
/// the backend cannot actually do — [FaceTimeBtn] hides itself unless every
/// participant validates for FaceTime, and [ManualMark] is the same read/unread
/// control used elsewhere.
class EchoChatHeader extends StatelessWidget implements PreferredSizeWidget {
  const EchoChatHeader({super.key, required this.controller});

  final ConversationViewController controller;

  @override
  Size get preferredSize => const Size.fromHeight(72);

  void _openDetails(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => ConversationDetails(chat: controller.chat)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final accent = Theme.of(context).colorScheme.primary;
    final chat = controller.chat;

    return SafeArea(
      bottom: false,
      child: Padding(
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
              Expanded(
                child: InkWell(
                  borderRadius: BorderRadius.circular(EchoTokens.radiusMd),
                  onTap: () => _openDetails(context),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        EchoAvatar(chat: chat, size: 38, accent: accent),
                        const SizedBox(width: EchoTokens.space3),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                chat.properTitle,
                                style: text.titleMedium,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Obx(() {
                                final typing = controller.showTypingIndicatorFor.isNotEmpty;
                                if (!typing && !chat.isGroup) return const SizedBox.shrink();
                                return Text(
                                  typing
                                      ? 'typing…'
                                      : '${chat.participants.length} people',
                                  style: text.labelSmall?.copyWith(
                                    color: typing ? accent : EchoTokens.textTertiary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                );
                              }),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              ManualMark(controller: controller),
              FaceTimeBtn(controller: controller),
              IconButton(
                icon: const Icon(Icons.palette_outlined, size: 20),
                color: EchoTokens.textSecondary,
                tooltip: 'Chat appearance',
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => EchoAppearanceStudio(
                      chatGuid: chat.guid,
                      chatTitle: chat.properTitle,
                    ),
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.info_outline_rounded, size: 20),
                color: EchoTokens.textSecondary,
                tooltip: 'Conversation details',
                onPressed: () => _openDetails(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
