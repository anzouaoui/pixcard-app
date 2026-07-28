import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pixcard/domain/entities/listing.dart';
import 'package:pixcard/presentation/providers/auth_provider.dart';
import 'package:pixcard/presentation/providers/providers.dart';

final favoriteIdsProvider = StreamProvider.autoDispose<List<String>>((ref) {
  final auth = ref.watch(authStateProvider);
  if (auth.user == null) return const Stream.empty();
  return ref.watch(userRepositoryProvider).watchFavoriteIds(auth.user!.id);
});

final isListingFavoriteProvider = Provider.autoDispose.family<bool, String>((ref, listingId) {
  final ids = ref.watch(favoriteIdsProvider).valueOrNull ?? [];
  return ids.contains(listingId);
});

final favoriteListingsProvider = FutureProvider.autoDispose<List<Listing>>((ref) async {
  final ids = ref.watch(favoriteIdsProvider).valueOrNull ?? [];
  if (ids.isEmpty) return [];
  final repo = ref.watch(listingRepositoryProvider);
  final listings = <Listing>[];
  for (final id in ids) {
    try {
      listings.add(await repo.getListingById(id));
    } catch (_) {}
  }
  return listings;
});
