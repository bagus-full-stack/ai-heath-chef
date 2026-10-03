import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

import 'package:ai_health_chef/services/storage_image_service.dart';

import '../local_db/fake_supabase.dart';

void main() {
  test('resolves a signed url for a given path', () async {
    var signCalls = 0;
    final client = await fakeAuthenticatedClient('user-1', (request) async {
      if (request.url.path.contains('/object/sign/avatars/')) {
        signCalls++;
        return jsonResponse(request, {'signedURL': '/object/sign/avatars/user-1/a.jpg?token=abc'});
      }
      return http.Response('not found', 404);
    });
    final service = StorageImageService(client);

    final url = await service.resolve('avatars', 'user-1/a.jpg');

    expect(signCalls, 1);
    expect(url, contains('/object/sign/avatars/user-1/a.jpg?token=abc'));
  });

  test('returns null without any network call when path is null', () async {
    final client = await fakeAuthenticatedClient('user-1', (request) async {
      fail('no network call expected for a null path');
    });
    final service = StorageImageService(client);

    expect(await service.resolve('avatars', null), isNull);
  });

  test('returns null (no exception) when the signing request fails', () async {
    final client = await fakeAuthenticatedClient('user-1', (request) async {
      return jsonResponse(request, {'message': 'not found'}, status: 404);
    });
    final service = StorageImageService(client);

    expect(await service.resolve('avatars', 'user-1/missing.jpg'), isNull);
  });

  test('caches the signed url: a second call before expiry does not re-sign', () async {
    var signCalls = 0;
    final client = await fakeAuthenticatedClient('user-1', (request) async {
      signCalls++;
      return jsonResponse(request, {'signedURL': '/object/sign/avatars/user-1/a.jpg?token=abc'});
    });
    final service = StorageImageService(client);

    await service.resolve('avatars', 'user-1/a.jpg');
    await service.resolve('avatars', 'user-1/a.jpg');

    expect(signCalls, 1);
  });

  test('re-signs once the cache entry is past its renewal margin', () async {
    var signCalls = 0;
    final client = await fakeAuthenticatedClient('user-1', (request) async {
      signCalls++;
      return jsonResponse(request, {'signedURL': '/object/sign/avatars/user-1/a.jpg?token=abc'});
    });
    var now = DateTime(2026, 1, 1);
    final service = StorageImageService(client, () => now);

    await service.resolve('avatars', 'user-1/a.jpg');
    now = now.add(const Duration(minutes: 51)); // past the 50-minute renewal mark
    await service.resolve('avatars', 'user-1/a.jpg');

    expect(signCalls, 2);
  });

  test('invalidate forces the next resolve to re-sign', () async {
    var signCalls = 0;
    final client = await fakeAuthenticatedClient('user-1', (request) async {
      signCalls++;
      return jsonResponse(request, {'signedURL': '/object/sign/avatars/user-1/a.jpg?token=abc'});
    });
    final service = StorageImageService(client);

    await service.resolve('avatars', 'user-1/a.jpg');
    service.invalidate('avatars', 'user-1/a.jpg');
    await service.resolve('avatars', 'user-1/a.jpg');

    expect(signCalls, 2);
  });
}
