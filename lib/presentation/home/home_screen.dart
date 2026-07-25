import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pixcard/presentation/widgets/listing_card.dart';
import 'package:pixcard/presentation/providers/listing_provider.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    final listingsAsync = ref.watch(listingsStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('PixCard'),
      ),
      body: listingsAsync.when(
        data: (listings) {
          if (listings.isEmpty) {
            return const Center(child: Text('Aucune annonce trouvée'));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: listings.length,
            itemBuilder: (context, index) {
              final listing = listings[index];
              return ListingCard(
                listing: listing,
                onTap: () => context.push('/listing/${listing.id}'),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erreur: $e')),
      ),
    );
  }
}
