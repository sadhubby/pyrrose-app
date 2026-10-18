// Copies the canonical flower catalog from the app into the web viewer so
// both renderers consume identical geometry data.
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
}
