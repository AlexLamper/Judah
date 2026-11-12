import 'judah_state.dart';

/// What Judah says in the app. Short, warm, never preachy.
String judahLine({required Mood mood, required Set<DailyTask> doneToday, required Stage stage}) {
  if (mood == Mood.praying) return 'That was good. I feel so peaceful now.';
  if (mood == Mood.sleepy && doneToday.length == DailyTask.values.length) {
    return 'What a day with you. Goodnight!';
  }
  if (mood == Mood.sleepy) return "*yawn* Still time for today's verse?";
  if (mood == Mood.sad) return 'I missed you! Shall we read together again?';
  if (doneToday.length == DailyTask.values.length) {
    return stage == Stage.adult
        ? 'Strong like a lion today. See you tomorrow!'
        : "All done! I'm growing because of you.";
  }
  if (doneToday.isEmpty) return "Good to see you! Let's read today's verse.";
  return 'Nice! Just a little more for today.';
}

String stageLabel(Stage s) => switch (s) {
      Stage.cub => 'Cub',
      Stage.young => 'Young lion',
      Stage.adult => 'Lion of Judah',
    };

/// The short guided prayer for today's verse, built from its first topic.
/// Written to sound like a person talking to God, not a template.
List<String> guidedPrayer(String topicId, String verseRef) {
  final middle = _prayerLines[topicId] ??
      'Let these words sink deep into my heart and change the way I live today.';
  return [
    'Father, thank you for speaking to me through $verseRef.',
    middle,
    'Help me to carry this verse with me through the rest of my day.',
    "In Jesus' name, amen.",
  ];
}

const _prayerLines = {
  'hope': 'When things look dark, remind me that my hope is in you, and you never let go.',
  'peace': 'Quiet my heart. I give you everything that is restless in me right now.',
  'strength': 'I feel weak sometimes, Lord. Be my strength where mine runs out.',
  'anxiety': 'I bring you my worries, one by one. Take them, and fill me with your peace.',
  'love': 'Thank you that you loved me first. Help me to love others the way you love me.',
  'faith': 'Grow my faith, even where it is small. I want to trust you more.',
  'gratitude': 'Open my eyes to the good things you have given me, big and small.',
  'forgiveness': 'Thank you for forgiving me. Help me to forgive others as freely as you forgive me.',
  'wisdom': 'Give me wisdom for the choices in front of me today.',
  'comfort': 'You see what hurts. Hold me close and comfort me where I need it most.',
  'courage': 'Make me brave. Remind me that you go before me wherever I go.',
  'identity': 'Help me to see myself the way you see me: loved, chosen and made new.',
  'patience': 'Teach me to wait on you, and to trust your timing over mine.',
  'joy': 'Fill me with your joy, the kind that does not depend on how my day goes.',
  'guidance': 'Show me the way you want me to go, and give me ears to hear you.',
  'prayer': 'Thank you that I can always come to you. Teach me to pray more and worry less.',
  'gods_presence': 'Thank you that you are with me right now, here, in this moment.',
};
