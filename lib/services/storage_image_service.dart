import 'package:supabase_flutter/supabase_flutter.dart';

/// Résout un chemin de fichier dans un bucket Storage **privé** en URL
/// signée temporaire, avec un cache mémoire par `bucket:path`.
///
/// Le cache est indispensable : sans lui, chaque rebuild signerait une
/// nouvelle URL (le token diffère), ce qui casse le cache d'image de Flutter
/// (`Image.network` le clé sur l'URL) et provoque clignotement + requêtes
/// réseau en boucle. Même principe que [ChatProvider.getSignedImageUrl]
/// (bucket `chat_images`), généralisé aux buckets photo (`avatars`,
/// `meal_photos`, `weight_photos`) une fois privés (migration 0020).
class StorageImageService {
  /// [now], pour les tests uniquement, permet de simuler l'expiration du
  /// cache sans attendre 50 minutes (voir storage_image_service_test.dart).
  StorageImageService([SupabaseClient? client, DateTime Function()? now])
      : _supabase = client ?? Supabase.instance.client,
        _now = now ?? DateTime.now;

  final SupabaseClient _supabase;
  final DateTime Function() _now;

  // URL signée valide 1h ; renouvelée 10 min avant expiration plutôt que
  // d'attendre une 403, pour qu'une image déjà affichée ne se mette jamais
  // à échouer silencieusement en cours de session.
  static const _signedUrlTtl = Duration(seconds: 3600);
  static const _renewMargin = Duration(seconds: 600);

  final Map<String, _CachedSignedUrl> _cache = {};

  /// Null si [path] est null, hors ligne, ou en cas d'échec réseau/serveur —
  /// à l'appelant d'afficher un placeholder dans ce cas, jamais d'exception.
  Future<String?> resolve(String bucket, String? path) async {
    if (path == null) return null;

    final key = '$bucket:$path';
    final cached = _cache[key];
    if (cached != null && _now().isBefore(cached.renewAt)) {
      return cached.url;
    }

    try {
      final url = await _supabase.storage
          .from(bucket)
          .createSignedUrl(path, _signedUrlTtl.inSeconds);
      _cache[key] = _CachedSignedUrl(
        url,
        _now().add(_signedUrlTtl - _renewMargin),
      );
      return url;
    } catch (_) {
      return null;
    }
  }

  /// À appeler après ré-upload d'un fichier déjà en cache (ex. nouvel
  /// avatar réutilisant un chemin déjà résolu), pour ne pas continuer à
  /// servir une URL signée pointant vers le fichier remplacé.
  void invalidate(String bucket, String path) {
    _cache.remove('$bucket:$path');
  }
}

class _CachedSignedUrl {
  _CachedSignedUrl(this.url, this.renewAt);

  final String url;
  final DateTime renewAt;
}
