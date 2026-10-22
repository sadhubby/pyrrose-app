import 'package:flutter_scene/scene.dart';
import 'package:vector_math/vector_math.dart';

import '../domain/flower.dart';
import 'procedural_tulip.dart';
import 'render_utils.dart';

/// Prefix used to tag the root node of each flower so raycast hits can be
/// traced back to a catalog entry.
const String flowerTagPrefix = 'flower:';

String flowerTag(String id) => '$flowerTagPrefix$id';

/// Walks up from a raycast hit to the nearest tagged flower node.
String? flowerIdOf(Node node) {
  Node? current = node;
  while (current != null) {
    final name = current.name;
    if (name.startsWith(flowerTagPrefix)) {
      return name.substring(flowerTagPrefix.length);
    }
    current = current.parent;
  }
  return null;
}

/// Builds a renderable node for [flower], tagged with [flowerTag].
///
/// Source precedence matches the web viewer: model, then procedural, then
/// box parts.
Future<Node> buildFlowerNode(Flower flower) async {
  final group = Node(name: flowerTag(flower.id));

  final model = flower.model;
  if (model != null) {
    final loaded = await loadScene('assets/models/${model.sceneId}');
    final placement = Node(name: 'flower:${flower.id}:model');
    placement.scale = Vector3.all(model.scale);
    placement.position = model.offset.clone();
    placement.add(loaded);
    group.add(placement);
    return group;
  }

  final procedural = flower.procedural;
  if (procedural != null) {
    final node = buildProceduralFlower(procedural, flower.accent);
    if (node == null) {
      throw UnsupportedError('Unknown procedural flower "$procedural".');
    }
    group.add(node);
    return group;
  }

  if (flower.parts.isEmpty) {
    throw StateError('Flower "${flower.id}" has no geometry source.');
  }

  for (final part in flower.parts) {
    group.add(_partNode(part));
  }
  return group;
}

Node _partNode(FlowerPart part) {
  switch (part.kind) {
    case 'box':
      final node = Node(
        mesh: Mesh(CuboidGeometry(part.size), flowerMaterial(part.color)),
      );
      node.position = part.at.clone();
      node.rotation = eulerDegreesQuaternion(part.rotation);
      return node;
    default:
      throw UnsupportedError('Unknown flower part kind "${part.kind}".');
  }
}
