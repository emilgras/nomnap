import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nomnap/models/baby_profile.dart';

void main() {
  group('BabyProfile', () {
    test('isEmpty is true only when nothing is filled in', () {
      expect(const BabyProfile().isEmpty, isTrue);
      expect(const BabyProfile(name: 'Emma').isEmpty, isFalse);
      expect(const BabyProfile(name: '   ').isEmpty, isTrue); // whitespace only
      expect(BabyProfile(birthDate: DateTime(2026, 3, 2)).isEmpty, isFalse);
      expect(const BabyProfile(sex: Sex.girl).isEmpty, isFalse);
      expect(const BabyProfile(feeding: FeedingMethod.breast).isEmpty, isFalse);
    });

    test('toDoc / fromDoc round-trips through household-document fields', () {
      final profile = BabyProfile(
        name: 'Emma',
        birthDate: DateTime(2026, 3, 2),
        sex: Sex.girl,
        feeding: FeedingMethod.mixed,
      );
      final restored = BabyProfile.fromDoc(profile.toDoc());
      expect(restored.name, 'Emma');
      expect(restored.birthDate, DateTime(2026, 3, 2));
      expect(restored.sex, Sex.girl);
      expect(restored.feeding, FeedingMethod.mixed);
    });

    test('fromDoc tolerates a null document and unknown enum keys', () {
      expect(BabyProfile.fromDoc(null).isEmpty, isTrue);
      final partial = BabyProfile.fromDoc({
        'babyName': 'Leo',
        'sex': 'nonsense',
        'feedingMethod': null,
      });
      expect(partial.name, 'Leo');
      expect(partial.sex, isNull);
      expect(partial.feeding, isNull);
      expect(partial.birthDate, isNull);
    });

    test('fromDoc reads a Firestore Timestamp birth date', () {
      final ts = Timestamp.fromDate(DateTime.utc(2026, 3, 2));
      final profile = BabyProfile.fromDoc({'birthDate': ts});
      expect(profile.birthDate, isNotNull);
      expect(profile.birthDate!.toUtc(), DateTime.utc(2026, 3, 2));
    });

    test('enum keys are stable', () {
      expect(Sex.boy.key, 'boy');
      expect(Sex.girl.key, 'girl');
      expect(SexX.fromKey('boy'), Sex.boy);
      expect(FeedingMethod.breast.key, 'breast');
      expect(FeedingMethodX.fromKey('mixed'), FeedingMethod.mixed);
      expect(FeedingMethodX.fromKey('unknown'), isNull);
    });
  });
}
