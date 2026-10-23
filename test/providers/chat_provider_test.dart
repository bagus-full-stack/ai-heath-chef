import 'dart:async';

import 'package:ai_health_chef/models/ingredient.dart';
import 'package:ai_health_chef/models/meal_suggestion.dart';
import 'package:ai_health_chef/providers/chat_provider.dart';
import 'package:ai_health_chef/providers/dashboard_provider.dart';
import 'package:ai_health_chef/providers/fasting_provider.dart';
import 'package:ai_health_chef/providers/local_ai_provider.dart';
import 'package:ai_health_chef/providers/locale_provider.dart';
import 'package:ai_health_chef/providers/profile_provider.dart';
import 'package:ai_health_chef/services/ai_service.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

import '../local_db/fake_supabase.dart';

/// Double de test d'[AIService] : jamais de réseau, réponse = écho du
/// message (`"Réponse à " + message`) pour que les assertions d'ordre
/// restent lisibles sans dépendre d'un texte généré. `historySnapshots` capture
/// l'historique reçu à chaque appel (voir test "history window" ci-dessous).
/// Les autres méthodes d'[AIService] ne sont pas utilisées par
/// `ChatNotifier` et ne sont donc pas exercées par ces tests.
class _FakeAiService implements AIService {
  int chatCalls = 0;
  final List<List<Map<String, dynamic>>> historySnapshots = [];

  /// Non-null seulement pendant le test de cancellation : retarde la
  /// résolution de l'appel pour laisser le temps à un resetConversation()
  /// de s'intercaler.
  Completer<void>? hold;

  @override
  Future<({String reply, String? suggestedDish})> chatWithCoach(
    String message,
    List<Map<String, dynamic>> history, {
    String coachTone = 'motivant',
    String dietType = 'none',
    List<String> allergies = const [],
    String lang = 'fr',
    String? dailyContext,
  }) async {
    chatCalls++;
    historySnapshots.add(history);
    if (hold != null) {
      await hold!.future;
    }
    return (reply: 'Réponse à $message', suggestedDish: null);
  }

  @override
  Future<String?> getDishImage(String dishName) async => null;

  @override
  Future<List<Ingredient>> analyzeMealImage(String imagePath, {String lang = 'fr'}) =>
      throw UnimplementedError();
  @override
  Future<List<Ingredient>> analyzeProductImage(String imagePath, {String lang = 'fr'}) =>
      throw UnimplementedError();
  @override
  Future<List<Ingredient>> analyzeMenuImage(String imagePath, {String lang = 'fr'}) =>
      throw UnimplementedError();
  @override
  Future<List<Ingredient>> analyzePantryImage(String imagePath, {String lang = 'fr'}) =>
      throw UnimplementedError();
  @override
  Future<List<MealSuggestion>> getMealSuggestions({
    required String goal,
    required int targetKcal,
    required double targetProt,
    required double targetGluc,
    required double targetLip,
    String dietType = 'none',
    List<String> allergies = const [],
    String cuisinePreference = 'none',
    int count = 6,
    int? days,
    int? mealsPerDay,
    List<String>? availableIngredients,
    String lang = 'fr',
  }) =>
      throw UnimplementedError();
  @override
  Future<List<MealSuggestion>> getMealImages(List<MealSuggestion> suggestions) =>
      throw UnimplementedError();
}

/// `chat_messages` : toute requête réussit (liste vide en lecture) — ces
/// tests portent sur l'état en mémoire de `ChatNotifier`, pas sur la
/// persistance cloud (déjà couverte ailleurs, voir data_export_service_test).
Future<http.Response> _okHandler(http.Request request) async {
  if (request.method == 'POST') {
    return jsonResponse(request, <dynamic>[], status: 201);
  }
  return jsonResponse(request, <dynamic>[]);
}

class _FixedLocale extends LocaleNotifier {
  @override
  Future<Locale> build() async => const Locale('fr');
}

class _FixedFasting extends FastingNotifier {
  @override
  Future<FastingState> build() async => const FastingState(goalHours: 16);
}

class _FixedLocalAi extends LocalAiSettingsNotifier {
  @override
  Future<LocalAiSettings> build() async =>
      const LocalAiSettings(enabled: false, isDownloaded: false);
}

void main() {
  late _FakeAiService fakeAi;

  Future<ProviderContainer> buildContainer() async {
    fakeAi = _FakeAiService();
    final client = await fakeAuthenticatedClient('user-1', _okHandler);
    final container = ProviderContainer(overrides: [
      chatProvider.overrideWith(() => ChatNotifier(aiService: fakeAi, supabase: client)),
      localeProvider.overrideWith(_FixedLocale.new),
      fastingProvider.overrideWith(_FixedFasting.new),
      localAiSettingsProvider.overrideWith(_FixedLocalAi.new),
      profileProvider.overrideWith((ref) async => null),
      todayMealsProvider.overrideWith((ref) async => const []),
      hydrationTodayProvider.overrideWith((ref) async => const []),
    ]);
    addTearDown(container.dispose);
    // `localeProvider` doit être résolu avant `chatProvider` : chatProvider
    // le `watch` dès son `build()`, et le lire pour la première fois depuis
    // là (plutôt que directement depuis le container) bloque indéfiniment
    // avec cette version de riverpod — artefact du test, pas du code réel
    // (un `ref.watch` depuis un widget n'a pas ce souci).
    await container.read(localeProvider.future);
    await container.read(chatProvider.future);
    return container;
  }

  group('ChatNotifier', () {
    test('history window : jamais le message de bienvenue, reflète les échanges précédents', () async {
      final container = await buildContainer();
      final notifier = container.read(chatProvider.notifier);

      await notifier.sendMessage('Salut');
      await notifier.sendMessage('Et après ?');

      expect(fakeAi.historySnapshots[0], isEmpty);
      expect(fakeAi.historySnapshots[1], hasLength(2));
      expect(fakeAi.historySnapshots[1][0]['parts'][0]['text'], 'Salut');
      expect(fakeAi.historySnapshots[1][0]['role'], 'user');
      expect(fakeAi.historySnapshots[1][1]['role'], 'model');
    });

    test('message order : bienvenue, puis user/assistant dans l\'ordre d\'envoi', () async {
      final container = await buildContainer();
      final notifier = container.read(chatProvider.notifier);

      await notifier.sendMessage('Premier');
      await notifier.sendMessage('Second');

      final texts = container.read(chatProvider).value!.map((m) => m.text).toList();
      expect(texts, [
        container.read(chatProvider).value!.first.text, // welcome, texte non assertable (localisé)
        'Premier',
        'Réponse à Premier',
        'Second',
        'Réponse à Second',
      ]);
    });

    test('double send : deux envois concurrents conservent les deux messages, sans perte', () async {
      final container = await buildContainer();
      final notifier = container.read(chatProvider.notifier);

      final f1 = notifier.sendMessage('Premier');
      final f2 = notifier.sendMessage('Second');
      await Future.wait([f1, f2]);

      final texts = container.read(chatProvider).value!.map((m) => m.text).toList();
      expect(texts, containsAll(['Premier', 'Second', 'Réponse à Premier', 'Réponse à Second']));
      expect(texts.indexOf('Premier'), lessThan(texts.indexOf('Second')));
      expect(texts.indexOf('Premier'), lessThan(texts.indexOf('Réponse à Premier')));
      expect(texts.indexOf('Second'), lessThan(texts.indexOf('Réponse à Second')));
    });

    test('cancellation : resetConversation() pendant un envoi en vol écarte sa réponse tardive', () async {
      final container = await buildContainer();
      final notifier = container.read(chatProvider.notifier);
      fakeAi.hold = Completer<void>();

      final pending = notifier.sendMessage('Message en vol');
      // Laisse sendMessage() progresser jusqu'à l'appel IA (bloqué sur `hold`).
      await Future.delayed(const Duration(milliseconds: 20));

      await notifier.resetConversation();
      fakeAi.hold!.complete();
      await pending;

      final messages = container.read(chatProvider).value!;
      expect(messages, hasLength(1)); // uniquement le message de bienvenue du reset
      expect(messages.single.id, 'welcome');
    });
  });
}
