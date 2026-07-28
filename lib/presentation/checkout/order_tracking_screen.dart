import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pixcard/core/utils/extensions.dart';
import 'package:pixcard/domain/entities/app_user.dart';
import 'package:pixcard/domain/entities/conversation.dart';
import 'package:pixcard/domain/entities/dispute.dart';
import 'package:pixcard/domain/entities/listing.dart';
import 'package:pixcard/domain/entities/order.dart';
import 'package:pixcard/domain/entities/review.dart';
import 'package:pixcard/presentation/providers/auth_provider.dart';
import 'package:pixcard/presentation/providers/providers.dart';

// ── Order stream ──

final _orderStreamProvider = StreamProvider.autoDispose.family<Order?, String>((ref, id) {
  return ref.watch(orderRepositoryProvider).watchOrderById(id);
});

// ── Listing provider ──

final _listingProvider = FutureProvider.autoDispose.family<Listing?, String>((ref, id) async {
  try {
    return await ref.watch(listingRepositoryProvider).getListingById(id);
  } catch (_) {
    return null;
  }
});

// ── User provider ──

final _userProvider = FutureProvider.autoDispose.family<AppUser?, String>((ref, userId) async {
  try {
    return await ref.watch(userRepositoryProvider).getUserById(userId);
  } catch (_) {
    return null;
  }
});

// ── Conversation provider ──

final _conversationProvider = FutureProvider.autoDispose.family<Conversation?, String>((ref, orderId) async {
  final orderAsync = ref.watch(_orderStreamProvider(orderId));
  final order = orderAsync.valueOrNull;
  if (order == null) return null;
  final auth = ref.watch(authStateProvider);
  final userId = auth.user?.id ?? '';
  try {
    return await ref.watch(conversationRepositoryProvider)
        .getConversationByListing(order.listingId, [userId, order.sellerId]);
  } catch (_) {
    return null;
  }
});

// ── Existing review provider ──

final _existingReviewProvider = FutureProvider.autoDispose.family<bool, String>((ref, orderId) async {
  try {
    final reviews = await ref.watch(reviewRepositoryProvider).getReviewsByOrder(orderId);
    return reviews.isNotEmpty;
  } catch (_) {
    return false;
  }
});

// ── Screen ──

class OrderTrackingScreen extends ConsumerWidget {
  const OrderTrackingScreen({super.key, required this.orderId});

  final String orderId;

  String _orderReference(Order o) =>
      'PX-${o.createdAt?.millisecondsSinceEpoch ?? DateTime.now().millisecondsSinceEpoch}';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final auth = ref.watch(authStateProvider);
    final currentUserId = auth.user?.id ?? '';

    final orderAsync = ref.watch(_orderStreamProvider(orderId));
    final currentOrder = orderAsync.valueOrNull;

    if (currentOrder == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Suivi de commande')),
        body: orderAsync.isLoading
            ? const Center(child: CircularProgressIndicator())
            : Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.search_off_rounded, size: 64, color: cs.onSurfaceVariant),
                    const SizedBox(height: 16),
                    Text('Commande introuvable', style: Theme.of(context).textTheme.titleMedium),
                  ],
                ),
              ),
      );
    }

    final isSeller = currentUserId == currentOrder.sellerId;
    final listingAsync = ref.watch(_listingProvider(currentOrder.listingId));
    final steps = _buildSteps(currentOrder, cs);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Suivi de commande'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        children: [
          // ── Listing header ──
          listingAsync.when(
            data: (listing) {
              if (listing == null) return const SizedBox.shrink();
              return _ListingHeader(listing: listing, cs: cs);
            },
            loading: () => const SizedBox(height: 72, child: Center(child: CircularProgressIndicator(strokeWidth: 2))),
            error: (_, _) => const SizedBox.shrink(),
          ),
          const SizedBox(height: 24),

          // ── Order reference + status badge ──
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _orderReference(currentOrder),
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _formatDate(currentOrder.createdAt ?? DateTime.now()),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: cs.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ),
              _StatusBadge(status: currentOrder.status, cs: cs),
            ],
          ),
          const SizedBox(height: 32),

          // ── Timeline ──
          Text(
            'Suivi',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: cs.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.3)),
            ),
            child: Column(
              children: List.generate(steps.length, (i) {
                final step = steps[i];
                final isFirst = i == 0;
                final isLast = i == steps.length - 1;
                return _TimelineStep(
                  step: step,
                  isFirst: isFirst,
                  isLast: isLast,
                );
              }),
            ),
          ),
          const SizedBox(height: 28),

          // ── Seller actions ──
          if (isSeller && currentOrder.status == OrderStatus.paid) ...[
            FilledButton.icon(
              onPressed: () => _markAsShipped(context, ref, currentOrder),
              icon: const Icon(Icons.local_shipping_rounded),
              label: const Text('Marquer comme expédié'),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
            const SizedBox(height: 28),
          ],

          // ── Buyer actions ──
          if (!isSeller && currentOrder.status == OrderStatus.shipped) ...[
            FilledButton.icon(
              onPressed: () => _markAsDelivered(context, ref, currentOrder),
              icon: const Icon(Icons.check_circle_rounded),
              label: const Text('Marquer comme reçu'),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
            const SizedBox(height: 28),
          ],

          // ── Tracking number ──
          if (currentOrder.trackingNumber != null && currentOrder.trackingNumber!.isNotEmpty)
            _TrackingNumberCard(trackingNumber: currentOrder.trackingNumber!, cs: cs),
          if (currentOrder.trackingNumber != null && currentOrder.trackingNumber!.isNotEmpty)
            const SizedBox(height: 28),

          // ── Contact card ──
          _buildContactSection(context, ref, currentOrder, isSeller, cs),
          const SizedBox(height: 28),

          // ── Signaler un problème ──
          if (!isSeller && currentOrder.status != OrderStatus.disputed) ...[
            OutlinedButton.icon(
              onPressed: () => _openDisputeForm(context, ref, currentOrder),
              icon: Icon(Icons.flag_outlined, color: cs.error),
              label: Text('Signaler un problème', style: TextStyle(color: cs.error)),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
                side: BorderSide(color: cs.error.withValues(alpha: 0.4)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
            const SizedBox(height: 28),
          ],

          // ── Laisser un avis ──
          if (!isSeller && currentOrder.status == OrderStatus.delivered) ...[
            ref.watch(_existingReviewProvider(currentOrder.id)).when(
              data: (hasReview) {
                if (hasReview) return const SizedBox.shrink();
                return Column(
                  children: [
                    FilledButton.icon(
                      onPressed: () => _openReviewDialog(context, ref, currentOrder),
                      icon: const Icon(Icons.rate_review_rounded),
                      label: const Text('Laisser un avis'),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(52),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),
                  ],
                );
              },
              loading: () => const SizedBox.shrink(),
              error: (_, _) => const SizedBox.shrink(),
            ),
          ],

          // ── Back to home ──
          FilledButton(
            onPressed: () => context.go('/'),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: const Text(
              "Retour à l'accueil",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactSection(BuildContext context, WidgetRef ref, Order order, bool isSeller, ColorScheme cs) {
    final contactId = isSeller ? order.buyerId : order.sellerId;
    final contactAsync = ref.watch(_userProvider(contactId));
    final convAsync = ref.watch(_conversationProvider(order.id));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isSeller ? 'Acheteur' : 'Vendeur',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 10),
        contactAsync.when(
          data: (contact) {
            if (contact == null) return const SizedBox.shrink();
            return convAsync.when(
              data: (conv) => _ContactCard(
                contact: contact,
                cs: cs,
                isSeller: isSeller,
                conversationId: conv?.id,
                order: order,
              ),
              loading: () => const SizedBox(height: 60, child: Center(child: CircularProgressIndicator(strokeWidth: 2))),
              error: (_, _) => _ContactCard(
                contact: contact,
                cs: cs,
                isSeller: isSeller,
                conversationId: null,
                order: order,
              ),
            );
          },
          loading: () => const SizedBox(height: 60, child: Center(child: CircularProgressIndicator(strokeWidth: 2))),
          error: (_, _) => const SizedBox.shrink(),
        ),
      ],
    );
  }

  Future<void> _markAsShipped(BuildContext context, WidgetRef ref, Order order) async {
    final trackingController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Marquer comme expédié'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Confirmez-vous que la commande a été expédiée ?'),
            const SizedBox(height: 16),
            TextField(
              controller: trackingController,
              decoration: const InputDecoration(
                labelText: 'Numéro de suivi (optionnel)',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text("Confirmer l'envoi"),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final updatedOrder = Order(
      id: order.id,
      listingId: order.listingId,
      buyerId: order.buyerId,
      sellerId: order.sellerId,
      cardPrice: order.cardPrice,
      paymentFee: order.paymentFee,
      totalPaid: order.totalPaid,
      sellerCommissionRate: order.sellerCommissionRate,
      sellerCommissionAmount: order.sellerCommissionAmount,
      sellerNetAmount: order.sellerNetAmount,
      status: OrderStatus.shipped,
      stripePaymentIntentId: order.stripePaymentIntentId,
      trackingNumber: trackingController.text.isNotEmpty
          ? trackingController.text
          : order.trackingNumber,
      createdAt: order.createdAt,
    );

    try {
      await ref.read(orderRepositoryProvider).updateOrder(updatedOrder);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Commande marquée comme expédiée')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur : $e')),
        );
      }
    }
  }

  Future<void> _markAsDelivered(BuildContext context, WidgetRef ref, Order order) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmer la réception'),
        content: const Text('Confirmez-vous avoir reçu la commande ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Confirmer'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final updatedOrder = Order(
      id: order.id,
      listingId: order.listingId,
      buyerId: order.buyerId,
      sellerId: order.sellerId,
      cardPrice: order.cardPrice,
      paymentFee: order.paymentFee,
      totalPaid: order.totalPaid,
      sellerCommissionRate: order.sellerCommissionRate,
      sellerCommissionAmount: order.sellerCommissionAmount,
      sellerNetAmount: order.sellerNetAmount,
      status: OrderStatus.delivered,
      stripePaymentIntentId: order.stripePaymentIntentId,
      trackingNumber: order.trackingNumber,
      createdAt: order.createdAt,
    );

    try {
      await ref.read(orderRepositoryProvider).updateOrder(updatedOrder);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Commande marquée comme reçue')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur : $e')),
        );
      }
    }
  }

  Future<void> _openDisputeForm(BuildContext context, WidgetRef ref, Order order) async {
    final reasons = [
      'Colis non reçu',
      'Article non conforme à la description',
      'Article endommagé',
      'Mauvaise carte reçue',
      'Autre problème',
    ];

    final descCtrl = TextEditingController();
    String selectedReason = reasons.first;

    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Signaler un problème'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Motif :'),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: selectedReason,
                  items: reasons.map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
                  onChanged: (v) {
                    if (v != null) setDialogState(() => selectedReason = v);
                  },
                  decoration: const InputDecoration(border: OutlineInputBorder()),
                ),
                const SizedBox(height: 16),
                const Text('Description :'),
                const SizedBox(height: 8),
                TextField(
                  controller: descCtrl,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    hintText: 'Décrivez le problème...',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Annuler'),
            ),
            FilledButton(
              onPressed: () {
                if (descCtrl.text.trim().isEmpty) return;
                Navigator.of(ctx).pop({
                  'reason': selectedReason,
                  'description': descCtrl.text.trim(),
                });
              },
              child: const Text('Envoyer'),
            ),
          ],
        ),
      ),
    );

    if (result == null) return;

    final auth = ref.read(authStateProvider);
    final buyerId = auth.user?.id ?? '';

    final dispute = Dispute(
      id: '',
      orderId: order.id,
      buyerId: buyerId,
      reason: result['reason'] ?? '',
      description: result['description'] ?? '',
    );

    try {
      await ref.read(disputeRepositoryProvider).createDispute(dispute);

      final updatedOrder = Order(
        id: order.id,
        listingId: order.listingId,
        buyerId: order.buyerId,
        sellerId: order.sellerId,
        cardPrice: order.cardPrice,
        paymentFee: order.paymentFee,
        totalPaid: order.totalPaid,
        sellerCommissionRate: order.sellerCommissionRate,
        sellerCommissionAmount: order.sellerCommissionAmount,
        sellerNetAmount: order.sellerNetAmount,
        status: OrderStatus.disputed,
        stripePaymentIntentId: order.stripePaymentIntentId,
        trackingNumber: order.trackingNumber,
        createdAt: order.createdAt,
      );
      await ref.read(orderRepositoryProvider).updateOrder(updatedOrder);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Votre litige a été enregistré')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur : $e')),
        );
      }
    }
  }

  Future<void> _openReviewDialog(BuildContext context, WidgetRef ref, Order order) async {
    int selectedRating = 0;
    final commentCtrl = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Laisser un avis'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Note'),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (i) {
                  final star = i + 1;
                  return IconButton(
                    onPressed: () => setDialogState(() => selectedRating = star),
                    icon: Icon(
                      star <= selectedRating ? Icons.star_rounded : Icons.star_outline_rounded,
                      color: Colors.amber,
                      size: 36,
                    ),
                  );
                }),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: commentCtrl,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Commentaire (optionnel)',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Annuler'),
            ),
            FilledButton(
              onPressed: selectedRating == 0 ? null : () => Navigator.of(ctx).pop(true),
              child: const Text('Envoyer'),
            ),
          ],
        ),
      ),
    );

    if (confirmed != true) return;

    final auth = ref.read(authStateProvider);
    final authorId = auth.user?.id ?? '';

    final review = Review(
      id: '',
      orderId: order.id,
      sellerId: order.sellerId,
      authorId: authorId,
      rating: selectedRating,
      comment: commentCtrl.text.trim().isEmpty ? null : commentCtrl.text.trim(),
    );

    try {
      await ref.read(reviewRepositoryProvider).createReview(review);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Avis envoyé')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur : $e')),
        );
      }
    }
  }

  List<_TimelineStepData> _buildSteps(Order order, ColorScheme cs) {
    final allSteps = [
      _TimelineStepData(
        title: 'Payé',
        subtitle: _formatDate(order.createdAt ?? DateTime.now()),
        isCompleted: true,
        isCurrent: false,
        icon: Icons.check_rounded,
      ),
      _TimelineStepData(
        title: 'Expédié',
        subtitle: order.status == OrderStatus.shipped || order.status == OrderStatus.delivered
            ? 'En cours d\'acheminement'
            : order.status == OrderStatus.disputed
                ? 'Litige ouvert'
                : 'En attente d\'expédition',
        isCompleted: order.status == OrderStatus.shipped || order.status == OrderStatus.delivered,
        isCurrent: order.status == OrderStatus.shipped,
        icon: Icons.local_shipping_rounded,
      ),
      _TimelineStepData(
        title: 'Livré',
        subtitle: order.status == OrderStatus.delivered
            ? 'Colis remis'
            : order.status == OrderStatus.disputed
                ? 'Litige ouvert'
                : 'En attente de livraison',
        isCompleted: order.status == OrderStatus.delivered,
        isCurrent: order.status == OrderStatus.delivered,
        icon: Icons.house_rounded,
      ),
    ];
    return allSteps;
  }

  String _formatDate(DateTime d) {
    const months = [
      '', 'janvier', 'février', 'mars', 'avril', 'mai', 'juin',
      'juillet', 'août', 'septembre', 'octobre', 'novembre', 'décembre',
    ];
    return '${d.day} ${months[d.month]} ${d.year}';
  }
}

// ── Listing Header ──

class _ListingHeader extends StatelessWidget {
  const _ListingHeader({required this.listing, required this.cs});

  final Listing listing;
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: SizedBox(
              width: 56,
              height: 56,
              child: listing.imageUrl.isNotEmpty
                  ? Image.network(listing.imageUrl, fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Icon(Icons.image_outlined, color: cs.onSurfaceVariant))
                  : Icon(Icons.image_outlined, color: cs.onSurfaceVariant),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  listing.cardName,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '${listing.game.capitalize} · ${listing.series}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Text(
            listing.price.toPriceString(),
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: cs.primary,
                ),
          ),
        ],
      ),
    );
  }
}

// ── Status Badge ──

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status, required this.cs});

  final OrderStatus status;
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    final (Color color, String label) = switch (status) {
      OrderStatus.paid => (cs.primary, 'Payée'),
      OrderStatus.shipped => (Colors.orange.shade600, 'Expédiée'),
      OrderStatus.delivered => (Colors.green, 'Livrée'),
      OrderStatus.disputed => (cs.error, 'Litige'),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w700,
          fontSize: 13,
        ),
      ),
    );
  }
}

// ── Timeline Step ──

class _TimelineStep extends StatelessWidget {
  const _TimelineStep({
    required this.step,
    required this.isFirst,
    required this.isLast,
  });

  final _TimelineStepData step;
  final bool isFirst;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final completedColor = Colors.green;
    final currentColor = cs.primary;
    final defaultColor = cs.outlineVariant.withValues(alpha: 0.6);

    final Color circleColor;
    final Color lineColor;
    final Color textColor;
    final Widget circleContent;

    if (step.isCompleted) {
      circleColor = completedColor;
      lineColor = completedColor;
      textColor = completedColor;
      circleContent = Icon(Icons.check_rounded, size: 16, color: Colors.white);
    } else if (step.isCurrent) {
      circleColor = currentColor;
      lineColor = defaultColor;
      textColor = currentColor;
      circleContent = Icon(step.icon, size: 14, color: Colors.white);
    } else {
      circleColor = Colors.transparent;
      lineColor = defaultColor;
      textColor = cs.onSurfaceVariant;
      circleContent = Icon(step.icon, size: 14, color: defaultColor);
    }

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 32,
            child: Column(
              children: [
                if (!isFirst)
                  Expanded(child: Container(width: 2, color: lineColor))
                else
                  const Expanded(child: SizedBox.shrink()),
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: circleColor,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: step.isCompleted || step.isCurrent ? circleColor : defaultColor,
                      width: 2,
                    ),
                  ),
                  child: circleContent,
                ),
                if (!isLast)
                  Expanded(child: Container(width: 2, color: lineColor))
                else
                  const Expanded(child: SizedBox.shrink()),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(
                top: isFirst ? 4 : 0,
                bottom: isLast ? 4 : 0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (!isFirst) const SizedBox(height: 18),
                  Text(
                    step.title,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: step.isCurrent ? FontWeight.w700 : FontWeight.w600,
                          color: textColor,
                        ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    step.subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                  ),
                  if (!isLast) const SizedBox(height: 18),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Timeline Step Data ──

class _TimelineStepData {
  const _TimelineStepData({
    required this.title,
    required this.subtitle,
    required this.isCompleted,
    required this.isCurrent,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final bool isCompleted;
  final bool isCurrent;
  final IconData icon;
}

// ── Tracking Number Card ──

class _TrackingNumberCard extends StatelessWidget {
  const _TrackingNumberCard({required this.trackingNumber, required this.cs});

  final String trackingNumber;
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.primaryContainer.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.local_post_office_rounded, color: cs.primary, size: 22),
              const SizedBox(width: 10),
              Text(
                'Numéro de suivi',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Text(
                  trackingNumber,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        fontFamily: 'monospace',
                      ),
                ),
              ),
              IconButton(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: trackingNumber));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Numéro de suivi copié')),
                  );
                },
                icon: Icon(Icons.copy_rounded, size: 20),
                tooltip: 'Copier',
              ),
              const SizedBox(width: 4),
              IconButton(
                onPressed: () {
                  // TODO: open carrier tracking URL
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Suivi transporteur bientôt disponible')),
                  );
                },
                icon: Icon(Icons.open_in_new_rounded, size: 20),
                tooltip: 'Ouvrir le suivi transporteur',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Contact Card ──

class _ContactCard extends StatelessWidget {
  const _ContactCard({
    required this.contact,
    required this.cs,
    required this.isSeller,
    required this.conversationId,
    required this.order,
  });

  final AppUser contact;
  final ColorScheme cs;
  final bool isSeller;
  final String? conversationId;
  final Order order;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: cs.primaryContainer,
            backgroundImage: contact.photoUrl != null && contact.photoUrl!.isNotEmpty
                ? NetworkImage(contact.photoUrl!)
                : null,
            child: contact.photoUrl == null || contact.photoUrl!.isEmpty
                ? Text(
                    contact.displayName.isNotEmpty ? contact.displayName[0].toUpperCase() : '?',
                    style: TextStyle(
                      color: cs.onPrimaryContainer,
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  contact.displayName.isNotEmpty ? contact.displayName : (isSeller ? 'Acheteur' : 'Vendeur'),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Icon(Icons.star_rounded, size: 14, color: Colors.amber.shade600),
                    const SizedBox(width: 2),
                    Text(
                      contact.rating.toStringAsFixed(1),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${contact.salesCount} vente${contact.salesCount > 1 ? 's' : ''}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: cs.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {
              if (conversationId != null) {
                context.push('/chat/$conversationId');
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Aucune conversation trouvée')),
                );
              }
            },
            icon: Icon(Icons.chat_outlined, color: cs.primary),
            tooltip: 'Contacter',
          ),
        ],
      ),
    );
  }
}

