import 'package:cloud_firestore/cloud_firestore.dart';

/// Writes user-submitted feedback (e.g. "missing tracker" suggestions) to a
/// top-level `feedback` collection.
///
/// There is no in-app reading of feedback — it's write-only from the client and
/// reviewed in the Firebase console. Security rules allow create-only so a
/// caregiver can't enumerate or alter others' submissions.
class FeedbackService {
  FeedbackService({FirebaseFirestore? db})
      : _db = db ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _feedback =>
      _db.collection('feedback');

  /// Records a free-text suggestion. [uid] stamps the author so the create
  /// rule can verify ownership; [householdId]/[locale] add context for triage.
  /// [email] is optional — supplied when the user wants to be contacted once
  /// the suggestion ships.
  Future<void> submitSuggestion({
    required String text,
    required String uid,
    required String householdId,
    required String locale,
    String? email,
    String? platform,
  }) async {
    final trimmedEmail = email?.trim();
    await _feedback.add({
      'kind': 'missing_tracker',
      'text': text.trim(),
      'email': ?(trimmedEmail != null && trimmedEmail.isNotEmpty
          ? trimmedEmail
          : null),
      'createdBy': uid,
      'householdId': householdId,
      'locale': locale,
      'platform': ?platform,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}
