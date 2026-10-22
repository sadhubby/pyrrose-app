import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({
    super.key,
    required this.onCreateBouquet,
    required this.onBrowseFlowers,
  });

  final VoidCallback onCreateBouquet;
  final VoidCallback onBrowseFlowers;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Pyrrose')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Your bouquets will live here',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onCreateBouquet,
              icon: const Icon(Icons.local_florist),
              label: const Text('New bouquet'),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: onBrowseFlowers,
              icon: const Icon(Icons.grid_view),
              label: const Text('Browse flowers'),
            ),
          ],
        ),
      ),
    );
  }
}
