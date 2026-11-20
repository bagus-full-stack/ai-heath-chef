import 'dart:io';

import 'package:flutter/material.dart';

/// Affiche une image locale (chemin renvoyé par image_picker/camera).
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
    return Image.file(
      File(path),
      fit: fit,
      width: width,
      height: height,
      errorBuilder: errorBuilder,
    );
  }
}
