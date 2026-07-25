import 'package:pixcard/domain/entities/app_user.dart';

abstract interface class AuthRepository {
  Stream<AppUser?> get authStateChanges;
  Future<AppUser?> getCurrentUser();
  Future<AppUser> signInWithEmail({required String email, required String password});
  Future<AppUser> signUpWithEmail({required String email, required String password, required String displayName});
  Future<AppUser> signInWithGoogle();
  Future<AppUser> signInWithApple();
  Future<void> sendPasswordResetEmail(String email);
  Future<void> signOut();
}
