// Migre les anciennes illustrations base64 de `chat_messages.image_url`
// (voir migration 0015) vers le bucket Storage privé `chat_images`
// (migration 0019) : pour chaque ligne avec `image_path is null` et
// `image_url is not null`, upload les octets décodés vers
// `chat_images/{user_id}/{uuid}.jpg` puis renseigne `image_path`.
//
// Ne touche JAMAIS `image_url` (lecture seule) — sa mise à NULL est un choix
// humain séparé, voir supabase/scripts/CLEANUP_image_url_apres_backfill.sql.
//
// Script autonome, pas d'app Flutter à lancer : appels REST directs à
// PostgREST + Storage avec la clé service_role (bypass RLS), via le package
// `http` déjà présent dans pubspec.yaml.
//
// Usage (depuis la racine du repo) :
//   SUPABASE_URL=https://xxxx.supabase.co \
//   SUPABASE_SERVICE_ROLE_KEY=eyJ... \
//   dart run supabase/scripts/backfill_chat_images.dart
//
// Options :
//   --dry-run   N'upload/ne met rien à jour, affiche juste ce qui serait fait.
//   --batch=N   Taille de page par itération (défaut 50).
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';

const _uuid = Uuid();

/// Décode une data URI (`data:image/jpeg;base64,...`) en (mimeType, octets).
/// Retourne `null` si `dataUri` est mal formée, plutôt que de lever une
/// exception — l'appelant saute alors cette ligne et continue le backfill.
(String, List<int>)? parseDataUri(String? dataUri) {
  if (dataUri == null || dataUri.isEmpty) return null;
  final match = RegExp(r'^data:([^;]+);base64,(.+)$', dotAll: true).firstMatch(dataUri);
  if (match == null) return null;
  try {
    return (match.group(1)!, base64Decode(match.group(2)!));
  } catch (_) {
    return null;
  }
}

/// Garde-fou minimal : vérifie que [parseDataUri] fonctionne sur un exemple
/// connu avant de lancer le vrai backfill, pour échouer vite si la logique
/// de parsing casse plutôt que de corrompre des lignes en base.
void _selfCheck() {
  final ok = parseDataUri('data:image/png;base64,aGVsbG8=');
  assert(ok != null && ok.$1 == 'image/png' && utf8.decode(ok.$2) == 'hello');
  assert(parseDataUri('pas une data uri') == null);
  assert(parseDataUri(null) == null);
}

Future<void> main(List<String> args) async {
  _selfCheck();

  final dryRun = args.contains('--dry-run');
  final batchArg = args.firstWhere((a) => a.startsWith('--batch='), orElse: () => '--batch=50');
  final batchSize = int.tryParse(batchArg.split('=').last) ?? 50;

  final supabaseUrl = Platform.environment['SUPABASE_URL'];
  final serviceKey = Platform.environment['SUPABASE_SERVICE_ROLE_KEY'];
  if (supabaseUrl == null || serviceKey == null) {
    stderr.writeln(
      'SUPABASE_URL et SUPABASE_SERVICE_ROLE_KEY doivent être définis dans l\'environnement.',
    );
    exitCode = 1;
    return;
  }
  final baseUrl = supabaseUrl.endsWith('/') ? supabaseUrl.substring(0, supabaseUrl.length - 1) : supabaseUrl;

  final client = http.Client();
  final headers = {
    'apikey': serviceKey,
    'Authorization': 'Bearer $serviceKey',
  };

  var migrated = 0;
  var failed = 0;

  try {
    while (true) {
      // Pas besoin de pagination par offset : chaque ligne traitée avec
      // succès voit son `image_path` renseigné, donc sort du filtre
      // `image_path=is.null` au tour suivant — la même requête renvoie
      // naturellement le prochain lot restant.
      final listUri = Uri.parse('$baseUrl/rest/v1/chat_messages').replace(queryParameters: {
        'select': 'id,user_id,image_url',
        'image_path': 'is.null',
        'image_url': 'not.is.null',
        'order': 'created_at.asc',
        'limit': '$batchSize',
      });
      final listResponse = await client.get(listUri, headers: headers);
      if (listResponse.statusCode != 200) {
        stderr.writeln('Échec de lecture (${listResponse.statusCode}) : ${listResponse.body}');
        exitCode = 1;
        break;
      }

      final rows = (jsonDecode(listResponse.body) as List).cast<Map<String, dynamic>>();
      if (rows.isEmpty) {
        break;
      }

      for (final row in rows) {
        final id = row['id'] as String;
        final userId = row['user_id'] as String;
        final parsed = parseDataUri(row['image_url'] as String?);
        if (parsed == null) {
          stdout.writeln('[SKIP] $id : image_url mal formée, ignorée.');
          failed++;
          continue;
        }
        final (mimeType, bytes) = parsed;
        final path = '$userId/${_uuid.v4()}.jpg';

        if (dryRun) {
          stdout.writeln('[DRY-RUN] $id -> chat_images/$path (${bytes.length} octets)');
          migrated++;
          // En dry-run on ne peut pas sortir la ligne du filtre, donc on
          // arrête après ce lot pour ne pas boucler indéfiniment sur les
          // mêmes lignes.
          continue;
        }

        final uploadResponse = await client.post(
          Uri.parse('$baseUrl/storage/v1/object/chat_images/$path'),
          headers: {...headers, 'Content-Type': mimeType, 'x-upsert': 'true'},
          body: bytes,
        );
        if (uploadResponse.statusCode != 200) {
          stdout.writeln('[FAIL upload] $id : HTTP ${uploadResponse.statusCode} — ${uploadResponse.body}');
          failed++;
          continue;
        }

        final patchResponse = await client.patch(
          Uri.parse('$baseUrl/rest/v1/chat_messages').replace(queryParameters: {'id': 'eq.$id'}),
          headers: {...headers, 'Content-Type': 'application/json', 'Prefer': 'return=minimal'},
          body: jsonEncode({'image_path': path}),
        );
        if (patchResponse.statusCode != 204 && patchResponse.statusCode != 200) {
          stdout.writeln('[FAIL update] $id : HTTP ${patchResponse.statusCode} — ${patchResponse.body}');
          failed++;
          continue;
        }

        stdout.writeln('[OK] $id -> chat_images/$path');
        migrated++;
      }

      if (dryRun) {
        // Pas de mise à jour en dry-run donc le lot ne "vide" jamais : un
        // seul tour suffit pour avoir un aperçu représentatif.
        break;
      }
    }
  } finally {
    client.close();
  }

  stdout.writeln('Terminé : $migrated ligne(s) migrée(s), $failed échec(s).');
  if (failed > 0) {
    exitCode = 1;
  }
}
