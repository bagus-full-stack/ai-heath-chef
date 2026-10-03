import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

import 'package:ai_health_chef/local_db/app_database.dart';
import 'package:ai_health_chef/local_db/weight_repository.dart';

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
      await db.into(db.weightEntries).insert(
            WeightEntriesCompanion.insert(
              id: 'e1',
              userId: _userId,
              weightKg: 70,
              recordedAt: DateTime.now(),
            ),
          );

      var upsertCalls = 0;
      final repo = WeightRepository(
        db,
        await fakeAuthenticatedClient(_userId, (request) async {
          if (request.method == 'POST' && request.url.path.endsWith('/rest/v1/weight_entries')) {
            upsertCalls++;
            return jsonResponse(request, [], status: 201);
          }
          if (request.method == 'GET') return jsonResponse(request, []);
          return http.Response('not found', 404);
        }),
      );

      await repo.syncEntries();

      expect(upsertCalls, 1);
      final row = await (db.select(db.weightEntries)..where((w) => w.id.equals('e1'))).getSingle();
      expect(row.isSynced, isTrue);
    });

    test('pulls a remote-only entry without overwriting a newer local one sharing its id', () async {
      await db.into(db.weightEntries).insert(
            WeightEntriesCompanion.insert(
              id: 'e1',
              userId: _userId,
              weightKg: 70, // locally updated since the last sync
              recordedAt: DateTime.now(),
              isSynced: const Value(true),
            ),
          );

      final repo = WeightRepository(
        db,
        await fakeAuthenticatedClient(_userId, (request) async {
          if (request.method == 'GET' && request.url.path.endsWith('/rest/v1/weight_entries')) {
            return jsonResponse(request, [
              {
                'id': 'e1',
                'weight_kg': 999, // stale remote value: must not overwrite
                'recorded_at': DateTime.now().toIso8601String(),
                'image_url': null,
              },
              {
                'id': 'e2', // only exists remotely (another device): pulled in
                'weight_kg': 65,
                'recorded_at': DateTime.now().toIso8601String(),
                'image_url': null,
              },
            ]);
          }
          return http.Response('not found', 404);
        }),
      );

      await repo.syncEntries();

      final rows = await db.select(db.weightEntries).get();
      expect(rows.firstWhere((r) => r.id == 'e1').weightKg, 70);
      expect(rows.firstWhere((r) => r.id == 'e2').weightKg, 65);
    });
  });
}
