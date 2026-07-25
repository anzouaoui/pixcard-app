import 'package:pixcard/domain/entities/app_user.dart';

abstract interface class UserRepository {
  Future<AppUser> getUserById(String id);
  Future<void> updateUser(AppUser user);
  Future<void> deleteUser(String id);
}
