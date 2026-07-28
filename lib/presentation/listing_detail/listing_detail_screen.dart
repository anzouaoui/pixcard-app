import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pixcard/core/constants/app_constants.dart';
import 'package:pixcard/core/utils/extensions.dart';
import 'package:pixcard/domain/entities/app_user.dart';
import 'package:pixcard/domain/entities/listing.dart';
import 'package:pixcard/presentation/providers/providers.dart';
import 'package:pixcard/presentation/providers/auth_provider.dart';

final _listingProvider = FutureProvider.autoDispose.family<Listing?, String>((ref, id) async {
  try {
    final repo = ref.watch(listingRepositoryProvider);
    return await repo.getListingById(id);
  } catch (_) {
    return null;
  }
});

final _sellerProvider = FutureProvider.autoDispose.family<AppUser?, String>((ref, sellerId) async {
  try {
    final repo = ref.watch(userRepositoryProvider);
    return await repo.getUserById(sellerId);
  } catch (_) {
    return null;
  }
});

class ListingDetailScreen extends ConsumerWidget {
  const ListingDetailScreen({super.key, required this.id});

  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final listingAsync = ref.watch(_listingProvider(id));
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      body: listingAsync.when(
        data: (listing) {
          if (listing == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.search_off_rounded, size: 64, color: cs.onSurfaceVariant),
                  const SizedBox(height: 16),
                  Text('Annonce introuvable', style: Theme.of(context).textTheme.titleMedium),
                ],
              ),
            );
          }
          return _DetailBody(listing: listing);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline_rounded, size: 48, color: cs.error),
              const SizedBox(height: 16),
              Text('Erreur de chargement', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () => ref.invalidate(_listingProvider(id)),
                child: const Text('Réessayer'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DetailBody extends ConsumerWidget {
  const _DetailBody({required this.listing});

  final Listing listing;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final sellerAsync = ref.watch(_sellerProvider(listing.sellerId));
    final conditionColor = _getConditionColor(listing.condition);
    final conditionLabel = _getConditionLabel(listing.condition);
    final buyerPays = listing.price / (1 - AppConstants.sellerCommissionRate);
    final commission = buyerPays - listing.price;

    return CustomScrollView(
      slivers: [
        // ── Image hero ──
        SliverAppBar(
          expandedHeight: 300,
          pinned: true,
          backgroundColor: cs.surface,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => Navigator.of(context).pop(),
          ),
          flexibleSpace: FlexibleSpaceBar(
            background: listing.imageUrl.isNotEmpty
                ? Image.network(
                    listing.imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _placeholderImage(cs),
                  )
                : _placeholderImage(cs),
          ),
        ),

        // ── Content ──
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Condition badge + game tag
                Row(
                  children: [
                    _Badge(label: conditionLabel, color: conditionColor),
                    const SizedBox(width: 8),
                    _Badge(
                      label: listing.game.toUpperCase(),
                      color: cs.secondaryContainer,
                      textColor: cs.onSecondaryContainer,
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Card name
                Text(
                  listing.cardName,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 4),

                // Series
                Text(
                  listing.series,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                ),
                const SizedBox(height: 24),

                // ── Price card ──
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: cs.primaryContainer.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Prix vendeur',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: cs.onSurfaceVariant,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        listing.price.toPriceString(),
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: cs.primary,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Commission PixCard : ${commission.toPriceString()}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: cs.onSurfaceVariant,
                            ),
                      ),
                      Text(
                        'Vous payez : ${buyerPays.toPriceString()}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: cs.onSurfaceVariant,
                            ),
                      ),
                      if (listing.marketPriceAvg != null) ...[
                        const SizedBox(height: 12),
                        const Divider(height: 1),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Icon(Icons.trending_up_rounded, size: 18, color: cs.primary),
                            const SizedBox(width: 6),
                            Text(
                              'Cote marché : ${listing.marketPriceAvg!.toPriceString()}',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: cs.primary,
                                  ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // ── Description ──
                if (listing.description != null && listing.description!.isNotEmpty) ...[
                  Text(
                    'Description',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    listing.description!,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: cs.onSurfaceVariant,
                          height: 1.5,
                        ),
                  ),
                  const SizedBox(height: 24),
                ],

                // ── Seller card ──
                Text(
                  'Vendeur',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 8),
                sellerAsync.when(
                  data: (seller) {
                    if (seller == null) return const SizedBox.shrink();
                    return _SellerCard(seller: seller);
                  },
                  loading: () => const SizedBox(height: 48, child: Center(child: CircularProgressIndicator(strokeWidth: 2))),
                  error: (_, __) => const SizedBox.shrink(),
                ),
                const SizedBox(height: 24),

                // ── Listing date ──
                if (listing.createdAt != null)
                  Text(
                    'Publiée le ${_formatDate(listing.createdAt!)}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                  ),
                const SizedBox(height: 24),

                // ── Make offer button ──
                Builder(
                  builder: (context) {
                    final currentUser = ref.watch(authStateProvider).user;
                    final isSeller = currentUser?.id == listing.sellerId;
                    if (isSeller) return const SizedBox.shrink();
                    return FilledButton.icon(
                      onPressed: () => context.push('/make-offer', extra: listing),
                      icon: const Icon(Icons.local_offer_outlined, size: 20),
                      label: const Text('Faire une offre'),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(52),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 100),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _placeholderImage(ColorScheme cs) {
    return Container(
      color: cs.surfaceContainerHighest,
      child: Center(
        child: Icon(Icons.image_outlined, size: 80, color: cs.onSurfaceVariant),
      ),
    );
  }

  static String _formatDate(DateTime d) {
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  }

  static Color _getConditionColor(CardCondition condition) {
    switch (condition) {
      case CardCondition.neuf:
        return Colors.green;
      case CardCondition.nearMount:
        return Colors.lightBlue;
      case CardCondition.tresBonEtat:
        return Colors.purple.shade200;
      case CardCondition.bonEtat:
        return Colors.amber.shade600;
      case CardCondition.jouable:
        return Colors.grey;
    }
  }

  static String _getConditionLabel(CardCondition condition) {
    switch (condition) {
      case CardCondition.neuf:
        return 'Neuf';
      case CardCondition.nearMount:
        return 'Near Mint';
      case CardCondition.tresBonEtat:
        return 'Très bon état';
      case CardCondition.bonEtat:
        return 'Bon état';
      case CardCondition.jouable:
        return 'Jouable';
    }
  }
}

// ── Reusable widgets ──

class _Badge extends StatelessWidget {
  const _Badge({
    required this.label,
    required this.color,
    this.textColor,
  });

  final String label;
  final Color color;
  final Color? textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor ?? Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _SellerCard extends StatelessWidget {
  const _SellerCard({required this.seller});

  final AppUser seller;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          // Avatar
          CircleAvatar(
            radius: 24,
            backgroundColor: cs.primaryContainer,
            backgroundImage: seller.photoUrl != null && seller.photoUrl!.isNotEmpty
                ? NetworkImage(seller.photoUrl!)
                : null,
            child: seller.photoUrl == null || seller.photoUrl!.isEmpty
                ? Text(
                    seller.displayName.isNotEmpty ? seller.displayName[0].toUpperCase() : '?',
                    style: TextStyle(
                      color: cs.onPrimaryContainer,
                      fontWeight: FontWeight.w700,
                      fontSize: 18,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 12),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  seller.displayName.isNotEmpty ? seller.displayName : 'Vendeur',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Icon(Icons.star_rounded, size: 16, color: Colors.amber.shade600),
                    const SizedBox(width: 2),
                    Text(
                      seller.rating.toStringAsFixed(1),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${seller.salesCount} vente${seller.salesCount > 1 ? 's' : ''}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: cs.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Reliability
          if (seller.reliabilityScore < 100)
            Icon(
              Icons.verified_rounded,
              size: 20,
              color: seller.reliabilityScore >= 90 ? Colors.green : Colors.orange,
            ),
        ],
      ),
    );
  }
}
