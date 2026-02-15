import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../providers/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;

  // LA NOUVELLE VARIABLE MAGIQUE 🪄
  // Si true -> On affiche la Connexion
  // Si false -> On affiche l'Inscription
  bool _isLogin = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // Fonction unique qui gère à la fois la connexion et l'inscription
  Future<void> _submit() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez remplir tous les champs.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      if (_isLogin) {
        // --- MODE CONNEXION ---
        await ref.read(authServiceProvider).signIn(email: email, password: password);
        if (mounted) context.go('/dashboard');

      } else {
        // --- MODE INSCRIPTION ---
        final response = await ref.read(authServiceProvider).signUp(email: email, password: password);

        // Supabase demande souvent de cliquer sur un lien par email pour confirmer
        if (response.session == null) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Compte créé ! Veuillez vérifier vos emails pour confirmer.'),
                backgroundColor: Colors.green,
                duration: Duration(seconds: 5),
              ),
            );
            // On rebascule sur l'écran de connexion
            setState(() => _isLogin = true);
          }
        } else {
          // Si la confirmation par email est désactivée sur Supabase, on va direct au Dashboard
          if (mounted) context.go('/dashboard');
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(e.toString().replaceAll('Exception: ', '')),
              backgroundColor: Colors.red
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF6B66FF);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Container(
            decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(8)),
            child: const Icon(Icons.bolt, color: Colors.white),
          ),
        ),
        // Le titre change dynamiquement
        title: Text(
            _isLogin ? 'CONNEXION' : 'INSCRIPTION',
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black)
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 10),
            Center(
                child: Container(
                    width: 80, height: 80,
                    decoration: BoxDecoration(color: Colors.grey.shade100, shape: BoxShape.circle),
                    child: const Icon(Icons.bolt, size: 40, color: Colors.black)
                )
            ),
            const SizedBox(height: 24),

            // Les textes de bienvenue changent dynamiquement
            Text(
                _isLogin ? 'Ravi de vous revoir' : 'Créer un compte',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)
            ),
            const SizedBox(height: 8),
            Text(
                _isLogin ? 'Connectez-vous pour suivre vos objectifs' : 'Rejoignez-nous pour analyser vos repas',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey.shade600)
            ),
            const SizedBox(height: 40),

            // Champ Email
            const Text('Email', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                hintText: 'nom@exemple.fr',
                prefixIcon: const Icon(Icons.email_outlined),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 20),

            // Champ Mot de passe
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Mot de passe', style: TextStyle(fontWeight: FontWeight.w600)),
                // Le bouton "Mot de passe oublié" ne s'affiche qu'en mode Connexion
                if (_isLogin)
                  GestureDetector(
                    onTap: () => context.push('/forgot_password'),
                    child: Text('Mot de passe oublié ?', style: TextStyle(color: Colors.pink.shade400, fontSize: 12)),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              decoration: InputDecoration(
                hintText: '••••••••',
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  icon: Icon(_obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                ),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 30),

            // Bouton de validation (S'inscrire ou Se connecter)
            ElevatedButton(
              onPressed: _isLoading ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _isLoading
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                      _isLogin ? 'Se connecter' : 'S\'inscrire',
                      style: const TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold)
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.arrow_forward, color: Colors.white, size: 20),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // LE BOUTON DE BASCULE (Toggle)
            TextButton(
              onPressed: () {
                setState(() {
                  _isLogin = !_isLogin; // Inverse le mode (Connexion <-> Inscription)
                });
              },
              child: Text(
                _isLogin ? "Pas encore de compte ? S'inscrire" : "Déjà un compte ? Se connecter",
                style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
              ),
            ),

            const SizedBox(height: 20),

            // Lignes de séparation
            Row(
              children: [
                Expanded(child: Divider(color: Colors.grey.shade300)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text('OU CONTINUER AVEC', style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                ),
                Expanded(child: Divider(color: Colors.grey.shade300)),
              ],
            ),
            const SizedBox(height: 20),

            // Boutons Sociaux OAuth
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => ref.read(authServiceProvider).signInWithOAuth(OAuthProvider.google),
                    icon: const Icon(Icons.g_mobiledata, color: Colors.black, size: 28),
                    label: const Text('Google', style: TextStyle(color: Colors.black)),
                    style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => ref.read(authServiceProvider).signInWithOAuth(OAuthProvider.github),
                    icon: const Icon(Icons.code, color: Colors.black),
                    label: const Text('GitHub', style: TextStyle(color: Colors.black)),
                    style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () => ref.read(authServiceProvider).signInWithOAuth(OAuthProvider.discord),
              icon: const Icon(Icons.discord, color: Color(0xFF5865F2)),
              label: const Text('Continuer avec Discord', style: TextStyle(color: Colors.black)),
              style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
              ),
            ),
          ],
        ),
      ),
    );
  }
}