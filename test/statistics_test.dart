import 'package:flutter_test/flutter_test.dart';
import 'package:nomnap/models/baby_event.dart';
import 'package:nomnap/services/statistics.dart';

BabyEvent _ev(String id, EventType type, DateTime ts,
        [Map<String, String>? meta]) =>
    BabyEvent(id: id, type: type, timestamp: ts, meta: meta);

void main() {
  group('Statistics on empty data', () {
    final stats = Statistics(const []);
    test('never divides by zero — all averages are zero', () {
      expect(stats.avgSleepDuration, Duration.zero);
      expect(stats.avgDailySleep, Duration.zero);
      expect(stats.avgFeedsPerDay, 0);
      expect(stats.avgTotalFeedsPerDay, 0);
      expect(stats.avgDiapersPerDay, 0);
      expect(stats.avgDailyVolumeMl, 0);
      expect(stats.longestSleep, Duration.zero);
      expect(stats.dailyStats, isEmpty);
      expect(stats.hasSupplementalFeeds, isFalse);
    });
  });

  group('Statistics aggregation', () {
    final day = DateTime(2026, 6, 28, 9);
    final stats = Statistics([
      _ev('s1', EventType.sleepStart, day),
      _ev('s2', EventType.sleepEnd, day.add(const Duration(hours: 2))),
      _ev('f1', EventType.feedStart, day.add(const Duration(hours: 3))),
      _ev('f2', EventType.feedEnd, day.add(const Duration(hours: 3, minutes: 20))),
      _ev('b1', EventType.feedBottle, day.add(const Duration(hours: 4)),
          const {'amount': '90'}),
      _ev('t1', EventType.feedTube, day.add(const Duration(hours: 5)),
          const {'amount': '30'}),
      _ev('d1', EventType.diaperPee, day.add(const Duration(hours: 6))),
      _ev('d2', EventType.diaperPoop, day.add(const Duration(hours: 7))),
    ]);

    test('rolls a single day up correctly', () {
      final daily = stats.statsForDay(day)!;
      expect(daily.sleepCount, 1);
      expect(daily.sleepTotal, const Duration(hours: 2));
      expect(daily.feedCount, 1);
      expect(daily.bottleCount, 1);
      expect(daily.tubeCount, 1);
      expect(daily.bottleMl, 90);
      expect(daily.tubeMl, 30);
      expect(daily.volumeMl, 120);
      expect(daily.peeCount, 1);
      expect(daily.poopCount, 1);
      expect(daily.diaperCount, 2);
      expect(daily.totalFeedCount, 3);
    });

    test('flags supplemental feeds and longest sleep', () {
      expect(stats.hasSupplementalFeeds, isTrue);
      expect(stats.longestSleep, const Duration(hours: 2));
    });

    test('memoized getters return stable, equal results across reads', () {
      expect(stats.dailyStats, same(stats.dailyStats));
      expect(stats.sleepSessions, same(stats.sleepSessions));
    });
  });

  group('dayKeyFor', () {
    test('with hour 0 it is the plain calendar day', () {
      expect(dayKeyFor(DateTime(2026, 6, 28, 1), 0), DateTime(2026, 6, 28));
    });

    test('a 6am boundary pushes early-morning times to the previous day', () {
      expect(dayKeyFor(DateTime(2026, 6, 28, 5), 6), DateTime(2026, 6, 27));
      expect(dayKeyFor(DateTime(2026, 6, 28, 6), 6), DateTime(2026, 6, 28));
    });
  });
}
