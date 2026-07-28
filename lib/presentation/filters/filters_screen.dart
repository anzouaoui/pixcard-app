import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pixcard/domain/entities/listing.dart';
import 'package:pixcard/presentation/providers/filter_provider.dart';

class FiltersScreen extends ConsumerStatefulWidget {
  const FiltersScreen({super.key});

  @override
  ConsumerState<FiltersScreen> createState() => _FiltersScreenState();
}

class _FiltersScreenState extends ConsumerState<FiltersScreen> {
  double _minPrice = 0;
  double _maxPrice = 500;

  @override
  void initState() {
    super.initState();
    final filter = ref.read(filterProvider);
    _minPrice = filter.minPrice ?? 0;
    _maxPrice = filter.maxPrice ?? 500;
  }

  @override
  Widget build(BuildContext context) {
    final filter = ref.watch(filterProvider);
    final sets = ref.watch(pokemonSetsProvider);
    final conditions = ref.watch(cardConditionsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Filtres'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          if (filter.hasActiveFilters)
            TextButton.icon(
              onPressed: () {
                ref.read(filterProvider.notifier).clearFilters();
                setState(() {
                  _minPrice = 0;
                  _maxPrice = 500;
                });
              },
              icon: const Icon(Icons.clear_all),
              label: const Text('Réinitialiser'),
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _SearchFilterSection(filter: filter, onSearchChanged: (query) {
                  ref.read(filterProvider.notifier).setSearchQuery(query);
                }),
                const SizedBox(height: 24),
                _ExpandableSection(
                  title: 'Éditions (Sets Pokémon)',
                  initiallyExpanded: true,
                  child: _SetsGrid(
                    sets: sets,
                    selectedSets: filter.selectedSets,
                    onToggle: (set) => ref.read(filterProvider.notifier).toggleSet(set),
                  ),
                ),
                const SizedBox(height: 16),
                _ExpandableSection(
                  title: 'État de la carte',
                  initiallyExpanded: true,
                  child: _ConditionsList(
                    conditions: conditions,
                    selectedConditions: filter.selectedConditions,
                    onToggle: (condition) =>
                        ref.read(filterProvider.notifier).toggleCondition(condition),
                  ),
                ),
                const SizedBox(height: 16),
                _ExpandableSection(
                  title: 'Fourchette de prix',
                  initiallyExpanded: true,
                  child: _PriceRangeSlider(
                    minPrice: _minPrice,
                    maxPrice: _maxPrice,
                    onChanged: (RangeValues values) {
                      setState(() {
                        _minPrice = values.start;
                        _maxPrice = values.end;
                      });
                      ref.read(filterProvider.notifier).setPriceRange(
                            values.start == 0 ? null : values.start,
                            values.end == 500 ? null : values.end,
                          );
                    },
                  ),
                ),
              ],
            ),
          ),
          _ApplyFiltersButton(
            hasActiveFilters: filter.hasActiveFilters,
            onApply: () {
              context.pop(filter);
            },
          ),
        ],
      ),
    );
  }
}

class _SearchFilterSection extends StatelessWidget {
  const _SearchFilterSection({
    required this.filter,
    required this.onSearchChanged,
  });

  final FilterState filter;
  final ValueChanged<String> onSearchChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      decoration: InputDecoration(
        labelText: 'Recherche',
        hintText: 'Nom de carte, série...',
        prefixIcon: const Icon(Icons.search),
        suffixIcon: filter.searchQuery.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () => onSearchChanged(''),
              )
            : null,
      ),
      onChanged: onSearchChanged,
    );
  }
}

class _ExpandableSection extends StatefulWidget {
  const _ExpandableSection({
    required this.title,
    required this.child,
    this.initiallyExpanded = false,
  });

  final String title;
  final Widget child;
  final bool initiallyExpanded;

  @override
  State<_ExpandableSection> createState() => _ExpandableSectionState();
}

class _ExpandableSectionState extends State<_ExpandableSection> {
  late bool _expanded;

  @override
  void initState() {
    super.initState();
    _expanded = widget.initiallyExpanded;
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ),
                  AnimatedRotation(
                    turns: _expanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      Icons.keyboard_arrow_down,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: widget.child,
            ),
            crossFadeState:
                _expanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 300),
          ),
        ],
      ),
    );
  }
}

class _SetsGrid extends StatelessWidget {
  const _SetsGrid({
    required this.sets,
    required this.selectedSets,
    required this.onToggle,
  });

  final List<String> sets;
  final List<String> selectedSets;
  final ValueChanged<String> onToggle;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: sets.map((set) {
        final isSelected = selectedSets.contains(set);
        return FilterChip(
          label: Text(set),
          selected: isSelected,
          onSelected: (_) => onToggle(set),
          selectedColor: Theme.of(context).colorScheme.primaryContainer,
          labelStyle: TextStyle(
            color: isSelected
                ? Theme.of(context).colorScheme.onPrimaryContainer
                : Theme.of(context).colorScheme.onSurface,
          ),
        );
      }).toList(),
    );
  }
}

class _ConditionsList extends StatelessWidget {
  const _ConditionsList({
    required this.conditions,
    required this.selectedConditions,
    required this.onToggle,
  });

  final List<CardCondition> conditions;
  final List<CardCondition> selectedConditions;
  final ValueChanged<CardCondition> onToggle;

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

  Color _getConditionColor(CardCondition condition) {
    switch (condition) {
      case CardCondition.neuf:
        return Colors.green;
      case CardCondition.nearMount:
        return Colors.lightBlue;
      case CardCondition.tresBonEtat:
        return Colors.purple.shade200;
      case CardCondition.bonEtat:
        return Colors.amber;
      case CardCondition.jouable:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: conditions.map((condition) {
        final isSelected = selectedConditions.contains(condition);
        return CheckboxListTile(
          title: Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: _getConditionColor(condition),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.grey.shade400),
                ),
              ),
              const SizedBox(width: 12),
              Text(_getConditionLabel(condition)),
            ],
          ),
          value: isSelected,
          onChanged: (_) => onToggle(condition),
          activeColor: Theme.of(context).colorScheme.primary,
          contentPadding: EdgeInsets.zero,
          dense: true,
        );
      }).toList(),
    );
  }
}

class _PriceRangeSlider extends StatelessWidget {
  const _PriceRangeSlider({
    required this.minPrice,
    required this.maxPrice,
    required this.onChanged,
  });

  final double minPrice;
  final double maxPrice;
  final ValueChanged<RangeValues> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('${minPrice.toInt()} €', style: Theme.of(context).textTheme.bodyMedium),
            Text('${maxPrice.toInt()} €', style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
        const SizedBox(height: 8),
        RangeSlider(
          values: RangeValues(minPrice, maxPrice),
          min: 0,
          max: 500,
          divisions: 50,
          labels: RangeLabels('${minPrice.toInt()} €', '${maxPrice.toInt()} €'),
          onChanged: onChanged,
        ),
      ],
    );
  }
}

class _ApplyFiltersButton extends StatelessWidget {
  const _ApplyFiltersButton({
    required this.hasActiveFilters,
    required this.onApply,
  });

  final bool hasActiveFilters;
  final VoidCallback onApply;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: FilledButton.icon(
          onPressed: onApply,
          icon: const Icon(Icons.filter_list),
          label: Text(hasActiveFilters ? 'Appliquer les filtres (actifs)' : 'Appliquer les filtres'),
          style: FilledButton.styleFrom(
            minimumSize: const Size(double.infinity, 52),
            backgroundColor: hasActiveFilters
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.primaryContainer,
            foregroundColor: hasActiveFilters
                ? Theme.of(context).colorScheme.onPrimary
                : Theme.of(context).colorScheme.onPrimaryContainer,
          ),
        ),
      ),
    );
  }
}