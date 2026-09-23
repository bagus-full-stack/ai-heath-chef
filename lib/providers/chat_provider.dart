import 'package:ai_health_chef/models/chat_message.dart';
import 'package:ai_health_chef/providers/local_ai_provider.dart';
import 'package:ai_health_chef/providers/locale_provider.dart';
import 'package:ai_health_chef/providers/profile_provider.dart';
import 'package:ai_health_chef/services/ai_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final chatProvider =
    AsyncNotifierProvider<ChatNotifier, List<ChatMessage>>(ChatNotifier.new);

class ChatNotifier extends AsyncNotifier<List<ChatMessage>> {
  final _aiService = AIService();
  final _supabase = Supabase.instance.client;

  static const _welcomeText =
      'Bonjour, je suis votre coach nutrition. Que souhaitez-vous améliorer aujourd\'hui ?';

  @override
  Future<List<ChatMessage>> build() async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      return [_buildWelcomeMessage()];
    }

    List<Map<String, dynamic>> rows;
    try {
      rows = await _supabase
          .from('chat_messages')
          .select('id, role, text, created_at')
          .eq('user_id', user.id)
          .order('created_at', ascending: false)
          .limit(50);
    } catch (_) {
      // Hors-ligne : pas d'historique cloud disponible, on démarre une
      // conversation locale plutôt que de rester en erreur.
      return [_buildWelcomeMessage()];
    }
    final sortedRows = rows.reversed;

    final messages = sortedRows
        .map<ChatMessage>((row) => ChatMessage(
              id: row['id']?.toString() ?? DateTime.now().microsecondsSinceEpoch.toString(),
              text: row['text'] as String? ?? '',
              isUser: (row['role'] as String?) == 'user',
              createdAt: DateTime.tryParse(row['created_at']?.toString() ?? '') ??
                  DateTime.now(),
            ))
        .where((message) => message.text.isNotEmpty)
        .toList();

    if (messages.isEmpty) {
      return [_buildWelcomeMessage()];
    }

    return [_buildWelcomeMessage(), ...messages];
  }

  Future<void> sendMessage(String message) async {
    final trimmed = message.trim();
    if (trimmed.isEmpty) {
      return;
    }

    final currentMessages = state.value ?? const <ChatMessage>[];
    final historyForGemini = currentMessages
        .where((entry) => entry.text != _welcomeText)
        .toList();
    final userMessage = _buildUserMessage(trimmed);
    state = AsyncData([...currentMessages, userMessage]);

    await _storeMessage(userMessage);

    final profile = ref.read(profileProvider).value;
    final coachTone = profile?.coachTone ?? 'motivant';
    final dietType = profile?.dietType ?? 'none';
    final allergies = profile?.allergies ?? const <String>[];
    final geminiHistory = _toGeminiHistory(historyForGemini);
    final lang = ref.read(localeProvider).value?.languageCode ?? 'fr';

    // IA locale d'abord si activée et téléchargée (pas de connexion requise,
    // n'utilise pas le quota cloud partagé), sinon/en cas d'échec repli sur
    // le cloud. Le try/catch ci-dessous n'existait pas avant l'ajout du mode
    // local — nécessaire pour savoir quand replier, pas un élargissement du
    // périmètre de cette fonction.
    String aiReplyText;
    final localSettings = ref.read(localAiSettingsProvider).value;
    if (localSettings?.isReadyToUse == true) {
      try {
        final local = ref.read(localAiServiceProvider);
        aiReplyText = await local.chatWithCoach(
          trimmed,
          geminiHistory,
          coachTone: coachTone,
          dietType: dietType,
          allergies: allergies,
          lang: lang,
        );
      } catch (_) {
        aiReplyText = await _aiService.chatWithCoach(
          trimmed,
          geminiHistory,
          coachTone: coachTone,
          dietType: dietType,
          allergies: allergies,
          lang: lang,
        );
      }
    } else {
      aiReplyText = await _aiService.chatWithCoach(
        trimmed,
        geminiHistory,
        coachTone: coachTone,
        dietType: dietType,
        allergies: allergies,
        lang: lang,
      );
    }
    final assistantMessage = _buildAssistantMessage(aiReplyText);

    state = AsyncData([...(state.value ?? currentMessages), assistantMessage]);
    await _storeMessage(assistantMessage);
  }

  Future<void> resetConversation() async {
    final user = _supabase.auth.currentUser;
    if (user != null) {
      await _supabase.from('chat_messages').delete().eq('user_id', user.id);
    }
    state = AsyncData([_buildWelcomeMessage()]);
  }

  Future<void> _storeMessage(ChatMessage message) async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      throw const AuthException('User must be authenticated to persist chat messages.');
    }

    try {
      await _supabase.from('chat_messages').insert({
        'user_id': user.id,
        'role': message.isUser ? 'user' : 'assistant',
        'text': message.text,
      });
    } catch (_) {
      // Hors-ligne : la persistance cloud échoue mais la conversation reste
      // utilisable localement (l'IA locale est justement conçue pour
      // fonctionner sans connexion) — seule la synchro cloud est perdue
      // pour ce message, pas la conversation en cours.
    }
  }

  ChatMessage _buildWelcomeMessage() {
    return ChatMessage(
      id: 'welcome',
      text: _welcomeText,
      isUser: false,
      createdAt: DateTime.now(),
    );
  }

  ChatMessage _buildUserMessage(String text) {
    return ChatMessage(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      text: text,
      isUser: true,
      createdAt: DateTime.now(),
    );
  }

  ChatMessage _buildAssistantMessage(String text) {
    return ChatMessage(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      text: text,
      isUser: false,
      createdAt: DateTime.now(),
    );
  }

  List<Map<String, dynamic>> _toGeminiHistory(List<ChatMessage> messages) {
    return messages.map((message) {
      return {
        'role': message.isUser ? 'user' : 'model',
        'parts': [
          {'text': message.text},
        ],
      };
    }).toList();
  }
}
