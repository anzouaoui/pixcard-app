import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pixcard/core/constants/app_constants.dart';
import 'package:pixcard/core/utils/extensions.dart';
import 'package:pixcard/domain/entities/listing.dart';
import 'package:pixcard/presentation/providers/auth_provider.dart';
import 'package:pixcard/presentation/providers/providers.dart';

class CreateListingScreen extends ConsumerStatefulWidget {
  const CreateListingScreen({super.key, this.prefill});

  final Map<String, dynamic>? prefill;

  @override
  ConsumerState<CreateListingScreen> createState() =>
      _CreateListingScreenState();
}

class _CreateListingScreenState extends ConsumerState<CreateListingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _cardNameController = TextEditingController();
  final _seriesController = TextEditingController();
  final _priceController = TextEditingController();
  final _descriptionController = TextEditingController();

  String _selectedGame = 'pokemon';
  CardCondition _selectedCondition = CardCondition.neuf;
  bool _isSubmitting = false;

  static const _games = ['pokemon', 'magic', 'yugioh'];

  double get _parsedPrice => double.tryParse(_priceController.text) ?? 0;
  double get _netAmount =>
      _parsedPrice * (1 - AppConstants.sellerCommissionRate);
  double get _commissionAmount =>
      _parsedPrice * AppConstants.sellerCommissionRate;

  @override
  void initState() {
    super.initState();
    _priceController.addListener(() => setState(() {}));
    _applyPrefill();
  }

  void _applyPrefill() {
    final p = widget.prefill;
    if (p == null) return;
    if (p['cardName'] is String) _cardNameController.text = p['cardName'];
    if (p['setName'] is String) _seriesController.text = p['setName'];
    if (p['condition'] is CardCondition) _selectedCondition = p['condition'];
    if (p['estimatedPrice'] is num) {
      _priceController.text = (p['estimatedPrice'] as num).toStringAsFixed(2);
    }
    if (p['game'] is String) _selectedGame = p['game'];
    if (p['description'] is String) {
      _descriptionController.text = p['description'];
    }
  }

  @override
  void dispose() {
    _cardNameController.dispose();
    _seriesController.dispose();
    _priceController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _publishListing() async {
    if (!_formKey.currentState!.validate()) return;

    final container = ProviderScope.containerOf(context);
    final user = container.read(authStateProvider).user;
    if (user == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vous devez être connecté')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final listing = Listing(
        id: '',
        sellerId: user.id,
        cardName: _cardNameController.text.trim(),
        game: _selectedGame,
        series: _seriesController.text.trim(),
        condition: _selectedCondition,
        price: _parsedPrice,
        marketPriceAvg: widget.prefill?['marketPriceAvg'] as double?,
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        imageUrl: widget.prefill?['imageUrl'] as String? ?? '',
      );

      final repo = container.read(listingRepositoryProvider);
      await repo.createListing(listing);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Annonce publiée avec succès')),
      );
      context.go('/');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur : $e')),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Nouvelle annonce')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildPhotoPicker(context),
              const SizedBox(height: 24),
              TextFormField(
                controller: _cardNameController,
                decoration:
                    const InputDecoration(labelText: 'Nom de la carte'),
                validator: (v) => v != null && v.isNotEmpty ? null : 'Requis',
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _seriesController,
                decoration: const InputDecoration(labelText: 'Série'),
                validator: (v) => v != null && v.isNotEmpty ? null : 'Requis',
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedGame,
                decoration: const InputDecoration(labelText: 'Jeu'),
                items: _games
                    .map((g) =>
                        DropdownMenuItem(value: g, child: Text(g.capitalize)))
                    .toList(),
                onChanged: (v) =>
                    setState(() => _selectedGame = v ?? _selectedGame),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<CardCondition>(
                value: _selectedCondition,
                decoration: const InputDecoration(labelText: 'État'),
                items: CardCondition.values
                    .map((c) => DropdownMenuItem(
                          value: c,
                          child: Text(_conditionLabel(c)),
                        ))
                    .toList(),
                onChanged: (v) {
                  if (v != null) setState(() => _selectedCondition = v);
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _priceController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(
                      RegExp(r'^\d+\.?\d{0,2}')),
                ],
                decoration: const InputDecoration(
                  labelText: 'Prix de vente',
                  suffixText: '€',
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Requis';
                  final price = double.tryParse(v);
                  return price != null && price > 0 ? null : 'Prix invalide';
                },
              ),
              const SizedBox(height: 8),
              _buildNetAmountBanner(cs),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 24),
              _buildCommissionSummary(cs),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isSubmitting ? null : _publishListing,
                child: _isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Publier l\'annonce'),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Sous-widgets
  // ---------------------------------------------------------------------------

  Widget _buildPhotoPicker(BuildContext context) {
    return GestureDetector(
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Upload photo à venir')),
        );
      },
      child: Container(
        height: 200,
        decoration: BoxDecoration(
          color:
              Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Theme.of(context).colorScheme.outline,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add_a_photo_outlined,
              size: 48,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 8),
            const Text('Ajouter une photo'),
          ],
        ),
      ),
    );
  }

  Widget _buildNetAmountBanner(ColorScheme cs) {
    return Row(
      children: [
        Icon(Icons.account_balance_wallet_outlined,
            size: 16, color: cs.onSurfaceVariant),
        const SizedBox(width: 6),
        Text(
          'Vous recevez : ',
          style: TextStyle(
            fontSize: 13,
            color: cs.onSurfaceVariant,
          ),
        ),
        Text(
          _netAmount.toPriceString(),
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: cs.primary,
          ),
        ),
      ],
    );
  }

  Widget _buildCommissionSummary(ColorScheme cs) {
    final pct =
        (AppConstants.sellerCommissionRate * 100).toStringAsFixed(0);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Prix de vente',
                  style: TextStyle(color: cs.onSurfaceVariant)),
              Text(
                _parsedPrice.toPriceString(),
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Commission PixCard ($pct%)',
                style: TextStyle(color: cs.onSurfaceVariant),
              ),
              Text(
                '- ${_commissionAmount.toPriceString()}',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: cs.error,
                ),
              ),
            ],
          ),
          const Divider(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Vous recevez',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              Text(
                _netAmount.toPriceString(),
                style: TextStyle(
                  fontSize: 17,
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

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  static String _conditionLabel(CardCondition c) {
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
