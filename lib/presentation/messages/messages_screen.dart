import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pixcard/domain/entities/app_user.dart';
import 'package:pixcard/domain/entities/conversation.dart';
import 'package:pixcard/presentation/providers/auth_provider.dart';
import 'package:pixcard/presentation/providers/providers.dart';

// ── Conversations stream for current user ──

final _conversationsProvider = StreamProvider.autoDispose<List<Conversation>>((ref) {
  final auth = ref.watch(authStateProvider);
  if (auth.user == null) return const Stream.empty();
  return ref.watch(conversationRepositoryProvider).watchConversationsByUser(auth.user!.id);
});

// ── Contact name/avatar provider ──

final _contactProvider = FutureProvider.autoDispose.family<AppUser?, String>((ref, userId) async {
  try {
    return await ref.watch(userRepositoryProvider).getUserById(userId);
  } catch (_) {
    return null;
  }
});

// ── Screen ──

class MessagesScreen extends ConsumerWidget {
  const MessagesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final conversationsAsync = ref.watch(_conversationsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Messages'),
      ),
      body: conversationsAsync.when(
        data: (conversations) {
          if (conversations.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.chat_bubble_outline_rounded,
                    size: 64,
                    color: cs.onSurfaceVariant,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Aucune conversation',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Vos conversations apparaîtront ici',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
            );
          }
          return ListView.separated(
            itemCount: conversations.length,
            separatorBuilder: (context, index) => Divider(
              height: 1,
              indent: 76,
              color: cs.outlineVariant.withValues(alpha: 0.3),
            ),
            itemBuilder: (context, index) {
              final conversation = conversations[index];
              return _ConversationTile(conversation: conversation);
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
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

// ── Conversation Tile ──

class _ConversationTile extends ConsumerWidget {
  const _ConversationTile({required this.conversation});

  final Conversation conversation;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final currentUser = ref.watch(authStateProvider).user;

    // Find the other participant
    final contactId = conversation.participantIds.firstWhere(
      (id) => id != currentUser?.id,
      orElse: () => '',
    );

    final contactAsync = ref.watch(_contactProvider(contactId));

    return InkWell(
      onTap: () => context.push('/chat/${conversation.id}'),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            // Avatar
            contactAsync.when(
              data: (contact) => CircleAvatar(
                radius: 24,
                backgroundColor: cs.primaryContainer,
                backgroundImage: contact != null &&
                        contact.photoUrl != null &&
                        contact.photoUrl!.isNotEmpty
                    ? NetworkImage(contact.photoUrl!)
                    : null,
                child: contact == null ||
                        contact.photoUrl == null ||
                        contact.photoUrl!.isEmpty
                    ? Text(
                        contact != null && contact.displayName.isNotEmpty
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
              loading: () => CircleAvatar(
                radius: 24,
                backgroundColor: cs.surfaceContainerHighest,
                child: const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
              error: (error, stack) => CircleAvatar(
                radius: 24,
                backgroundColor: cs.surfaceContainerHighest,
                child: Icon(Icons.person, color: cs.onSurfaceVariant),
              ),
            ),
            const SizedBox(width: 12),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  contactAsync.when(
                    data: (contact) => Text(
                      contact != null && contact.displayName.isNotEmpty
                          ? contact.displayName
                          : 'Utilisateur',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    loading: () => Text(
                      'Chargement...',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: cs.onSurfaceVariant,
                          ),
                    ),
                    error: (error, stack) => Text(
                      'Utilisateur',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    conversation.lastMessageText.isNotEmpty
                        ? conversation.lastMessageText
                        : 'Aucun message',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            // Time
            if (conversation.lastMessageAt != null)
              Text(
                _formatTime(conversation.lastMessageAt!),
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
              ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);

    if (diff.inDays > 0) {
      return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}';
    }
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}
