import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pixcard/domain/entities/message.dart';
import 'package:pixcard/domain/entities/offer.dart';
import 'package:pixcard/presentation/providers/providers.dart';
import 'package:pixcard/presentation/providers/auth_provider.dart';
import 'package:pixcard/core/utils/extensions.dart';

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

  Future<void> _updateOfferStatus(Offer offer, OfferStatus newStatus) async {
    final offerRepo = ref.read(offerRepositoryProvider);
    await offerRepo.updateOffer(offer.copyWith(status: newStatus));
  }

  @override
  Widget build(BuildContext context) {
    final convRepo = ref.watch(conversationRepositoryProvider);
    final messagesStream = convRepo.watchMessages(widget.conversationId);
    final currentUser = ref.watch(authStateProvider).user;
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Conversation'),
      ),
      body: Column(
        children: [
          // ── Messages list ──
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
                    child: Text(
                      'Aucun message',
                      style: TextStyle(color: cs.onSurfaceVariant),
                    ),
                  );
                }
                return ListView.builder(
                  controller: _scrollController,
                  reverse: true,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final isMe = message.senderId == currentUser?.id;
                    return _MessageBubble(
                      message: message,
                      isMe: isMe,
                      onOfferAction: (offer, status) => _updateOfferStatus(offer, status),
                    );
                  },
                );
              },
            ),
          ),

          // ── Text input ──
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
                      controller: _messageController,
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
                      onSubmitted: (_) => _sendTextMessage(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: _sendTextMessage,
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

// ── Message Bubble ──

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({
    required this.message,
    required this.isMe,
    required this.onOfferAction,
  });

  final Message message;
  final bool isMe;
  final Future<void> Function(Offer offer, OfferStatus status) onOfferAction;

  @override
  Widget build(BuildContext context) {
    if (message.type == MessageType.offer && message.offerId != null) {
      return _OfferBubble(
        offerId: message.offerId!,
        isMe: isMe,
        onOfferAction: onOfferAction,
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

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
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
    );
  }
}

// ── Offer Bubble (special) ──

class _OfferBubble extends ConsumerWidget {
  const _OfferBubble({
    required this.offerId,
    required this.isMe,
    required this.onOfferAction,
  });

  final String offerId;
  final bool isMe;
  final Future<void> Function(Offer offer, OfferStatus status) onOfferAction;

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
        return _OfferCard(offer: offer, isMe: isMe, onOfferAction: onOfferAction);
      },
    );
  }
}

class _OfferCard extends StatelessWidget {
  const _OfferCard({
    required this.offer,
    required this.isMe,
    required this.onOfferAction,
  });

  final Offer offer;
  final bool isMe;
  final Future<void> Function(Offer offer, OfferStatus status) onOfferAction;

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
                        onPressed: () => onOfferAction(offer, OfferStatus.declined),
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
                        onPressed: () => onOfferAction(offer, OfferStatus.accepted),
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

            // ── No actions if already acted (padding only) ──
            if (!showActions) const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}
