import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pixcard/domain/entities/app_user.dart';
import 'package:pixcard/domain/entities/order.dart';
import 'package:pixcard/presentation/providers/providers.dart';

// ── Seller provider ──

final _sellerProvider = FutureProvider.autoDispose.family<AppUser?, String>((ref, sellerId) async {
  try {
    return await ref.watch(userRepositoryProvider).getUserById(sellerId);
  } catch (_) {
    return null;
  }
});

// ── Screen ──

class OrderTrackingScreen extends ConsumerWidget {
  const OrderTrackingScreen({super.key, required this.order});

  final Order order;

  String get _orderReference =>
      'PX-${order.createdAt?.millisecondsSinceEpoch ?? DateTime.now().millisecondsSinceEpoch}';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final sellerAsync = ref.watch(_sellerProvider(order.sellerId));

    final steps = _buildSteps(cs);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Suivi de commande'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        children: [
          // ── Order reference + status badge ──
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _orderReference,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _formatDate(order.createdAt ?? DateTime.now()),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: cs.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ),
              _StatusBadge(status: order.status, cs: cs),
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

          // ── Tracking number ──
          if (order.trackingNumber != null && order.trackingNumber!.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cs.primaryContainer.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  Icon(Icons.local_post_office_rounded, color: cs.primary, size: 22),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Numéro de suivi',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: cs.onSurfaceVariant,
                              ),
                        ),
                        Text(
                          order.trackingNumber!,
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      // TODO: open carrier tracking URL
                    },
                    icon: Icon(Icons.open_in_new_rounded, size: 20),
                    tooltip: 'Ouvrir le suivi transporteur',
                  ),
                ],
              ),
            ),
          if (order.trackingNumber != null && order.trackingNumber!.isNotEmpty)
            const SizedBox(height: 28),

          // ── Seller contact ──
          Text(
            'Vendeur',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 10),
          sellerAsync.when(
            data: (seller) {
              if (seller == null) return const SizedBox.shrink();
              return _SellerCard(seller: seller, cs: cs);
            },
            loading: () => const SizedBox(
              height: 60,
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            ),
            error: (_, __) => const SizedBox.shrink(),
          ),
          const SizedBox(height: 36),

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
              'Retour à l\'accueil',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  List<_TimelineStepData> _buildSteps(ColorScheme cs) {
    final allSteps = [
      _TimelineStepData(
        title: 'Paiement confirmé',
        subtitle: _formatDate(order.createdAt ?? DateTime.now()),
        isCompleted: true,
        icon: Icons.check_rounded,
      ),
      _TimelineStepData(
        title: 'Expédié',
        subtitle: order.status.index >= OrderStatus.shipped.index
            ? 'En cours d\'acheminement'
            : 'En attente d\'expédition',
        isCompleted: order.status.index >= OrderStatus.shipped.index,
        icon: Icons.local_shipping_rounded,
      ),
      _TimelineStepData(
        title: 'Livré',
        subtitle: order.status == OrderStatus.delivered
            ? 'Colis remis'
            : 'En attente de livraison',
        isCompleted: order.status == OrderStatus.delivered,
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
    final defaultColor = cs.outlineVariant.withValues(alpha: 0.6);
    final color = step.isCompleted ? completedColor : defaultColor;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Timeline line ──
          SizedBox(
            width: 32,
            child: Column(
              children: [
                if (!isFirst)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: color,
                    ),
                  )
                else
                  const Expanded(child: SizedBox.shrink()),
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: step.isCompleted
                        ? completedColor
                        : Colors.transparent,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: color,
                      width: 2,
                    ),
                  ),
                  child: step.isCompleted
                      ? Icon(Icons.check_rounded, size: 16, color: Colors.white)
                      : Icon(step.icon, size: 14, color: color),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: color,
                    ),
                  )
                else
                  const Expanded(child: SizedBox.shrink()),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // ── Content ──
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
                          fontWeight: FontWeight.w600,
                          color: step.isCompleted ? completedColor : cs.onSurfaceVariant,
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
    required this.icon,
  });

  final String title;
  final String subtitle;
  final bool isCompleted;
  final IconData icon;
}

// ── Seller Card ──

class _SellerCard extends StatelessWidget {
  const _SellerCard({required this.seller, required this.cs});

  final AppUser seller;
  final ColorScheme cs;

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
            backgroundImage: seller.photoUrl != null && seller.photoUrl!.isNotEmpty
                ? NetworkImage(seller.photoUrl!)
                : null,
            child: seller.photoUrl == null || seller.photoUrl!.isEmpty
                ? Text(
                    seller.displayName.isNotEmpty ? seller.displayName[0].toUpperCase() : '?',
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
                  seller.displayName.isNotEmpty ? seller.displayName : 'Vendeur',
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
          IconButton(
            onPressed: () {
              // TODO: navigate to conversation with seller
              context.go('/messages');
            },
            icon: Icon(Icons.chat_outlined, color: cs.primary),
            tooltip: 'Contacter le vendeur',
          ),
        ],
      ),
    );
  }
}
