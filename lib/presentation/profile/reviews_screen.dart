import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pixcard/domain/entities/review.dart';
import 'package:pixcard/domain/entities/app_user.dart';
import 'package:pixcard/presentation/providers/providers.dart';

final _reviewsProvider = StreamProvider.autoDispose.family<List<Review>, String>((ref, targetId) {
  return ref.watch(reviewRepositoryProvider).watchReviewsByTarget(targetId);
});

final _authorProvider = FutureProvider.autoDispose.family<AppUser?, String>((ref, userId) async {
  try {
    return await ref.watch(userRepositoryProvider).getUserById(userId);
  } catch (_) {
    return null;
  }
});

class ReviewsScreen extends ConsumerWidget {
  const ReviewsScreen({super.key, required this.sellerId});

  final String sellerId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reviewsAsync = ref.watch(_reviewsProvider(sellerId));
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Avis')),
      body: reviewsAsync.when(
        data: (reviews) {
          if (reviews.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.rate_review_outlined, size: 64, color: cs.onSurfaceVariant),
                  const SizedBox(height: 16),
                  Text('Pas encore d\'avis', style: Theme.of(context).textTheme.titleMedium),
                ],
              ),
            );
          }

          final avgRating = reviews.fold<int>(0, (sum, r) => sum + r.rating) / reviews.length;
          final totalReviews = reviews.length;

          return Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Column(
                  children: [
                    Text(
                      avgRating.toStringAsFixed(1),
                      style: Theme.of(context).textTheme.displaySmall?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(5, (i) {
                        return Icon(
                          i < avgRating.round() ? Icons.star_rounded : Icons.star_outline_rounded,
                          color: Colors.amber,
                          size: 28,
                        );
                      }),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$totalReviews avis',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: reviews.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, index) => _ReviewItem(review: reviews[index]),
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Erreur: $err')),
      ),
    );
  }
}

class _ReviewItem extends ConsumerWidget {
  const _ReviewItem({required this.review});

  final Review review;

  String _relativeDate(DateTime? date) {
    if (date == null) return '';
    final diff = DateTime.now().difference(date);
    if (diff.inDays >= 365) {
      final y = diff.inDays ~/ 365;
      return 'Il y a $y an${y > 1 ? 's' : ''}';
    }
    if (diff.inDays >= 30) {
      return 'Il y a ${diff.inDays ~/ 30} mois';
    }
    if (diff.inDays >= 7) {
      final w = diff.inDays ~/ 7;
      return 'Il y a $w semaine${w > 1 ? 's' : ''}';
    }
    if (diff.inDays >= 1) {
      return 'Il y a ${diff.inDays} jour${diff.inDays > 1 ? 's' : ''}';
    }
    if (diff.inHours >= 1) {
      return 'Il y a ${diff.inHours} heure${diff.inHours > 1 ? 's' : ''}';
    }
    if (diff.inMinutes >= 1) {
      return 'Il y a ${diff.inMinutes} minute${diff.inMinutes > 1 ? 's' : ''}';
    }
    return "À l'instant";
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authorAsync = ref.watch(_authorProvider(review.authorId));
    final cs = Theme.of(context).colorScheme;
    final authorName = authorAsync.valueOrNull?.displayName;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Row(
                children: List.generate(5, (i) {
                  return Icon(
                    i < review.rating ? Icons.star_rounded : Icons.star_outline_rounded,
                    color: Colors.amber,
                    size: 20,
                  );
                }),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: review.isFromBuyer
                      ? Colors.green.withValues(alpha: 0.1)
                      : Colors.blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  review.isFromBuyer ? 'Acheteur' : 'Vendeur',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: review.isFromBuyer ? Colors.green.shade700 : Colors.blue.shade700,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
              const Spacer(),
              Text(
                _relativeDate(review.createdAt),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
              ),
            ],
          ),
          if (review.comment != null && review.comment!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(review.comment!, style: Theme.of(context).textTheme.bodyMedium),
          ],
          const SizedBox(height: 4),
          Text(
            authorName ?? 'Anonyme',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}
