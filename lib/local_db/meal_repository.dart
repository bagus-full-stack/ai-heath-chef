import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../models/ingredient.dart';
import '../models/meal.dart';
import 'app_database.dart';

const _uuid = Uuid();

/// Préfixe utilisé pour marquer un [Meal.imageUrl] comme un chemin de
/// fichier local (photo pas encore uploadée) plutôt qu'une URL Supabase —
/// évite les soucis d'encodage d'un `Uri.file()` sur un chemin Windows/
/// Android, on stocke le chemin brut derrière ce préfixe.
const localImagePrefix = 'local://';

/// Source de vérité pour les repas loggés : écrit toujours en local
/// d'abord (utilisable hors ligne), puis pousse vers Supabase dès que
/// possible. Remplace les méthodes repas de `DatabaseService`
/// (`saveMeal`/`getTodayMeals`/`uploadMealPhoto`), qui écrivaient
/// directement dans Supabase sans aucune persistance locale.
class MealRepository {
  MealRepository(this._db);

  final AppDatabase _db;
  SupabaseClient get _supabase => Supabase.instance.client;

  /// Sauvegarde un repas en local (utilisable immédiatement, même hors
  /// ligne), puis tente une synchronisation immédiate — sans faire échouer
  /// l'appel si celle-ci échoue, elle sera retentée via [syncPendingMeals].
  Future<void> saveMeal(
    List<Ingredient> ingredients,
    String mealName, {
    String? imagePath,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      throw Exception('Vous devez être connecté pour sauvegarder un repas.');
    }

    final id = _uuid.v4();
    final totalKcal = ingredients.fold<int>(0, (sum, i) => sum + i.currentKcal);
    final totalProt = ingredients.fold<double>(0, (sum, i) => sum + i.currentProt);
    final totalGluc = ingredients.fold<double>(0, (sum, i) => sum + i.currentGluc);
    final totalLip = ingredients.fold<double>(0, (sum, i) => sum + i.currentLip);
    final totalFiber = ingredients.fold<double>(0, (sum, i) => sum + i.currentFiber);
    final totalSugar = ingredients.fold<double>(0, (sum, i) => sum + i.currentSugar);
    final totalSatFat = ingredients.fold<double>(0, (sum, i) => sum + i.currentSatFat);

    final localImagePath = imagePath == null ? null : await _storeLocalPhoto(id, imagePath);

    await _db.into(_db.localMeals).insert(LocalMealsCompanion.insert(
          id: id,
          userId: user.id,
          name: mealName,
          totalKcal: totalKcal,
          totalProt: Value(totalProt),
          totalGluc: Value(totalGluc),
          totalLip: Value(totalLip),
          totalFiber: Value(totalFiber),
          totalSugar: Value(totalSugar),
          totalSatFat: Value(totalSatFat),
          ingredientsJson: Value(jsonEncode(ingredients.map((i) => i.toJson()).toList())),
          localImagePath: Value(localImagePath),
          createdAt: DateTime.now(),
        ));

    // Meilleur effort : autant synchroniser tout de suite si le réseau est
    // là plutôt que d'attendre le prochain déclenchement (retour réseau).
    unawaited(syncPendingMeals());
  }

  /// Compresse la photo et la copie dans le stockage permanent de l'app
  /// (survit au redémarrage), sous un nom dérivé de l'id du repas.
  Future<String> _storeLocalPhoto(String mealId, String sourcePath) async {
    final compressedBytes = await FlutterImageCompress.compressWithFile(
      sourcePath,
      minWidth: 800,
      minHeight: 800,
      quality: 70,
    );
    if (compressedBytes == null) {
      throw Exception("Impossible de compresser l'image.");
    }

    final docsDir = await getApplicationDocumentsDirectory();
    final photosDir = Directory('${docsDir.path}/meal_photos');
    await photosDir.create(recursive: true);
    final file = File('${photosDir.path}/$mealId.jpg');
    await file.writeAsBytes(compressedBytes);
    return file.path;
  }

  /// Repas du jour, lus depuis la base locale (jamais directement depuis
  /// Supabase) : reste consultable hors ligne à tout moment.
  Future<List<Meal>> getTodayMeals() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return [];

    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final query = _db.select(_db.localMeals)
      ..where((m) =>
          m.userId.equals(user.id) &
          m.isDeleted.equals(false) &
          m.createdAt.isBiggerOrEqualValue(startOfDay) &
          m.createdAt.isSmallerThanValue(endOfDay))
      ..orderBy([(m) => OrderingTerm.desc(m.createdAt)]);

    final rows = await query.get();
    return rows.map(_toMeal).toList();
  }

  /// Repas des [days] derniers jours (aujourd'hui inclus), du plus ancien
  /// au plus récent — utilisé pour les tendances nutritionnelles.
  Future<List<Meal>> getMealsSince(int days) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return [];

    final now = DateTime.now();
    final startDate = DateTime(now.year, now.month, now.day).subtract(Duration(days: days - 1));

    final query = _db.select(_db.localMeals)
      ..where((m) =>
          m.userId.equals(user.id) &
          m.isDeleted.equals(false) &
          m.createdAt.isBiggerOrEqualValue(startDate))
      ..orderBy([(m) => OrderingTerm.asc(m.createdAt)]);

    final rows = await query.get();
    return rows.map(_toMeal).toList();
  }

  Meal _toMeal(LocalMeal row) {
    return Meal(
      id: row.id,
      name: row.name,
      totalKcal: row.totalKcal,
      totalProt: row.totalProt,
      totalGluc: row.totalGluc,
      totalLip: row.totalLip,
      totalFiber: row.totalFiber,
      totalSugar: row.totalSugar,
      totalSatFat: row.totalSatFat,
      imageUrl: row.imageUrl ?? (row.localImagePath != null ? '$localImagePrefix${row.localImagePath}' : null),
      createdAt: row.createdAt,
    );
  }

  /// Marque un repas comme supprimé localement — répercuté sur Supabase à
  /// la prochaine synchronisation plutôt qu'effacé immédiatement, pour ne
  /// pas perdre la suppression si elle survient hors ligne.
  Future<void> deleteMeal(String id) async {
    await (_db.update(_db.localMeals)..where((m) => m.id.equals(id)))
        .write(const LocalMealsCompanion(isDeleted: Value(true)));
    unawaited(syncPendingMeals());
  }

  /// Pousse vers Supabase tous les repas locaux en attente (créations et
  /// suppressions). Best-effort : une ligne qui échoue (pas de réseau,
  /// erreur serveur...) est simplement retentée au prochain appel, sans
  /// bloquer la synchronisation des autres.
  Future<void> syncPendingMeals() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    final pending = await (_db.select(_db.localMeals)
          ..where((m) =>
              m.userId.equals(user.id) & (m.isSynced.equals(false) | m.isDeleted.equals(true))))
        .get();

    for (final row in pending) {
      try {
        if (row.isDeleted) {
          if (row.isSynced) {
            await _supabase.from('meals').delete().eq('id', row.id);
          }
          if (row.localImagePath != null) {
            final file = File(row.localImagePath!);
            if (await file.exists()) await file.delete();
          }
          await (_db.delete(_db.localMeals)..where((m) => m.id.equals(row.id))).go();
          continue;
        }

        var imageUrl = row.imageUrl;
        if (imageUrl == null && row.localImagePath != null) {
          imageUrl = await _uploadPhoto(user.id, row.id, row.localImagePath!);
        }

        await _supabase.from('meals').upsert({
          'id': row.id,
          'user_id': row.userId,
          'name': row.name,
          'total_kcal': row.totalKcal,
          'total_prot': row.totalProt,
          'total_gluc': row.totalGluc,
          'total_lip': row.totalLip,
          'total_fiber': row.totalFiber,
          'total_sugar': row.totalSugar,
          'total_sat_fat': row.totalSatFat,
          'ingredients': jsonDecode(row.ingredientsJson),
          'image_url': imageUrl,
          'created_at': row.createdAt.toUtc().toIso8601String(),
        });

        await (_db.update(_db.localMeals)..where((m) => m.id.equals(row.id))).write(
          LocalMealsCompanion(isSynced: const Value(true), imageUrl: Value(imageUrl)),
        );
      } catch (_) {
        // Échec (réseau, serveur...) : ce repas reste en attente et sera
        // retenté au prochain appel de syncPendingMeals.
      }
    }
  }

  Future<String> _uploadPhoto(String userId, String mealId, String localPath) async {
    final bytes = await File(localPath).readAsBytes();
    final storagePath = '$userId/$mealId.jpg';
    await _supabase.storage.from('meal_photos').uploadBinary(
          storagePath,
          bytes,
          fileOptions: const FileOptions(contentType: 'image/jpeg', upsert: true),
        );
    return _supabase.storage.from('meal_photos').getPublicUrl(storagePath);
  }
}
