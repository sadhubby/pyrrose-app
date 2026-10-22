// Copies the canonical flower catalog and the 3D model assets from the app
// into the web viewer so both renderers consume identical data.
//
// Usage: dart run tool/sync_catalog.dart   (from the repo root)

import 'dart:io';

void main() {
  final root = Directory.current;
  final source = File('${root.path}/app/assets/catalog/flowers.json');
  final targetDir = Directory('${root.path}/viewer/data');
  final target = File('${targetDir.path}/flowers.json');

  if (!source.existsSync()) {
    stderr.writeln('Source catalog not found: ${source.path}');
    exitCode = 1;
    return;
  }

  targetDir.createSync(recursive: true);
  target.writeAsStringSync(source.readAsStringSync());
  stdout.writeln('Synced ${source.path} -> ${target.path}');

  syncModels(root, targetDir);
}

// The viewer loads the same .glb files the app bundles, so they are copied
// next to the catalog. Only the models themselves, not the .gltf sources the
// converter reads.
void syncModels(Directory root, Directory targetDir) {
  final modelDir = Directory('${root.path}/app/assets/models');
  if (!modelDir.existsSync()) {
    stdout.writeln('No model directory to sync.');
    return;
  }

  var copied = 0;
  for (final file in modelDir.listSync().whereType<File>()) {
    if (!file.path.endsWith('.glb')) continue;
    final name = file.uri.pathSegments.last;
    final destination = File('${targetDir.path}/$name');
    destination.writeAsBytesSync(file.readAsBytesSync());
    stdout.writeln('Synced ${file.path} -> ${destination.path}');
    copied++;
  }

  if (copied == 0) {
    stdout.writeln('No models to sync.');
  }
}
