import 'package:flutter/material.dart';

import '../../views/builder/builder_screen.dart';
import '../../views/catalog/catalog_screen.dart';
import '../../views/home/home_screen.dart';

/// Minimal stack-based navigation for the skeleton. Replaced by go_router
/// (or kept simple) once routes multiply in Phase 3.
class AppRouter extends StatelessWidget {
  const AppRouter({super.key});

  @override
  Widget build(BuildContext context) {
    return HomeScreen(
      onCreateBouquet: () {
        Navigator.of(
          context,
        ).push(MaterialPageRoute<void>(builder: (_) => const BuilderScreen()));
      },
      onBrowseFlowers: () {
        Navigator.of(
          context,
        ).push(MaterialPageRoute<void>(builder: (_) => const CatalogScreen()));
      },
    );
  }
}
