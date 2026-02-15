import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  // On récupère l'instance de Supabase initialisée dans le main.dart
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Inscription avec Email et Mot de passe
  Future<AuthResponse> signUp({required String email, required String password}) async {
    try {
      return await _supabase.auth.signUp(email: email, password: password);
    } catch (e) {
      throw Exception('Erreur lors de l\'inscription : ${e.toString()}');
    }
  }

  /// Connexion avec Email et Mot de passe
  Future<AuthResponse> signIn({required String email, required String password}) async {
    try {
      return await _supabase.auth.signInWithPassword(email: email, password: password);
    } catch (e) {
      throw Exception('Email ou mot de passe incorrect.');
    }
  }

  /// Déconnexion de l'utilisateur
  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }

  /// Envoi de l'email pour le mot de passe oublié
  Future<void> resetPassword(String email) async {
    try {
      await _supabase.auth.resetPasswordForEmail(email);
    } catch (e) {
      throw Exception('Erreur lors de l\'envoi de l\'email.');
    }
  }

  /// Connexion via un fournisseur tiers (Google, GitHub, Discord, etc.)
  Future<void> signInWithOAuth(OAuthProvider provider) async {
    try {
      await _supabase.auth.signInWithOAuth(
        provider,
        // C'est l'URL qui dira au navigateur de rouvrir ton application une fois connecté.
        // Format typique : ton.bundle.id://login-callback
        redirectTo: 'com.aihealthchef.app://login-callback/',
      );
    } catch (e) {
      throw Exception('Erreur de connexion avec ${provider.name} : ${e.toString()}');
    }
  }

  /// Permet de savoir qui est connecté actuellement (renvoie null si personne)
  User? get currentUser => _supabase.auth.currentUser;

  /// Un "Stream" qui écoute en temps réel si l'utilisateur se connecte ou se déconnecte.
  /// C'est magique pour rediriger automatiquement l'utilisateur vers le Login s'il se déconnecte !
  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;
}