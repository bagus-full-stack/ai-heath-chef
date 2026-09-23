import 'package:drift/drift.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import 'app_database.dart';

const _uuid = Uuid();

/// Prises d'eau, purement local (voir [HydrationEntries]) — pas de cible
/// personnalisée : la carte "Hydratation" du dashboard utilise un objectif
/// fixe (voir dashboard_screen.dart).
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
    return id;
  }

  Future<void> deleteEntry(String id) async {
    await (_db.delete(_db.hydrationEntries)..where((h) => h.id.equals(id))).go();
  }

  Future<List<HydrationEntry>> getTodayEntries() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return [];

    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final query = _db.select(_db.hydrationEntries)
      ..where((h) => h.userId.equals(user.id) & h.recordedAt.isBiggerOrEqualValue(startOfDay))
      ..orderBy([(h) => OrderingTerm.asc(h.recordedAt)]);

    return query.get();
  }
}
