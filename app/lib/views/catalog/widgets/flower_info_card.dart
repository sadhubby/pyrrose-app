import 'package:flutter/material.dart';

import '../../../features/catalog/domain/flower.dart';

/// The tap-to-show card with the flower's name, scientific name, and meaning.
class FlowerInfoCard extends StatelessWidget {
  const FlowerInfoCard({
    super.key,
    required this.flower,
    required this.onClose,
  });

  final Flower flower;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      elevation: 4,
      color: theme.colorScheme.surface.withValues(alpha: 0.97),
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: flower.accent,
              child: const Icon(
                Icons.local_florist,
                size: 18,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(flower.name, style: theme.textTheme.titleMedium),
                  const SizedBox(height: 2),
                  Text(
                    flower.scientificName,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontStyle: FontStyle.italic,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(flower.meaning, style: theme.textTheme.bodyMedium),
                ],
              ),
            ),
            IconButton(
              onPressed: onClose,
              icon: const Icon(Icons.close),
              tooltip: 'Dismiss',
            ),
          ],
        ),
      ),
    );
  }
}
