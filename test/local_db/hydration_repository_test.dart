import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

import 'package:ai_health_chef/local_db/app_database.dart';
import 'package:ai_health_chef/local_db/hydration_repository.dart';

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

  group('syncEntries', () {
    test('pushes a pending entry and marks it synced', () async {
      await db.into(db.hydrationEntries).insert(
            HydrationEntriesCompanion.insert(
              id: 'h1',
              userId: _userId,
              amountMl: 250,
              recordedAt: DateTime.now(),
            ),
          );

      var upsertCalls = 0;
      final repo = HydrationRepository(
        db,
        await fakeAuthenticatedClient(_userId, (request) async {
          if (request.method == 'POST' &&
              request.url.path.endsWith('/rest/v1/hydration_entries')) {
            upsertCalls++;
            return jsonResponse(request, [], status: 201);
          }
          if (request.method == 'GET') return jsonResponse(request, []);
          return http.Response('not found', 404);
        }),
      );

      await repo.syncEntries();

      expect(upsertCalls, 1);
      final row =
          await (db.select(db.hydrationEntries)..where((h) => h.id.equals('h1'))).getSingle();
      expect(row.isSynced, isTrue);
    });

    test('propagates a local deletion to Supabase and removes the local row', () async {
      await db.into(db.hydrationEntries).insert(
            HydrationEntriesCompanion.insert(
              id: 'h1',
              userId: _userId,
              amountMl: 250,
              recordedAt: DateTime.now(),
              isSynced: const Value(true),
            ),
          );
      await (db.update(db.hydrationEntries)..where((h) => h.id.equals('h1')))
          .write(const HydrationEntriesCompanion(isDeleted: Value(true)));

      var deleteCalls = 0;
      final repo = HydrationRepository(
        db,
        await fakeAuthenticatedClient(_userId, (request) async {
          if (request.method == 'DELETE' &&
              request.url.path.endsWith('/rest/v1/hydration_entries')) {
            deleteCalls++;
            return jsonResponse(request, [], status: 200);
          }
          if (request.method == 'GET') return jsonResponse(request, []);
          return http.Response('not found', 404);
        }),
      );

      await repo.syncEntries();

      expect(deleteCalls, 1);
      expect(await db.select(db.hydrationEntries).get(), isEmpty);
    });

    test('pulls a remote-only entry without overwriting a local one sharing its id', () async {
      await db.into(db.hydrationEntries).insert(
            HydrationEntriesCompanion.insert(
              id: 'h1',
              userId: _userId,
              amountMl: 250, // local value must survive the pull
              recordedAt: DateTime.now(),
              isSynced: const Value(true),
            ),
          );

      final repo = HydrationRepository(
        db,
        await fakeAuthenticatedClient(_userId, (request) async {
          if (request.method == 'GET' &&
              request.url.path.endsWith('/rest/v1/hydration_entries')) {
            return jsonResponse(request, [
              {'id': 'h1', 'amount_ml': 999, 'recorded_at': DateTime.now().toIso8601String()},
              {'id': 'h2', 'amount_ml': 500, 'recorded_at': DateTime.now().toIso8601String()},
            ]);
          }
          return http.Response('not found', 404);
        }),
      );

      await repo.syncEntries();

      final rows = await db.select(db.hydrationEntries).get();
      expect(rows.firstWhere((r) => r.id == 'h1').amountMl, 250);
      expect(rows.firstWhere((r) => r.id == 'h2').amountMl, 500);
    });
  });
}
