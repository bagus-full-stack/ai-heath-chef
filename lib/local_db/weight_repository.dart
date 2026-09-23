import 'package:drift/drift.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import 'app_database.dart';

const _uuid = Uuid();

/// Historique du poids, purement local (voir [WeightEntries]) — le poids
/// courant du profil (`profiles.current_weight`, synchronisé via
/// `AuthService.upsertProfile`) reste la source de vérité pour les calculs
/// (IMC, cibles caloriques) ; cette table ne sert qu'à la courbe de
/// progression.
class WeightRepository {
  WeightRepository(this._db);

  final AppDatabase _db;
  SupabaseClient get _supabase => Supabase.instance.client;

  Future<void> addEntry(double weightKg) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    await _db.into(_db.weightEntries).insert(WeightEntriesCompanion.insert(
          id: _uuid.v4(),
          userId: user.id,
          weightKg: weightKg,
          recordedAt: DateTime.now(),
        ));
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
}
