import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ai_health_chef/local_db/app_database.dart';
import 'package:ai_health_chef/local_db/local_data_purge.dart';

void main() {
  group('wipeLocalDatabase', () {
    late AppDatabase db;

    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
    });

    tearDown(() async {
      await db.close();
    });

    test('empties meals, weight and hydration tables', () async {
      await db.into(db.localMeals).insert(
            LocalMealsCompanion.insert(
              id: 'meal-1',
              userId: 'user-1',
              name: 'Riz',
              totalKcal: 100,
              createdAt: DateTime.now(),
            ),
          );
      await db.into(db.weightEntries).insert(
            WeightEntriesCompanion.insert(
              id: 'weight-1',
              userId: 'user-1',
              weightKg: 70,
              recordedAt: DateTime.now(),
            ),
          );
      await db.into(db.hydrationEntries).insert(
            HydrationEntriesCompanion.insert(
              id: 'hydration-1',
              userId: 'user-1',
              amountMl: 250,
              recordedAt: DateTime.now(),
            ),
          );

      await wipeLocalDatabase(db);

      expect(await db.select(db.localMeals).get(), isEmpty);
      expect(await db.select(db.weightEntries).get(), isEmpty);
      expect(await db.select(db.hydrationEntries).get(), isEmpty);
    });
  });
}
