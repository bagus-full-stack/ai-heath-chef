import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/storage_image_service.dart';

/// Instance partagée : le cache mémoire d'URLs signées ([StorageImageService])
/// n'a d'intérêt que s'il survit entre les widgets qui l'utilisent.
final storageImageServiceProvider = Provider<StorageImageService>((ref) {
  return StorageImageService();
});
