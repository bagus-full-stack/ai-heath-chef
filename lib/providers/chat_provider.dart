import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/chat_message.dart';
import '../services/ai_service.dart'; // On importe le service

class ChatNotifier extends Notifier<List<ChatMessage>> {
  @override
  List<ChatMessage> build() {
    return [
      ChatMessage(
        id: 'welcome',
        text: 'Bonjour ! Je suis ton Chef Santé IA. Que veux-tu savoir sur tes repas ou ta nutrition aujourd\'hui ?',
        isUser: false,
        createdAt: DateTime.now(),
      )
    ];
  }

  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    // 1. On affiche immédiatement le message de l'utilisateur
    final userMsg = ChatMessage(
      id: DateTime.now().toString(),
      text: text,
      isUser: true,
      createdAt: DateTime.now(),
    );
    state = [...state, userMsg];

    // 2. On prépare l'historique pour Gemini
    // L'API Google attend un format très spécifique : { role: 'user' ou 'model', parts: [{text: '...'}] }
    final historyForGemini = state
        .where((m) => m.id != 'welcome' && m.id != userMsg.id) // On exclut le message de bienvenue et le tout dernier message
        .map((m) => {
      'role': m.isUser ? 'user' : 'model',
      'parts': [{'text': m.text}],
    })
        .toList();

    // 3. On appelle Supabase -> Gemini
    try {
      final aiService = AIService();
      final reply = await aiService.chatWithCoach(text, historyForGemini);

      // 4. On affiche la vraie réponse de l'IA !
      final aiMsg = ChatMessage(
        id: DateTime.now().toString() + '_ai',
        text: reply,
        isUser: false,
        createdAt: DateTime.now(),
      );
      state = [...state, aiMsg];

    } catch (e) {
      // S'il y a un problème (pas d'internet, erreur serveur...)
      final errorMsg = ChatMessage(
        id: DateTime.now().toString() + '_err',
        text: "Désolé, j'ai eu un petit problème de connexion à mon cerveau 🧠. Réessaie !",
        isUser: false,
        createdAt: DateTime.now(),
      );
      state = [...state, errorMsg];
    }
  }
}

final chatProvider = NotifierProvider<ChatNotifier, List<ChatMessage>>(() {
  return ChatNotifier();
});