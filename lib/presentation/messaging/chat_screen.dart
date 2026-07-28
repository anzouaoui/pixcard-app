import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pixcard/core/utils/extensions.dart';
import 'package:pixcard/domain/entities/app_user.dart';
import 'package:pixcard/domain/entities/conversation.dart';
import 'package:pixcard/domain/entities/listing.dart';
import 'package:pixcard/domain/entities/message.dart';
import 'package:pixcard/domain/entities/offer.dart';
import 'package:pixcard/presentation/providers/auth_provider.dart';
import 'package:pixcard/presentation/providers/providers.dart';

// ── Providers ──

final _conversationProvider = FutureProvider.autoDispose.family<Conversation?, String>((ref, id) async {
  try {
    return await ref.watch(conversationRepositoryProvider).getConversationById(id);
  } catch (_) {
    return null;
  }
});

final _contactProvider = FutureProvider.autoDispose.family<AppUser?, String>((ref, userId) async {
  try {
    return await ref.watch(userRepositoryProvider).getUserById(userId);
  } catch (_) {
    return null;
  }
});

final _listingProvider = FutureProvider.autoDispose.family<Listing?, String>((ref, listingId) async {
  try {
    return await ref.watch(listingRepositoryProvider).getListingById(listingId);
  } catch (_) {
    return null;
  }
});

// ── Screen ──

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key, required this.conversationId});

  final String conversationId;

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendTextMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    final currentUser = ref.read(authStateProvider).user;
    if (currentUser == null) return;

    _messageController.clear();

    final convRepo = ref.read(conversationRepositoryProvider);
    await convRepo.sendMessage(
      widget.conversationId,
      Message(
        id: '',
        senderId: currentUser.id,
        type: MessageType.text,
        text: text,
      ),
    );
  }

  Future<void> _handleOfferAction(Offer offer, OfferStatus newStatus, Listing listing) async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(newStatus == OfferStatus.accepted ? 'Accepter l\'offre ?' : 'Refuser l\'offre ?'),
        content: Text(
          newStatus == OfferStatus.accepted
              ? 'Vous acceptez l\'offre de ${offer.amount.toPriceString()}. La carte sera marquée comme vendue.'
              : 'Voulez-vous vraiment refuser cette offre ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: newStatus == OfferStatus.accepted ? null : Theme.of(ctx).colorScheme.error,
            ),
            child: Text(newStatus == OfferStatus.accepted ? 'Accepter' : 'Refuser'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final offerRepo = ref.read(offerRepositoryProvider);
    final convRepo = ref.read(conversationRepositoryProvider);
    final listingRepo = ref.read(listingRepositoryProvider);

    // 1. Update offer status
    await offerRepo.updateOffer(offer.copyWith(status: newStatus));

    // 2. Send system message
    final messageText = newStatus == OfferStatus.accepted
        ? 'Offre de ${offer.amount.toPriceString()} acceptée'
        : 'Offre de ${offer.amount.toPriceString()} refusée';
    await convRepo.sendMessage(
      widget.conversationId,
      Message(
        id: '',
        senderId: 'system',
        type: MessageType.system,
        text: messageText,
      ),
    );

    // 3. If accepted: mark listing as sold + decline other pending offers
    if (newStatus == OfferStatus.accepted) {
      // Mark listing as sold
      final updatedListing = Listing(
        id: listing.id,
        sellerId: listing.sellerId,
        cardName: listing.cardName,
        game: listing.game,
        series: listing.series,
        condition: listing.condition,
        price: listing.price,
        marketPriceAvg: listing.marketPriceAvg,
        description: listing.description,
        imageUrl: listing.imageUrl,
        status: ListingStatus.sold,
        createdAt: listing.createdAt,
      );
      await listingRepo.updateListing(updatedListing);

      // Decline other pending offers
      final allOffers = await offerRepo.getOffersByListing(listing.id);
      for (final otherOffer in allOffers) {
        if (otherOffer.id != offer.id && otherOffer.status == OfferStatus.pending) {
          await offerRepo.updateOffer(otherOffer.copyWith(status: OfferStatus.declined));
        }
      }
    }

    if (!mounted) return;

    // Refresh listing in the UI
    ref.invalidate(_listingProvider(listing.id));
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(authStateProvider).user;
    final convAsync = ref.watch(_conversationProvider(widget.conversationId));

    return convAsync.when(
      data: (conversation) {
        if (conversation == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Conversation')),
            body: const Center(child: Text('Conversation introuvable')),
          );
        }
        final contactId = conversation.participantIds.firstWhere(
          (id) => id != currentUser?.id,
          orElse: () => '',
        );
        return _ChatBody(
          conversation: conversation,
          contactId: contactId,
          onSend: _sendTextMessage,
          onOfferAction: _handleOfferAction,
          messageController: _messageController,
          scrollController: _scrollController,
        );
      },
      loading: () => Scaffold(
        appBar: AppBar(title: const Text('Conversation')),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (_, __) => Scaffold(
        appBar: AppBar(title: const Text('Conversation')),
        body: const Center(child: Text('Erreur de chargement')),
      ),
    );
  }
}

// ── Chat Body ──

class _ChatBody extends ConsumerWidget {
  const _ChatBody({
    required this.conversation,
    required this.contactId,
    required this.onSend,
    required this.onOfferAction,
    required this.messageController,
    required this.scrollController,
  });

  final Conversation conversation;
  final String contactId;
  final VoidCallback onSend;
  final Future<void> Function(Offer offer, OfferStatus status, Listing listing) onOfferAction;
  final TextEditingController messageController;
  final ScrollController scrollController;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final contactAsync = ref.watch(_contactProvider(contactId));
    final listingAsync = conversation.listingId != null
        ? ref.watch(_listingProvider(conversation.listingId!))
        : null;
    final currentUser = ref.watch(authStateProvider).user;
    final convRepo = ref.watch(conversationRepositoryProvider);
    final messagesStream = convRepo.watchMessages(conversation.id);

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: contactAsync.when(
          data: (contact) => contact != null
              ? _ContactAppBar(contact: contact)
              : const Text('Conversation'),
          loading: () => const Text('Conversation'),
          error: (_, __) => const Text('Conversation'),
        ),
      ),
      body: Column(
        children: [
          // ── Listing banner (pinned) ──
          if (listingAsync != null)
            listingAsync.when(
              data: (listing) => listing != null
                  ? _ListingBanner(listing: listing)
                  : const SizedBox.shrink(),
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),

          // ── Messages ──
          Expanded(
            child: StreamBuilder<List<Message>>(
              stream: messagesStream,
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final messages = snapshot.data!;
                if (messages.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.chat_bubble_outline_rounded, size: 48, color: cs.onSurfaceVariant),
                        const SizedBox(height: 12),
                        Text(
                          'Aucun message',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: cs.onSurfaceVariant,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Envoyez le premier message',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: cs.onSurfaceVariant,
                              ),
                        ),
                      ],
                    ),
                  );
                }
                return ListView.builder(
                  controller: scrollController,
                  reverse: true,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final isMe = message.senderId == currentUser?.id;
                    return _MessageBubble(
                      message: message,
                      isMe: isMe,
                      onOfferAction: onOfferAction,
                      listing: listingAsync?.valueOrNull,
                    );
                  },
                );
              },
            ),
          ),

          // ── Input bar ──
          SafeArea(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: cs.surface,
                boxShadow: [
                  BoxShadow(
                    color: cs.outlineVariant.withValues(alpha: 0.3),
                    blurRadius: 4,
                    offset: const Offset(0, -1),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: messageController,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: InputDecoration(
                        hintText: 'Message...',
                        hintStyle: TextStyle(color: cs.onSurfaceVariant),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: cs.surfaceContainerHighest,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      ),
                      onSubmitted: (_) => onSend(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: onSend,
                    icon: const Icon(Icons.send_rounded, size: 20),
                    style: IconButton.styleFrom(
                      shape: const CircleBorder(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Contact AppBar ──

class _ContactAppBar extends StatelessWidget {
  const _ContactAppBar({required this.contact});

  final AppUser contact;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: [
        // Avatar with online indicator
        Stack(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: cs.primaryContainer,
              backgroundImage: contact.photoUrl != null && contact.photoUrl!.isNotEmpty
                  ? NetworkImage(contact.photoUrl!)
                  : null,
              child: contact.photoUrl == null || contact.photoUrl!.isEmpty
                  ? Text(
                      contact.displayName.isNotEmpty
                          ? contact.displayName[0].toUpperCase()
                          : '?',
                      style: TextStyle(
                        color: cs.onPrimaryContainer,
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    )
                  : null,
            ),
            // Online dot
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                  border: Border.all(color: cs.surface, width: 2),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(width: 12),
        // Name + status
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                contact.displayName.isNotEmpty ? contact.displayName : 'Vendeur',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                'En ligne',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.green,
                      fontSize: 11,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Listing Banner ──

class _ListingBanner extends StatelessWidget {
  const _ListingBanner({required this.listing});

  final Listing listing;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.5),
        border: Border(
          bottom: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.3)),
        ),
      ),
      child: Row(
        children: [
          // Miniature
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              width: 44,
              height: 44,
              child: listing.imageUrl.isNotEmpty
                  ? Image.network(
                      listing.imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _placeholder(cs),
                    )
                  : _placeholder(cs),
            ),
          ),
          const SizedBox(width: 10),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  listing.cardName,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  listing.price.toPriceString(),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: cs.primary,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ],
            ),
          ),
          // Buy button / Sold badge
          if (listing.status == ListingStatus.sold)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Vendu',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: Colors.orange.shade700,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            )
          else
            FilledButton(
              onPressed: () => context.push('/checkout', extra: listing),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text('Acheter', style: TextStyle(fontSize: 12)),
            ),
        ],
      ),
    );
  }

  Widget _placeholder(ColorScheme cs) {
    return Container(
      color: cs.surfaceContainerHighest,
      child: Icon(Icons.style_outlined, size: 22, color: cs.onSurfaceVariant),
    );
  }
}

// ── Message Bubble ──

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({
    required this.message,
    required this.isMe,
    required this.onOfferAction,
    this.listing,
  });

  final Message message;
  final bool isMe;
  final Future<void> Function(Offer offer, OfferStatus status, Listing listing) onOfferAction;
  final Listing? listing;

  @override
  Widget build(BuildContext context) {
    if (message.type == MessageType.system) {
      return _SystemBubble(text: message.text ?? '');
    }
    if (message.type == MessageType.offer && message.offerId != null) {
      return _OfferBubble(
        offerId: message.offerId!,
        isMe: isMe,
        onOfferAction: onOfferAction,
        listing: listing,
      );
    }
    return _TextBubble(message: message, isMe: isMe);
  }
}

// ── Text Bubble ──

class _TextBubble extends StatelessWidget {
  const _TextBubble({required this.message, required this.isMe});

  final Message message;
  final bool isMe;

  String _formatTime(DateTime? dt) {
    if (dt == null) return '';
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 3),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
            decoration: BoxDecoration(
              color: isMe ? cs.primary : cs.surfaceContainerHighest,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(16),
                topRight: const Radius.circular(16),
                bottomLeft: Radius.circular(isMe ? 16 : 4),
                bottomRight: Radius.circular(isMe ? 4 : 16),
              ),
            ),
            child: Text(
              message.text ?? '',
              style: TextStyle(
                color: isMe ? cs.onPrimary : cs.onSurface,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              _formatTime(message.createdAt),
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: cs.onSurfaceVariant,
                    fontSize: 10,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── System Bubble ──

class _SystemBubble extends StatelessWidget {
  const _SystemBubble({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Align(
      alignment: Alignment.center,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          text,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: cs.onSurfaceVariant,
                fontStyle: FontStyle.italic,
              ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

// ── Offer Bubble ──

class _OfferBubble extends ConsumerWidget {
  const _OfferBubble({
    required this.offerId,
    required this.isMe,
    required this.onOfferAction,
    this.listing,
  });

  final String offerId;
  final bool isMe;
  final Future<void> Function(Offer offer, OfferStatus status, Listing listing) onOfferAction;
  final Listing? listing;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final offerRepo = ref.watch(offerRepositoryProvider);

    return FutureBuilder<Offer>(
      future: offerRepo.getOfferById(offerId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Padding(
            padding: EdgeInsets.all(8),
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          );
        }
        final offer = snapshot.data!;
        return _OfferCard(offer: offer, isMe: isMe, onOfferAction: onOfferAction, listing: listing);
      },
    );
  }
}

class _OfferCard extends StatelessWidget {
  const _OfferCard({
    required this.offer,
    required this.isMe,
    required this.onOfferAction,
    this.listing,
  });

  final Offer offer;
  final bool isMe;
  final Future<void> Function(Offer offer, OfferStatus status, Listing listing) onOfferAction;
  final Listing? listing;

  Color _statusColor(OfferStatus status, ColorScheme cs) {
    switch (status) {
      case OfferStatus.pending:
        return cs.primary;
      case OfferStatus.accepted:
        return Colors.green;
      case OfferStatus.declined:
        return cs.error;
      case OfferStatus.expired:
        return cs.onSurfaceVariant;
    }
  }

  String _statusLabel(OfferStatus status) {
    switch (status) {
      case OfferStatus.pending:
        return 'En attente';
      case OfferStatus.accepted:
        return 'Acceptée';
      case OfferStatus.declined:
        return 'Refusée';
      case OfferStatus.expired:
        return 'Expirée';
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isPending = offer.status == OfferStatus.pending;
    // Show actions to the recipient (seller) when pending
    final showActions = !isMe && isPending;

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        width: MediaQuery.of(context).size.width * 0.78,
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _statusColor(offer.status, cs).withValues(alpha: 0.4),
            width: 1.5,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: _statusColor(offer.status, cs).withValues(alpha: 0.1),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.local_offer_rounded,
                    size: 18,
                    color: _statusColor(offer.status, cs),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    isMe ? 'Votre offre' : 'Offre reçue',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: _statusColor(offer.status, cs),
                        ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: _statusColor(offer.status, cs).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _statusLabel(offer.status),
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: _statusColor(offer.status, cs),
                          ),
                    ),
                  ),
                ],
              ),
            ),

            // ── Amount ──
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 4),
              child: Text(
                offer.amount.toPriceString(),
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: cs.onSurface,
                    ),
              ),
            ),

            // ── Actions (seller only, pending) ──
            if (showActions)
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 8, 14, 14),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: listing != null ? () => onOfferAction(offer, OfferStatus.declined, listing!) : null,
                        icon: const Icon(Icons.close_rounded, size: 18),
                        label: const Text('Refuser'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: cs.error,
                          side: BorderSide(color: cs.error.withValues(alpha: 0.5)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: listing != null ? () => onOfferAction(offer, OfferStatus.accepted, listing!) : null,
                        icon: const Icon(Icons.check_rounded, size: 18),
                        label: const Text('Accepter'),
                        style: FilledButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // ── Pay button (buyer only, accepted) ──
            if (isMe && offer.status == OfferStatus.accepted && listing != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 8, 14, 14),
                child: FilledButton.icon(
                  onPressed: () {
                    context.push('/checkout', extra: {
                      'listing': listing!,
                      'offerPrice': offer.amount,
                    });
                  },
                  icon: const Icon(Icons.payment_rounded, size: 18),
                  label: const Text('Procéder au paiement'),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(44),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),

            // ── No actions if already acted ──
            if (!showActions && !(isMe && offer.status == OfferStatus.accepted))
              const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}
