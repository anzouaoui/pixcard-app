import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pixcard/presentation/widgets/listing_card.dart';
import 'package:pixcard/presentation/providers/auth_provider.dart';
import 'package:pixcard/presentation/providers/favorites_provider.dart';
import 'package:pixcard/presentation/providers/filter_provider.dart';
import 'package:pixcard/presentation/providers/providers.dart';
import 'package:pixcard/domain/entities/favorite.dart';
import 'package:pixcard/domain/entities/listing.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  String _selectedFilter = 'Tout';
  String _sortBy = 'Pertinence';

  final List<String> _filters = ['Tout', 'Pokémon'];
  final List<String> _sortOptions = ['Pertinence', 'Prix croissant', 'Prix décroissant', 'Plus récents'];

@override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateProvider).user;
    final pseudo = user?.displayName ?? 'Utilisateur';
    final filters = ref.watch(filterProvider);
    final listingsAsync = ref.watch(filteredListingsProvider);

    return SafeArea(
      child: Column(
        children: [
          _buildHeader(pseudo),
          _buildSearchBar(),
          _buildQuickFilters(),
          _buildListingsHeader(listingsAsync, filters),
          Expanded(
            child: _buildListingsGrid(listingsAsync),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(String pseudo) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Text(
            'Bonjour, $pseudo',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.filter_list_rounded, size: 28),
            onPressed: () => context.push('/filters'),
            tooltip: 'Filtres',
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: TextField(
        decoration: InputDecoration(
          hintText: 'Rechercher une carte...',
          prefixIcon: const Icon(Icons.search_rounded),
          suffixIcon: IconButton(
            icon: const Icon(Icons.mic_none_rounded),
            onPressed: () {},
          ),
          filled: true,
          fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
        ),
        onChanged: (value) => ref.read(searchQueryProvider.notifier).state = value,
      ),
    );
  }

  Widget _buildQuickFilters() {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: _filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final filter = _filters[index];
          final isSelected = _selectedFilter == filter;
          final isDisabled = filter != 'Tout' && filter != 'Pokémon';
          return FilterChip(
            label: Text(filter),
            selected: isSelected,
            onSelected: isDisabled ? null : (selected) {
              if (selected) {
                setState(() => _selectedFilter = filter);
              }
            },
            selectedColor: Theme.of(context).colorScheme.primaryContainer,
            labelStyle: TextStyle(
              color: isSelected
                  ? Theme.of(context).colorScheme.onPrimaryContainer
                  : isDisabled
                      ? Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.5)
                      : Theme.of(context).colorScheme.onSurface,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            ),
            showCheckmark: false,
            side: BorderSide(
              color: isSelected
                  ? Theme.of(context).colorScheme.primary
                  : isDisabled
                      ? Theme.of(context).colorScheme.outline.withOpacity(0.3)
                      : Theme.of(context).colorScheme.outline,
            ),
            backgroundColor: isDisabled
                ? Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.3)
                : Theme.of(context).colorScheme.surfaceContainerHighest,
          );
        },
      ),
    );
  }

  Widget _buildListingsHeader(AsyncValue<List<Listing>> listingsAsync, FilterState filters) {
    final count = listingsAsync.value?.length ?? 0;
    final hasActiveFilters = filters.hasActiveFilters;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Text(
            '$count annonce${count > 1 ? 's' : ''}',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          if (hasActiveFilters) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Filtres actifs',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
              ),
            ),
          ],
          const Spacer(),
          PopupMenuButton<String>(
            initialValue: _sortBy,
            onSelected: (value) => setState(() => _sortBy = value),
            itemBuilder: (context) => _sortOptions.map((option) {
              return PopupMenuItem(value: option, child: Text(option));
            }).toList(),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.sort_rounded, size: 20, color: Theme.of(context).colorScheme.onSurfaceVariant),
                const SizedBox(width: 4),
                Text(
                  _sortBy,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
                const SizedBox(width: 4),
                Icon(Icons.expand_more_rounded, size: 20, color: Theme.of(context).colorScheme.onSurfaceVariant),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListingsGrid(AsyncValue<List<Listing>> listingsAsync) {
    return listingsAsync.when(
      data: (listings) {
        if (listings.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.search_off_rounded, size: 64, color: Theme.of(context).colorScheme.onSurfaceVariant),
                const SizedBox(height: 16),
                Text(
                  'Aucune annonce trouvée',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Essayez de modifier vos filtres',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          );
        }
        return GridView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16),
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
              onToggleFavorite: () {
                final userId = ref.read(authStateProvider).user?.id;
                if (userId == null) return;
                final repo = ref.read(userRepositoryProvider);
                if (isFav) {
                  repo.removeFavorite(userId, listing.id);
                } else {
                  repo.addFavorite(userId, Favorite(listingId: listing.id, addedAt: DateTime.now()));
                }
              },
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline_rounded, size: 48, color: Theme.of(context).colorScheme.error),
            const SizedBox(height: 16),
            Text('Erreur de chargement', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(e.toString(), style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => ref.invalidate(filteredListingsProvider),
              child: const Text('Réessayer'),
            ),
          ],
        ),
      ),
    );
  }
}
