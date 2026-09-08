import 'dart:convert';

import 'package:bluebubbles/database/models.dart';
import 'package:bluebubbles/helpers/helpers.dart';
import 'package:bluebubbles/services/services.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class ChatEvent extends StatefulWidget {
  ChatEvent({
    super.key,
    required this.part,
    required this.message,
  });

  final MessagePart part;
  final Message message;

  @override
  State<ChatEvent> createState() => _ChatEventState();
}

class _ChatEventState extends State<ChatEvent> {
  bool revealed = false;

  MessagePart get part => widget.part;
  Message get message => widget.message;
  bool get iOS => ss.settings.skin.value == Skins.iOS;

  // The original text/subject of a retracted (unsent) part is kept on the
  // model (see Message.buildMessageParts) purely so it can be revealed here -
  // it's never shown unless the user explicitly taps to reveal it.
  String? get originalText {
    final text = [part.displaySubject, part.displayText].where((e) => !isNullOrEmpty(e)).join("\n");
    return text.isEmpty ? null : text;
  }

  bool get canReveal => part.isUnsent && !isNullOrEmpty(originalText);

  void _showMessageInfo(BuildContext context) {
    const encoder = JsonEncoder.withIndent("     ");
    Map map = message.toMap(includeObjects: true);
    if (map["dateCreated"] is int) {
      map["dateCreated"] =
          DateFormat("MMMM d, yyyy h:mm:ss a").format(
              DateTime.fromMillisecondsSinceEpoch(map["dateCreated"]));
    }
    if (map["dateDelivered"] is int) {
      map["dateDelivered"] =
          DateFormat("MMMM d, yyyy h:mm:ss a").format(
              DateTime.fromMillisecondsSinceEpoch(map["dateDelivered"]));
    }
    if (map["dateRead"] is int) {
      map["dateRead"] =
          DateFormat("MMMM d, yyyy h:mm:ss a").format(
              DateTime.fromMillisecondsSinceEpoch(map["dateRead"]));
    }
    if (map["dateEdited"] is int) {
      map["dateEdited"] =
          DateFormat("MMMM d, yyyy h:mm:ss a").format(
              DateTime.fromMillisecondsSinceEpoch(map["dateEdited"]));
    }
    String str = encoder.convert(map);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          "Message Info",
          style: context.theme.textTheme.titleLarge,
        ),
        backgroundColor: context.theme.colorScheme.properSurface,
        content: SizedBox(
          width: ns.width(context) * 3 / 5,
          height: context.height * 1 / 4,
          child: Container(
            padding: const EdgeInsets.all(10.0),
            decoration: BoxDecoration(
                color: context.theme.colorScheme.background,
                borderRadius: const BorderRadius.all(Radius.circular(10))
            ),
            child: SingleChildScrollView(
              child: SelectableText(
                str,
                style: context.theme.textTheme.bodyLarge,
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            child: Text(
                "Close",
                style: context.theme.textTheme.bodyLarge!.copyWith(color: context.theme.colorScheme.primary)
            ),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  void _toggleReveal() {
    HapticFeedback.lightImpact();
    setState(() => revealed = !revealed);
  }

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
        child: GestureDetector(
          onLongPress: () => _showMessageInfo(context),
          onTap: canReveal ? _toggleReveal : null,
          child: AnimatedSize(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOutCubic,
            alignment: Alignment.center,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        part.isUnsent
                            ? (message.isFromMe! ? "You unsent a message. Others may still see the message on devices where the software hasn't been updated" : "${message.handle?.displayName ?? "Unknown"} unsent a message")
                            : message.groupEventText,
                        style: context.theme.textTheme.bodySmall!.copyWith(color: context.theme.colorScheme.outline),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 2,
                        textAlign: TextAlign.center,
                      ),
                    ),
                    if (canReveal) ...[
                      const SizedBox(width: 4),
                      Icon(
                        revealed
                            ? (iOS ? CupertinoIcons.eye_slash : Icons.visibility_off)
                            : (iOS ? CupertinoIcons.eye : Icons.visibility),
                        size: 14,
                        color: context.theme.colorScheme.outline,
                      ),
                    ],
                  ],
                ),
                if (canReveal)
                  AnimatedCrossFade(
                    duration: const Duration(milliseconds: 250),
                    sizeCurve: Curves.easeOutCubic,
                    crossFadeState: revealed ? CrossFadeState.showSecond : CrossFadeState.showFirst,
                    firstChild: const SizedBox(width: double.infinity, height: 0),
                    secondChild: Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: Text(
                        originalText ?? "",
                        style: context.theme.textTheme.bodySmall!.copyWith(
                          color: context.theme.colorScheme.properOnSurface,
                          fontStyle: FontStyle.italic,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
