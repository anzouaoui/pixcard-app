import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pixcard/core/utils/extensions.dart';
import 'package:pixcard/domain/entities/order.dart' as domain;
import 'package:pixcard/presentation/providers/auth_provider.dart';
import 'package:pixcard/presentation/providers/providers.dart';

// ── Mode ──

enum OrdersMode { buyer, seller }

// ── Orders stream for current user ──

final _buyerOrdersProvider = StreamProvider.autoDispose<List<domain.Order>>((ref) {
  final auth = ref.watch(authStateProvider);
  if (auth.user == null) return const Stream.empty();
  return ref.watch(orderRepositoryProvider).watchOrdersByBuyer(auth.user!.id);
});

final _sellerOrdersProvider = StreamProvider.autoDispose<List<domain.Order>>((ref) {
  final auth = ref.watch(authStateProvider);
  if (auth.user == null) return const Stream.empty();
  return ref.watch(orderRepositoryProvider).watchOrdersBySeller(auth.user!.id);
});

// ── Screen ──

class OrdersScreen extends ConsumerWidget {
  const OrdersScreen({super.key, this.mode = OrdersMode.buyer});

  final OrdersMode mode;

  String _orderReference(domain.Order order) =>
      'PX-${order.createdAt?.millisecondsSinceEpoch ?? DateTime.now().millisecondsSinceEpoch}';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final ordersAsync = ref.watch(
      mode == OrdersMode.buyer ? _buyerOrdersProvider : _sellerOrdersProvider,
    );

    final isBuyer = mode == OrdersMode.buyer;

    return Scaffold(
      appBar: AppBar(
        title: Text(isBuyer ? 'Mes achats' : 'Mes ventes'),
      ),
      body: ordersAsync.when(
        data: (orders) {
          if (orders.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    isBuyer ? Icons.shopping_bag_outlined : Icons.storefront_outlined,
                    size: 64,
                    color: cs.onSurfaceVariant,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    isBuyer ? 'Aucun achat pour le moment' : 'Aucune vente pour le moment',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isBuyer ? 'Vos commandes apparaîtront ici' : 'Vos ventes apparaîtront ici',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: orders.length,
            separatorBuilder: (_, __) => Divider(
              height: 1,
              indent: 16,
              endIndent: 16,
              color: cs.outlineVariant.withValues(alpha: 0.3),
            ),
            itemBuilder: (context, index) {
              final order = orders[index];
              return _OrderTile(
                order: order,
                reference: _orderReference(order),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => Center(
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

// ── Order Tile ──

class _OrderTile extends StatelessWidget {
  const _OrderTile({required this.order, required this.reference});

  final domain.Order order;
  final String reference;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final (Color statusColor, String statusLabel) = switch (order.status) {
      domain.OrderStatus.paid => (cs.primary, 'Payée'),
      domain.OrderStatus.shipped => (Colors.orange.shade600, 'Expédiée'),
      domain.OrderStatus.delivered => (Colors.green, 'Livrée'),
      domain.OrderStatus.disputed => (cs.error, 'Litige'),
    };

    return InkWell(
      onTap: () => context.push('/order-tracking', extra: order),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            // Icon
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                order.status == domain.OrderStatus.delivered
                    ? Icons.check_circle_rounded
                    : Icons.receipt_long_rounded,
                color: statusColor,
                size: 24,
              ),
            ),
            const SizedBox(width: 14),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    reference,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${order.totalPaid.toPriceString()} · ${order.listingId.substring(0, 8).toUpperCase()}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            // Status badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                statusLabel,
                style: TextStyle(
                  color: statusColor,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ),

            const SizedBox(width: 4),
            Icon(Icons.chevron_right, size: 20, color: cs.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}
