import 'dart:convert';

import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ai_health_chef/local_db/app_database.dart';
import 'package:ai_health_chef/services/data_export_service.dart';

import '../local_db/fake_supabase.dart';

const _userId = 'user-1';

Future<http.Response> _notFound(http.Request request) async => http.Response('not found', 404);

void main() {
  late AppDatabase db;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    SharedPreferences.setMockInitialValues({});
  });

  tearDown(() async {
    await db.close();
  });

  test('empty local db and offline remote: well-formed export with empty sections', () async {
    final service = DataExportService(db, await fakeAuthenticatedClient(_userId, _notFound));

    final export = await service.buildExport();

    expect(export['schema_version'], 1);
    expect(export['user_id'], _userId);
    expect(DateTime.parse(export['exported_at'] as String).isUtc, isTrue);
    expect(export['profile'], isNull);
    expect(export['meals'], isEmpty);
    expect(export['weight_entries'], isEmpty);
    expect(export['hydration_entries'], isEmpty);
    expect(export['chat_messages'], isEmpty);
    expect(export['weekly_meal_plans'], isEmpty);
    expect(export['shopping_list'], isEmpty);
    expect(export['custom_reminders'], isEmpty);
    expect(export['other_local_preferences'], isEmpty);
    // Must still be JSON-encodable as a whole.
    expect(() => jsonEncode(export), returnsNormally);
  });

  test('merges local meals with a remote-only meal and resolves signed photo urls', () async {
    await db.into(db.localMeals).insert(LocalMealsCompanion.insert(
          id: 'local-meal',
          userId: _userId,
          name: 'Salade',
          totalKcal: 300,
          ingredientsJson: const Value('[{"name":"tomate"}]'),
          imagePath: const Value('$_userId/local-meal.jpg'),
          createdAt: DateTime.utc(2026, 1, 1),
        ));

    var signCalls = 0;
    final service = DataExportService(
      db,
      await fakeAuthenticatedClient(_userId, (request) async {
        if (request.url.path.contains('/object/sign/')) {
          signCalls++;
          return jsonResponse(request, {'signedURL': '/object/sign/meal_photos/x.jpg?token=abc'});
        }
        if (request.url.path.endsWith('/rest/v1/meals')) {
          return jsonResponse(request, [
            {
              'id': 'local-meal', // already local: must not be duplicated
              'name': 'Salade',
              'ingredients': [],
            },
            {
              'id': 'remote-only-meal', // only on another device: must be merged in
              'name': 'Soupe',
              'ingredients': [],
            },
          ]);
        }
        return _notFound(request);
      }),
    );

    final export = await service.buildExport();

    final meals = export['meals'] as List;
    expect(meals.map((m) => m['id']), containsAll(['local-meal', 'remote-only-meal']));
    expect(meals.length, 2);
    final local = meals.firstWhere((m) => m['id'] == 'local-meal');
    expect(local['photo_signed_url'], contains('/object/sign/meal_photos/x.jpg?token=abc'));
    expect(signCalls, 1);
  });

  test('never leaks the auth session or another user\'s rows', () async {
    await db.into(db.localMeals).insert(LocalMealsCompanion.insert(
          id: 'mine',
          userId: _userId,
          name: 'Mon repas',
          totalKcal: 100,
          createdAt: DateTime.utc(2026, 1, 1),
        ));
    await db.into(db.localMeals).insert(LocalMealsCompanion.insert(
          id: 'not-mine',
          userId: 'user-2',
          name: 'Repas d\'un autre utilisateur',
          totalKcal: 100,
          createdAt: DateTime.utc(2026, 1, 1),
        ));

    final service = DataExportService(db, await fakeAuthenticatedClient(_userId, _notFound));

    final encoded = jsonEncode(await service.buildExport());

    expect(encoded, isNot(contains('not-mine')));
    expect(encoded, isNot(contains('user-2')));
    expect(encoded, isNot(contains('refresh-token'))); // fake session's refresh token
    expect(encoded, isNot(contains('anon-key'))); // client API key
  });
}
