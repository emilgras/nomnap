import '../models/baby_event.dart';

/// The calendar day a timestamp belongs to, given a configurable day boundary.
///
/// With [dayStartHour] == 0 this is the plain calendar day. With e.g. 6, a day
/// runs 06:00 → next 06:00, so anything before 06:00 counts toward the previous
/// day (handy when nights belong to the day that started that morning).
DateTime dayKeyFor(DateTime t, int dayStartHour) {
  final shifted = t.subtract(Duration(hours: dayStartHour));
  return DateTime(shifted.year, shifted.month, shifted.day);
}

class Session {
  final DateTime start;
  final DateTime? end;
  Session(this.start, this.end);
  Duration? get duration => end?.difference(start);
}

class DailyStats {
  final DateTime day;
  int sleepCount = 0;
  // Nursing (breastfeed) sessions only. Bottle and tube are tracked separately
  // below: they are point-in-time events measured in volume (ml), not time.
  int feedCount = 0;
  int bottleCount = 0;
  int tubeCount = 0;
  int bottleMl = 0;
  int tubeMl = 0;
  int peeCount = 0;
  int poopCount = 0;
  Duration sleepTotal = Duration.zero;
  Duration feedTotal = Duration.zero;
  DailyStats(this.day);

  int get diaperCount => peeCount + poopCount;

  /// All feeding events for the day: nursing sessions + bottle + tube.
  int get totalFeedCount => feedCount + bottleCount + tubeCount;

  /// Combined bottle + tube volume for the day, in ml.
  int get volumeMl => bottleMl + tubeMl;
}

class Statistics {
  final List<BabyEvent> events;

  /// Hour (0–23) at which a tracking day rolls over. 0 = midnight.
  final int dayStartHour;

  Statistics(List<BabyEvent> source, {this.dayStartHour = 0})
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

    DateTime keyOf(DateTime t) => dayKeyFor(t, dayStartHour);

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
    // Instant feeds (bottle / tube): point-in-time events measured in volume,
    // not time. Tracked apart from nursing so each unit (minutes vs ml) stays
    // honest; meta['amount'] is a digit string of ml (absent if not tracked).
    for (final e in events) {
      if (!e.type.isInstantFeed) continue;
      final k = keyOf(e.timestamp);
      final stat = out.putIfAbsent(k, () => DailyStats(k));
      final ml = int.tryParse(e.meta?['amount'] ?? '') ?? 0;
      if (e.type == EventType.feedBottle) {
        stat.bottleCount++;
        stat.bottleMl += ml;
      } else {
        stat.tubeCount++;
        stat.tubeMl += ml;
      }
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

  /// Average nursing sessions per day (bottle/tube excluded — see
  /// [avgTotalFeedsPerDay] for the all-feeds figure).
  double get avgFeedsPerDay {
    final days = dailyStats;
    if (days.isEmpty) return 0;
    final total = days.fold<int>(0, (acc, d) => acc + d.feedCount);
    return total / days.length;
  }

  /// Average feeds per day across every kind: nursing + bottle + tube.
  double get avgTotalFeedsPerDay {
    final days = dailyStats;
    if (days.isEmpty) return 0;
    final total = days.fold<int>(0, (acc, d) => acc + d.totalFeedCount);
    return total / days.length;
  }

  /// Whether any bottle or tube feeds have been logged at all.
  bool get hasSupplementalFeeds =>
      dailyStats.any((d) => d.bottleCount > 0 || d.tubeCount > 0);

  /// Average bottle volume (ml) per day, over all tracked days.
  double get avgDailyBottleMl {
    final days = dailyStats;
    if (days.isEmpty) return 0;
    final total = days.fold<int>(0, (acc, d) => acc + d.bottleMl);
    return total / days.length;
  }

  /// Average tube volume (ml) per day, over all tracked days.
  double get avgDailyTubeMl {
    final days = dailyStats;
    if (days.isEmpty) return 0;
    final total = days.fold<int>(0, (acc, d) => acc + d.tubeMl);
    return total / days.length;
  }

  /// Average combined bottle + tube volume (ml) per day.
  double get avgDailyVolumeMl => avgDailyBottleMl + avgDailyTubeMl;

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
    final key = dayKeyFor(day, dayStartHour);
    return _byDay()[key];
  }
}
