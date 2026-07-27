import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pixcard/data/repositories/auth_repository_impl.dart';
import 'package:pixcard/data/repositories/listing_repository_impl.dart';
import 'package:pixcard/data/repositories/user_repository_impl.dart';
import 'package:pixcard/data/repositories/offer_repository_impl.dart';
import 'package:pixcard/data/repositories/conversation_repository_impl.dart';
import 'package:pixcard/data/repositories/order_repository_impl.dart';
import 'package:pixcard/data/repositories/review_repository_impl.dart';
import 'package:pixcard/domain/repositories/auth_repository.dart';
import 'package:pixcard/domain/repositories/listing_repository.dart';
import 'package:pixcard/domain/repositories/user_repository.dart';
import 'package:pixcard/domain/repositories/offer_repository.dart';
import 'package:pixcard/domain/repositories/conversation_repository.dart';
import 'package:pixcard/domain/repositories/order_repository.dart';
import 'package:pixcard/domain/repositories/review_repository.dart';

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

final offerRepositoryProvider = Provider<OfferRepository>((ref) {
  return OfferRepositoryImpl(ref.watch(firebaseFirestoreProvider));
});

final conversationRepositoryProvider = Provider<ConversationRepository>((ref) {
  return ConversationRepositoryImpl(ref.watch(firebaseFirestoreProvider));
});

final orderRepositoryProvider = Provider<OrderRepository>((ref) {
  return OrderRepositoryImpl(ref.watch(firebaseFirestoreProvider));
});

final reviewRepositoryProvider = Provider<ReviewRepository>((ref) {
  return ReviewRepositoryImpl(ref.watch(firebaseFirestoreProvider));
});
