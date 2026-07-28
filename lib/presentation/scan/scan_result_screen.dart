import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:pixcard/core/utils/extensions.dart';
import 'package:pixcard/domain/entities/listing.dart';
import 'package:pixcard/domain/repositories/listing_repository.dart';

class ScanResultScreen extends StatelessWidget {
  const ScanResultScreen({super.key, required this.result, this.imagePath});

  final CardAnalysisResult result;
  final String? imagePath;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          _Header(confidence: result.confidence),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                children: [
                  _CardIdentification(result: result, imagePath: imagePath),
                  const SizedBox(height: 16),
                  if (result.marketPricesWeek != null &&
                      result.marketPricesWeek!.isNotEmpty)
                    _MarketCoteSection(
                      prices: result.marketPricesWeek!,
                      minPrice: result.marketPriceMin,
                      avgPrice: result.marketPriceAvg,
                      maxPrice: result.marketPriceMax,
                    ),
                  if (result.marketPricesWeek != null &&
                      result.marketPricesWeek!.isNotEmpty)
                    const SizedBox(height: 16),
                  if (result.estimatedPrice != null &&
                      result.marketPriceAvg != null)
                    _SuggestedPriceBlock(
                      suggestedPrice: result.estimatedPrice!,
                      avgPrice: result.marketPriceAvg!,
                    ),
                  if (result.estimatedPrice != null &&
                      result.marketPriceAvg != null)
                    const SizedBox(height: 16),
                ],
              ),
            ),
          ),
          _BottomActions(imagePath: imagePath, result: result),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Header violet
// ---------------------------------------------------------------------------
class _Header extends StatelessWidget {
  const _Header({required this.confidence});

  final double confidence;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            cs.primary,
            cs.primary.withValues(alpha: 0.8),
          ],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Column(
            children: [
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_rounded,
                        color: Colors.white, size: 28),
                    onPressed: () => context.pop(),
                  ),
                  const Expanded(
                    child: Text(
                      'Carte identifi\u00e9e \u2713',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
              const SizedBox(height: 4),
              _ConfidenceBadge(confidence: confidence),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Badge de confiance
// ---------------------------------------------------------------------------
class _ConfidenceBadge extends StatelessWidget {
  const _ConfidenceBadge({required this.confidence});

  final double confidence;

  Color _color() {
    if (confidence >= 0.8) return const Color(0xFF22C55E);
    if (confidence >= 0.6) return const Color(0xFFF59E0B);
    return const Color(0xFFEF4444);
  }

  @override
  Widget build(BuildContext context) {
    final pct = (confidence * 100).toStringAsFixed(0);
    final color = _color();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.verified_rounded, color: color, size: 18),
          const SizedBox(width: 6),
          Text(
            'Identifi\u00e9e avec confiance $pct%',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Carte identifi\u00e9e (image + infos)
// ---------------------------------------------------------------------------
class _CardIdentification extends StatelessWidget {
  const _CardIdentification({
    required this.result,
    this.imagePath,
  });

  final CardAnalysisResult result;
  final String? imagePath;

  Color _conditionColor(CardCondition c) {
    switch (c) {
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

  String _conditionLabel(CardCondition c) {
    switch (c) {
      case CardCondition.neuf:
        return 'Neuf';
      case CardCondition.nearMount:
        return 'Near Mint';
      case CardCondition.tresBonEtat:
        return 'Tr\u00e8s bon \u00e9tat';
      case CardCondition.bonEtat:
        return 'Bon \u00e9tat';
      case CardCondition.jouable:
        return 'Jouable';
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final condColor = _conditionColor(result.condition);
    final condLabel = _conditionLabel(result.condition);

    return Card(
      margin: const EdgeInsets.only(top: 24),
      clipBehavior: Clip.antiAlias,
      child: Row(
        children: [
          SizedBox(
            width: 120,
            height: 140,
            child: _buildImage(),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    result.cardName,
                    style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    result.setName,
                    style: tt.bodySmall?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: condColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      condLabel,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  if (result.estimatedPrice != null) ...[
                    const SizedBox(height: 10),
                    Text(
                      result.estimatedPrice!.toPriceString(),
                      style: tt.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: cs.primary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
    );
  }

  Widget _buildImage() {
    if (imagePath != null && imagePath!.isNotEmpty) {
      return Image.asset(
        imagePath!,
        fit: BoxFit.cover,
        errorBuilder: (_, _e, _s) => _placeholder(),
      );
    }
    if (result.imageUrl != null && result.imageUrl!.isNotEmpty) {
      return Image.network(
        result.imageUrl!,
        fit: BoxFit.cover,
        errorBuilder: (_, _e, _s) => _placeholder(),
      );
    }
    return _placeholder();
  }

  Widget _placeholder() => Container(
        color: Colors.grey.shade200,
        child: const Icon(Icons.style_rounded, size: 48, color: Colors.grey),
      );
}

// ---------------------------------------------------------------------------
// Cote de march\u00e9 — mini graphique en barres
// ---------------------------------------------------------------------------
class _MarketCoteSection extends StatelessWidget {
  const _MarketCoteSection({
    required this.prices,
    this.minPrice,
    this.avgPrice,
    this.maxPrice,
  });

  final List<double> prices;
  final double? minPrice;
  final double? avgPrice;
  final double? maxPrice;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final maxVal = prices.reduce((a, b) => a > b ? a : b);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Cote de march\u00e9 \u2014 7 jours',
              style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 120,
              child: _BarChart(
                values: prices,
                maxValue: maxVal > 0 ? maxVal : 1,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _StatChip(
                  label: 'Min',
                  value: minPrice,
                  color: const Color(0xFF22C55E),
                ),
                _StatChip(
                  label: 'Moy',
                  value: avgPrice,
                  color: cs.primary,
                ),
                _StatChip(
                  label: 'Max',
                  value: maxPrice,
                  color: const Color(0xFFEF4444),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Mini bar chart sans d\u00e9pendance externe
// ---------------------------------------------------------------------------
class _BarChart extends StatelessWidget {
  const _BarChart({required this.values, required this.maxValue});

  final List<double> values;
  final double maxValue;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final now = DateTime.now();

    return LayoutBuilder(
      builder: (context, constraints) {
        return Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: List.generate(values.length, (i) {
            final ratio = maxValue > 0 ? values[i] / maxValue : 0.0;
            final day = now.subtract(Duration(days: values.length - 1 - i));
            final label = '${day.day}/${day.month}';
            final isToday = i == values.length - 1;

            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: Column(
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    Text(
                      values[i].toStringAsFixed(0),
                      style: TextStyle(
                        fontSize: 9,
                        color: cs.onSurfaceVariant,
                        fontWeight:
                            isToday ? FontWeight.w700 : FontWeight.w400,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Expanded(
                      child: FractionallySizedBox(
                        heightFactor: ratio,
                        alignment: Alignment.bottomCenter,
                        child: Container(
                          decoration: BoxDecoration(
                            color: isToday ? cs.primary : cs.primaryContainer,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 9,
                        color: cs.onSurfaceVariant,
                        fontWeight:
                            isToday ? FontWeight.w700 : FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Stat chip (Min / Moy / Max)
// ---------------------------------------------------------------------------
class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.label,
    this.value,
    required this.color,
  });

  final String label;
  final double? value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          '$label : ${value != null ? value!.toPriceString() : '\u2014'}',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w500,
              ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Bloc prix sugg\u00e9r\u00e9 avec badge contextuel
// ---------------------------------------------------------------------------
class _SuggestedPriceBlock extends StatelessWidget {
  const _SuggestedPriceBlock({
    required this.suggestedPrice,
    required this.avgPrice,
  });

  final double suggestedPrice;
  final double avgPrice;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final ratio = avgPrice > 0 ? suggestedPrice / avgPrice : 1.0;

    final String badgeLabel;
    final Color badgeColor;

    if (ratio < 0.9) {
      badgeLabel = 'Sous la cote';
      badgeColor = const Color(0xFF22C55E);
    } else if (ratio > 1.1) {
      badgeLabel = 'Au-dessus de la cote';
      badgeColor = const Color(0xFFEF4444);
    } else {
      badgeLabel = 'Dans la cote';
      badgeColor = const Color(0xFFF59E0B);
    }

    final diff = suggestedPrice - avgPrice;
    final diffStr =
        '${diff >= 0 ? '+' : ''}${diff.toStringAsFixed(2)} \u20ac vs moy.';

    return Card(
      color: cs.primaryContainer.withValues(alpha: 0.3),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.payments_rounded, color: cs.primary, size: 22),
                const SizedBox(width: 8),
                Text(
                  'Prix sugg\u00e9r\u00e9',
                  style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  suggestedPrice.toPriceString(),
                  style: tt.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: cs.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: badgeColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: badgeColor.withValues(alpha: 0.4)),
                  ),
                  child: Text(
                    badgeLabel,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: badgeColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              diffStr,
              style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Actions bottom (Ajuster et publier / Scanner une autre)
// ---------------------------------------------------------------------------
class _BottomActions extends StatelessWidget {
  const _BottomActions({this.imagePath, required this.result});

  final String? imagePath;
  final CardAnalysisResult result;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton.icon(
                onPressed: () {
                  context.push('/create-listing', extra: {
                    'cardName': result.cardName,
                    'setName': result.setName,
                    'condition': result.condition,
                    'estimatedPrice': result.estimatedPrice,
                    'imagePath': imagePath,
                  });
                },
                icon: const Icon(Icons.edit_rounded, size: 20),
                label: const Text(
                  'Ajuster et publier l\u2019annonce',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: OutlinedButton.icon(
                onPressed: () {
                  context.go('/scan');
                },
                icon: const Icon(Icons.camera_alt_rounded, size: 20),
                label: const Text(
                  'Scanner une autre carte',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                ),
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
