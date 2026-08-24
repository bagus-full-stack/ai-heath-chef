import 'package:ai_health_chef/models/chat_message.dart';
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

    final rows = await _supabase
        .from('chat_messages')
        .select('id, role, text, created_at')
        .eq('user_id', user.id)
        .order('created_at', ascending: true);

    final messages = rows
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

    final aiReplyText = await _aiService.chatWithCoach(
      trimmed,
      _toGeminiHistory(historyForGemini),
    );
    final assistantMessage = _buildAssistantMessage(aiReplyText);

    state = AsyncData([...(state.value ?? currentMessages), assistantMessage]);
    await _storeMessage(assistantMessage);
  }

  Future<void> _storeMessage(ChatMessage message) async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      throw const AuthException('User must be authenticated to persist chat messages.');
    }

    await _supabase.from('chat_messages').insert({
      'user_id': user.id,
      'role': message.isUser ? 'user' : 'assistant',
      'text': message.text,
    });
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
