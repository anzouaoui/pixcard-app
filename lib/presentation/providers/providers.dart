import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pixcard/data/repositories/auth_repository_impl.dart';
import 'package:pixcard/data/repositories/listing_repository_impl.dart';
import 'package:pixcard/data/repositories/user_repository_impl.dart';
import 'package:pixcard/domain/repositories/auth_repository.dart';
import 'package:pixcard/domain/repositories/listing_repository.dart';
import 'package:pixcard/domain/repositories/user_repository.dart';

final firebaseAuthProvider = Provider<FirebaseAuth>((ref) => FirebaseAuth.instance);

final firebaseFirestoreProvider = Provider<FirebaseFirestore>((ref) => FirebaseFirestore.instance);

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(
    ref.watch(firebaseAuthProvider),
    ref.watch(firebaseFirestoreProvider),
  );
});

final listingRepositoryProvider = Provider<ListingRepository>((ref) {
  return ListingRepositoryImpl(ref.watch(firebaseFirestoreProvider));
});

final userRepositoryProvider = Provider<UserRepository>((ref) {
  return UserRepositoryImpl(ref.watch(firebaseFirestoreProvider));
});
