import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthRepository {
  // CHANGED: Lazy getters prevent early initialization crashes on Web
  FirebaseAuth get _auth => FirebaseAuth.instance;
  GoogleSignIn get _googleSignIn => GoogleSignIn();

  User? get currentUser => _auth.currentUser;
  bool get isSignedIn => _auth.currentUser != null;
  bool get isAnonymous => _auth.currentUser?.isAnonymous ?? true;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<User?> signInAnonymously() async {
    final credential = await _auth.signInAnonymously();
    return credential.user;
  }

  Future<User?> signUpWithEmail({
    required String email,
    required String password,
    required String displayName,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    await credential.user?.updateDisplayName(displayName);
    return credential.user;
  }

  Future<User?> logInWithEmail({required String email, required String password}) async {
    final credential = await _auth.signInWithEmailAndPassword(email: email, password: password);
    return credential.user;
  }

  Future<User?> signInWithGoogle() async {
    final googleUser = await _googleSignIn.signIn();
    if (googleUser == null) return null; // user cancelled

    final googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );
    final result = await _auth.signInWithCredential(credential);
    return result.user;
  }

  Future<User?> signInWithApple() async {
    throw UnimplementedError(
      'Apple Sign-In needs platform configuration first - see README.md "Auth Setup."',
    );
  }

  Future<User?> linkEmailToAnonymousAccount({
    required String email,
    required String password,
  }) async {
    final user = _auth.currentUser;
    if (user == null || !user.isAnonymous) {
      throw StateError('No anonymous session to upgrade.');
    }
    final credential = EmailAuthProvider.credential(email: email, password: password);
    final result = await user.linkWithCredential(credential);
    return result.user;
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }

  Future<void> deleteAccount() async {
    await _auth.currentUser?.delete();
  }
}