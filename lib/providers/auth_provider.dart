import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/supabase_service.dart';

// 1. On rend notre AuthService accessible partout dans l'application
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

// 2. On crée un StreamProvider pour écouter les changements d'état (Connecté/Déconnecté)
// Ça nous sera très utile plus tard pour protéger le Dashboard et rediriger l'utilisateur s'il n'est pas connecté.
final authStateProvider = StreamProvider<AuthState>((ref) {
  final authService = ref.watch(authServiceProvider);
  return authService.authStateChanges;
});