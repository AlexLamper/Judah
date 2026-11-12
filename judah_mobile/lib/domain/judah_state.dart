/// Pure rules for Judah: growth, mood and time of day.
///
/// No Flutter imports, so every rule is unit-tested in test/judah_state_test.dart
/// and the same rules can be mirrored in the native widget code.
library;

enum Stage { cub, young, adult }

enum Mood { happy, sad, sleepy, praying }

enum Scene { morning, day, evening, night }

/// The three things that make Judah happy each day.
enum DailyTask { verse, prayer, chapter }

/// A calendar day without a time, so day maths never trips over DST.
class Day implements Comparable<Day> {
  const Day(this.year, this.month, this.day);

  factory Day.of(DateTime t) => Day(t.year, t.month, t.day);

  factory Day.parse(String s) {
    final p = s.split('-').map(int.parse).toList();
    return Day(p[0], p[1], p[2]);
  }

  final int year;
  final int month;
  final int day;

  DateTime get _utc => DateTime.utc(year, month, day);

  int daysSince(Day other) => _utc.difference(other._utc).inDays;

  Day add(int days) => Day.of(_utc.add(Duration(days: days)));

  /// Days since 1970-01-01, used to pick the daily verse.
  int get epochDay => _utc.millisecondsSinceEpoch ~/ Duration.millisecondsPerDay;

  String get key =>
      '$year-${month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}';

  @override
  int compareTo(Day other) => _utc.compareTo(other._utc);

  @override
  bool operator ==(Object other) => other is Day && other.key == key;

  @override
  int get hashCode => key.hashCode;

  @override
  String toString() => key;
}

/// Judah is fully grown after 7 days with the verse read. Growth never resets:
/// a missed day only makes Judah sad, it never takes a stage away.
const int youngAfterDays = 3;
const int adultAfterDays = 7;

Stage stageFor(int growthDays) {
  if (growthDays >= adultAfterDays) return Stage.adult;
  if (growthDays >= youngAfterDays) return Stage.young;
  return Stage.cub;
}

/// 0.0-1.0 progress towards the next stage, for the progress bar.
double progressToNextStage(int growthDays) {
  if (growthDays >= adultAfterDays) return 1;
  if (growthDays >= youngAfterDays) {
    return (growthDays - youngAfterDays) / (adultAfterDays - youngAfterDays);
  }
  return growthDays / youngAfterDays;
}

Scene sceneFor(DateTime now) {
  final h = now.hour;
  if (h >= 5 && h < 11) return Scene.morning;
  if (h >= 11 && h < 17) return Scene.day;
  if (h >= 17 && h < 22) return Scene.evening;
  return Scene.night;
}

/// The progress Judah needs to decide his mood.
class Progress {
  const Progress({
    this.completed = const {},
    this.lastPrayerAt,
  });

  /// Tasks done per day, keyed by [Day.key].
  final Map<String, Set<DailyTask>> completed;
  final DateTime? lastPrayerAt;

  Set<DailyTask> on(Day day) => completed[day.key] ?? const {};

  /// A day counts for growth once the verse of that day was read.
  int get growthDays =>
      completed.values.where((t) => t.contains(DailyTask.verse)).length;

  Day? get lastActiveDay {
    final days = completed.entries
        .where((e) => e.value.isNotEmpty)
        .map((e) => Day.parse(e.key))
        .toList()
      ..sort();
    return days.isEmpty ? null : days.last;
  }

  /// Days in a row with the verse read, ending today or yesterday.
  int streak(Day today) {
    var day = on(today).contains(DailyTask.verse) ? today : today.add(-1);
    var count = 0;
    while (on(day).contains(DailyTask.verse)) {
      count++;
      day = day.add(-1);
    }
    return count;
  }

  Progress withTask(Day day, DailyTask task, DateTime now) {
    final next = Map<String, Set<DailyTask>>.from(completed);
    next[day.key] = {...on(day), task};
    return Progress(
      completed: next,
      lastPrayerAt: task == DailyTask.prayer ? now : lastPrayerAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'completed': completed.map(
          (k, v) => MapEntry(k, v.map((t) => t.name).toList()),
        ),
        'lastPrayerAt': lastPrayerAt?.toIso8601String(),
      };

  factory Progress.fromJson(Map<String, dynamic> json) {
    final raw = (json['completed'] as Map?) ?? const {};
    return Progress(
      completed: raw.map(
        (k, v) => MapEntry(
          k as String,
          (v as List)
              .map((n) => DailyTask.values.where((t) => t.name == n))
              .expand((t) => t)
              .toSet(),
        ),
      ),
      lastPrayerAt: json['lastPrayerAt'] == null
          ? null
          : DateTime.tryParse(json['lastPrayerAt'] as String),
    );
  }
}

/// How long Judah keeps his peaceful praying pose after a prayer.
const prayingGlow = Duration(minutes: 30);

/// Mood rules, in priority order:
/// 1. praying: within 30 minutes after a prayer
/// 2. sleepy: at night (22:00-05:00)
/// 3. sad: a whole day was missed since the last activity
/// 4. happy: otherwise
Mood moodFor(Progress p, DateTime now) {
  final prayed = p.lastPrayerAt;
  if (prayed != null && now.difference(prayed) < prayingGlow && !now.isBefore(prayed)) {
    return Mood.praying;
  }
  if (sceneFor(now) == Scene.night) return Mood.sleepy;
  return isMissing(p, Day.of(now)) ? Mood.sad : Mood.happy;
}

/// True when the user skipped at least one full day and has not been back yet.
bool isMissing(Progress p, Day today) {
  final last = p.lastActiveDay;
  if (last == null) return false; // brand new users start happy
  return today.daysSince(last) >= 2;
}
