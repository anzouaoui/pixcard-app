import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pixcard/domain/entities/listing.dart';
import 'package:pixcard/presentation/providers/listing_provider.dart';

class FilterState {
  const FilterState({
    this.searchQuery = '',
    this.selectedSets = const [],
    this.selectedConditions = const [],
    this.minPrice,
    this.maxPrice,
    this.sortBy = 'Pertinence',
  });

  final String searchQuery;
  final List<String> selectedSets;
  final List<CardCondition> selectedConditions;
  final double? minPrice;
  final double? maxPrice;
  final String sortBy;

  bool get hasActiveFilters =>
      searchQuery.isNotEmpty ||
      selectedSets.isNotEmpty ||
      selectedConditions.isNotEmpty ||
      minPrice != null ||
      maxPrice != null;

  FilterState copyWith({
    String? searchQuery,
    List<String>? selectedSets,
    List<CardCondition>? selectedConditions,
    double? minPrice,
    double? maxPrice,
    String? sortBy,
  }) {
    return FilterState(
      searchQuery: searchQuery ?? this.searchQuery,
      selectedSets: selectedSets ?? this.selectedSets,
      selectedConditions: selectedConditions ?? this.selectedConditions,
      minPrice: minPrice ?? this.minPrice,
      maxPrice: maxPrice ?? this.maxPrice,
      sortBy: sortBy ?? this.sortBy,
    );
  }
}

class FilterNotifier extends StateNotifier<FilterState> {
  FilterNotifier() : super(const FilterState());

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  void toggleSet(String set) {
    final sets = List<String>.from(state.selectedSets);
    if (sets.contains(set)) {
      sets.remove(set);
    } else {
      sets.add(set);
    }
    state = state.copyWith(selectedSets: sets);
  }

  void toggleCondition(CardCondition condition) {
    final conditions = List<CardCondition>.from(state.selectedConditions);
    if (conditions.contains(condition)) {
      conditions.remove(condition);
    } else {
      conditions.add(condition);
    }
    state = state.copyWith(selectedConditions: conditions);
  }

  void setPriceRange(double? min, double? max) {
    state = state.copyWith(minPrice: min, maxPrice: max);
  }

  void setSortBy(String sortBy) {
    state = state.copyWith(sortBy: sortBy);
  }

  void clearFilters() {
    state = const FilterState();
  }
}

final filterProvider = StateNotifierProvider<FilterNotifier, FilterState>((ref) {
  return FilterNotifier();
});

final searchQueryProvider = StateProvider<String>((ref) => '');

final filteredListingsProvider = Provider<AsyncValue<List<Listing>>>((ref) {
  final filters = ref.watch(filterProvider);
  final listingsAsync = ref.watch(listingsStreamProvider);

  return listingsAsync.when(
    data: (listings) {
      var filtered = listings.where((listing) {
        // Search query filter
        if (filters.searchQuery.isNotEmpty) {
          final query = filters.searchQuery.toLowerCase();
          if (!listing.cardName.toLowerCase().contains(query) &&
              !listing.series.toLowerCase().contains(query)) {
            return false;
          }
        }

        // Sets filter
        if (filters.selectedSets.isNotEmpty) {
          if (!filters.selectedSets.contains(listing.series)) {
            return false;
          }
        }

        // Conditions filter
        if (filters.selectedConditions.isNotEmpty) {
          if (!filters.selectedConditions.contains(listing.condition)) {
            return false;
          }
        }

        // Price range filter
        if (filters.minPrice != null && listing.price < filters.minPrice!) {
          return false;
        }
        if (filters.maxPrice != null && listing.price > filters.maxPrice!) {
          return false;
        }

        return true;
      }).toList();

      // Sort
      switch (filters.sortBy) {
        case 'Prix croissant':
          filtered.sort((a, b) => a.price.compareTo(b.price));
          break;
        case 'Prix décroissant':
          filtered.sort((a, b) => b.price.compareTo(a.price));
          break;
        case 'Plus récents':
          filtered.sort((a, b) {
            if (a.createdAt == null && b.createdAt == null) return 0;
            if (a.createdAt == null) return 1;
            if (b.createdAt == null) return -1;
            return b.createdAt!.compareTo(a.createdAt!);
          });
          break;
        default:
          break;
      }

      return AsyncValue.data(filtered);
    },
    loading: () => const AsyncValue.loading(),
    error: (e, st) => AsyncValue.error(e, st),
  );
});

final pokemonSetsProvider = Provider<List<String>>((ref) {
  return [
    'Base Set',
    'Jungle',
    'Fossil',
    'Base Set 2',
    'Team Rocket',
    'Gym Heroes',
    'Gym Challenge',
    'Neo Genesis',
    'Neo Discovery',
    'Neo Revelation',
    'Neo Destiny',
    'Legendary Collection',
    'Expedition',
    'Aquapolis',
    'Skyridge',
    'EX Ruby & Sapphire',
    'EX Sandstorm',
    'EX Dragon',
    'EX Team Magma vs Team Aqua',
    'EX Hidden Legends',
    'EX FireRed & LeafGreen',
    'EX Team Rocket Returns',
    'EX Deoxys',
    'EX Emerald',
    'EX Unseen Forces',
    'EX Delta Species',
    'EX Legend Maker',
    'EX Holon Phantoms',
    'EX Crystal Guardians',
    'EX Dragon Frontiers',
    'EX Power Keepers',
    'Diamond & Pearl',
    'Mysterious Treasures',
    'Secret Wonders',
    'Great Encounters',
    'Majestic Dawn',
    'Legends Awakened',
    'Stormfront',
    'Platinum',
    'Rising Rivals',
    'Supreme Victors',
    'Arceus',
    'HeartGold & SoulSilver',
    'Unleashed',
    'Undaunted',
    'Triumphant',
    'Call of Legends',
    'Black & White',
    'Emerging Powers',
    'Noble Victories',
    'Next Destinies',
    'Dark Explorers',
    'Dragons Exalted',
    'Boundaries Crossed',
    'Plasma Storm',
    'Plasma Freeze',
    'Plasma Blast',
    'Legendary Treasures',
    'XY',
    'Flashfire',
    'Furious Fists',
    'Phantom Forces',
    'Primal Clash',
    'Roaring Skies',
    'Ancient Origins',
    'BREAKthrough',
    'BREAKpoint',
    'Fates Collide',
    'Steam Siege',
    'Evolutions',
    'Sun & Moon',
    'Guardians Rising',
    'Burning Shadows',
    'Crimson Invasion',
    'Ultra Prism',
    'Forbidden Light',
    'Celestial Storm',
    'Lost Thunder',
    'Team Up',
    'Unbroken Bonds',
    'Unified Minds',
    'Cosmic Eclipse',
    'Sword & Shield',
    'Rebel Clash',
    'Darkness Ablaze',
    'Champion\'s Path',
    'Vivid Voltage',
    'Shining Fates',
    'Battle Styles',
    'Chilling Reign',
    'Evolving Skies',
    'Celebrations',
    'Fusion Strike',
    'Brilliant Stars',
    'Astral Radiance',
    'Lost Origin',
    'Silver Tempest',
    'Crown Zenith',
    'Scarlet & Violet',
    'Paldea Evolved',
    'Obsidian Flames',
    'Paldea Fates',
    'Temporal Forces',
    'Twilight Masquerade',
    'Stellar Crown',
  ];
});

final cardConditionsProvider = Provider<List<CardCondition>>((ref) {
  return [
    CardCondition.neuf,
    CardCondition.nearMount,
    CardCondition.tresBonEtat,
    CardCondition.bonEtat,
    CardCondition.jouable,
  ];
});