import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pixcard/domain/entities/favorite.dart';
import 'package:pixcard/domain/entities/listing.dart';
import 'package:pixcard/presentation/providers/auth_provider.dart';
import 'package:pixcard/presentation/providers/providers.dart';

// ── Firestore stream of favorite IDs ──

final favoriteIdsProvider = StreamProvider.autoDispose<List<String>>((ref) {
  final auth = ref.watch(authStateProvider);
  if (auth.user == null) return const Stream.empty();
  return ref.watch(userRepositoryProvider).watchFavoriteIds(auth.user!.id);
});

// ── Optimistic toggle overrides ──
// Stores listing IDs where we've optimistically flipped the favorite state.
// The override auto-clears once the Firestore stream catches up (2s timeout).

final _optimisticOverridesProvider = StateProvider.autoDispose<Set<String>>((ref) => {});

// ── Is a specific listing favorited? (with optimistic support) ──

final isListingFavoriteProvider = Provider.autoDispose.family<bool, String>((ref, listingId) {
  final streamIds = ref.watch(favoriteIdsProvider).valueOrNull ?? [];
  final overrides = ref.watch(_optimisticOverridesProvider);
  final fromStream = streamIds.contains(listingId);
  if (overrides.contains(listingId)) return !fromStream;
  return fromStream;
});

// ── Helper: toggle a listing's favorite status with optimistic UI ──

void toggleFavorite(WidgetRef ref, String listingId) {
  final streamIds = ref.read(favoriteIdsProvider).valueOrNull ?? [];
  final currentlyFav = streamIds.contains(listingId);
  final userId = ref.read(authStateProvider).user?.id;
  if (userId == null) return;

  // Optimistic: immediately flip
  final overrides = ref.read(_optimisticOverridesProvider);
  ref.read(_optimisticOverridesProvider.notifier).state = {...overrides, listingId};

  // Schedule cleanup after stream should have caught up
  Future.delayed(const Duration(seconds: 2), () {
    final current = ref.read(_optimisticOverridesProvider);
    if (current.contains(listingId)) {
      ref.read(_optimisticOverridesProvider.notifier).state = current.where((id) => id != listingId).toSet();
    }
  });

  // Firestore write (fire-and-forget)
  final repo = ref.read(userRepositoryProvider);
  if (currentlyFav) {
    repo.removeFavorite(userId, listingId);
  } else {
    repo.addFavorite(userId, Favorite(listingId: listingId, addedAt: DateTime.now()));
  }
}

// ── Fetch full listings for all favorite IDs ──

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
