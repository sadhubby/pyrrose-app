import 'package:flutter/material.dart';

import '../../../features/catalog/domain/flower.dart';

/// Horizontal chip selector for the catalog's flowers.
class FlowerSelector extends StatelessWidget {
  const FlowerSelector({
    super.key,
    required this.flowers,
    required this.selectedId,
    required this.onSelected,
  });

  final List<Flower> flowers;
  final String selectedId;
  final ValueChanged<Flower> onSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      elevation: 2,
      color: theme.colorScheme.surface.withValues(alpha: 0.94),
      borderRadius: BorderRadius.circular(20),
      child: SizedBox(
        height: 60,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          itemCount: flowers.length,
          separatorBuilder: (_, _) => const SizedBox(width: 8),
          itemBuilder: (context, index) {
            final flower = flowers[index];
            return ChoiceChip(
              selected: flower.id == selectedId,
              showCheckmark: false,
              avatar: CircleAvatar(backgroundColor: flower.accent, radius: 7),
              label: Text(flower.name),
              onSelected: (_) => onSelected(flower),
            );
          },
        ),
      ),
    );
  }
}
