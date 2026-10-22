import 'dart:math' as math;
import 'dart:ui' show Color;

import 'package:flutter_scene/scene.dart';
import 'package:vector_math/vector_math.dart';

/// Converts one sRGB channel (0..1) to linear space.
///
/// `PhysicallyBasedMaterial.baseColorFactor` is linear RGBA, while the catalog
/// authors colours as sRGB hex, so parts and procedural meshes convert here.
double srgbToLinear(double channel) {
  if (channel <= 0.04045) return channel / 12.92;
  return math.pow((channel + 0.055) / 1.055, 2.4).toDouble();
}

/// The linear RGBA tint for a catalog colour.
Vector4 linearColor(Color color) => Vector4(
  srgbToLinear(color.r),
  srgbToLinear(color.g),
  srgbToLinear(color.b),
  color.a,
);

/// Builds a quaternion from an XYZ-order Euler rotation in radians.
///
/// Matches Three.js's default `Euler` order, which the viewer and catalog use.
Quaternion eulerQuaternion(Vector3 euler) {
  final x = Quaternion.axisAngle(Vector3(1, 0, 0), euler.x);
  final y = Quaternion.axisAngle(Vector3(0, 1, 0), euler.y);
  final z = Quaternion.axisAngle(Vector3(0, 0, 1), euler.z);
  return x * y * z;
}

/// Builds a quaternion from an XYZ-order Euler rotation in degrees.
Quaternion eulerDegreesQuaternion(Vector3 degrees) =>
    eulerQuaternion(degrees * (math.pi / 180));

/// A lit material with the same rough look as the viewer's `MeshStandardMaterial`.
PhysicallyBasedMaterial flowerMaterial(
  Color color, {
  double roughness = 0.65,
  double metallic = 0,
  bool doubleSided = false,
}) {
  return PhysicallyBasedMaterial()
    ..baseColorFactor = linearColor(color)
    ..roughnessFactor = roughness
    ..metallicFactor = metallic
    ..doubleSided = doubleSided;
}
