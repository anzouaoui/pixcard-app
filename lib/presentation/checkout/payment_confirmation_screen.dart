import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:pixcard/domain/entities/order.dart';

class PaymentConfirmationScreen extends StatefulWidget {
  const PaymentConfirmationScreen({super.key, required this.order});

  final Order order;

  @override
  State<PaymentConfirmationScreen> createState() => _PaymentConfirmationScreenState();
}

class _PaymentConfirmationScreenState extends State<PaymentConfirmationScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _iconController;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _fadeAnimation;

  Order get _order => widget.order;

  String get _orderReference => 'PX-${_order.createdAt?.millisecondsSinceEpoch ?? DateTime.now().millisecondsSinceEpoch}';

  DateTime get _estimatedDelivery =>
      (_order.createdAt ?? DateTime.now()).add(const Duration(days: 5, hours: 12));

  @override
  void initState() {
    super.initState();
    _iconController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _scaleAnimation = CurvedAnimation(
      parent: _iconController,
      curve: Curves.elasticOut,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _iconController,
      curve: const Interval(0, 0.5, curve: Curves.easeIn),
    );
    _iconController.forward();
  }

  @override
  void dispose() {
    _iconController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ── Animated success icon ──
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: ScaleTransition(
                    scale: _scaleAnimation,
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.check_rounded,
                        size: 56,
                        color: Colors.green.shade600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 28),

                // ── Title ──
                Text(
                  'Paiement confirmé !',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),

                // ── Subtitle ──
                Text(
                  'Votre commande a été enregistrée.\nLe vendeur sera notifié et préparera l\'envoi.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: cs.onSurfaceVariant,
                        height: 1.4,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 28),

                // ── Recap card ──
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerHighest.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      _RecapRow(
                        icon: Icons.receipt_long_rounded,
                        label: 'N° de commande',
                        value: _orderReference,
                        valueWeight: FontWeight.w700,
                      ),
                      const _RecapDivider(),
                      _RecapRow(
                        icon: Icons.payment_rounded,
                        label: 'Montant débité',
                        value: '${_order.totalPaid.toStringAsFixed(2)} €',
                        valueWeight: FontWeight.w800,
                        valueColor: cs.primary,
                      ),
                      const _RecapDivider(),
                      _RecapRow(
                        icon: Icons.local_shipping_outlined,
                        label: 'Livraison estimée',
                        value: _formatDate(_estimatedDelivery),
                      ),
                      const _RecapDivider(),
                      _RecapRow(
                        icon: Icons.shield_rounded,
                        label: 'Protection acheteur',
                        value: 'Active',
                        valueColor: Colors.green.shade600,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // ── Suivre ma commande ──
                FilledButton.icon(
                  onPressed: () => context.push('/order-tracking', extra: _order),
                  icon: const Icon(Icons.route_rounded, size: 20),
                  label: const Text(
                    'Suivre ma commande',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // ── Retour à l'accueil ──
                OutlinedButton(
                  onPressed: () => context.go('/'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    'Retour à l\'accueil',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime d) {
    const months = [
      '', 'janvier', 'février', 'mars', 'avril', 'mai', 'juin',
      'juillet', 'août', 'septembre', 'octobre', 'novembre', 'décembre',
    ];
    return '${d.day} ${months[d.month]} ${d.year}';
  }
}

// ── Recap row ──

class _RecapRow extends StatelessWidget {
  const _RecapRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueWeight,
    this.valueColor,
  });

  final IconData icon;
  final String label;
  final String value;
  final FontWeight? valueWeight;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: cs.onSurfaceVariant),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
            ),
          ),
          Flexible(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: valueWeight ?? FontWeight.w600,
                    color: valueColor,
                  ),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Divider between rows ──

class _RecapDivider extends StatelessWidget {
  const _RecapDivider();

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.3),
    );
  }
}
