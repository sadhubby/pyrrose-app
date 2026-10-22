import 'dart:ui' show Color;

import 'package:flutter/foundation.dart';
import 'package:vector_math/vector_math.dart';

/// A single flower definition from `assets/catalog/flowers.json`.
///
/// A flower is built from exactly one of three sources, checked in this order
/// by the renderer: [model], [procedural], or [parts].
@immutable
class Flower {
  const Flower({
    required this.id,
    required this.name,
    required this.scientificName,
    required this.meaning,
    required this.accent,
    this.parts = const [],
    this.procedural,
    this.model,
  });

  final String id;
  final String name;
  final String scientificName;
  final String meaning;

  /// UI accent colour, used for the selector dot and the info card avatar.
  final Color accent;

  /// Box parts for the box-part fallback renderer.
  final List<FlowerPart> parts;

  /// Key into the app/viewer procedural builder registry.
  final String? procedural;

  /// Model file plus the placement transform the catalog applies to it.
  final FlowerModel? model;

  bool get isModel => model != null;

  bool get isProcedural => procedural != null;

  factory Flower.fromJson(Map<String, dynamic> json) {
    final rawParts = json['parts'];
    final parts = <FlowerPart>[];
    if (rawParts is List) {
      for (final rawPart in rawParts) {
        if (rawPart is! Map<String, dynamic>) {
          throw const FormatException('Each flower part must be an object.');
        }
        parts.add(FlowerPart.fromJson(rawPart));
      }
    }

    final rawModel = json['model'];

    return Flower(
      id: _string(json, 'id'),
      name: _string(json, 'name'),
      scientificName: _string(json, 'scientificName'),
      meaning: _string(json, 'meaning'),
      accent: colorFromHex(_string(json, 'accent')),
      parts: parts,
      procedural: json['procedural'] as String?,
      model: rawModel is Map<String, dynamic>
          ? FlowerModel.fromJson(rawModel)
          : null,
    );
  }
}

/// One box in a box-part flower spec. Mirrors the viewer's `BoxGeometry` usage.
@immutable
class FlowerPart {
  const FlowerPart({
    required this.at,
    required this.rotation,
    required this.size,
    required this.color,
    this.kind = 'box',
  });

  /// Part kind. Only `box` is supported today; unknown kinds throw when built.
  final String kind;

  /// Local position.
  final Vector3 at;

  /// Local Euler rotation in degrees, XYZ order (matches Three.js).
  final Vector3 rotation;

  /// Box extents (full width/height/depth).
  final Vector3 size;

  final Color color;

  factory FlowerPart.fromJson(Map<String, dynamic> json) {
    return FlowerPart(
      kind: json['kind'] as String? ?? 'box',
      at: _vector3(json['at'], 'parts[].at'),
      rotation: _vector3(json['rot'], 'parts[].rot'),
      size: _vector3(json['size'], 'parts[].size'),
      color: colorFromHex(_string(json, 'color')),
    );
  }
}

/// A glTF model plus the transform that places it in the flower's local space.
@immutable
class FlowerModel {
  FlowerModel({required this.file, this.scale = 1, Vector3? offset})
    : offset = offset ?? Vector3.zero();

  /// File name inside `assets/models/`, e.g. `rose.glb`.
  final String file;

  final double scale;
  final Vector3 offset;

  /// The extensionless asset id passed to `loadScene` (the build hook keys
  /// generated scenes by their source path without the `.glb` suffix).
  String get sceneId {
    final dot = file.lastIndexOf('.');
    final slash = file.lastIndexOf('/');
    return dot > slash ? file.substring(0, dot) : file;
  }

  factory FlowerModel.fromJson(Map<String, dynamic> json) {
    return FlowerModel(
      file: _string(json, 'file'),
      scale: _number(json, 'scale', fallback: 1),
      offset: json['offset'] == null
          ? Vector3.zero()
          : _vector3(json['offset'], 'model.offset'),
    );
  }
}

/// The parsed contents of `flowers.json`.
@immutable
class FlowerCatalog {
  const FlowerCatalog({required this.version, required this.flowers});

  final int version;
  final List<Flower> flowers;

  Flower? byId(String id) {
    for (final flower in flowers) {
      if (flower.id == id) return flower;
    }
    return null;
  }

  factory FlowerCatalog.fromJson(Map<String, dynamic> json) {
    final rawFlowers = json['flowers'];
    if (rawFlowers is! List) {
      throw const FormatException('Catalog is missing a "flowers" array.');
    }

    final flowers = <Flower>[];
    for (final rawFlower in rawFlowers) {
      if (rawFlower is! Map<String, dynamic>) {
        throw const FormatException('Each flower must be an object.');
      }
      flowers.add(Flower.fromJson(rawFlower));
    }

    if (flowers.isEmpty) {
      throw const FormatException('Catalog contains no flowers.');
    }

    return FlowerCatalog(
      version: (json['version'] as num?)?.toInt() ?? 1,
      flowers: List<Flower>.unmodifiable(flowers),
    );
  }
}

/// Parses `#rrggbb` or `#aarrggbb` (and the same without `#`) into a [Color].
Color colorFromHex(String hex) {
  final cleaned = hex.trim().replaceFirst('#', '');
  if (cleaned.length != 6 && cleaned.length != 8) {
    throw FormatException('Expected #rrggbb or #aarrggbb, got "$hex".');
  }
  final value = int.parse(cleaned, radix: 16);
  return Color(cleaned.length == 6 ? 0xFF000000 | value : value);
}

String _string(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is String && value.isNotEmpty) return value;
  throw FormatException('Expected a non-empty string at "$key".');
}

double _number(Map<String, dynamic> json, String key, {double fallback = 0}) {
  final value = json[key];
  if (value == null) return fallback;
  if (value is num) return value.toDouble();
  throw FormatException('Expected a number at "$key".');
}

Vector3 _vector3(Object? value, String key) {
  if (value is! List ||
      value.length != 3 ||
      value.any((component) => component is! num)) {
    throw FormatException('Expected a [x, y, z] number array at "$key".');
  }
  return Vector3(
    (value[0] as num).toDouble(),
    (value[1] as num).toDouble(),
    (value[2] as num).toDouble(),
  );
}
