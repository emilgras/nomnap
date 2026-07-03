import 'package:cloud_firestore/cloud_firestore.dart';

/// The baby's biological sex — needed for sex-specific growth percentiles.
enum Sex { boy, girl }

/// How the baby is primarily fed. Drives which feed trackers are pre-enabled
/// on the home page; the user can always change it later.
enum FeedingMethod { breast, bottle, mixed }

extension SexX on Sex {
  String get key => this == Sex.boy ? 'boy' : 'girl';
  static Sex? fromKey(String? key) {
    switch (key) {
      case 'boy':
        return Sex.boy;
      case 'girl':
        return Sex.girl;
      default:
        return null;
    }
  }
}

extension FeedingMethodX on FeedingMethod {
  String get key {
    switch (this) {
      case FeedingMethod.breast:
        return 'breast';
      case FeedingMethod.bottle:
        return 'bottle';
      case FeedingMethod.mixed:
        return 'mixed';
    }
  }

  static FeedingMethod? fromKey(String? key) {
    switch (key) {
      case 'breast':
        return FeedingMethod.breast;
      case 'bottle':
        return FeedingMethod.bottle;
      case 'mixed':
        return FeedingMethod.mixed;
      default:
        return null;
    }
  }
}

/// The baby's profile: the details captured during onboarding and editable
/// later from the Profile tab. Shared across caregivers, so it lives on the
/// household document in Firestore (see [BabyProfileService]).
class BabyProfile {
  final String name;
  final DateTime? birthDate;
  final Sex? sex;
  final FeedingMethod? feeding;

  const BabyProfile({
    this.name = '',
    this.birthDate,
    this.sex,
    this.feeding,
  });

  bool get hasName => name.trim().isNotEmpty;

  /// True when nothing has been filled in — used to decide whether to show an
  /// empty state or the baby's details.
  bool get isEmpty =>
      !hasName && birthDate == null && sex == null && feeding == null;

  BabyProfile copyWith({
    String? name,
    DateTime? birthDate,
    Sex? sex,
    FeedingMethod? feeding,
  }) {
    return BabyProfile(
      name: name ?? this.name,
      birthDate: birthDate ?? this.birthDate,
      sex: sex ?? this.sex,
      feeding: feeding ?? this.feeding,
    );
  }

  /// Reads the profile fields off a household document. Tolerant of missing or
  /// malformed fields (a partially-filled or legacy household) — anything it
  /// can't parse simply stays null.
  factory BabyProfile.fromDoc(Map<String, dynamic>? data) {
    if (data == null) return const BabyProfile();
    final rawBirth = data['birthDate'];
    DateTime? birth;
    if (rawBirth is Timestamp) {
      birth = rawBirth.toDate().toLocal();
    } else if (rawBirth is String) {
      birth = DateTime.tryParse(rawBirth)?.toLocal();
    }
    return BabyProfile(
      name: (data['babyName'] as String?)?.trim() ?? '',
      birthDate: birth,
      sex: SexX.fromKey(data['sex'] as String?),
      feeding: FeedingMethodX.fromKey(data['feedingMethod'] as String?),
    );
  }

  /// The subset of household-document fields this profile owns. Merged into the
  /// existing document so unrelated fields (createdBy, createdAt) are untouched.
  Map<String, dynamic> toDoc() => {
        'babyName': name.trim(),
        'birthDate':
            birthDate == null ? null : Timestamp.fromDate(birthDate!.toUtc()),
        'sex': sex?.key,
        'feedingMethod': feeding?.key,
      };
}
