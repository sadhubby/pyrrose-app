import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/flower_catalog_repository.dart';
import '../domain/flower.dart';

final flowerCatalogRepositoryProvider = Provider<FlowerCatalogRepository>(
  (ref) => const FlowerCatalogRepository(),
);

/// The shared catalog, loaded once from the app bundle.
final flowerCatalogProvider = FutureProvider<FlowerCatalog>(
  (ref) => ref.watch(flowerCatalogRepositoryProvider).load(),
);

/// The flower currently shown in the catalog renderer.
class SelectedFlowerId extends Notifier<String?> {
  @override
  String? build() => null;

  void select(String? id) {
    if (state == id) return;
    state = id;
  }
}

final selectedFlowerIdProvider = NotifierProvider<SelectedFlowerId, String?>(
  SelectedFlowerId.new,
);
