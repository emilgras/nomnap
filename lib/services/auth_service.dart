import 'package:firebase_auth/firebase_auth.dart';

/// Silent, screen-less authentication.
///
/// On first launch we create an anonymous Firebase account so every device has
/// a stable uid for membership/security rules — the user never sees a login.
/// A new phone or reinstall gets a fresh uid; recovery is handled separately
/// (export/import backup today, optional account-linking later).
class AuthService {
  AuthService({FirebaseAuth? auth}) : _auth = auth ?? FirebaseAuth.instance;

  final FirebaseAuth _auth;

  User? get currentUser => _auth.currentUser;
  String? get uid => _auth.currentUser?.uid;

  /// Returns the current user, signing in anonymously if needed.
  Future<User> ensureSignedIn() async {
    final existing = _auth.currentUser;
    if (existing != null) return existing;
    final cred = await _auth.signInAnonymously();
    return cred.user!;
  }

  Stream<User?> authStateChanges() => _auth.authStateChanges();
}
