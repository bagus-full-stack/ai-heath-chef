import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:path_provider/path_provider.dart';

part 'app_database.g.dart';

/// Repas loggés localement, en miroir de la table Supabase `meals`
/// (`supabase/migrations/0001_init_schema.sql` + `0006_add_meal_photos.sql`).
/// [id] est un uuid v4 généré côté client (voir `uuid` dans pubspec) plutôt
/// que par Postgres, pour que le même id serve à la fois de clé locale et de
/// clé distante une fois le repas synchronisé.
class LocalMeals extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();
  TextColumn get name => text()();
  IntColumn get totalKcal => integer()();
  RealColumn get totalProt => real().withDefault(const Constant(0))();
  RealColumn get totalGluc => real().withDefault(const Constant(0))();
  RealColumn get totalLip => real().withDefault(const Constant(0))();
  RealColumn get totalFiber => real().withDefault(const Constant(0))();
  RealColumn get totalSugar => real().withDefault(const Constant(0))();
  RealColumn get totalSatFat => real().withDefault(const Constant(0))();

  /// Snapshot des ingrédients, encodé en JSON (même contenu que la colonne
  /// jsonb `ingredients` côté Supabase).
  TextColumn get ingredientsJson => text().withDefault(const Constant('[]'))();

  /// URL publique une fois la photo uploadée vers Supabase Storage. Null
  /// tant que l'upload n'a pas eu lieu (ou si le repas n'a pas de photo).
  TextColumn get imageUrl => text().nullable()();

  /// Chemin du fichier photo compressé sur le disque local, en attente
  /// d'upload. Distinct de [imageUrl] : permet d'afficher la photo
  /// immédiatement même hors ligne, avant toute synchronisation.
  TextColumn get localImagePath => text().nullable()();

  DateTimeColumn get createdAt => dateTime()();

  /// Faux tant que ce repas (création, ou suppression via [isDeleted]) n'a
  /// pas été répercuté sur Supabase — c'est ce flag qui pilotera la file de
  /// synchronisation à l'étape suivante.
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();

  /// Suppression différée : on marque plutôt que d'effacer la ligne
  /// immédiatement, pour pouvoir répercuter la suppression sur Supabase une
  /// fois la connexion revenue.
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

/// Pesées enregistrées localement, pour la courbe de progression de l'écran
/// "Suivi du poids", synchronisées vers la table Supabase `weight_entries`
/// (voir [WeightRepository]) — append-only, jamais modifiées ni supprimées
/// depuis l'app, donc pas de colonne `isDeleted` ici (contrairement à
/// [LocalMeals]/[HydrationEntries] qui exposent une suppression).
class WeightEntries extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();
  RealColumn get weightKg => real()();
  DateTimeColumn get recordedAt => dateTime()();

  /// Faux tant que cette pesée n'a pas été poussée vers Supabase.
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

/// Prises d'eau enregistrées localement (horodatées, en ml), pour la carte
/// "Hydratation" du dashboard, synchronisées vers la table Supabase
/// `hydration_entries` (voir [HydrationRepository]).
class HydrationEntries extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();
  IntColumn get amountMl => integer()();
  DateTimeColumn get recordedAt => dateTime()();

  /// Faux tant que cette entrée n'a pas été poussée vers Supabase.
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();

  /// Suppression différée (voir [LocalMeals.isDeleted]) : le bouton "Annuler"
  /// de la snackbar peut être tapé avant la fin de la synchronisation.
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

@DriftDatabase(tables: [LocalMeals, WeightEntries, HydrationEntries])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _openConnection());

  @override
  int get schemaVersion => 5;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            await m.addColumn(localMeals, localMeals.totalFiber);
            await m.addColumn(localMeals, localMeals.totalSugar);
            await m.addColumn(localMeals, localMeals.totalSatFat);
          }
          if (from < 3) {
            await m.createTable(weightEntries);
          }
          if (from < 4) {
            await m.createTable(hydrationEntries);
          }
          if (from < 5) {
            await m.addColumn(weightEntries, weightEntries.isSynced);
            await m.addColumn(hydrationEntries, hydrationEntries.isSynced);
            await m.addColumn(hydrationEntries, hydrationEntries.isDeleted);
          }
        },
      );

  static QueryExecutor _openConnection() {
    return driftDatabase(
      name: 'ai_health_chef',
      native: const DriftNativeOptions(
        databaseDirectory: getApplicationSupportDirectory,
      ),
    );
  }
}
