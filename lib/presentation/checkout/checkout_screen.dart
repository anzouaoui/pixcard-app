import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pixcard/core/constants/app_constants.dart';
import 'package:pixcard/core/utils/extensions.dart';
import 'package:pixcard/domain/entities/app_user.dart';
import 'package:pixcard/domain/entities/listing.dart';
import 'package:pixcard/domain/entities/order.dart' as domain;
import 'package:pixcard/presentation/checkout/order_confirmation_screen.dart';
import 'package:pixcard/presentation/providers/auth_provider.dart';
import 'package:pixcard/presentation/providers/providers.dart';

// ── Sellers provider (reused from listing detail) ──

final _sellerProvider = FutureProvider.autoDispose.family<AppUser?, String>((ref, sellerId) async {
  try {
    return await ref.watch(userRepositoryProvider).getUserById(sellerId);
  } catch (_) {
    return null;
  }
});

// ── Payment method enum ──

enum PaymentMethod { card, applePay, paypal }

// ── Screen ──

class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key, required this.listing});

  final Listing listing;

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  PaymentMethod _selectedMethod = PaymentMethod.card;
  bool _isProcessing = false;

  Listing get _listing => widget.listing;

  // Stripe fee: 2.9% + 0.30€
  double get _paymentFee => _listing.price * 0.029 + 0.30;
  double get _total => _listing.price + _paymentFee;

  Future<void> _handlePayment() async {
    setState(() => _isProcessing = true);

    try {
      // TODO: Integrate real Stripe payment flow
      // 1. Call Cloud Function to create PaymentIntent
      // 2. Present Stripe payment sheet
      // 3. On success, create order in Firestore

      // Simulated payment delay
      await Future<void>.delayed(const Duration(seconds: 2));

      // Calculate commission
      final commissionAmount = _listing.price * AppConstants.sellerCommissionRate;
      final sellerNet = _listing.price - commissionAmount;

      // Get current user
      final auth = ProviderScope.containerOf(context).read(authStateProvider);
      final buyerId = auth.user?.id ?? '';

      // Create order in Firestore
      final order = domain.Order(
        id: '',
        listingId: _listing.id,
        buyerId: buyerId,
        sellerId: _listing.sellerId,
        cardPrice: _listing.price,
        paymentFee: _paymentFee,
        totalPaid: _total,
        sellerCommissionRate: AppConstants.sellerCommissionRate,
        sellerCommissionAmount: commissionAmount,
        sellerNetAmount: sellerNet,
        status: domain.OrderStatus.paid,
      );

      final orderRepo = ProviderScope.containerOf(context).read(orderRepositoryProvider);
      final createdOrder = await orderRepo.createOrder(order);

      if (!mounted) return;

      // Navigate to confirmation screen
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => OrderConfirmationScreen(order: createdOrder),
        ),
        (route) => route.isFirst,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur de paiement : $e')),
      );
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final sellerAsync = ref.watch(_sellerProvider(_listing.sellerId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Paiement'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        children: [
          // ── Listing summary ──
          _ListingSummary(listing: _listing, sellerAsync: sellerAsync),
          const SizedBox(height: 24),

          // ── Fee breakdown ──
          _FeeBreakdown(
            price: _listing.price,
            fee: _paymentFee,
            total: _total,
          ),
          const SizedBox(height: 24),

          // ── Payment method ──
          _PaymentMethodSelector(
            selected: _selectedMethod,
            onChanged: (m) => setState(() => _selectedMethod = m),
          ),
          const SizedBox(height: 20),

          // ── Security message ──
          _SecurityBanner(cs: cs),
          const SizedBox(height: 28),

          // ── Confirm button ──
          FilledButton(
            onPressed: _isProcessing ? null : _handlePayment,
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(54),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: _isProcessing
                ? const SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : Text(
                    'Confirmer le paiement — ${_total.toPriceString()}',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
          ),
        ],
      ),
    );
  }
}

// ── Listing Summary ──

class _ListingSummary extends StatelessWidget {
  const _ListingSummary({required this.listing, required this.sellerAsync});

  final Listing listing;
  final AsyncValue<AppUser?> sellerAsync;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              width: 80,
              height: 80,
              child: listing.imageUrl.isNotEmpty
                  ? Image.network(listing.imageUrl, fit: BoxFit.cover,
                      errorBuilder: (context, error, stack) => _placeholder(cs))
                  : _placeholder(cs),
            ),
          ),
          const SizedBox(width: 14),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  listing.cardName,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  '${listing.game.capitalize} · ${listing.series}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    // Condition chip
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: _conditionColor(listing.condition).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _conditionLabel(listing.condition),
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: _conditionColor(listing.condition),
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                // Seller
                sellerAsync.when(
                  data: (seller) {
                    if (seller == null) return const SizedBox.shrink();
                    return Row(
                      children: [
                        CircleAvatar(
                          radius: 10,
                          backgroundColor: cs.primaryContainer,
                          backgroundImage: seller.photoUrl != null && seller.photoUrl!.isNotEmpty
                              ? NetworkImage(seller.photoUrl!)
                              : null,
                          child: seller.photoUrl == null || seller.photoUrl!.isEmpty
                              ? Text(
                                  seller.displayName.isNotEmpty ? seller.displayName[0].toUpperCase() : '?',
                                  style: TextStyle(fontSize: 10, color: cs.onPrimaryContainer),
                                )
                              : null,
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            seller.displayName.isNotEmpty ? seller.displayName : 'Vendeur',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  fontWeight: FontWeight.w500,
                                ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    );
                  },
                  loading: () => const SizedBox.shrink(),
                  error: (error, stack) => const SizedBox.shrink(),
                ),
              ],
            ),
          ),
          // Price
          Text(
            listing.price.toPriceString(),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: cs.primary,
                ),
          ),
        ],
      ),
    );
  }

  Widget _placeholder(ColorScheme cs) {
    return Container(
      color: cs.surfaceContainerHighest,
      child: Center(
        child: Icon(Icons.style_outlined, size: 32, color: cs.onSurfaceVariant),
      ),
    );
  }

  Color _conditionColor(CardCondition c) {
    switch (c) {
      case CardCondition.neuf:
        return Colors.green;
      case CardCondition.nearMount:
        return Colors.lightBlue;
      case CardCondition.tresBonEtat:
        return Colors.purple;
      case CardCondition.bonEtat:
        return Colors.amber.shade700;
      case CardCondition.jouable:
        return Colors.grey;
    }
  }

  String _conditionLabel(CardCondition c) {
    switch (c) {
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

// ── Fee Breakdown ──

class _FeeBreakdown extends StatelessWidget {
  const _FeeBreakdown({
    required this.price,
    required this.fee,
    required this.total,
  });

  final double price;
  final double fee;
  final double total;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Détail des frais',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 12),

          // Card price
          _FeeRow(label: 'Prix de la carte', amount: price),
          const SizedBox(height: 8),

          // Payment fee
          _FeeRow(
            label: 'Frais de paiement (2,9% + 0,30€)',
            amount: fee,
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Divider(height: 1),
          ),

          // Total
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total à payer',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              Text(
                total.toPriceString(),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: cs.primary,
                    ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FeeRow extends StatelessWidget {
  const _FeeRow({required this.label, required this.amount});

  final String label;
  final double amount;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          amount.toPriceString(),
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
      ],
    );
  }
}

// ── Payment Method Selector ──

class _PaymentMethodSelector extends StatelessWidget {
  const _PaymentMethodSelector({
    required this.selected,
    required this.onChanged,
  });

  final PaymentMethod selected;
  final ValueChanged<PaymentMethod> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Méthode de paiement',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 10),
        _MethodTile(
          icon: Icons.credit_card_rounded,
          title: 'Carte bancaire',
          subtitle: 'Visa, Mastercard, Amex',
          isSelected: selected == PaymentMethod.card,
          onTap: () => onChanged(PaymentMethod.card),
        ),
        const SizedBox(height: 8),
        _MethodTile(
          icon: Icons.apple,
          title: 'Apple Pay',
          subtitle: 'Paiement rapide et sécurisé',
          isSelected: selected == PaymentMethod.applePay,
          onTap: () => onChanged(PaymentMethod.applePay),
        ),
        const SizedBox(height: 8),
        _MethodTile(
          icon: Icons.account_balance_wallet_rounded,
          title: 'PayPal',
          subtitle: 'Protection acheteur PayPal',
          isSelected: selected == PaymentMethod.paypal,
          onTap: () => onChanged(PaymentMethod.paypal),
        ),
      ],
    );
  }
}

class _MethodTile extends StatelessWidget {
  const _MethodTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.isSelected,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? cs.primaryContainer.withValues(alpha: 0.3)
              : cs.surfaceContainerHighest.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? cs.primary : cs.outlineVariant.withValues(alpha: 0.3),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, size: 24, color: isSelected ? cs.primary : cs.onSurfaceVariant),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle_rounded, size: 22, color: cs.primary),
          ],
        ),
      ),
    );
  }
}

// ── Security Banner ──

class _SecurityBanner extends StatelessWidget {
  const _SecurityBanner({required this.cs});

  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.green.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.shield_rounded, size: 20, color: Colors.green.shade700),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Paiement sécurisé · Remboursement garanti si non conforme',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.green.shade800,
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
