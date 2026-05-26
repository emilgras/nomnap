import 'dart:convert';

enum EventType { sleepStart, sleepEnd, feedStart, feedEnd }

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
    }
  }

  static EventType fromId(String id) {
    return EventType.values.firstWhere((e) => e.id == id);
  }
}

class BabyEvent {
  final String id;
  final EventType type;
  final DateTime timestamp;

  BabyEvent({required this.id, required this.type, required this.timestamp});

  BabyEvent copyWith({DateTime? timestamp}) {
    return BabyEvent(
      id: id,
      type: type,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.id,
        'ts': timestamp.toUtc().toIso8601String(),
      };

  factory BabyEvent.fromJson(Map<String, dynamic> json) => BabyEvent(
        id: json['id'] as String,
        type: EventTypeX.fromId(json['type'] as String),
        timestamp: DateTime.parse(json['ts'] as String).toLocal(),
      );

  static String encodeList(List<BabyEvent> events) =>
      jsonEncode(events.map((e) => e.toJson()).toList());

  static List<BabyEvent> decodeList(String raw) {
    final list = jsonDecode(raw) as List<dynamic>;
    return list
        .map((e) => BabyEvent.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
