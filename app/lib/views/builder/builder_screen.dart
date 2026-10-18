import 'package:flutter/material.dart';

/// Placeholder builder screen. Phase 3 replaces this with the 3D scene,
/// slot ring, flower palette, and customizer controls.
class BuilderScreen extends StatelessWidget {
  const BuilderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('New bouquet')),
      body: const Center(
        child: Text('Bouquet canvas arrives in Phase 3'),
      ),
    );
  }
}
