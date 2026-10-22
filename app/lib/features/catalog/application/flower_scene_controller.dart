import 'dart:ui' show Offset, Size;

import 'package:flutter/foundation.dart';
import 'package:flutter_scene/scene.dart';

import '../domain/flower.dart';
import 'flower_node_builder.dart';

/// Owns the [Scene], the orbiting camera, and the currently displayed flower.
///
/// One controller lives per catalog screen. Call [showFlower] to swap the
/// model; call [pickFlower] with a tap position to raycast back to a catalog
/// entry.
class FlowerSceneController extends ChangeNotifier {
  FlowerSceneController() {
    _cameraNode.addComponent(_camera);
    _cameraNode.addComponent(_orbit);
    _scene.add(_cameraNode);
  }

  final Scene _scene = Scene();
  final Node _cameraNode = Node(name: 'camera');
  final CameraComponent _camera = CameraComponent(activateOnMount: true);
  final OrbitCameraController _orbit = OrbitCameraController(
    distance: 5,
    azimuth: 0,
    polar: 0.28,
  );

  Node? _flowerNode;
  Flower? _flower;
  int _loadToken = 0;
  bool _disposed = false;

  Scene get scene => _scene;

  OrbitCameraController get orbit => _orbit;

  Flower? get flower => _flower;

  Future<void> showFlower(Flower flower) async {
    if (_disposed) return;
    final token = ++_loadToken;

    // Shaders must be resident before the first frame, and this also keeps the
    // subsequent frame from showing a half-built scene.
    await Scene.initializeStaticResources();
    if (_disposed || token != _loadToken) return;

    final node = await buildFlowerNode(flower);
    if (_disposed || token != _loadToken) return;

    final previous = _flowerNode;
    if (previous != null) _scene.remove(previous);

    _flowerNode = node;
    _flower = flower;
    _scene.add(node);

    final bounds = node.combinedWorldBounds;
    if (bounds != null) {
      _orbit.frame(bounds, margin: 1.7);
    }

    notifyListeners();
  }

  /// Returns the flower under [position] (logical pixels in a [viewSize] view),
  /// or null when the tap missed every tagged flower.
  Flower? pickFlower(Offset position, Size viewSize, List<Flower> flowers) {
    if (_disposed || _flower == null) return null;

    final ray = _camera.toCamera().screenPointToRay(position, viewSize);
    final hit = _scene.raycast(ray);
    if (hit == null) return null;

    final id = flowerIdOf(hit.node);
    if (id == null) return null;

    for (final flower in flowers) {
      if (flower.id == id) return flower;
    }
    return null;
  }

  @override
  void dispose() {
    _disposed = true;
    _loadToken++;
    _scene.dispose();
    super.dispose();
  }
}
