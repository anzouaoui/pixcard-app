import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pixcard/domain/entities/app_user.dart';
import 'package:pixcard/presentation/providers/providers.dart';

class AuthState {
  const AuthState({this.user, this.isLoading = false, this.error});

  final AppUser? user;
  final bool isLoading;
  final String? error;

  bool get isAuthenticated => user != null;

  AuthState copyWith({AppUser? user, bool? isLoading, String? error, bool clearUser = false}) {
    return AuthState(
      user: clearUser ? null : (user ?? this.user),
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier(this._ref) : super(const AuthState()) {
    _listenToAuthChanges();
  }

  final Ref _ref;

  void _listenToAuthChanges() {
    _ref.read(authRepositoryProvider).authStateChanges.listen((user) {
      state = state.copyWith(user: user, clearUser: user == null);
    });
  }

  Future<void> signInWithEmail(String email, String password) async {
    state = state.copyWith(isLoading: true);
    try {
      final user = await _ref.read(authRepositoryProvider).signInWithEmail(
            email: email,
            password: password,
          );
      state = state.copyWith(user: user, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> signUpWithEmail(String email, String password, String displayName) async {
    state = state.copyWith(isLoading: true);
    try {
      final user = await _ref.read(authRepositoryProvider).signUpWithEmail(
            email: email,
            password: password,
            displayName: displayName,
          );
      state = state.copyWith(user: user, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> signInWithGoogle() async {
    state = state.copyWith(isLoading: true);
    try {
      final user = await _ref.read(authRepositoryProvider).signInWithGoogle();
      state = state.copyWith(user: user, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> signOut() async {
    await _ref.read(authRepositoryProvider).signOut();
    state = state.copyWith(clearUser: true);
  }
}

final authStateProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref);
});
