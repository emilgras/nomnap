import 'package:flutter_test/flutter_test.dart';
import 'package:nomnap/models/baby_event.dart';
import 'package:nomnap/models/baby_session.dart';

BabyEvent _ev(String id, EventType type, DateTime ts,
        [Map<String, String>? meta]) =>
    BabyEvent(id: id, type: type, timestamp: ts, meta: meta);

void main() {
  final t0 = DateTime(2026, 6, 28, 8);

  group('BabySession.from', () {
    test('pairs a start with its following end', () {
      final sessions = BabySession.from([
        _ev('a', EventType.sleepStart, t0),
        _ev('b', EventType.sleepEnd, t0.add(const Duration(hours: 2))),
      ]);
      expect(sessions, hasLength(1));
      expect(sessions.single.kind, SessionKind.sleep);
      expect(sessions.single.isOngoing, isFalse);
      expect(sessions.single.duration, const Duration(hours: 2));
    });

    test('a start with no end becomes an ongoing session', () {
      final sessions = BabySession.from([_ev('a', EventType.feedStart, t0)]);
      expect(sessions.single.isOngoing, isTrue);
      expect(sessions.single.duration, isNull);
    });

    test('orphan end events (no preceding start) are skipped', () {
      final sessions = BabySession.from([_ev('a', EventType.sleepEnd, t0)]);
      expect(sessions, isEmpty);
    });

    test('a second start before an end closes the first as ongoing', () {
      final sessions = BabySession.from([
        _ev('a', EventType.sleepStart, t0),
        _ev('b', EventType.sleepStart, t0.add(const Duration(hours: 1))),
      ]);
      expect(sessions, hasLength(2));
      expect(sessions.every((s) => s.isOngoing), isTrue);
    });

    test('carries the feed side from the start event', () {
      final sessions = BabySession.from([
        _ev('a', EventType.feedStart, t0, const {'side': 'R'}),
        _ev('b', EventType.feedEnd, t0.add(const Duration(minutes: 15))),
      ]);
      expect(sessions.single.side, 'R');
    });

    test('point events are not paired into sessions', () {
      final sessions = BabySession.from([
        _ev('a', EventType.diaperPee, t0),
        _ev('b', EventType.feedBottle, t0),
      ]);
      expect(sessions, isEmpty);
    });
  });

  group('duration clamping', () {
    test('an end before its start yields zero, never a negative duration', () {
      final sessions = BabySession.from([
        _ev('a', EventType.sleepStart, t0),
        _ev('b', EventType.sleepEnd, t0.subtract(const Duration(hours: 1))),
      ]);
      // Pairing sorts by timestamp, so construct directly to force the order.
      final s = BabySession(
        kind: SessionKind.sleep,
        startEventId: 'a',
        endEventId: 'b',
        start: t0,
        end: t0.subtract(const Duration(hours: 1)),
      );
      expect(s.duration, Duration.zero);
      expect(s.duration!.isNegative, isFalse);
      expect(sessions, hasLength(1));
    });
  });
}
