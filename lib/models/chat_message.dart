class ChatMessage {
  final String id;
  final String text;
  final bool isUser; // true si c'est l'utilisateur, false si c'est l'IA
  final DateTime createdAt;
  // Legacy (avant migration 0019) : data URI base64 de l'illustration IA du
  // plat recommandé, encore présente pour les messages pas migrés vers
  // Storage (voir supabase/scripts/backfill_chat_images.dart). Ne plus
  // jamais l'alimenter pour un nouveau message.
  final String? imageUrl;
  // Chemin de l'illustration dans le bucket Storage privé `chat_images`
  // ({user_id}/{uuid}.jpg, voir migration 0019 et chat_provider.dart) —
  // remplace [imageUrl] pour tout nouveau message. Null si aucun plat précis
  // n'a été suggéré, ou si l'upload a échoué.
  final String? imagePath;
  // true si ce message chargé depuis la base a une illustration legacy
  // (`image_url` non-nul) pas encore migrée, sans avoir chargé son contenu
  // base64 en masse (voir ChatNotifier._fetchPage) — déclenche un
  // chargement à la demande côté UI.
  final bool hasLegacyImage;

  ChatMessage({
    required this.id,
    required this.text,
    required this.isUser,
    required this.createdAt,
    this.imageUrl,
    this.imagePath,
    this.hasLegacyImage = false,
  });
}