import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/baby_profile.dart';

/// Owns the baby's [BabyProfile] and the local "has finished onboarding" flag.
///
/// The profile itself is shared across caregivers, so it is stored on the
/// household document in Firestore and kept live via a snapshot listener — a
/// change one caregiver makes shows up on the others. The onboarding flag is
/// per-device (a caregiver joining an already-set-up household shouldn't be
/// pushed through setup), so it lives in [SharedPreferences].
///
/// Mirrors the `ChangeNotifier` + scope shape of `HomeConfig` / `EventStore`;
/// access it in the widget tree via [BabyProfileScope].
class BabyProfileService extends ChangeNotifier {
  BabyProfileService({
    required this.householdId,
    FirebaseFirestore? db,
  }) : _db = db ?? FirebaseFirestore.instance;

  final String householdId;
  final FirebaseFirestore _db;

  static const _onboardedKey = 'nomnap.onboarded.v1';

  DocumentReference<Map<String, dynamic>> get _doc =>
      _db.collection('households').doc(householdId);

  BabyProfile _profile = const BabyProfile();
  BabyProfile get profile => _profile;

  bool _onboardingComplete = false;
  bool get onboardingComplete => _onboardingComplete;

  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _sub;

  /// Loads the onboarding flag and the current profile, then starts listening
  /// for live profile changes. Resolves once the first read has completed so
  /// callers can rely on [profile] / [onboardingComplete] being populated.
  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _onboardingComplete = prefs.getBool(_onboardedKey) ?? false;
    } catch (_) {/* default: not yet onboarded */}

    try {
      final snap = await _doc.get();
      _profile = BabyProfile.fromDoc(snap.data());
    } catch (_) {/* offline / transient — keep empty profile */}

    _sub = _doc.snapshots().listen(
      (snap) {
        _profile = BabyProfile.fromDoc(snap.data());
        notifyListeners();
      },
      onError: (_) {/* transient listener error — keep last known profile */},
    );
  }

  /// Persists the profile fields onto the household document (merging so
  /// unrelated fields survive). Updates in-memory state optimistically.
  Future<void> save(BabyProfile profile) async {
    _profile = profile;
    notifyListeners();
    try {
      await _doc.set(profile.toDoc(), SetOptions(merge: true));
    } catch (e) {
      debugPrint('BabyProfileService: failed to save profile: $e');
    }
  }

  /// Marks onboarding as finished (or skipped) so it stops appearing on
  /// launch. Idempotent.
  Future<void> markOnboardingComplete() async {
    if (_onboardingComplete) return;
    _onboardingComplete = true;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_onboardedKey, true);
    } catch (e) {
      debugPrint('BabyProfileService: failed to persist onboarded flag: $e');
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}

class BabyProfileScope extends InheritedNotifier<BabyProfileService> {
  const BabyProfileScope({
    super.key,
    required BabyProfileService service,
    required super.child,
  }) : super(notifier: service);

  static BabyProfileService of(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<BabyProfileScope>()!
        .notifier!;
  }
}
