import '../models/baby_event.dart';

class Session {
  final DateTime start;
  final DateTime? end;
  Session(this.start, this.end);
  Duration? get duration => end?.difference(start);
}

class DailyStats {
  final DateTime day;
  int sleepCount = 0;
  int feedCount = 0;
  int peeCount = 0;
  int poopCount = 0;
  Duration sleepTotal = Duration.zero;
  Duration feedTotal = Duration.zero;
  DailyStats(this.day);

  int get diaperCount => peeCount + poopCount;
}

class Statistics {
  final List<BabyEvent> events;
  Statistics(List<BabyEvent> source)
      : events = List<BabyEvent>.from(source)
          ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

  /// Pair start/end events into sessions. Open (unfinished) sessions get a null end.
  List<Session> _sessionsOf(EventType startType, EventType endType) {
    final sessions = <Session>[];
    DateTime? openStart;
    for (final e in events) {
      if (e.type == startType) {
        if (openStart != null) {
          // discarded incomplete start (no end) — push as open then reopen
          sessions.add(Session(openStart, null));
        }
        openStart = e.timestamp;
      } else if (e.type == endType) {
        if (openStart != null) {
          sessions.add(Session(openStart, e.timestamp));
          openStart = null;
        }
      }
    }
    if (openStart != null) sessions.add(Session(openStart, null));
    return sessions;
  }

  List<Session> get sleepSessions =>
      _sessionsOf(EventType.sleepStart, EventType.sleepEnd);

  List<Session> get feedSessions =>
      _sessionsOf(EventType.feedStart, EventType.feedEnd);

  /// Group completed sessions by calendar day (by their start time).
  Map<DateTime, DailyStats> _byDay() {
    final out = <DateTime, DailyStats>{};

    DateTime keyOf(DateTime t) => DateTime(t.year, t.month, t.day);

    for (final s in sleepSessions) {
      if (s.duration == null) continue;
      final k = keyOf(s.start);
      final stat = out.putIfAbsent(k, () => DailyStats(k));
      stat.sleepCount++;
      stat.sleepTotal += s.duration!;
    }
    for (final s in feedSessions) {
      if (s.duration == null) continue;
      final k = keyOf(s.start);
      final stat = out.putIfAbsent(k, () => DailyStats(k));
      stat.feedCount++;
      stat.feedTotal += s.duration!;
    }
    for (final e in events) {
      if (!e.type.isDiaper) continue;
      final k = keyOf(e.timestamp);
      final stat = out.putIfAbsent(k, () => DailyStats(k));
      if (e.type == EventType.diaperPee) {
        stat.peeCount++;
      } else {
        stat.poopCount++;
      }
    }
    return out;
  }

  List<DailyStats> get dailyStats {
    final m = _byDay();
    final days = m.values.toList()..sort((a, b) => b.day.compareTo(a.day));
    return days;
  }

  /// Average of completed sleep session durations across all time.
  Duration get avgSleepDuration {
    final ds = sleepSessions.where((s) => s.duration != null).toList();
    if (ds.isEmpty) return Duration.zero;
    final total =
        ds.fold<Duration>(Duration.zero, (acc, s) => acc + s.duration!);
    return Duration(milliseconds: total.inMilliseconds ~/ ds.length);
  }

  Duration get avgFeedDuration {
    final ds = feedSessions.where((s) => s.duration != null).toList();
    if (ds.isEmpty) return Duration.zero;
    final total =
        ds.fold<Duration>(Duration.zero, (acc, s) => acc + s.duration!);
    return Duration(milliseconds: total.inMilliseconds ~/ ds.length);
  }

  /// Average per-day totals across days that had any tracked activity.
  Duration get avgDailySleep {
    final days = dailyStats;
    if (days.isEmpty) return Duration.zero;
    final total =
        days.fold<Duration>(Duration.zero, (acc, d) => acc + d.sleepTotal);
    return Duration(milliseconds: total.inMilliseconds ~/ days.length);
  }

  Duration get avgDailyFeed {
    final days = dailyStats;
    if (days.isEmpty) return Duration.zero;
    final total =
        days.fold<Duration>(Duration.zero, (acc, d) => acc + d.feedTotal);
    return Duration(milliseconds: total.inMilliseconds ~/ days.length);
  }

  double get avgFeedsPerDay {
    final days = dailyStats;
    if (days.isEmpty) return 0;
    final total = days.fold<int>(0, (acc, d) => acc + d.feedCount);
    return total / days.length;
  }

  double get avgSleepsPerDay {
    final days = dailyStats;
    if (days.isEmpty) return 0;
    final total = days.fold<int>(0, (acc, d) => acc + d.sleepCount);
    return total / days.length;
  }

  Duration get longestSleep {
    final ds = sleepSessions.where((s) => s.duration != null);
    if (ds.isEmpty) return Duration.zero;
    return ds
        .map((s) => s.duration!)
        .reduce((a, b) => a > b ? a : b);
  }

  double get avgDiapersPerDay {
    final days = dailyStats.where((d) => d.diaperCount > 0).toList();
    if (days.isEmpty) return 0;
    final total = days.fold<int>(0, (acc, d) => acc + d.diaperCount);
    return total / days.length;
  }

  double get avgPeesPerDay {
    final days = dailyStats.where((d) => d.peeCount > 0).toList();
    if (days.isEmpty) return 0;
    final total = days.fold<int>(0, (acc, d) => acc + d.peeCount);
    return total / days.length;
  }

  double get avgPoopsPerDay {
    final days = dailyStats.where((d) => d.poopCount > 0).toList();
    if (days.isEmpty) return 0;
    final total = days.fold<int>(0, (acc, d) => acc + d.poopCount);
    return total / days.length;
  }

  DailyStats? statsForDay(DateTime day) {
    final key = DateTime(day.year, day.month, day.day);
    return _byDay()[key];
  }
}
