import 'dart:async';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../utils/photo_storage.dart';
import 'app_database.dart';

const _uuid = Uuid();

/// Historique du poids : écrit d'abord en local (utilisable hors ligne), puis
/// synchronisé vers la table Supabase `weight_entries` — même principe que
/// [MealRepository], en plus simple (append-only, jamais de suppression
/// depuis l'app). Le poids courant du profil (`profiles.current_weight`,
/// synchronisé via `AuthService.upsertProfile`) reste la source de vérité
/// pour les calculs (IMC, cibles caloriques) ; cette table ne sert qu'à la
/// courbe de progression et à sa restauration après désinstallation/sur un
/// nouvel appareil.
class WeightRepository {
  /// [supabaseClient] n'est à fournir que pour les tests (voir
  /// test/local_db/weight_repository_test.dart).
  WeightRepository(this._db, [SupabaseClient? supabaseClient])
      : _supabase = supabaseClient ?? Supabase.instance.client;

  final AppDatabase _db;
  final SupabaseClient _supabase;

  /// [photoPath] est le chemin d'une photo de progression tout juste prise
  /// (caméra/galerie), optionnelle — compressée et copiée dans le stockage
  /// permanent de l'app avant d'être uploadée par [syncEntries].
  Future<void> addEntry(double weightKg, {String? photoPath}) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    final id = _uuid.v4();
    final localImagePath = photoPath == null
        ? null
        : await compressAndStorePhoto('weight_photos', id, photoPath);

    await _db.into(_db.weightEntries).insert(WeightEntriesCompanion.insert(
          id: id,
          userId: user.id,
          weightKg: weightKg,
          recordedAt: DateTime.now(),
          localImagePath: Value(localImagePath),
        ));

    unawaited(syncEntries());
  }

  /// Pesées des [days] derniers jours (aujourd'hui inclus), de la plus
  /// ancienne à la plus récente.
  Future<List<WeightEntry>> getEntriesSince(int days) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return [];

    final startDate = DateTime.now().subtract(Duration(days: days));
    final query = _db.select(_db.weightEntries)
      ..where((w) => w.userId.equals(user.id) & w.recordedAt.isBiggerOrEqualValue(startDate))
      ..orderBy([(w) => OrderingTerm.asc(w.recordedAt)]);

    return query.get();
  }

  /// Pousse les pesées locales pas encore synchronisées, puis rapatrie celles
  /// enregistrées depuis un autre appareil (absentes localement) : restaure
  /// l'historique après une désinstallation et le partage entre appareils.
  /// Best-effort, comme [MealRepository.syncPendingMeals].
  Future<void> syncEntries() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    final pending =
        await (_db.select(_db.weightEntries)..where((w) => w.isSynced.equals(false))).get();

    for (final row in pending) {
      try {
        var imagePath = row.imagePath;
        if (imagePath == null && row.localImagePath != null) {
          imagePath = await _uploadPhoto(user.id, row.id, row.localImagePath!);
        }

        await _supabase.from('weight_entries').upsert({
          'id': row.id,
          'user_id': row.userId,
          'weight_kg': row.weightKg,
          'recorded_at': row.recordedAt.toUtc().toIso8601String(),
          'image_path': imagePath,
        });
        await (_db.update(_db.weightEntries)..where((w) => w.id.equals(row.id)))
            .write(WeightEntriesCompanion(isSynced: const Value(true), imagePath: Value(imagePath)));
      } catch (_) {
        // Réessayé au prochain appel (voir main.dart : démarrage + retour réseau).
      }
    }

    try {
      final localIds = await (_db.selectOnly(_db.weightEntries)..addColumns([_db.weightEntries.id]))
          .map((row) => row.read(_db.weightEntries.id)!)
          .get();

      final remote = await _supabase.from('weight_entries').select().eq('user_id', user.id);
      final missing = (remote as List).where((row) => !localIds.contains(row['id'] as String));

      for (final row in missing) {
        await _db.into(_db.weightEntries).insert(
              WeightEntriesCompanion.insert(
                id: row['id'] as String,
                userId: user.id,
                weightKg: (row['weight_kg'] as num).toDouble(),
                recordedAt: DateTime.parse(row['recorded_at'] as String),
                isSynced: const Value(true),
                imagePath: Value(row['image_path'] as String?),
              ),
              mode: InsertMode.insertOrIgnore,
            );
      }
    } catch (_) {
      // Pas de réseau ou erreur serveur : la restauration sera retentée au
      // prochain appel.
    }
  }

  Future<String> _uploadPhoto(String userId, String entryId, String localPath) async {
    final bytes = await File(localPath).readAsBytes();
    final storagePath = '$userId/$entryId.jpg';
    await _supabase.storage.from('weight_photos').uploadBinary(
          storagePath,
          bytes,
          fileOptions: const FileOptions(contentType: 'image/jpeg', upsert: true),
        );
    return storagePath;
  }
}
