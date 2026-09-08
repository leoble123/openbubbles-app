import 'package:bluebubbles/database/models.dart';
import 'package:bluebubbles/services/services.dart';

/// TEMPORARY, throwaway: seeds a couple of fake chats/messages and skips
/// setup so the UI (glass surfaces, edge-swipe-back, unsent-message reveal)
/// can be screenshotted without a working Apple ID login. Only runs when
/// built with `--dart-define=DEMO_SEED=true` - never part of a normal build.
/// Not meant to be merged into the real feature branch.
const bool kDemoSeed = bool.fromEnvironment('DEMO_SEED', defaultValue: false);

Future<void> seedDemoDataIfRequested() async {
  if (!kDemoSeed) return;
  if (Chat.findOne(guid: "demo-chat-1") != null) {
    ss.settings.finishedSetup.value = true;
    await ss.settings.saveAsync();
    return;
  }

  final priya = Handle(address: "priya@icloud.com", service: "iMessage").save();
  final now = DateTime.now();

  final chat1 = Chat(guid: "demo-chat-1", displayName: "Priya", participants: [priya]).save();
  await chat1.addMessage(Message(
    guid: "demo-msg-1",
    text: "omw, 10 min",
    dateCreated: now.subtract(const Duration(minutes: 8)),
    isFromMe: false,
    handle: priya,
  ));
  await chat1.addMessage(Message(
    guid: "demo-msg-2",
    text: "no rush, table's not till 8",
    dateCreated: now.subtract(const Duration(minutes: 7)),
    isFromMe: true,
    dateDelivered: now.subtract(const Duration(minutes: 7)),
  ));
  await chat1.addMessage(Message(
    guid: "demo-msg-3",
    text: "wait don't tell dev yet",
    dateCreated: now.subtract(const Duration(minutes: 6)),
    isFromMe: false,
    handle: priya,
    attributedBody: [AttributedBody.raw("wait don't tell dev yet")],
  ));
  // an unsent message, to demo the one-tap reveal
  await chat1.addMessage(Message(
    guid: "demo-msg-4",
    text: "don't tell dev about the bug til i fix it lol",
    dateCreated: now.subtract(const Duration(minutes: 5)),
    isFromMe: false,
    handle: priya,
    attributedBody: [AttributedBody.raw("don't tell dev about the bug til i fix it lol")],
    messageSummaryInfo: [
      MessageSummaryInfo(retractedParts: [0], editedContent: {}, originalTextRange: {}, editedParts: [])
    ],
  ));
  await chat1.addMessage(Message(
    guid: "demo-msg-5",
    text: "too late 😅",
    dateCreated: now.subtract(const Duration(minutes: 4)),
    isFromMe: true,
    dateDelivered: now.subtract(const Duration(minutes: 4)),
  ));

  final mom = Handle(address: "mom@icloud.com", service: "iMessage").save();
  final dev = Handle(address: "+15555550101", service: "iMessage").save();
  final chat2 = Chat(guid: "demo-chat-2", displayName: "Family Group", participants: [mom, dev]).save();
  await chat2.addMessage(Message(
    guid: "demo-msg-6",
    text: "don't forget bread",
    dateCreated: now.subtract(const Duration(hours: 2)),
    isFromMe: false,
    handle: mom,
  ));

  final devHandle = Handle(address: "dev@icloud.com", service: "iMessage").save();
  final chat3 = Chat(guid: "demo-chat-3", displayName: "Dev", participants: [devHandle]).save();
  await chat3.addMessage(Message(
    guid: "demo-msg-7",
    text: "pushed the fix, can you check?",
    dateCreated: now.subtract(const Duration(days: 1)),
    isFromMe: false,
    handle: devHandle,
  ));

  ss.settings.finishedSetup.value = true;
  await ss.settings.saveAsync();
}
