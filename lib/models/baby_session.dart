import 'baby_event.dart';

enum SessionKind { sleep, feed }

extension SessionKindX on SessionKind {
  EventType get startType => this == SessionKind.sleep
      ? EventType.sleepStart
      : EventType.feedStart;
  EventType get endType =>
      this == SessionKind.sleep ? EventType.sleepEnd : EventType.feedEnd;
}

/// A start (+ optional end) pair derived from the event stream.
class BabySession {
  final SessionKind kind;
  final String startEventId;
  final String? endEventId;
  final DateTime start;
  final DateTime? end;

  BabySession({
    required this.kind,
    required this.startEventId,
    required this.start,
    this.endEventId,
    this.end,
  });

  bool get isOngoing => end == null;
  Duration? get duration => end?.difference(start);

  /// Pair start/end events into sessions, in chronological order.
  /// If a start has no end, it becomes an ongoing session.
  /// Orphan end events (no preceding start) are skipped.
  static List<BabySession> from(List<BabyEvent> events) {
    final sorted = [...events]
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
    final result = <BabySession>[];
    BabyEvent? openSleep;
    BabyEvent? openFeed;
    for (final e in sorted) {
      switch (e.type) {
        case EventType.sleepStart:
          if (openSleep != null) {
            result.add(BabySession(
              kind: SessionKind.sleep,
              startEventId: openSleep.id,
              start: openSleep.timestamp,
            ));
          }
          openSleep = e;
          break;
        case EventType.sleepEnd:
          if (openSleep != null) {
            result.add(BabySession(
              kind: SessionKind.sleep,
              startEventId: openSleep.id,
              endEventId: e.id,
              start: openSleep.timestamp,
              end: e.timestamp,
            ));
            openSleep = null;
          }
          break;
        case EventType.feedStart:
          if (openFeed != null) {
            result.add(BabySession(
              kind: SessionKind.feed,
              startEventId: openFeed.id,
              start: openFeed.timestamp,
            ));
          }
          openFeed = e;
          break;
        case EventType.feedEnd:
          if (openFeed != null) {
            result.add(BabySession(
              kind: SessionKind.feed,
              startEventId: openFeed.id,
              endEventId: e.id,
              start: openFeed.timestamp,
              end: e.timestamp,
            ));
            openFeed = null;
          }
          break;
      }
    }
    if (openSleep != null) {
      result.add(BabySession(
        kind: SessionKind.sleep,
        startEventId: openSleep.id,
        start: openSleep.timestamp,
      ));
    }
    if (openFeed != null) {
      result.add(BabySession(
        kind: SessionKind.feed,
        startEventId: openFeed.id,
        start: openFeed.timestamp,
      ));
    }
    result.sort((a, b) => a.start.compareTo(b.start));
    return result;
  }
}
