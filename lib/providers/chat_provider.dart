import 'package:ai_health_chef/config/coach_prompt.dart';
import 'package:ai_health_chef/config/emergency_contacts.dart';
import 'package:ai_health_chef/l10n/app_localizations.dart';
import 'package:ai_health_chef/models/chat_message.dart';
import 'package:ai_health_chef/providers/ai_consent_provider.dart';
import 'package:ai_health_chef/providers/local_ai_provider.dart';
import 'package:ai_health_chef/providers/locale_provider.dart';
import 'package:ai_health_chef/providers/dashboard_provider.dart';
import 'package:ai_health_chef/providers/fasting_provider.dart';
import 'package:ai_health_chef/providers/profile_provider.dart';
import 'package:ai_health_chef/services/ai_service.dart';
import 'package:ai_health_chef/utils/coach_context_builder.dart';
import 'package:ai_health_chef/utils/health_risk_filter.dart';
import 'package:ai_health_chef/utils/image_data_uri.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

const _uuid = Uuid();

final chatProvider =
    AsyncNotifierProvider<ChatNotifier, List<ChatMessage>>(ChatNotifier.new);

class ChatNotifier extends AsyncNotifier<List<ChatMessage>> {
  /// Params optionnels : permet d'injecter des doubles de test (voir
  /// test/providers/chat_provider_test.dart) sans toucher au comportement
  /// réel, où `Supabase.instance.client`/`AIService()` restent les défauts.
  ChatNotifier({AIService? aiService, SupabaseClient? supabase})
      : _aiService = aiService ?? AIService(),
        _supabase = supabase ?? Supabase.instance.client;

  final AIService _aiService;
  final SupabaseClient _supabase;

  // Pagination simple de l'historique (voir loadOlderMessages) : un petit
  // lot à la fois plutôt que tout l'historique au chargement de l'écran.
  static const _pageSize = 30;
  bool _hasMoreHistory = true;
  bool _isLoadingOlder = false;

  // Incrémenté à chaque resetConversation : permet à un sendMessage en vol
  // de détecter qu'il a été réinitialisé pendant l'appel réseau et d'annuler
  // son écriture tardive plutôt que de ressusciter un message supprimé.
  int _conversationGeneration = 0;

  bool get hasMoreHistory => _hasMoreHistory;
  bool get isLoadingOlder => _isLoadingOlder;

  @override
  Future<List<ChatMessage>> build() async {
    // `watch` (pas `read`) : un changement de langue doit reconstruire
    // immédiatement le message de bienvenue, pas seulement après un
    // resetConversation().
    ref.watch(localeProvider);

    final user = _supabase.auth.currentUser;
    if (user == null) {
      return [_buildWelcomeMessage()];
    }

    final messages = await _fetchPage(user.id, before: null);
    if (messages.isEmpty) {
      return [_buildWelcomeMessage()];
    }

    return [_buildWelcomeMessage(), ...messages];
  }

  /// Charge jusqu'à [_pageSize] messages plus anciens que [before] (ou les
  /// plus récents si `null`), triés chronologiquement. Sélectionne
  /// `image_path` seulement — jamais `image_url` en masse, potentiellement
  /// énorme en base64 pour chaque ligne (voir migration 0019) — et repère,
  /// uniquement parmi ce lot, les messages legacy ayant encore une
  /// illustration non migrée (`hasLegacyImage`), chargée à la demande par
  /// l'UI plutôt qu'ici.
  Future<List<ChatMessage>> _fetchPage(String userId, {DateTime? before}) async {
    List<Map<String, dynamic>> rows;
    try {
      var query = _supabase
          .from('chat_messages')
          .select('id, role, text, created_at, image_path')
          .eq('user_id', userId);
      if (before != null) {
        query = query.lt('created_at', before.toUtc().toIso8601String());
      }
      rows = await query.order('created_at', ascending: false).limit(_pageSize);
    } catch (_) {
      // Hors-ligne : pas d'historique cloud disponible, on démarre une
      // conversation locale plutôt que de rester en erreur.
      return const [];
    }
    if (rows.isEmpty) {
      return const [];
    }

    final legacyCandidateIds = rows
        .where((row) => row['image_path'] == null)
        .map((row) => row['id'])
        .toList();
    var legacyIds = const <Object?>{};
    if (legacyCandidateIds.isNotEmpty) {
      try {
        final legacyRows = await _supabase
            .from('chat_messages')
            .select('id')
            .inFilter('id', legacyCandidateIds)
            .not('image_url', 'is', null);
        legacyIds = legacyRows.map((row) => row['id']).toSet();
      } catch (_) {
        // Pas bloquant : au pire l'ancienne illustration ne s'affichera pas
        // pour ce lot.
      }
    }

    return rows.reversed
        .map<ChatMessage>((row) => ChatMessage(
              id: row['id']?.toString() ?? DateTime.now().microsecondsSinceEpoch.toString(),
              text: row['text'] as String? ?? '',
              isUser: (row['role'] as String?) == 'user',
              createdAt: DateTime.tryParse(row['created_at']?.toString() ?? '') ??
                  DateTime.now(),
              imagePath: row['image_path'] as String?,
              hasLegacyImage: legacyIds.contains(row['id']),
            ))
        .where((message) => message.text.isNotEmpty)
        .toList();
  }

  /// Charge le lot de messages précédant les plus anciens déjà affichés
  /// (voir `_pageSize`) et les insère juste après le message de bienvenue.
  /// Pas d'effet si hors-ligne, si tout l'historique est déjà chargé, ou si
  /// un chargement est déjà en cours.
  Future<void> loadOlderMessages() async {
    final user = _supabase.auth.currentUser;
    if (user == null || !_hasMoreHistory || _isLoadingOlder) {
      return;
    }

    final current = state.value ?? const <ChatMessage>[];
    final realMessages = current.where((message) => message.id != 'welcome').toList();
    if (realMessages.isEmpty) {
      return;
    }

    _isLoadingOlder = true;
    try {
      final older = await _fetchPage(user.id, before: realMessages.first.createdAt);
      if (older.length < _pageSize) {
        _hasMoreHistory = false;
      }
      if (older.isEmpty) {
        return;
      }

      final hasWelcome = current.isNotEmpty && current.first.id == 'welcome';
      final rest = hasWelcome ? current.skip(1).toList() : current;
      state = AsyncData([
        if (hasWelcome) _buildWelcomeMessage(),
        ...older,
        ...rest,
      ]);
    } finally {
      _isLoadingOlder = false;
    }
  }

  /// URL signée (1h) pour afficher l'illustration stockée à [path] dans le
  /// bucket privé `chat_images`. Null en cas d'échec (réseau, chemin
  /// supprimé...) — l'UI retombe alors sur un placeholder.
  Future<String?> getSignedImageUrl(String path) async {
    try {
      return await _supabase.storage.from('chat_images').createSignedUrl(path, 3600);
    } catch (_) {
      return null;
    }
  }

  /// Charge à la demande l'ancienne data URI base64 d'un message legacy
  /// (voir [ChatMessage.hasLegacyImage]) — jamais sélectionnée en masse au
  /// chargement de l'historique.
  Future<String?> fetchLegacyImageDataUri(String messageId) async {
    try {
      final row = await _supabase
          .from('chat_messages')
          .select('image_url')
          .eq('id', messageId)
          .maybeSingle();
      return row?['image_url'] as String?;
    } catch (_) {
      return null;
    }
  }

  Future<void> sendMessage(String message) async {
    final trimmed = message.trim();
    if (trimmed.isEmpty) {
      return;
    }

    final generation = _conversationGeneration;
    final currentMessages = state.value ?? const <ChatMessage>[];
    // Comparaison par id plutôt que par texte : un id stable ('welcome')
    // reste correct même si le message de bienvenue change de langue ou de
    // formulation, contrairement à une égalité de texte.
    final historyForGemini =
        currentMessages.where((entry) => entry.id != 'welcome').toList();
    final userMessage = _buildUserMessage(trimmed);
    state = AsyncData([...currentMessages, userMessage]);

    await _storeMessage(userMessage);

    final profile = ref.read(profileProvider).value;
    final coachTone = profile?.coachTone ?? 'motivant';
    final dietType = profile?.dietType ?? 'none';
    final allergies = profile?.allergies ?? const <String>[];
    final geminiHistory = _toGeminiHistory(historyForGemini);
    final lang = ref.read(localeProvider).value?.languageCode ?? 'fr';

    // Bloc contexte du jour : lu depuis les
    // providers déjà existants (DB locale), jamais de nouvelle requête ici.
    // En lecture seule via `read` : sendMessage() est un instantané au
    // moment de l'envoi, pas un flux réactif.
    final fasting = ref.read(fastingProvider).value;
    final contextInput = DailyContextInput(
      profile: profile,
      todayMeals: ref.read(todayMealsProvider).value ?? const [],
      hydrationMl: (ref.read(hydrationTodayProvider).value ?? const [])
          .fold<int>(0, (sum, entry) => sum + entry.amountMl),
      isFasting: fasting?.isFasting ?? false,
      fastingElapsedHours: fasting?.elapsed.inHours ?? 0,
      fastingGoalHours: fasting?.goalHours ?? 16,
      lang: lang,
    );

    // Non-null seulement pour une réponse cloud recommandant un plat précis
    // (voir coach-chat/index.ts) : l'IA locale ne produit pas cette balise,
    // donc pas d'illustration pour les réponses générées hors-ligne.
    String aiReplyText;
    String? suggestedDish;
    // Indicateur de transparence : quel
    // moteur a réellement généré cette réponse, pas quel moteur était
    // configuré — distingue un repli cloud après échec local (null = aucun
    // modèle, ex. filet de sécurité ou double échec).
    String? usedEngine;

    // Filet de sécurité déterministe, avant tout appel modèle : un petit
    // modèle local n'a pas le garde-fou santé du prompt cloud, donc ce
    // filtre doit intercepter le message avant la branche local/cloud, pas
    // dans le prompt (voir lib/utils/health_risk_filter.dart).
    final riskCategory = detectHealthRisk(trimmed);
    if (riskCategory != null) {
      aiReplyText = _buildSafetyReply(riskCategory, lang);
    } else {
      // IA locale d'abord si activée et téléchargée (pas de connexion
      // requise, n'utilise pas le quota cloud partagé), sinon/en cas
      // d'échec repli sur le cloud. Le try/catch ci-dessous n'existait pas
      // avant l'ajout du mode local — nécessaire pour savoir quand replier,
      // pas un élargissement du périmètre de cette fonction.
      final localSettings = ref.read(localAiSettingsProvider).value;
      try {
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
              dailyContext: buildDailyContextBlock(contextInput, compact: true),
            );
            usedEngine = 'local';
          } catch (_) {
            // Repli cloud uniquement si le consentement a déjà été donné
            // (étape 3, cas 5) : jamais d'appel cloud silencieux faute de
            // mieux.
            if (ref.read(cloudAiConsentProvider).value == true) {
              final cloudReply = await _aiService.chatWithCoach(
                trimmed,
                geminiHistory,
                coachTone: coachTone,
                dietType: dietType,
                allergies: allergies,
                lang: lang,
                dailyContext: buildDailyContextBlock(contextInput),
              );
              aiReplyText = cloudReply.reply;
              suggestedDish = cloudReply.suggestedDish;
              usedEngine = 'cloud';
            } else {
              aiReplyText =
                  lookupAppLocalizations(Locale(lang)).coachLocalAiFailedNoCloudConsent;
            }
          }
        } else {
          final cloudReply = await _aiService.chatWithCoach(
            trimmed,
            geminiHistory,
            coachTone: coachTone,
            dietType: dietType,
            allergies: allergies,
            lang: lang,
            dailyContext: buildDailyContextBlock(contextInput),
          );
          aiReplyText = cloudReply.reply;
          suggestedDish = cloudReply.suggestedDish;
          usedEngine = 'cloud';
        }
      } catch (e) {
        // Local ET cloud ont échoué (quota épuisé, réseau, tous les modèles
        // Gemini en échec...) : on affiche l'erreur comme réponse du coach
        // plutôt que de laisser l'exception remonter sans réponse visible
        // (voir chat_provider.dart historique : sendMessage n'avait aucun
        // catch englobant avant ce correctif).
        aiReplyText = e.toString().replaceAll('Exception: ', '');
        suggestedDish = null;
      }
    }

    if (generation != _conversationGeneration) {
      // Conversation réinitialisée pendant l'appel réseau : ne pas
      // ressusciter ce message dans l'état ni en base après le reset.
      return;
    }

    String? imagePath;
    if (suggestedDish != null && suggestedDish.isNotEmpty) {
      final dataUri = await _aiService.getDishImage(suggestedDish);
      imagePath = await _uploadDishImage(dataUri);
    }
    final assistantMessage = _buildAssistantMessage(
      aiReplyText,
      imagePath: imagePath,
      engine: usedEngine,
    );

    state = AsyncData([...(state.value ?? currentMessages), assistantMessage]);
    await _storeMessage(assistantMessage);
  }

  /// Insère un message du coach sans intervention de l'utilisateur (ex :
  /// alerte de stagnation de poids) — même stockage que les réponses IA, pour
  /// que le message survive au redémarrage et à la synchro multi-appareil.
  Future<void> pushCoachMessage(String text) async {
    final message = _buildAssistantMessage(text);
    final current = state.value ?? const <ChatMessage>[];
    state = AsyncData([...current, message]);
    await _storeMessage(message);
  }

  // Longueur max du texte signalé conservé dans chat_reports.excerpt — borne
  // défensive, les réponses du coach sont limitées à 3 phrases en pratique.
  static const int _reportExcerptMaxLength = 1000;

  /// Signale [message] comme problématique (dangereux/incorrect/inapproprié/
  /// autre), exigence de modération Google Play. RLS (migration 0022_add_chat_reports.sql) n'autorise l'insertion
  /// que de ses propres signalements, jamais leur modification/suppression.
  /// `message.id` n'est pas la clé primaire de la ligne `chat_messages`
  /// correspondante (générée côté serveur) : `excerpt` conserve donc le
  /// texte signalé indépendamment de toute jointure.
  Future<void> reportMessage(
    ChatMessage message, {
    required String motif,
    String? commentaire,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      throw const AuthException('User must be authenticated to report a message.');
    }

    final excerpt = message.text.length > _reportExcerptMaxLength
        ? message.text.substring(0, _reportExcerptMaxLength)
        : message.text;

    await _supabase.from('chat_reports').insert({
      'user_id': user.id,
      'message_id': message.id,
      'motif': motif,
      'commentaire': commentaire,
      'excerpt': excerpt,
      'prompt_version': CoachPrompt.version,
      'engine': message.engine,
    });
  }

  Future<void> resetConversation() async {
    _conversationGeneration++;
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
      // `image_path` uniquement — jamais `image_url` : le base64 ne sert
      // qu'à l'appel Edge Function/génération d'image, jamais persisté en
      // base (voir migration 0019 et _uploadDishImage).
      await _supabase.from('chat_messages').insert({
        'user_id': user.id,
        'role': message.isUser ? 'user' : 'assistant',
        'text': message.text,
        'image_path': message.imagePath,
      });
    } catch (_) {
      // Hors-ligne : la persistance cloud échoue mais la conversation reste
      // utilisable localement (l'IA locale est justement conçue pour
      // fonctionner sans connexion) — seule la synchro cloud est perdue
      // pour ce message, pas la conversation en cours.
    }
  }

  /// Upload l'illustration générée par [AIService.getDishImage] (reçue en
  /// data URI) vers le bucket privé Storage `chat_images` et retourne son
  /// chemin ({user_id}/{uuid}.jpg). Le base64 décodé ici ne sert qu'à cet
  /// upload — jamais stocké tel quel en base (voir migration 0019). Retombe
  /// sur `null` en cas d'échec (décodage, upload...) plutôt que de faire
  /// échouer toute la réponse du coach.
  Future<String?> _uploadDishImage(String? dataUri) async {
    final bytes = decodeImageDataUri(dataUri);
    if (bytes == null) {
      return null;
    }
    final user = _supabase.auth.currentUser;
    if (user == null) {
      return null;
    }

    try {
      final path = '${user.id}/${_uuid.v4()}.jpg';
      await _supabase.storage.from('chat_images').uploadBinary(
            path,
            bytes,
            fileOptions: const FileOptions(contentType: 'image/jpeg'),
          );
      return path;
    } catch (_) {
      return null;
    }
  }

  /// Lit la langue courante à chaque appel (plutôt qu'une constante figée) :
  /// affiché à la fois au chargement initial et après un changement de
  /// langue suivi d'un resetConversation(), donc jamais figé dans la langue
  /// de démarrage de l'app.
  ChatMessage _buildWelcomeMessage() {
    final lang = ref.read(localeProvider).value?.languageCode ?? 'fr';
    return ChatMessage(
      id: 'welcome',
      text: lookupAppLocalizations(Locale(lang)).coachWelcomeMessage,
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

  ChatMessage _buildAssistantMessage(String text, {String? imagePath, String? engine}) {
    return ChatMessage(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      text: text,
      isUser: false,
      createdAt: DateTime.now(),
      imagePath: imagePath,
      engine: engine,
    );
  }

  /// Réponse fixe du filet de sécurité (voir [detectHealthRisk]) : jamais de
  /// chiffre ni de plan, uniquement une orientation vers un professionnel.
  /// Numéros d'urgence ajoutés uniquement pour le risque suicidaire, à
  /// vérifier manuellement (voir lib/config/emergency_contacts.dart).
  String _buildSafetyReply(HealthRiskCategory category, String lang) {
    final l10n = lookupAppLocalizations(Locale(lang));
    switch (category) {
      case HealthRiskCategory.selfHarm:
        return '${l10n.coachSafetyReplySelfHarm} ${EmergencyContacts.lineFor(lang)}';
      case HealthRiskCategory.eatingDisorder:
        return l10n.coachSafetyReplyEatingDisorder;
      case HealthRiskCategory.dangerousGoal:
        return l10n.coachSafetyReplyDangerousGoal;
    }
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
