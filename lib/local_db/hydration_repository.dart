import 'dart:async';

import 'package:drift/drift.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import 'app_database.dart';

const _uuid = Uuid();

/// Prises d'eau : écrites d'abord en local (utilisable hors ligne), puis
/// synchronisées vers la table Supabase `hydration_entries` — même principe
/// que [MealRepository] (soft-delete pour ne pas perdre une suppression
/// survenue hors ligne).
class HydrationRepository {
  HydrationRepository(this._db);

  final AppDatabase _db;
  SupabaseClient get _supabase => Supabase.instance.client;

  /// Enregistre une prise d'eau et retourne son id, pour permettre l'action
  /// "Annuler" de la snackbar de confirmation.
  Future<String?> addEntry(int amountMl) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return null;

    final id = _uuid.v4();
    await _db.into(_db.hydrationEntries).insert(HydrationEntriesCompanion.insert(
          id: id,
          userId: user.id,
          amountMl: amountMl,
          recordedAt: DateTime.now(),
        ));

    unawaited(syncEntries());
    return id;
  }

  /// Marque une entrée comme supprimée localement — répercuté sur Supabase à
  /// la prochaine synchronisation (voir [MealRepository.deleteMeal]).
  Future<void> deleteEntry(String id) async {
    await (_db.update(_db.hydrationEntries)..where((h) => h.id.equals(id)))
        .write(const HydrationEntriesCompanion(isDeleted: Value(true)));
    unawaited(syncEntries());
  }

  Future<List<HydrationEntry>> getTodayEntries() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return [];

    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final query = _db.select(_db.hydrationEntries)
      ..where((h) =>
          h.userId.equals(user.id) &
          h.isDeleted.equals(false) &
          h.recordedAt.isBiggerOrEqualValue(startOfDay))
      ..orderBy([(h) => OrderingTerm.asc(h.recordedAt)]);

    return query.get();
  }

  /// Pousse les entrées locales en attente (créations et suppressions), puis
  /// rapatrie celles enregistrées depuis un autre appareil — restaure
  /// l'historique du jour après une désinstallation et le partage entre
  /// appareils. Best-effort, comme [MealRepository.syncPendingMeals].
  Future<void> syncEntries() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    final pending = await (_db.select(_db.hydrationEntries)
          ..where((h) =>
              h.userId.equals(user.id) & (h.isSynced.equals(false) | h.isDeleted.equals(true))))
        .get();

    for (final row in pending) {
      try {
        if (row.isDeleted) {
          if (row.isSynced) {
            await _supabase.from('hydration_entries').delete().eq('id', row.id);
          }
          await (_db.delete(_db.hydrationEntries)..where((h) => h.id.equals(row.id))).go();
          continue;
        }

        await _supabase.from('hydration_entries').upsert({
          'id': row.id,
          'user_id': row.userId,
          'amount_ml': row.amountMl,
          'recorded_at': row.recordedAt.toUtc().toIso8601String(),
        });
        await (_db.update(_db.hydrationEntries)..where((h) => h.id.equals(row.id)))
            .write(const HydrationEntriesCompanion(isSynced: Value(true)));
      } catch (_) {
        // Réessayé au prochain appel (voir main.dart : démarrage + retour réseau).
      }
    }

    try {
      final localIds =
          await (_db.selectOnly(_db.hydrationEntries)..addColumns([_db.hydrationEntries.id]))
              .map((row) => row.read(_db.hydrationEntries.id)!)
              .get();

      final remote = await _supabase.from('hydration_entries').select().eq('user_id', user.id);
      final missing = (remote as List).where((row) => !localIds.contains(row['id'] as String));

      for (final row in missing) {
        await _db.into(_db.hydrationEntries).insert(
              HydrationEntriesCompanion.insert(
                id: row['id'] as String,
                userId: user.id,
                amountMl: (row['amount_ml'] as num).toInt(),
                recordedAt: DateTime.parse(row['recorded_at'] as String),
                isSynced: const Value(true),
              ),
              mode: InsertMode.insertOrIgnore,
            );
      }
    } catch (_) {
      // Pas de réseau ou erreur serveur : la restauration sera retentée au
      // prochain appel.
    }
  }
}
