import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

import 'package:ai_health_chef/local_db/app_database.dart';
import 'package:ai_health_chef/local_db/meal_repository.dart';

import 'fake_supabase.dart';

const _userId = 'user-1';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  Future<void> insertPendingMeal(String id, {bool isSynced = false}) {
    return db.into(db.localMeals).insert(
          LocalMealsCompanion.insert(
            id: id,
            userId: _userId,
            name: 'Riz',
            totalKcal: 100,
            isSynced: Value(isSynced),
            createdAt: DateTime.now(),
          ),
        );
  }

  group('syncPendingMeals', () {
    test('pushes an offline meal and marks it synced', () async {
      await insertPendingMeal('meal-1');
      var upsertCalls = 0;
      final repo = MealRepository(
        db,
        await fakeAuthenticatedClient(_userId, (request) async {
          if (request.method == 'POST' && request.url.path.endsWith('/rest/v1/meals')) {
            upsertCalls++;
            return jsonResponse(request, [], status: 201);
          }
          return http.Response('not found', 404);
        }),
      );

      await repo.syncPendingMeals();

      expect(upsertCalls, 1);
      final row = await (db.select(db.localMeals)..where((m) => m.id.equals('meal-1'))).getSingle();
      expect(row.isSynced, isTrue);
    });

    test('is idempotent: a second sync does not re-push an already-synced meal', () async {
      await insertPendingMeal('meal-1');
      var upsertCalls = 0;
      final repo = MealRepository(
        db,
        await fakeAuthenticatedClient(_userId, (request) async {
          if (request.method == 'POST' && request.url.path.endsWith('/rest/v1/meals')) {
            upsertCalls++;
            return jsonResponse(request, [], status: 201);
          }
          return http.Response('not found', 404);
        }),
      );

      await repo.syncPendingMeals();
      await repo.syncPendingMeals();

      expect(upsertCalls, 1);
    });

    test(
      'a network failure mid-batch leaves the failed meal pending, the others synced, '
      'and a later retry resumes without re-pushing the already-synced one',
      () async {
        await insertPendingMeal('meal-ok');
        await insertPendingMeal('meal-fails');
        final pushed = <String>[];
        var shouldFail = true;
        final repo = MealRepository(
          db,
          await fakeAuthenticatedClient(_userId, (request) async {
            if (request.method == 'POST' && request.url.path.endsWith('/rest/v1/meals')) {
              final body = jsonDecode(request.body) as Map<String, dynamic>;
              final id = body['id'] as String;
              if (id == 'meal-fails' && shouldFail) {
                return http.Response('server error', 500);
              }
              pushed.add(id);
              return jsonResponse(request, [], status: 201);
            }
            return http.Response('not found', 404);
          }),
        );

        await repo.syncPendingMeals();
        expect(pushed, ['meal-ok']);
        var rows = await db.select(db.localMeals).get();
        expect(rows.firstWhere((r) => r.id == 'meal-ok').isSynced, isTrue);
        expect(rows.firstWhere((r) => r.id == 'meal-fails').isSynced, isFalse);

        // Retry after the network/server recovers: only the still-pending
        // meal is pushed, the already-synced one is not re-sent.
        shouldFail = false;
        await repo.syncPendingMeals();
        expect(pushed, ['meal-ok', 'meal-fails']);
        rows = await db.select(db.localMeals).get();
        expect(rows.every((r) => r.isSynced), isTrue);
      },
    );

    test('propagates a local deletion to Supabase and removes the local row', () async {
      await insertPendingMeal('meal-1', isSynced: true);
      await (db.update(db.localMeals)..where((m) => m.id.equals('meal-1')))
          .write(const LocalMealsCompanion(isDeleted: Value(true)));

      var deleteCalls = 0;
      final repo = MealRepository(
        db,
        await fakeAuthenticatedClient(_userId, (request) async {
          if (request.method == 'DELETE' && request.url.path.endsWith('/rest/v1/meals')) {
            deleteCalls++;
            expect(request.url.queryParameters['id'], 'eq.meal-1');
            return jsonResponse(request, [], status: 200);
          }
          return http.Response('not found', 404);
        }),
      );

      await repo.syncPendingMeals();

      expect(deleteCalls, 1);
      final rows = await db.select(db.localMeals).get();
      expect(rows, isEmpty);
    });

    test('a meal never synced to Supabase is deleted locally without calling DELETE remotely', () async {
      await insertPendingMeal('meal-1'); // isSynced: false
      await (db.update(db.localMeals)..where((m) => m.id.equals('meal-1')))
          .write(const LocalMealsCompanion(isDeleted: Value(true)));

      var deleteCalls = 0;
      final repo = MealRepository(
        db,
        await fakeAuthenticatedClient(_userId, (request) async {
          if (request.method == 'DELETE') deleteCalls++;
          return jsonResponse(request, [], status: 200);
        }),
      );

      await repo.syncPendingMeals();

      expect(deleteCalls, 0);
      expect(await db.select(db.localMeals).get(), isEmpty);
    });
  });

  group('repeatMeal', () {
    test('does not share the local image file between the original and the duplicate', () async {
      final docsDir = await Directory.systemTemp.createTemp('meal_repo_test');
      final photosDir = Directory('${docsDir.path}/meal_photos');
      await photosDir.create(recursive: true);
      final originalPhoto = File('${photosDir.path}/meal-1.jpg');
      await originalPhoto.writeAsBytes([1, 2, 3]);

      await db.into(db.localMeals).insert(
            LocalMealsCompanion.insert(
              id: 'meal-1',
              userId: _userId,
              name: 'Riz',
              totalKcal: 100,
              localImagePath: Value(originalPhoto.path),
              createdAt: DateTime.now(),
            ),
          );

      final repo = MealRepository(
        db,
        await fakeAuthenticatedClient(_userId, (request) async => jsonResponse(request, [], status: 201)),
      );

      await repo.repeatMeal('meal-1');
      // repeatMeal() fires an unawaited syncPendingMeals() for the original
      // row (still pending, with a localImagePath): drain it before touching
      // the temp dir, otherwise its file read races the cleanup below.
      await repo.syncPendingMeals();

      final rows = await db.select(db.localMeals).get();
      expect(rows, hasLength(2));
      final duplicate = rows.firstWhere((r) => r.id != 'meal-1');
      // Documented regression: the duplicate never copies [localImagePath] —
      // only an already-uploaded [imageUrl] — precisely so that deleteMeal on
      // one row never deletes a photo file still referenced by the other.
      expect(duplicate.localImagePath, isNull);

      await docsDir.delete(recursive: true);
    });
  });
}
