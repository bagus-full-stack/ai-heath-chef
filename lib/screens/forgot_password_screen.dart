import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../l10n/l10n_extensions.dart';
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
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.l10n.forgotPasswordErrorEmailRequired)));
      return;
    }

    setState(() => _isLoading = true);

    try {
      await ref.read(authServiceProvider).resetPassword(email);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.forgotPasswordSuccessMessage), backgroundColor: Colors.green),
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
            Center(child: Container(width: 80, height: 80, decoration: BoxDecoration(color: primaryColor.withValues(alpha: 0.05), shape: BoxShape.circle), child: const Icon(Icons.vpn_key_outlined, size: 36, color: primaryColor))),
            const SizedBox(height: 24),
            Text(context.l10n.forgotPasswordTitle, textAlign: TextAlign.center, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Text(context.l10n.forgotPasswordSubtitle, textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: Colors.grey.shade600, height: 1.4)),
            const SizedBox(height: 40),

            // Champ Email
            Text(context.l10n.forgotPasswordEmailLabel, style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            TextField(
              controller: _emailController, // Connecté au contrôleur
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                hintText: context.l10n.forgotPasswordEmailHint,
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
                  : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(context.l10n.forgotPasswordSubmitButton, style: const TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold)),
                  const SizedBox(width: 8),
                  const Icon(Icons.arrow_forward, color: Colors.white, size: 20),
                ],
              ),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => context.pop(),
              child: Text(context.l10n.forgotPasswordBackToLogin, style: TextStyle(color: Colors.grey.shade700, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }
}