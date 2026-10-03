import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/storage_image_provider.dart';

/// Résout [path] (chemin dans [bucket], un bucket Storage privé) en URL
/// signée et délègue l'affichage à [builder] — centralise la résolution/le
/// cache du `Future` (jamais relancé à chaque rebuild, voir [_DishImage]
/// dans coach_screen.dart dont ce widget généralise le principe), pas la
/// mise en page : chaque site d'affichage (avatar rond, miniature repas/
/// pesée) a un rendu différent selon [snapshot] (`null` tant que la
/// résolution n'est pas terminée, puis l'URL signée ou `null` si [path]
/// était nul ou que la résolution a échoué).
class StorageImage extends ConsumerStatefulWidget {
  const StorageImage({
    super.key,
    required this.bucket,
    required this.path,
    required this.builder,
  });

  final String bucket;
  final String? path;
  final Widget Function(BuildContext context, AsyncSnapshot<String?> snapshot)
  builder;

  @override
  ConsumerState<StorageImage> createState() => _StorageImageState();
}

class _StorageImageState extends ConsumerState<StorageImage> {
  late Future<String?> _future;

  @override
  void initState() {
    super.initState();
    _resolve();
  }

  @override
  void didUpdateWidget(StorageImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.bucket != widget.bucket || oldWidget.path != widget.path) {
      _resolve();
    }
  }

  void _resolve() {
    _future = ref
        .read(storageImageServiceProvider)
        .resolve(widget.bucket, widget.path);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: _future,
      builder: widget.builder,
    );
  }
}
