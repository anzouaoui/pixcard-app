import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pixcard/domain/entities/app_user.dart';
import 'package:pixcard/domain/repositories/user_repository.dart';

class UserRepositoryImpl implements UserRepository {
  UserRepositoryImpl(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference get _users => _firestore.collection('users');

  @override
  Future<AppUser> getUserById(String id) async {
    final doc = await _users.doc(id).get();
    if (!doc.exists) throw Exception('User not found');
    return AppUser.fromMap(doc.data() as Map<String, dynamic>);
  }

  @override
  Future<void> updateUser(AppUser user) async {
    await _users.doc(user.id).update(user.toMap());
  }

  @override
  Future<void> deleteUser(String id) async {
    await _users.doc(id).delete();
  }
}
