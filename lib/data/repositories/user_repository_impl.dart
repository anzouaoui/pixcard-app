import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pixcard/domain/entities/app_user.dart';
import 'package:pixcard/domain/entities/favorite.dart';
import 'package:pixcard/domain/repositories/user_repository.dart';

class UserRepositoryImpl implements UserRepository {
  UserRepositoryImpl(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference get _users => _firestore.collection('users');

  @override
  Future<AppUser> getUserById(String id) async {
    final doc = await _users.doc(id).get();
    if (!doc.exists) throw Exception('User not found');
    return AppUser.fromMap({
      'id': doc.id,
      ...doc.data() as Map<String, dynamic>,
    });
  }

  @override
  Future<void> updateUser(AppUser user) async {
    await _users.doc(user.id).update(user.toMap());
  }

  @override
  Future<void> deleteUser(String id) async {
    await _users.doc(id).delete();
  }

  // ── Favorites ──

  @override
  Future<void> addFavorite(String userId, Favorite favorite) async {
    await _users.doc(userId).collection('favorites').doc(favorite.listingId).set(
          favorite.toMap(),
        );
  }

  @override
  Future<void> removeFavorite(String userId, String listingId) async {
    await _users.doc(userId).collection('favorites').doc(listingId).delete();
  }

  @override
  Future<List<Favorite>> getFavorites(String userId) async {
    final snapshot = await _users
        .doc(userId)
        .collection('favorites')
        .orderBy('addedAt', descending: true)
        .get();

    return snapshot.docs
        .map((doc) => Favorite.fromMap(doc.data()))
        .toList();
  }

  @override
  Stream<List<String>> watchFavoriteIds(String userId) {
    return _users
        .doc(userId)
        .collection('favorites')
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => doc.id).toList(),
        );
  }
}
