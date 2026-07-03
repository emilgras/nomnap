import 'dart:convert';

enum EventType {
  sleepStart,
  sleepEnd,
  feedStart,
  feedEnd,
  feedBottle,
  feedTube,
  diaperPee,
  diaperPoop,
}

extension EventTypeX on EventType {
  String get id {
    switch (this) {
      case EventType.sleepStart:
        return 'sleep_start';
      case EventType.sleepEnd:
        return 'sleep_end';
      case EventType.feedStart:
        return 'feed_start';
      case EventType.feedEnd:
        return 'feed_end';
      case EventType.feedBottle:
        return 'feed_bottle';
      case EventType.feedTube:
        return 'feed_tube';
      case EventType.diaperPee:
        return 'diaper_pee';
      case EventType.diaperPoop:
        return 'diaper_poop';
    }
  }

  bool get isDiaper =>
      this == EventType.diaperPee || this == EventType.diaperPoop;

  /// Instant (non-session) feed events: bottle and tube.
  bool get isInstantFeed =>
      this == EventType.feedBottle || this == EventType.feedTube;

  /// Point-in-time events that show as single timeline rows (not sessions).
  bool get isPointEvent => isDiaper || isInstantFeed;

  /// Resolves an id, returning null for an unknown one (e.g. a forward-compat
  /// event written by a newer client) so callers can skip it instead of
  /// throwing and poisoning the whole event stream.
  static EventType? fromIdOrNull(String? id) {
    if (id == null) return null;
    for (final e in EventType.values) {
      if (e.id == id) return e;
    }
    return null;
  }

  static EventType fromId(String id) =>
      fromIdOrNull(id) ?? (throw FormatException('Unknown event type: $id'));
}

class BabyEvent {
  final String id;
  final EventType type;
  final DateTime timestamp;
  final Map<String, String>? meta;

  BabyEvent({
    required this.id,
    required this.type,
    required this.timestamp,
    this.meta,
  });

  BabyEvent copyWith({DateTime? timestamp, Map<String, String>? meta}) {
    return BabyEvent(
      id: id,
      type: type,
      timestamp: timestamp ?? this.timestamp,
      meta: meta ?? this.meta,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.id,
        'ts': timestamp.toUtc().toIso8601String(),
        if (meta != null && meta!.isNotEmpty) 'meta': meta,
      };

  factory BabyEvent.fromJson(Map<String, dynamic> json) => BabyEvent(
        id: json['id'] as String,
        type: EventTypeX.fromId(json['type'] as String),
        timestamp: DateTime.parse(json['ts'] as String).toLocal(),
        meta: (json['meta'] as Map<String, dynamic>?)?.map(
          (k, v) => MapEntry(k, v as String),
        ),
      );

  static String encodeList(List<BabyEvent> events) =>
      jsonEncode(events.map((e) => e.toJson()).toList());

  static List<BabyEvent> decodeList(String raw) {
    final list = jsonDecode(raw) as List<dynamic>;
    final result = <BabyEvent>[];
    for (final e in list) {
      // Skip any corrupt/forward-incompatible entry rather than aborting the
      // whole import (used for legacy migration and backup restore).
      try {
        result.add(BabyEvent.fromJson(e as Map<String, dynamic>));
      } catch (_) {}
    }
    return result;
  }
}
