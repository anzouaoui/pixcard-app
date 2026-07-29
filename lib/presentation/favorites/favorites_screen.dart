import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pixcard/presentation/providers/favorites_provider.dart';
import 'package:pixcard/presentation/widgets/listing_card.dart';

class FavoritesScreen extends ConsumerWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final listingsAsync = ref.watch(favoriteListingsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes favoris'),
      ),
      body: listingsAsync.when(
        data: (listings) {
          if (listings.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.favorite_outline_rounded, size: 64, color: cs.onSurfaceVariant),
                  const SizedBox(height: 16),
                  Text(
                    'Aucune carte en favoris pour l\'instant',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: () => context.go('/'),
                    icon: const Icon(Icons.home_rounded, size: 20),
                    label: const Text('Retour à l\'accueil'),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }
          return GridView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.72,
            ),
            itemCount: listings.length,
            itemBuilder: (context, index) {
              final listing = listings[index];
              final isFav = ref.watch(isListingFavoriteProvider(listing.id));
              return ListingCard(
                listing: listing,
                isFavorite: isFav,
                onTap: () => context.push('/listing/${listing.id}'),
                onToggleFavorite: () => toggleFavorite(ref, listing.id),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline_rounded, size: 48, color: cs.error),
              const SizedBox(height: 16),
              Text('Erreur de chargement', style: Theme.of(context).textTheme.titleMedium),
            ],
          ),
        ),
      ),
    );
  }
}
