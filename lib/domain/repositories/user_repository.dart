import 'package:pixcard/domain/entities/app_user.dart';
import 'package:pixcard/domain/entities/favorite.dart';

abstract interface class UserRepository {
  Future<AppUser> getUserById(String id);
  Future<void> updateUser(AppUser user);
  Future<void> deleteUser(String id);
  Future<void> addFavorite(String userId, Favorite favorite);
  Future<void> removeFavorite(String userId, String listingId);
  Future<List<Favorite>> getFavorites(String userId);
  Stream<List<String>> watchFavoriteIds(String userId);
}
