class ChatMessage {
  final String id;
  final String text;
  final bool isUser; // true si c'est l'utilisateur, false si c'est l'IA
  final DateTime createdAt;
  // Illustration IA du plat recommandé par le coach (voir chat_provider.dart
  // et AIService.getDishImage), null si aucun plat précis n'a été suggéré.
  final String? imageUrl;

  ChatMessage({
    required this.id,
    required this.text,
    required this.isUser,
    required this.createdAt,
    this.imageUrl,
  });
}