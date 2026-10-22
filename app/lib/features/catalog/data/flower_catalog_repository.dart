import 'dart:convert';

import 'package:flutter/services.dart';

import '../domain/flower.dart';

/// Loads the canonical catalog that the app and the web viewer share.
class FlowerCatalogRepository {
  const FlowerCatalogRepository({this.bundle});

  final AssetBundle? bundle;

  static const String assetPath = 'assets/catalog/flowers.json';

  Future<FlowerCatalog> load() async {
    final raw = await (bundle ?? rootBundle).loadString(assetPath);
    final decoded = jsonDecode(raw);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Catalog root must be a JSON object.');
    }
    return FlowerCatalog.fromJson(decoded);
  }
}
