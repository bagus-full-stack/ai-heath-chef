import 'dart:io';

import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'purchase_service.dart';

class AuthService {
  // On récupère l'instance de Supabase initialisée dans le main.dart
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Inscription avec Email et Mot de passe
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    String? fullName,
  }) async {
    try {
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: fullName == null || fullName.trim().isEmpty
            ? null
            : {'full_name': fullName.trim()},
      );
      final userId = response.user?.id;
      if (userId != null) {
        await PurchaseService.instance.logIn(userId);
      }
      return response;
    } catch (e) {
      throw Exception('Erreur lors de l\'inscription : ${e.toString()}');
    }
  }

  /// Connexion avec Email et Mot de passe
  Future<AuthResponse> signIn({required String email, required String password}) async {
    try {
      final response = await _supabase.auth.signInWithPassword(email: email, password: password);
      final userId = response.user?.id;
      if (userId != null) {
        await PurchaseService.instance.logIn(userId);
      }
      return response;
    } catch (e) {
      throw Exception('Email ou mot de passe incorrect.');
    }
  }

  /// Crée ou met à jour le profil métier de l'utilisateur connecté.
  ///
  /// [avatarUrl] est optionnel : s'il n'est pas fourni, la colonne
  /// `avatar_url` n'est pas touchée (la photo précédemment uploadée via
  /// [uploadAvatar] est conservée).
  Future<void> upsertProfile({
    String? fullName,
    required String sex,
    required int age,
    required double currentWeight,
    required double targetWeight,
    required String goal,
    String? avatarUrl,
  }) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('Vous devez être connecté pour enregistrer votre profil.');
      }

      await _supabase.from('profiles').upsert({
        'user_id': user.id,
        'email': user.email,
        'full_name': (fullName?.trim().isNotEmpty ?? false)
            ? fullName!.trim()
            : (user.userMetadata?['full_name'] as String?) ??
                user.email?.split('@').first ??
                'Utilisateur',
        'sex': sex,
        'age': age,
        'current_weight': currentWeight,
        'target_weight': targetWeight,
        'goal': goal,
        if (avatarUrl != null) 'avatar_url': avatarUrl,
      }, onConflict: 'user_id');
    } catch (e) {
      throw Exception('Erreur lors de la sauvegarde du profil : ${e.toString()}');
    }
  }

  /// Compresse puis uploade une photo de profil vers le bucket Supabase
  /// Storage `avatars`, et retourne son URL publique.
  ///
  /// Nécessite qu'un bucket public nommé "avatars" existe sur le projet
  /// Supabase, avec une policy de storage autorisant chaque utilisateur à
  /// écrire uniquement dans son propre dossier (`{user_id}/...`). Ce bucket
  /// n'est pas créé automatiquement par ce code, voir le dashboard Supabase
  /// > Storage.
  Future<String> uploadAvatar(File imageFile) async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      throw Exception('Vous devez être connecté pour changer ta photo de profil.');
    }

    try {
      final compressedBytes = await FlutterImageCompress.compressWithFile(
        imageFile.path,
        minWidth: 400,
        minHeight: 400,
        quality: 80,
      );
      if (compressedBytes == null) {
        throw Exception("Impossible de traiter l'image.");
      }

      final path = '${user.id}/avatar.jpg';
      await _supabase.storage.from('avatars').uploadBinary(
            path,
            compressedBytes,
            fileOptions: const FileOptions(upsert: true, contentType: 'image/jpeg'),
          );

      final publicUrl = _supabase.storage.from('avatars').getPublicUrl(path);
      // On ajoute un paramètre de cache-busting pour que l'app affiche
      // immédiatement la nouvelle image plutôt qu'une version mise en cache.
      return '$publicUrl?updated=${DateTime.now().millisecondsSinceEpoch}';
    } catch (e) {
      throw Exception('Erreur lors de l’envoi de la photo : ${e.toString()}');
    }
  }

  /// Récupère le profil métier de l'utilisateur connecté.
  Future<Map<String, dynamic>?> fetchMyProfile() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        return null;
      }

      final response = await _supabase
          .from('profiles')
          .select()
          .eq('user_id', user.id)
          .maybeSingle();

      return response == null ? null : Map<String, dynamic>.from(response as Map);
    } catch (e) {
      throw Exception('Erreur lors de la récupération du profil : ${e.toString()}');
    }
  }

  /// Déconnexion de l'utilisateur
  Future<void> signOut() async {
    await _supabase.auth.signOut();
    await PurchaseService.instance.logOut();
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