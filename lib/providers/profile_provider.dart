import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/user_profile.dart';
import 'auth_provider.dart';

const _kCachedProfileKey = 'cached_profile_json';

/// Profil de l'utilisateur connecté — mis en cache localement à chaque
/// récupération réussie, pour rester disponible (IMC, cibles, statut PRO...)
/// même hors connexion plutôt que de casser tous les écrans qui en dépendent.
final profileProvider = FutureProvider<UserProfile?>((ref) async {
  ref.watch(authStateProvider);
  final service = ref.watch(authServiceProvider);
  final prefs = await SharedPreferences.getInstance();

  Map<String, dynamic>? data;
  try {
    data = await service.fetchMyProfile();
  } catch (_) {
    final cached = prefs.getString(_kCachedProfileKey);
    if (cached == null) rethrow;
    return UserProfile.fromJson(jsonDecode(cached) as Map<String, dynamic>);
  }

  if (data == null) {
    await prefs.remove(_kCachedProfileKey);
    return null;
  }
  await prefs.setString(_kCachedProfileKey, jsonEncode(data));
  return UserProfile.fromJson(data);
});
