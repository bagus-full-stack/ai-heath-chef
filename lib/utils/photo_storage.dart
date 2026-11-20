import 'dart:io';

import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';

/// Compresse la photo à [sourcePath] et la copie dans un sous-dossier
/// permanent de l'app (`[subDir]/[fileId].jpg`, survit au redémarrage) —
/// logique partagée par [MealRepository] (`meal_photos`) et
/// [WeightRepository] (`weight_photos`).
Future<String> compressAndStorePhoto(
  String subDir,
  String fileId,
  String sourcePath,
) async {
  final compressedBytes = await FlutterImageCompress.compressWithFile(
    sourcePath,
    minWidth: 800,
    minHeight: 800,
    quality: 70,
  );
  if (compressedBytes == null) {
    throw Exception('Compression de la photo échouée');
  }

  final docsDir = await getApplicationDocumentsDirectory();
  final photosDir = Directory('${docsDir.path}/$subDir');
  await photosDir.create(recursive: true);
  final file = File('${photosDir.path}/$fileId.jpg');
  await file.writeAsBytes(compressedBytes);
  return file.path;
}
