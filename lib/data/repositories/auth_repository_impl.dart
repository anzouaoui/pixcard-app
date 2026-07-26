import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:pixcard/domain/entities/app_user.dart';
import 'package:pixcard/domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl(this._firebaseAuth, this._firestore);

  final FirebaseAuth _firebaseAuth;
  final FirebaseFirestore _firestore;
  final _googleSignIn = GoogleSignIn();

  CollectionReference get _users => _firestore.collection('users');

  Future<void> _createUserDoc(AppUser user) async {
    await _users.doc(user.id).set(user.toMap());
  }

  @override
  Stream<AppUser?> get authStateChanges {
    return _firebaseAuth.authStateChanges().map((user) {
      if (user == null) return null;
      return AppUser(
        id: user.uid,
        email: user.email ?? '',
        displayName: user.displayName ?? '',
        photoUrl: user.photoURL ?? '',
      );
    });
  }

  @override
  Future<AppUser?> getCurrentUser() async {
    final user = _firebaseAuth.currentUser;
    if (user == null) return null;
    return AppUser(
      id: user.uid,
      email: user.email ?? '',
      displayName: user.displayName ?? '',
      photoUrl: user.photoURL ?? '',
    );
  }

  @override
  Future<AppUser> signInWithEmail({
    required String email,
    required String password,
  }) async {
    final credential = await _firebaseAuth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    final user = credential.user!;
    return AppUser(
      id: user.uid,
      email: user.email ?? '',
      displayName: user.displayName ?? '',
      photoUrl: user.photoURL ?? '',
    );
  }

  @override
  Future<AppUser> signUpWithEmail({
    required String email,
    required String password,
    required String displayName,
  }) async {
    final credential = await _firebaseAuth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    final user = credential.user!;
    await user.updateDisplayName(displayName);
    final appUser = AppUser(
      id: user.uid,
      email: user.email ?? '',
      displayName: displayName,
      createdAt: DateTime.now(),
    );
    await _createUserDoc(appUser);
    return appUser;
  }

  @override
  Future<AppUser> signInWithGoogle() async {
    final googleUser = await _googleSignIn.signIn();
    if (googleUser == null) throw Exception('Google sign in aborted');

    final googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    final userCredential = await _firebaseAuth.signInWithCredential(credential);
    final user = userCredential.user!;
    final appUser = AppUser(
      id: user.uid,
      email: user.email ?? '',
      displayName: user.displayName ?? '',
      photoUrl: user.photoURL ?? '',
    );
    final doc = await _users.doc(user.uid).get();
    if (!doc.exists) await _createUserDoc(appUser);
    return appUser;
  }

  @override
  Future<AppUser> signInWithApple() async {
    final appleCredential = await SignInWithApple.getAppleIDCredential(
      scopes: [
        AppleIDAuthorizationScopes.email,
        AppleIDAuthorizationScopes.fullName,
      ],
    );

    final oauthCredential = OAuthProvider('apple.com').credential(
      idToken: appleCredential.identityToken,
      accessToken: appleCredential.authorizationCode,
    );

    final userCredential = await _firebaseAuth.signInWithCredential(oauthCredential);
    final user = userCredential.user!;

    final fullName = appleCredential.givenName;
    if (fullName != null && user.displayName == null) {
      await user.updateDisplayName(fullName);
    }

    final appUser = AppUser(
      id: user.uid,
      email: user.email ?? '',
      displayName: user.displayName ?? fullName ?? '',
      photoUrl: user.photoURL ?? '',
    );
    final doc = await _users.doc(user.uid).get();
    if (!doc.exists) await _createUserDoc(appUser);
    return appUser;
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    await _firebaseAuth.sendPasswordResetEmail(email: email);
  }

  @override
  Future<void> signOut() async {
    await Future.wait([
      _firebaseAuth.signOut(),
      _googleSignIn.signOut(),
    ]);
  }
}
