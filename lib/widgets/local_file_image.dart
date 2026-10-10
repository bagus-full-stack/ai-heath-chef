import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Affiche une image locale (chemin renvoyé par image_picker/camera), de
/// façon compatible web : `Image.file` n'est pas supporté sur Flutter Web
/// (pas de système de fichiers), seul `Image.network` sait charger l'URL
/// blob: qu'image_picker renvoie dans ce cas.
class LocalFileImage extends StatelessWidget {
  const LocalFileImage(
    this.path, {
    super.key,
    this.fit,
    this.width,
    this.height,
    this.errorBuilder,
  });

  final String path;
  final BoxFit? fit;
  final double? width;
  final double? height;
  final ImageErrorWidgetBuilder? errorBuilder;

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      return Image.network(
        path,
        fit: fit,
        width: width,
        height: height,
        errorBuilder: errorBuilder,
      );
    }
    return Image.file(
      File(path),
      fit: fit,
      width: width,
      height: height,
      errorBuilder: errorBuilder,
    );
  }
}
