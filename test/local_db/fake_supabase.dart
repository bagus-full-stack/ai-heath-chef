import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Construit un [SupabaseClient] de test dont les appels PostgREST/Storage
/// passent par [handler] (voir `http.MockClient`) plutôt que par le réseau,
/// et dont `auth.currentUser.id` vaut déjà [userId] sans aucun appel réseau :
/// `recoverSession` accepte une session non expirée localement, sans
/// rafraîchissement (voir gotrue_client.dart, `recoverSession`).
Future<SupabaseClient> fakeAuthenticatedClient(
  String userId,
  Future<http.Response> Function(http.Request request) handler,
) async {
  final client = SupabaseClient(
    'https://example.test',
    'anon-key',
    httpClient: MockClient(handler),
  );
  await client.auth.recoverSession(jsonEncode({
    'access_token': _fakeJwt(userId),
    'refresh_token': 'refresh-token',
    'token_type': 'bearer',
    'user': {
      'id': userId,
      'aud': 'authenticated',
      'created_at': DateTime.now().toIso8601String(),
      'app_metadata': <String, dynamic>{},
      'user_metadata': <String, dynamic>{},
    },
  }));
  return client;
}

/// JWT minimal (signature factice, jamais vérifiée côté client) avec un
/// `exp` dans le futur — seul champ lu par `recoverSession` pour décider si
/// la session peut être acceptée sans appel réseau.
String _fakeJwt(String userId) {
  String part(Object payload) =>
      base64Url.encode(utf8.encode(jsonEncode(payload))).replaceAll('=', '');
  final header = part({'alg': 'none', 'typ': 'JWT'});
  final payload = part({
    'sub': userId,
    'exp': DateTime.now().add(const Duration(hours: 1)).millisecondsSinceEpoch ~/ 1000,
  });
  return '$header.$payload.sig';
}

/// [request] doit être le [http.Request] reçu par le handler : sans lui,
/// `response.request` reste `null` et postgrest (`_parseResponse`) plante sur
/// `response.request!.method` — voir `package:http/src/mock_client.dart`, qui
/// ne remplit `StreamedResponse.request` qu'à partir de `response.request`.
http.Response jsonResponse(http.Request request, Object? body, {int status = 200}) {
  return http.Response(jsonEncode(body), status,
      request: request, headers: {'content-type': 'application/json'});
}
