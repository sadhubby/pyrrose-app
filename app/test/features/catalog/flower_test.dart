import 'dart:convert';
import 'dart:io';
import 'dart:ui' show Color;

import 'package:flutter_scene/scene.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pyrrose/features/catalog/application/flower_node_builder.dart';
import 'package:pyrrose/features/catalog/application/render_utils.dart';
import 'package:pyrrose/features/catalog/domain/flower.dart';
import 'package:vector_math/vector_math.dart';

FlowerCatalog _realCatalog() {
  final raw = File('assets/catalog/flowers.json').readAsStringSync();
  return FlowerCatalog.fromJson(jsonDecode(raw) as Map<String, dynamic>);
}

void main() {
  group('catalog parsing', () {
    test('parses the real catalog', () {
      final catalog = _realCatalog();

      expect(catalog.version, 1);
      expect(catalog.flowers.map((flower) => flower.id), [
        'rose',
        'tulip',
        'rose-voxel',
      ]);
    });

    test('parses box parts with colours and transforms', () {
      final rose = _realCatalog().byId('rose')!;

      expect(rose.parts, hasLength(6));
      final stem = rose.parts.first;
      expect(stem.kind, 'box');
      expect(stem.color, const Color(0xFF3E7D3A));
      expect(stem.at, Vector3(0, 0.5, 0));
      expect(stem.size, Vector3(0.08, 1.0, 0.08));
    });

    test('parses procedural entries', () {
      final tulip = _realCatalog().byId('tulip')!;

      expect(tulip.procedural, 'tulip');
      expect(tulip.isProcedural, isTrue);
      expect(tulip.parts, isEmpty);
      expect(tulip.model, isNull);
    });

    test('parses model placement and strips the file extension', () {
      final rose = _realCatalog().byId('rose-voxel')!;
      final model = rose.model!;

      expect(model.file, 'rose.glb');
      expect(model.sceneId, 'rose');
      expect(model.scale, 0.0625);
      expect(model.offset, Vector3(-0.09375, 0, -0.0625));
    });

    test('byId returns null for unknown ids', () {
      expect(_realCatalog().byId('nope'), isNull);
    });

    test('rejects a catalog with no flowers', () {
      expect(
        () => FlowerCatalog.fromJson({'version': 1, 'flowers': []}),
        throwsFormatException,
      );
    });

    test('rejects malformed vectors', () {
      expect(
        () => FlowerPart.fromJson({
          'at': [0, 1],
          'rot': [0, 0, 0],
          'size': [1, 1, 1],
          'color': '#ffffff',
        }),
        throwsFormatException,
      );
    });
  });

  group('colour helpers', () {
    test('parses #rrggbb and #aarrggbb', () {
      expect(colorFromHex('#c2185b'), const Color(0xFFC2185B));
      expect(colorFromHex('80c2185b'), const Color(0x80C2185B));
    });

    test('rejects malformed hex', () {
      expect(() => colorFromHex('#abc'), throwsFormatException);
    });

    test('linearizes sRGB channels', () {
      expect(srgbToLinear(0), 0);
      expect(srgbToLinear(1), 1);
      expect(srgbToLinear(0.5), closeTo(0.2140, 0.001));
    });
  });

  group('rotation parity with Three.js XYZ Euler order', () {
    Vector3 apply(Quaternion q, Vector3 v) {
      final matrix = Matrix4.compose(Vector3.zero(), q, Vector3.all(1));
      return matrix.transformed3(v);
    }

    test('90 degrees around Z points +X at +Y', () {
      final rotated = apply(
        eulerDegreesQuaternion(Vector3(0, 0, 90)),
        Vector3(1, 0, 0),
      );
      expect(rotated.x, closeTo(0, 1e-6));
      expect(rotated.y, closeTo(1, 1e-6));
      expect(rotated.z, closeTo(0, 1e-6));
    });

    test('composes X then Y then Z like Three.js', () {
      // R = Rx * Ry: +Z rotates to +X under Y, then stays put under X.
      final rotated = apply(
        eulerDegreesQuaternion(Vector3(90, 90, 0)),
        Vector3(0, 0, 1),
      );
      expect(rotated.x, closeTo(1, 1e-6));
      expect(rotated.y, closeTo(0, 1e-6));
      expect(rotated.z, closeTo(0, 1e-6));
    });
  });

  group('flower tags', () {
    test('flowerIdOf walks up to the tagged root', () {
      final root = Node(name: flowerTag('rose-voxel'));
      final middle = Node(name: 'model');
      final leaf = Node(name: 'mesh');
      middle.add(leaf);
      root.add(middle);

      expect(flowerIdOf(leaf), 'rose-voxel');
      expect(flowerIdOf(root), 'rose-voxel');
    });

    test('flowerIdOf returns null outside a tagged subtree', () {
      final root = Node(name: 'scene');
      final leaf = Node(name: 'mesh');
      root.add(leaf);

      expect(flowerIdOf(leaf), isNull);
    });
  });
}
