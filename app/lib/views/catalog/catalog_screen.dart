import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_scene/scene.dart';

import '../../features/catalog/application/catalog_providers.dart';
import '../../features/catalog/application/flower_scene_controller.dart';
import '../../features/catalog/domain/flower.dart';
import 'widgets/flower_info_card.dart';
import 'widgets/flower_selector.dart';

/// Phase 2 catalog renderer: one flower at a time, orbit controls, a chip
/// selector, and a tap-to-show info card.
class CatalogScreen extends ConsumerStatefulWidget {
  const CatalogScreen({super.key});

  @override
  ConsumerState<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends ConsumerState<CatalogScreen> {
  FlowerSceneController? _controller;
  Flower? _infoFlower;
  String? _shownFlowerId;
  bool _requestedController = false;
  Offset? _pointerDown;
  DateTime? _pointerDownAt;

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final catalogAsync = ref.watch(flowerCatalogProvider);
    final selectedId = ref.watch(selectedFlowerIdProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Flowers')),
      body: catalogAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => _CatalogError(
          message: '$error',
          onRetry: () => ref.invalidate(flowerCatalogProvider),
        ),
        data: (catalog) {
          _ensureController(catalog);
          return _buildContent(catalog, selectedId);
        },
      ),
    );
  }

  Widget _buildContent(FlowerCatalog catalog, String? selectedId) {
    final activeId =
        selectedId ?? _controller?.flower?.id ?? catalog.flowers.first.id;

    return Stack(
      fit: StackFit.expand,
      children: [
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFFFAF7F5), Color(0xFFEADFE4)],
            ),
          ),
        ),
        LayoutBuilder(
          builder: (context, constraints) {
            final viewSize = constraints.biggest;
            final controller = _controller;
            if (controller == null) {
              return const Center(child: CircularProgressIndicator());
            }
            return Listener(
              behavior: HitTestBehavior.opaque,
              onPointerDown: _handlePointerDown,
              onPointerCancel: (_) => _clearPointer(),
              onPointerUp: (event) =>
                  _handlePointerUp(event, viewSize, catalog),
              child: CameraControls(
                controller: controller.orbit,
                child: SceneView(
                  controller.scene,
                  loadingBuilder: (context, progress) =>
                      const Center(child: CircularProgressIndicator()),
                ),
              ),
            );
          },
        ),
        Positioned(
          left: 16,
          right: 16,
          bottom: 16,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                transitionBuilder: (child, animation) => SizeTransition(
                  sizeFactor: animation,
                  alignment: Alignment.topLeft,
                  child: FadeTransition(opacity: animation, child: child),
                ),
                child: _infoFlower == null
                    ? const SizedBox.shrink()
                    : Padding(
                        key: ValueKey(_infoFlower!.id),
                        padding: const EdgeInsets.only(bottom: 12),
                        child: FlowerInfoCard(
                          flower: _infoFlower!,
                          onClose: () => setState(() => _infoFlower = null),
                        ),
                      ),
              ),
              FlowerSelector(
                flowers: catalog.flowers,
                selectedId: activeId,
                onSelected: (flower) => _selectFlower(flower, revealInfo: true),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _ensureController(FlowerCatalog catalog) {
    if (_requestedController) return;
    _requestedController = true;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _controller != null) return;

      final controller = FlowerSceneController();
      setState(() => _controller = controller);

      final selected = ref.read(selectedFlowerIdProvider);
      final flower =
          (selected == null ? null : catalog.byId(selected)) ??
          catalog.flowers.first;

      ref.read(selectedFlowerIdProvider.notifier).select(flower.id);
      unawaited(_showFlower(flower, revealInfo: false));
    });
  }

  void _selectFlower(Flower flower, {required bool revealInfo}) {
    ref.read(selectedFlowerIdProvider.notifier).select(flower.id);
    unawaited(_showFlower(flower, revealInfo: revealInfo));
  }

  Future<void> _showFlower(Flower flower, {required bool revealInfo}) async {
    final controller = _controller;
    if (controller == null) {
      if (revealInfo && mounted) {
        setState(() => _infoFlower = flower);
      }
      return;
    }

    final alreadyShown = _shownFlowerId == flower.id;
    _shownFlowerId = flower.id;

    if (revealInfo) {
      if (mounted) setState(() => _infoFlower = flower);
    } else if (_infoFlower != null && mounted) {
      setState(() => _infoFlower = null);
    }

    if (alreadyShown) return;

    try {
      await controller.showFlower(flower);
    } catch (error) {
      _shownFlowerId = null;
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not load ${flower.name}: $error')),
      );
    }
  }

  void _handlePointerDown(PointerDownEvent event) {
    _pointerDown = event.localPosition;
    _pointerDownAt = DateTime.now();
  }

  void _handlePointerUp(
    PointerUpEvent event,
    Size viewSize,
    FlowerCatalog catalog,
  ) {
    final down = _pointerDown;
    final downAt = _pointerDownAt;
    _clearPointer();
    if (down == null || downAt == null) return;

    // Ignore drags (orbit/pan) and long presses; only treat a short, nearly
    // stationary press as a tap.
    if ((event.localPosition - down).distance > 8) return;
    if (DateTime.now().difference(downAt) > const Duration(milliseconds: 400)) {
      return;
    }

    final flower = _controller?.pickFlower(
      event.localPosition,
      viewSize,
      catalog.flowers,
    );
    if (flower == null) {
      if (_infoFlower != null) setState(() => _infoFlower = null);
      return;
    }

    _selectFlower(flower, revealInfo: true);
  }

  void _clearPointer() {
    _pointerDown = null;
    _pointerDownAt = null;
  }
}

class _CatalogError extends StatelessWidget {
  const _CatalogError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 40, color: theme.colorScheme.error),
            const SizedBox(height: 12),
            Text(
              'The flower catalog could not be loaded.',
              style: theme.textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: theme.textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton.tonal(
              onPressed: onRetry,
              child: const Text('Try again'),
            ),
          ],
        ),
      ),
    );
  }
}
