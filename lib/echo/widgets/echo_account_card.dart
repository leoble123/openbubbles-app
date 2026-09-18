import 'package:bluebubbles/app/components/avatars/contact_avatar_widget.dart';
import 'package:bluebubbles/app/layouts/settings/pages/profile/profile_panel.dart';
import 'package:bluebubbles/echo/glass/glass_surface.dart';
import 'package:bluebubbles/echo/theme/echo_prefs.dart';
import 'package:bluebubbles/echo/theme/echo_tokens.dart';
import 'package:bluebubbles/services/network/backend_service.dart';
import 'package:bluebubbles/services/services.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// The account card at the top of Settings.
///
/// Its material shifts with the real connection state rather than decorating a
/// fixed look. Connectivity is only claimed where the app can actually observe
/// it — when a remote service is configured, the card follows the socket. In
/// direct (rustpush) mode there is no socket to read, so the card shows the
/// account identity and says nothing about connectivity rather than guessing.
class EchoAccountCard extends StatelessWidget {
  const EchoAccountCard({super.key});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final accent = echoPrefs.accent.value;
    final hasRemote = !kIsWeb && backend.getRemoteService() != null;

    return Obx(() {
      final redacted = ss.settings.redactedMode.value && ss.settings.hideContactInfo.value;
      final name = redacted ? 'User Name' : ss.settings.userName.value;
      final handle = redacted ? '' : ss.settings.defaultHandle.value;

      _Status? status;
      if (hasRemote) {
        switch (socket.state.value) {
          case SocketState.connected:
            status = const _Status('Connected', EchoTokens.success);
            break;
          case SocketState.connecting:
            status = const _Status('Connecting…', EchoTokens.warning);
            break;
          case SocketState.disconnected:
            status = const _Status('Disconnected', EchoTokens.textTertiary);
            break;
          default:
            status = const _Status('Connection error', EchoTokens.danger);
            break;
        }
      }

      return Padding(
        padding: const EdgeInsets.fromLTRB(
          EchoTokens.space4,
          EchoTokens.space3,
          EchoTokens.space4,
          EchoTokens.space2,
        ),
        child: GlassSurface(
          level: 3,
          radius: EchoTokens.radiusXl,
          // The tint follows the connection state, so the surface itself
          // carries the status rather than only a coloured dot.
          tint: status?.color ?? accent,
          glowColor: status?.color,
          glowStrength: 0.35,
          padding: const EdgeInsets.all(EchoTokens.space4),
          onTap: () => ns.pushAndRemoveSettingsUntil(
            context,
            ProfilePanel(),
            (route) => route.isFirst,
          ),
          child: Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: (status?.color ?? accent).withOpacity(0.7), width: 2),
                ),
                padding: const EdgeInsets.all(2),
                child: ContactAvatarWidget(
                  handle: null,
                  borderThickness: 0.1,
                  editable: false,
                  fontSize: 21,
                  size: 50,
                ),
              ),
              const SizedBox(width: EchoTokens.space4),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(name, style: text.titleLarge, maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        if (status != null) ...[
                          Container(
                            width: 7,
                            height: 7,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: status.color,
                              boxShadow: [
                                BoxShadow(color: status.color.withOpacity(0.5), blurRadius: 7),
                              ],
                            ),
                          ),
                          const SizedBox(width: EchoTokens.space2),
                          Text(
                            status.label,
                            style: text.labelMedium?.copyWith(color: status.color),
                          ),
                          if (handle.isNotEmpty) ...[
                            Text('  ·  ', style: text.labelMedium),
                            Flexible(
                              child: Text(
                                handle,
                                style: text.labelMedium,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ] else
                          Flexible(
                            child: Text(
                              handle.isNotEmpty ? handle : 'Tap to view your account',
                              style: text.labelMedium,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: EchoTokens.textTertiary),
            ],
          ),
        ),
      );
    });
  }
}

class _Status {
  const _Status(this.label, this.color);

  final String label;
  final Color color;
}
