import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite3;

import 'package:ai_health_chef/local_db/app_database.dart';

/// Construit la base au schéma d'une ancienne version (SQL brut + exactement
/// les colonnes qui existaient alors), pour vérifier que
/// [AppDatabase.migration] (onUpgrade) amène au schéma actuel sans perte de
/// données. Alternative volontairement plus légère que
/// `drift_dev schema generate/validate` (qui demanderait un dossier de
/// snapshots versionnés en plus du CI) : `NativeDatabase.opened` est le
/// mécanisme que drift utilise lui-même pour ses tests de migration
/// (cf. doc officielle « Verifying migrations »).
AppDatabase openAtVersion(sqlite3.Database raw, int version) {
  raw.userVersion = version;
  return AppDatabase(NativeDatabase.opened(raw));
}

void main() {
  test('v1 -> v6: keeps existing meals and backfills the new nutrient columns', () async {
    final raw = sqlite3.sqlite3.openInMemory();
    raw.execute('''
      CREATE TABLE local_meals (
        id TEXT NOT NULL,
        user_id TEXT NOT NULL,
        name TEXT NOT NULL,
        total_kcal INTEGER NOT NULL,
        total_prot REAL NOT NULL DEFAULT 0,
        total_gluc REAL NOT NULL DEFAULT 0,
        total_lip REAL NOT NULL DEFAULT 0,
        ingredients_json TEXT NOT NULL DEFAULT '[]',
        image_url TEXT,
        local_image_path TEXT,
        created_at INTEGER NOT NULL,
        is_synced INTEGER NOT NULL DEFAULT 0,
        is_deleted INTEGER NOT NULL DEFAULT 0,
        PRIMARY KEY (id)
      );
    ''');
    raw.execute('''
      INSERT INTO local_meals (id, user_id, name, total_kcal, created_at)
      VALUES ('meal-1', 'user-1', 'Riz', 300, 1700000000);
    ''');

    final db = openAtVersion(raw, 1);
    final meals = await db.select(db.localMeals).get();
    expect(meals, hasLength(1));
    expect(meals.single.name, 'Riz');
    expect(meals.single.totalFiber, 0);
    expect(meals.single.totalSugar, 0);
    expect(meals.single.totalSatFat, 0);

    // weight_entries/hydration_entries didn't exist at v1: created along the way.
    expect(await db.select(db.weightEntries).get(), isEmpty);
    expect(await db.select(db.hydrationEntries).get(), isEmpty);
    expect(raw.userVersion, 6);
    await db.close();
  });

  test('v4 -> v6: keeps an existing weight/hydration entry and backfills isSynced', () async {
    final raw = sqlite3.sqlite3.openInMemory();
    raw.execute('''
      CREATE TABLE local_meals (
        id TEXT NOT NULL, user_id TEXT NOT NULL, name TEXT NOT NULL,
        total_kcal INTEGER NOT NULL,
        total_prot REAL NOT NULL DEFAULT 0, total_gluc REAL NOT NULL DEFAULT 0,
        total_lip REAL NOT NULL DEFAULT 0, total_fiber REAL NOT NULL DEFAULT 0,
        total_sugar REAL NOT NULL DEFAULT 0, total_sat_fat REAL NOT NULL DEFAULT 0,
        ingredients_json TEXT NOT NULL DEFAULT '[]',
        image_url TEXT, local_image_path TEXT, created_at INTEGER NOT NULL,
        is_synced INTEGER NOT NULL DEFAULT 0, is_deleted INTEGER NOT NULL DEFAULT 0,
        PRIMARY KEY (id)
      );
      CREATE TABLE weight_entries (
        id TEXT NOT NULL, user_id TEXT NOT NULL, weight_kg REAL NOT NULL,
        recorded_at INTEGER NOT NULL, PRIMARY KEY (id)
      );
      CREATE TABLE hydration_entries (
        id TEXT NOT NULL, user_id TEXT NOT NULL, amount_ml INTEGER NOT NULL,
        recorded_at INTEGER NOT NULL, PRIMARY KEY (id)
      );
    ''');
    raw.execute('''
      INSERT INTO weight_entries (id, user_id, weight_kg, recorded_at)
      VALUES ('w1', 'user-1', 70.5, 1700000000);
      INSERT INTO hydration_entries (id, user_id, amount_ml, recorded_at)
      VALUES ('h1', 'user-1', 250, 1700000000);
    ''');

    final db = openAtVersion(raw, 4);
    final weights = await db.select(db.weightEntries).get();
    expect(weights, hasLength(1));
    expect(weights.single.weightKg, 70.5);
    expect(weights.single.isSynced, isFalse); // backfilled default
    expect(weights.single.imageUrl, null);

    final hydration = await db.select(db.hydrationEntries).get();
    expect(hydration, hasLength(1));
    expect(hydration.single.amountMl, 250);
    expect(hydration.single.isSynced, isFalse);
    expect(hydration.single.isDeleted, isFalse);
    await db.close();
  });

  test('v5 -> v6: keeps an already-synced weight entry and backfills photo columns', () async {
    final raw = sqlite3.sqlite3.openInMemory();
    raw.execute('''
      CREATE TABLE local_meals (
        id TEXT NOT NULL, user_id TEXT NOT NULL, name TEXT NOT NULL,
        total_kcal INTEGER NOT NULL,
        total_prot REAL NOT NULL DEFAULT 0, total_gluc REAL NOT NULL DEFAULT 0,
        total_lip REAL NOT NULL DEFAULT 0, total_fiber REAL NOT NULL DEFAULT 0,
        total_sugar REAL NOT NULL DEFAULT 0, total_sat_fat REAL NOT NULL DEFAULT 0,
        ingredients_json TEXT NOT NULL DEFAULT '[]',
        image_url TEXT, local_image_path TEXT, created_at INTEGER NOT NULL,
        is_synced INTEGER NOT NULL DEFAULT 0, is_deleted INTEGER NOT NULL DEFAULT 0,
        PRIMARY KEY (id)
      );
      CREATE TABLE weight_entries (
        id TEXT NOT NULL, user_id TEXT NOT NULL, weight_kg REAL NOT NULL,
        recorded_at INTEGER NOT NULL, is_synced INTEGER NOT NULL DEFAULT 0,
        PRIMARY KEY (id)
      );
      CREATE TABLE hydration_entries (
        id TEXT NOT NULL, user_id TEXT NOT NULL, amount_ml INTEGER NOT NULL,
        recorded_at INTEGER NOT NULL, is_synced INTEGER NOT NULL DEFAULT 0,
        is_deleted INTEGER NOT NULL DEFAULT 0, PRIMARY KEY (id)
      );
    ''');
    raw.execute('''
      INSERT INTO weight_entries (id, user_id, weight_kg, recorded_at, is_synced)
      VALUES ('w1', 'user-1', 70.5, 1700000000, 1);
    ''');

    final db = openAtVersion(raw, 5);
    final weights = await db.select(db.weightEntries).get();
    expect(weights, hasLength(1));
    expect(weights.single.isSynced, isTrue); // not clobbered by the backfill
    expect(weights.single.imageUrl, null);
    expect(weights.single.localImagePath, null);
    await db.close();
  });
}
