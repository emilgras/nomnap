import 'package:flutter_test/flutter_test.dart';
import 'package:nomnap/models/baby_event.dart';

void main() {
  group('EventTypeX.fromIdOrNull', () {
    test('resolves every known id round-trip', () {
      for (final type in EventType.values) {
        expect(EventTypeX.fromIdOrNull(type.id), type);
      }
    });

    test('returns null for an unknown or null id instead of throwing', () {
      expect(EventTypeX.fromIdOrNull('not_a_real_type'), isNull);
      expect(EventTypeX.fromIdOrNull(null), isNull);
    });

    test('fromId throws on an unknown id', () {
      expect(() => EventTypeX.fromId('nope'), throwsFormatException);
    });
  });

  group('BabyEvent json', () {
    test('round-trips through toJson/fromJson preserving fields', () {
      final event = BabyEvent(
        id: 'abc',
        type: EventType.feedBottle,
        timestamp: DateTime(2026, 6, 28, 14, 30),
        meta: const {'amount': '120'},
      );
      final back = BabyEvent.fromJson(event.toJson());
      expect(back.id, event.id);
      expect(back.type, event.type);
      expect(back.timestamp, event.timestamp);
      expect(back.meta?['amount'], '120');
    });

    test('decodeList skips corrupt entries instead of aborting the whole list',
        () {
      // A valid entry, an entry with an unknown type, and structural garbage.
      const raw = '['
          '{"id":"1","type":"sleep_start","ts":"2026-06-28T10:00:00.000Z"},'
          '{"id":"2","type":"made_up_type","ts":"2026-06-28T11:00:00.000Z"},'
          '{"id":"3"},'
          '{"id":"4","type":"diaper_pee","ts":"2026-06-28T12:00:00.000Z"}'
          ']';
      final events = BabyEvent.decodeList(raw);
      expect(events.map((e) => e.id), ['1', '4']);
      expect(events[0].type, EventType.sleepStart);
      expect(events[1].type, EventType.diaperPee);
    });
  });
}
