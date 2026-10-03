import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../local_db/app_database.dart';
import 'storage_image_service.dart';

/// Rassemble toutes les données personnelles de l'utilisateur connecté en un
/// unique JSON exportable (droit d'accès/portabilité RGPD, voir
/// docs/PRIVACY_POLICY_DRAFT.md section 7).
///
/// Chaque source distante est lue en best-effort (voir
/// [MealRepository.syncPendingMeals] pour le même principe) : une erreur
/// réseau sur une table n'empêche pas l'export des autres, l'app restant
/// utilisable hors ligne. Seul [_exportMeals] rapatrie explicitement les
/// lignes Supabase absentes en local : `weight_entries`/`hydration_entries`
/// sont déjà restaurées localement à chaque démarrage de l'app (voir
/// main.dart), alors que les repas n'ont qu'une synchronisation en poussée
/// (pas de restauration) — un repas créé sur un autre appareil n'existerait
/// donc pas en local sans ce rapatriement.
class DataExportService {
  DataExportService(
    this._db, [
    SupabaseClient? client,
    StorageImageService? storageImageService,
  ])  : _supabase = client ?? Supabase.instance.client,
        _storageImageService = storageImageService ?? StorageImageService(client);

  final AppDatabase _db;
  final SupabaseClient _supabase;
  final StorageImageService _storageImageService;

  static const schemaVersion = 1;

  Future<Map<String, dynamic>> buildExport() async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      throw Exception('Utilisateur non connecté.');
    }
    final userId = user.id;

    final profile = await _exportProfile(userId);
    final meals = await _exportMeals(userId);
    final weightEntries = await _exportWeightEntries(userId);
    final hydrationEntries = await _exportHydrationEntries(userId);
    final chatMessages = await _exportChatMessages(userId);
    final weeklyMealPlans = await _exportWeeklyMealPlans(userId);
    final localPrefs = await _exportLocalPreferences();

    await _resolveSignedUrls(
      profile: profile,
      meals: meals,
      weightEntries: weightEntries,
    );

    return {
      'schema_version': schemaVersion,
      'exported_at': DateTime.now().toUtc().toIso8601String(),
      'user_id': userId,
      'profile': profile,
      'meals': meals,
      'weight_entries': weightEntries,
      'hydration_entries': hydrationEntries,
      'chat_messages': chatMessages,
      'weekly_meal_plans': weeklyMealPlans,
      'shopping_list': localPrefs.shoppingList,
      'custom_reminders': localPrefs.customReminders,
      'consents': {
        'cloud_ai_consent_given': localPrefs.cloudAiConsentGiven,
        'accepted_terms_at': profile?['accepted_terms_at'],
        'accepted_terms_version': profile?['accepted_terms_version'],
      },
      'other_local_preferences': localPrefs.other,
    };
  }

  /// Supabase en priorité (colonnes complètes, y compris `email` et
  /// `accepted_terms_*`, absentes du modèle [UserProfile] côté app) ; sinon
  /// le cache local déjà écrit par `profileProvider` (même donnée brute).
  Future<Map<String, dynamic>?> _exportProfile(String userId) async {
    try {
      final row =
          await _supabase.from('profiles').select().eq('user_id', userId).maybeSingle();
      if (row != null) return Map<String, dynamic>.from(row);
    } catch (_) {}

    final prefs = await SharedPreferences.getInstance();
    final cached = prefs.getString('cached_profile_json');
    return cached == null ? null : Map<String, dynamic>.from(jsonDecode(cached) as Map);
  }

  Future<List<Map<String, dynamic>>> _exportMeals(String userId) async {
    final localRows =
        await (_db.select(_db.localMeals)..where((m) => m.userId.equals(userId))).get();
    final localIds = localRows.map((r) => r.id).toSet();

    final result = <Map<String, dynamic>>[
      for (final r in localRows)
        if (!r.isDeleted)
          <String, dynamic>{
            'id': r.id,
            'name': r.name,
            'total_kcal': r.totalKcal,
            'total_prot': r.totalProt,
            'total_gluc': r.totalGluc,
            'total_lip': r.totalLip,
            'total_fiber': r.totalFiber,
            'total_sugar': r.totalSugar,
            'total_sat_fat': r.totalSatFat,
            'ingredients': jsonDecode(r.ingredientsJson),
            'image_path': r.imagePath,
            'created_at': r.createdAt.toUtc().toIso8601String(),
            'synced': r.isSynced,
          },
    ];

    try {
      final remote = await _supabase.from('meals').select().eq('user_id', userId);
      for (final row in (remote as List).cast<Map<String, dynamic>>()) {
        if (localIds.contains(row['id'])) continue;
        result.add(<String, dynamic>{
          'id': row['id'],
          'name': row['name'],
          'total_kcal': row['total_kcal'],
          'total_prot': row['total_prot'],
          'total_gluc': row['total_gluc'],
          'total_lip': row['total_lip'],
          'total_fiber': row['total_fiber'],
          'total_sugar': row['total_sugar'],
          'total_sat_fat': row['total_sat_fat'],
          'ingredients': row['ingredients'],
          'image_path': row['image_path'],
          'created_at': row['created_at'],
          'synced': true,
        });
      }
    } catch (_) {
      // Hors ligne : export limité aux repas déjà en local.
    }
    return result;
  }

  Future<List<Map<String, dynamic>>> _exportWeightEntries(String userId) async {
    final rows =
        await (_db.select(_db.weightEntries)..where((w) => w.userId.equals(userId))).get();
    return [
      for (final r in rows)
        <String, dynamic>{
          'id': r.id,
          'weight_kg': r.weightKg,
          'recorded_at': r.recordedAt.toUtc().toIso8601String(),
          'image_path': r.imagePath,
        },
    ];
  }

  Future<List<Map<String, dynamic>>> _exportHydrationEntries(String userId) async {
    final rows = await (_db.select(_db.hydrationEntries)
          ..where((h) => h.userId.equals(userId) & h.isDeleted.equals(false)))
        .get();
    return [
      for (final r in rows)
        <String, dynamic>{
          'id': r.id,
          'amount_ml': r.amountMl,
          'recorded_at': r.recordedAt.toUtc().toIso8601String(),
        },
    ];
  }

  /// Paginée (1000 lignes/page, limite par défaut de l'API PostgREST) :
  /// seule table dont l'historique peut raisonnablement dépasser cette
  /// limite au fil du temps.
  Future<List<Map<String, dynamic>>> _exportChatMessages(String userId) async {
    const pageSize = 1000;
    final result = <Map<String, dynamic>>[];
    try {
      var offset = 0;
      while (true) {
        final page = await _supabase
            .from('chat_messages')
            .select()
            .eq('user_id', userId)
            .order('created_at')
            .range(offset, offset + pageSize - 1);
        result.addAll((page as List).cast<Map<String, dynamic>>());
        if (page.length < pageSize) break;
        offset += pageSize;
      }
    } catch (_) {
      // Hors ligne : pas d'historique de chat conservé en local.
    }
    return result;
  }

  Future<List<Map<String, dynamic>>> _exportWeeklyMealPlans(String userId) async {
    try {
      final rows = await _supabase.from('weekly_meal_plans').select().eq('user_id', userId);
      return (rows as List).cast<Map<String, dynamic>>();
    } catch (_) {
      return [];
    }
  }

  Future<_LocalPrefsExport> _exportLocalPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    final all = <String, Object?>{for (final key in prefs.getKeys()) key: prefs.get(key)};

    List<dynamic> decodeList(String key) {
      final raw = all.remove(key) as String?;
      if (raw == null || raw.isEmpty) return const [];
      return jsonDecode(raw) as List<dynamic>;
    }

    final shoppingList = decodeList('shopping_list_items');
    final customReminders = decodeList('custom_reminders');
    final cloudAiConsentGiven = all.remove('cloud_ai_consent_given') as bool? ?? false;
    all.remove('custom_reminders_restored'); // flag interne, pas une donnée utilisateur
    all.remove('cached_profile_json'); // doublon du profil déjà exporté ci-dessus

    return _LocalPrefsExport(
      shoppingList: shoppingList,
      customReminders: customReminders,
      cloudAiConsentGiven: cloudAiConsentGiven,
      other: all,
    );
  }

  /// Ajoute une URL signée fraîche (1h, voir [StorageImageService]) à côté
  /// de chaque `image_path`/`avatar_path` non nul, pour une consultation
  /// immédiate du fichier sans requête supplémentaire côté lecteur de
  /// l'export.
  Future<void> _resolveSignedUrls({
    required Map<String, dynamic>? profile,
    required List<Map<String, dynamic>> meals,
    required List<Map<String, dynamic>> weightEntries,
  }) async {
    Future<void> resolveInto(String bucket, Map<String, dynamic> item, String pathKey) async {
      final path = item[pathKey] as String?;
      if (path == null) return;
      item['photo_signed_url'] = await _storageImageService.resolve(bucket, path);
    }

    await Future.wait([
      if (profile != null) resolveInto('avatars', profile, 'avatar_path'),
      for (final m in meals) resolveInto('meal_photos', m, 'image_path'),
      for (final w in weightEntries) resolveInto('weight_photos', w, 'image_path'),
    ]);
  }
}

class _LocalPrefsExport {
  _LocalPrefsExport({
    required this.shoppingList,
    required this.customReminders,
    required this.cloudAiConsentGiven,
    required this.other,
  });

  final List<dynamic> shoppingList;
  final List<dynamic> customReminders;
  final bool cloudAiConsentGiven;
  final Map<String, Object?> other;
}
