import 'package:flutter/material.dart';

/// A message in the demo. Deliberately a plain model rather than the app's
/// [Message] entity, so demo mode can never reach the database.
class EchoDemoMessage {
  EchoDemoMessage({
    required this.text,
    required this.fromMe,
    required this.time,
    this.sender,
    this.reaction,
    this.delivered = true,
  });

  final String text;
  final bool fromMe;
  final String time;

  /// Only shown in group threads.
  final String? sender;
  final String? reaction;
  final bool delivered;
}

/// A conversation in the demo.
class EchoDemoChat {
  EchoDemoChat({
    required this.id,
    required this.title,
    required this.initials,
    required this.color,
    required this.messages,
    this.isGroup = false,
    this.unread = false,
    this.pinned = false,
    this.muted = false,
    this.timeLabel = '',
    this.participants = 0,
  });

  final String id;
  final String title;
  final String initials;
  final Color color;
  final List<EchoDemoMessage> messages;
  final bool isGroup;
  final bool unread;
  final bool pinned;
  final bool muted;
  final String timeLabel;
  final int participants;

  String get preview {
    if (messages.isEmpty) return '';
    final last = messages.last;
    final prefix = last.fromMe ? 'You: ' : (isGroup && last.sender != null ? '${last.sender}: ' : '');
    return '$prefix${last.text}';
  }
}

/// The five sample conversations shown in demo mode.
///
/// Everything here is invented sample content. It is never sent, never stored,
/// and never touches a real account.
List<EchoDemoChat> buildEchoDemoChats() => [
      EchoDemoChat(
        id: 'demo-1',
        title: 'Lana',
        initials: 'L',
        color: const Color(0xFF4EA8FF),
        unread: true,
        pinned: true,
        timeLabel: '9:41 AM',
        messages: [
          EchoDemoMessage(text: 'you free later?', fromMe: false, time: '9:32 AM'),
          EchoDemoMessage(text: "yeah probably — want to grab food?", fromMe: true, time: '9:35 AM'),
          EchoDemoMessage(text: 'yes please. same place?', fromMe: false, time: '9:36 AM'),
          EchoDemoMessage(text: "for sure, I'll lyk when I'm on the way", fromMe: true, time: '9:38 AM'),
          EchoDemoMessage(
            text: "I'll be there around 7 :)",
            fromMe: false,
            time: '9:41 AM',
            reaction: '❤️',
          ),
        ],
      ),
      EchoDemoChat(
        id: 'demo-2',
        title: 'Track Practice',
        initials: 'TP',
        color: const Color(0xFF4FE0B0),
        isGroup: true,
        participants: 6,
        timeLabel: '8:07 AM',
        messages: [
          EchoDemoMessage(text: 'practice moved to 4 today', fromMe: false, sender: 'Coach', time: '7:58 AM'),
          EchoDemoMessage(text: 'got it', fromMe: true, time: '8:01 AM'),
          EchoDemoMessage(text: 'anyone need a ride?', fromMe: false, sender: 'Marcus', time: '8:04 AM'),
          EchoDemoMessage(text: 'me!! 🙏', fromMe: false, sender: 'Sydney', time: '8:07 AM'),
        ],
      ),
      EchoDemoChat(
        id: 'demo-3',
        title: 'Mom',
        initials: 'M',
        color: const Color(0xFFFF6F91),
        unread: true,
        timeLabel: '8:13 AM',
        messages: [
          EchoDemoMessage(text: 'did you land okay?', fromMe: false, time: '6:20 AM'),
          EchoDemoMessage(text: 'yes! got in late but all good', fromMe: true, time: '7:45 AM'),
          EchoDemoMessage(text: 'good. call me when you can ❤️', fromMe: false, time: '8:13 AM'),
        ],
      ),
      EchoDemoChat(
        id: 'demo-4',
        title: 'Family',
        initials: 'F',
        color: const Color(0xFF9B7BFF),
        isGroup: true,
        participants: 4,
        muted: true,
        timeLabel: '7:21 AM',
        messages: [
          EchoDemoMessage(text: 'dinner sunday?', fromMe: false, sender: 'Dad', time: '7:02 AM'),
          EchoDemoMessage(text: "I'm in", fromMe: false, sender: 'Olivia', time: '7:10 AM'),
          EchoDemoMessage(text: 'same, what should I bring', fromMe: true, time: '7:18 AM'),
          EchoDemoMessage(text: 'just yourself 🙂', fromMe: false, sender: 'Dad', time: '7:21 AM'),
        ],
      ),
      EchoDemoChat(
        id: 'demo-5',
        title: 'Ethan',
        initials: 'E',
        color: const Color(0xFFFF8A5B),
        timeLabel: 'Yesterday',
        messages: [
          EchoDemoMessage(text: 'that view is insane', fromMe: false, time: 'Yesterday'),
          EchoDemoMessage(text: 'right? photos do not do it justice', fromMe: true, time: 'Yesterday'),
          EchoDemoMessage(text: 'send more when you can', fromMe: false, time: 'Yesterday'),
        ],
      ),
    ];
