import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pixcard/core/utils/extensions.dart';
import 'package:pixcard/domain/entities/conversation.dart';
import 'package:pixcard/domain/entities/listing.dart';
import 'package:pixcard/domain/entities/message.dart';
import 'package:pixcard/domain/entities/offer.dart';
import 'package:pixcard/presentation/providers/providers.dart';
import 'package:pixcard/presentation/providers/auth_provider.dart';

class MakeOfferScreen extends ConsumerStatefulWidget {
  const MakeOfferScreen({super.key, required this.listing});

  final Listing listing;

  @override
  ConsumerState<MakeOfferScreen> createState() => _MakeOfferScreenState();
}

class _MakeOfferScreenState extends ConsumerState<MakeOfferScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  bool _isSubmitting = false;

  Listing get _listing => widget.listing;

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _submitOffer() async {
    if (!_formKey.currentState!.validate()) return;

    final currentUser = ref.read(authStateProvider).user;
    if (currentUser == null) return;

    setState(() => _isSubmitting = true);

    try {
      final amount = double.parse(_amountController.text);

      // 1. Create the offer in Firestore
      final offerRepo = ref.read(offerRepositoryProvider);
      final offer = await offerRepo.createOffer(
        Offer(
          id: '',
          listingId: _listing.id,
          buyerId: currentUser.id,
          sellerId: _listing.sellerId,
          amount: amount,
          status: OfferStatus.pending,
        ),
      );

      // 2. Find or create a conversation between buyer & seller for this listing
      final convRepo = ref.read(conversationRepositoryProvider);
      final conversations = await convRepo.getConversationsByUser(currentUser.id);

      Conversation? conversation;
      for (final c in conversations) {
        if (c.listingId == _listing.id &&
            c.participantIds.contains(_listing.sellerId)) {
          conversation = c;
          break;
        }
      }

      conversation ??= await convRepo.createConversation(
        Conversation(
          id: '',
          participantIds: [currentUser.id, _listing.sellerId],
          listingId: _listing.id,
        ),
      );

      // 3. Send an offer message in the conversation
      await convRepo.sendMessage(
        conversation.id,
        Message(
          id: '',
          senderId: currentUser.id,
          type: MessageType.offer,
          offerId: offer.id,
          text: 'Offre de ${amount.toPriceString()}',
        ),
      );

      if (!mounted) return;

      // 4. Navigate to the chat screen
      context.go('/chat/${conversation.id}');
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
      appBar: AppBar(
        title: const Text('Faire une offre'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // ── Card preview ──
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  // Miniature
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: SizedBox(
                      width: 72,
                      height: 72,
                      child: _listing.imageUrl.isNotEmpty
                          ? Image.network(
                              _listing.imageUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => _placeholder(cs),
                            )
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
                          _listing.cardName,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _listing.series,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: cs.onSurfaceVariant,
                              ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Prix demandé : ${_listing.price.toPriceString()}',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: cs.primary,
                              ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // ── Price info ──
            Text(
              'Votre offre',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              'Proposez un prix au vendeur. Il pourra accepter ou refuser.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 16),

            // ── Amount field ──
            TextFormField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              autofocus: true,
              decoration: InputDecoration(
                labelText: 'Montant de l\'offre',
                prefixText: '€ ',
                suffixText: '/ ${_listing.price.toPriceString()}',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Veuillez entrer un montant';
                }
                final amount = double.tryParse(value.trim());
                if (amount == null || amount <= 0) {
                  return 'Montant invalide';
                }
                if (amount >= _listing.price) {
                  return 'L\'offre doit être inférieure au prix demandé';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),

            // ── Hint ──
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: cs.tertiaryContainer.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.lightbulb_outline_rounded, size: 18, color: cs.tertiary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Conseil : les offres entre 70% et 90% du prix demandé ont plus de chances d\'être acceptées.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: cs.onTertiaryContainer,
                          ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // ── Submit button ──
            FilledButton(
              onPressed: _isSubmitting ? null : _submitOffer,
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Envoyer l\'offre'),
            ),
          ],
        ),
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
}
