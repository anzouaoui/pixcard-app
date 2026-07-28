import 'package:flutter/material.dart';
import 'package:pixcard/core/utils/extensions.dart';
import 'package:pixcard/domain/entities/listing.dart';

class ListingCard extends StatelessWidget {
  const ListingCard({super.key, required this.listing, this.onTap, this.isFavorite, this.onToggleFavorite});

  final Listing listing;
  final VoidCallback? onTap;
  final bool? isFavorite;
  final VoidCallback? onToggleFavorite;

  Color _getConditionColor(CardCondition condition) {
    switch (condition) {
      case CardCondition.neuf:
        return Colors.green;
      case CardCondition.nearMount:
        return Colors.lightBlue;
      case CardCondition.tresBonEtat:
        return Colors.purple.shade200;
      case CardCondition.bonEtat:
        return Colors.amber.shade600;
      case CardCondition.jouable:
        return Colors.grey;
    }
  }

  String _getConditionLabel(CardCondition condition) {
    switch (condition) {
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

  @override
  Widget build(BuildContext context) {
    final conditionColor = _getConditionColor(listing.condition);
    final conditionLabel = _getConditionLabel(listing.condition);

    return Card(
      clipBehavior: Clip.antiAlias,
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                AspectRatio(
                  aspectRatio: 1,
                  child: listing.imageUrl.isNotEmpty
                      ? Image.network(
                          listing.imageUrl,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          errorBuilder: (context, url, error) => Container(
                            color: Theme.of(context).colorScheme.surfaceContainerHighest,
                            child: const Icon(Icons.image_not_supported_outlined, size: 40),
                          ),
                        )
                      : Container(
                          color: Theme.of(context).colorScheme.surfaceContainerHighest,
                          child: const Icon(Icons.image_outlined, size: 40),
                        ),
                ),
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: conditionColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      conditionLabel,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                if (onToggleFavorite != null)
                  Positioned(
                    top: 4,
                    right: 4,
                    child: IconButton(
                      onPressed: onToggleFavorite,
                      icon: Icon(
                        isFavorite == true ? Icons.favorite_rounded : Icons.favorite_outline_rounded,
                        size: 22,
                        color: isFavorite == true ? Colors.red : Colors.white,
                      ),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.black26,
                        padding: const EdgeInsets.all(4),
                        minimumSize: const Size(32, 32),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                  ),
              ],
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 6, 8, 4),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      listing.cardName,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${listing.game.toUpperCase()} - ${listing.series}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      listing.price.toPriceString(),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
