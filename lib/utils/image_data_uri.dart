import 'dart:convert';
import 'dart:typed_data';

/// Décode une data URI base64 (`data:image/...;base64,...`) en octets bruts.
/// Retourne `null` si `dataUri` est nul/vide ou mal formé, plutôt que de
/// lever une exception — l'appelant retombe alors sur une icône par défaut.
Uint8List? decodeImageDataUri(String? dataUri) {
  if (dataUri == null || dataUri.isEmpty) return null;
  final commaIndex = dataUri.indexOf(',');
  if (commaIndex == -1) return null;
  try {
    return base64Decode(dataUri.substring(commaIndex + 1));
  } catch (_) {
    return null;
  }
}
