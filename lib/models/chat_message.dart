class ChatMessage {
  final String id;
  final String text;
  final bool isUser; // true si c'est l'utilisateur, false si c'est l'IA
  final DateTime createdAt;

  ChatMessage({
    required this.id,
    required this.text,
    required this.isUser,
    required this.createdAt,
  });
}