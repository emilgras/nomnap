import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// One caregiver in a household.
class Member {
  final String uid;
  final String role; // 'owner' | 'caregiver'
  final DateTime? joinedAt;

  Member({required this.uid, required this.role, this.joinedAt});
}

/// Manages the shared "household" that owns a baby's events: creating one,
/// joining via an invite code, and managing caregivers/invites.
///
/// The active household id is cached locally so we don't re-resolve it every
/// launch. Membership itself lives in Firestore at households/{hid}/members/{uid}.
class HouseholdService {
  HouseholdService({FirebaseFirestore? db})
      : _db = db ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  static const _activeHouseholdKey = 'nomnap.householdId.v1';

  // Unambiguous alphabet (no 0/O/1/I/L) for human-shareable codes.
  static const _codeAlphabet = 'ABCDEFGHJKMNPQRSTUVWXYZ23456789';
  static const _codeLength = 8;
  static const _inviteValidity = Duration(days: 7);

  CollectionReference<Map<String, dynamic>> get _households =>
      _db.collection('households');
  CollectionReference<Map<String, dynamic>> get _invites =>
      _db.collection('invites');

  DocumentReference<Map<String, dynamic>> _member(String hid, String uid) =>
      _households.doc(hid).collection('members').doc(uid);

  /// The household this device is currently attached to, if any.
  Future<String?> activeHouseholdId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_activeHouseholdKey);
  }

  Future<void> _setActiveHousehold(String hid) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_activeHouseholdKey, hid);
  }

  Future<void> _clearActiveHousehold() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_activeHouseholdKey);
  }

  /// Resolves the household for [uid], creating a fresh one on first run.
  ///
  /// If a cached household exists and the user is still a member, it is reused;
  /// otherwise a new household is created. Returns the household id.
  Future<String> ensureHousehold(String uid, {String babyName = ''}) async {
    final cached = await activeHouseholdId();
    if (cached != null) {
      final member = await _member(cached, uid).get();
      if (member.exists) return cached;
      // Membership was revoked or lost — fall through to create a new one.
      await _clearActiveHousehold();
    }
    return createHousehold(uid, babyName: babyName);
  }

  /// Creates a new household founded by [uid] and records membership.
  ///
  /// Done as two sequential writes (not a batch) because the members-create
  /// rule reads the household's `createdBy` via get(), which only sees
  /// committed data.
  Future<String> createHousehold(String uid, {String babyName = ''}) async {
    final doc = _households.doc();
    await doc.set({
      'createdBy': uid,
      'babyName': babyName,
      'createdAt': FieldValue.serverTimestamp(),
    });
    await _member(doc.id, uid).set({
      'role': 'owner',
      'joinedAt': FieldValue.serverTimestamp(),
    });
    await _setActiveHousehold(doc.id);
    return doc.id;
  }

  /// Generates a shareable invite code for [hid], valid for 7 days.
  Future<String> createInvite(String hid, String uid) async {
    final code = _generateCode();
    await _invites.doc(code).set({
      'householdId': hid,
      'createdBy': uid,
      'expiresAt': Timestamp.fromDate(
        DateTime.now().toUtc().add(_inviteValidity),
      ),
    });
    return code;
  }

  /// Redeems [code] for [uid], joining that household. Switches this device to
  /// the joined household. Throws [InviteException] on bad/expired codes.
  Future<String> joinWithCode(String uid, String code) async {
    final normalized = code.trim().toUpperCase();
    final invite = await _invites.doc(normalized).get();
    if (!invite.exists) {
      throw const InviteException('not_found', 'This invite code does not exist.');
    }
    final data = invite.data()!;
    final expiresAt = (data['expiresAt'] as Timestamp?)?.toDate();
    if (expiresAt == null || expiresAt.isBefore(DateTime.now().toUtc())) {
      throw const InviteException('expired', 'This invite has expired.');
    }
    final hid = data['householdId'] as String;
    // The member-create rule re-validates the invite server-side.
    await _member(hid, uid).set({
      'role': 'caregiver',
      'joinedAt': FieldValue.serverTimestamp(),
      'inviteCode': normalized,
    });
    await _setActiveHousehold(hid);
    return hid;
  }

  /// Live list of caregivers in [hid].
  Stream<List<Member>> watchMembers(String hid) {
    return _households.doc(hid).collection('members').snapshots().map(
          (snap) => snap.docs
              .map((d) => Member(
                    uid: d.id,
                    role: (d.data()['role'] as String?) ?? 'caregiver',
                    joinedAt: (d.data()['joinedAt'] as Timestamp?)?.toDate(),
                  ))
              .toList(),
        );
  }

  /// Removes a caregiver (revokes access immediately via rules).
  Future<void> removeMember(String hid, String uid) =>
      _member(hid, uid).delete();

  /// Revokes a pending invite so it can no longer be redeemed.
  Future<void> revokeInvite(String code) =>
      _invites.doc(code.trim().toUpperCase()).delete();

  String _generateCode() {
    final rng = Random.secure();
    return List.generate(
      _codeLength,
      (_) => _codeAlphabet[rng.nextInt(_codeAlphabet.length)],
    ).join();
  }
}

class InviteException implements Exception {
  /// Stable code for the UI to localize: 'not_found', 'expired', or 'generic'.
  final String code;
  final String message;
  const InviteException(this.code, this.message);
  @override
  String toString() => message;
}
