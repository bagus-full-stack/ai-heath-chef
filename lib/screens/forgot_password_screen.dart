import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _resetPassword() async {
    final email = _emailController.text.trim();

    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Veuillez entrer votre adresse e-mail.')));
      return;
    }

    setState(() => _isLoading = true);

    try {
      await ref.read(authServiceProvider).resetPassword(email);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Lien de réinitialisation envoyé ! Vérifiez vos emails.'), backgroundColor: Colors.green),
        );
        // On ramène l'utilisateur à l'écran de connexion après le succès
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll('Exception: ', '')), backgroundColor: Colors.red),
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
      appBar: AppBar( /* ... Garde ton AppBar actuel ... */ ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ... (Garde ton en-tête et l'icône) ...
            const SizedBox(height: 20),
            Center(child: Container(width: 80, height: 80, decoration: BoxDecoration(color: primaryColor.withOpacity(0.05), shape: BoxShape.circle), child: const Icon(Icons.vpn_key_outlined, size: 36, color: primaryColor))),
            const SizedBox(height: 24),
            const Text('Mot de passe oublié', textAlign: TextAlign.center, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Text('Ne vous inquiétez pas, cela arrive.\nEntrez votre email pour recevoir un\nlien de réinitialisation.', textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: Colors.grey.shade600, height: 1.4)),
            const SizedBox(height: 40),

            // Champ Email
            const Text('Adresse e-mail', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            TextField(
              controller: _emailController, // Connecté au contrôleur
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                hintText: 'exemple@email.com',
                prefixIcon: const Icon(Icons.email_outlined),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 24),

            // Bouton Envoyer avec Loader
            ElevatedButton(
              onPressed: _isLoading ? null : _resetPassword, // Désactivé pendant le chargement
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _isLoading
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Envoyer le lien', style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold)),
                  SizedBox(width: 8),
                  Icon(Icons.arrow_forward, color: Colors.white, size: 20),
                ],
              ),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => context.pop(),
              child: Text('Retour à la connexion', style: TextStyle(color: Colors.grey.shade700, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }
}