import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ForgotPasswordScreen extends StatelessWidget {
  const ForgotPasswordScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF6B66FF);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black, size: 20),
          onPressed: () => context.pop(), // Retour à l'écran précédent
        ),
        title: Container(
          padding: const EdgeInsets.all(6.0),
          decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(8)),
          child: const Icon(Icons.bolt, color: Colors.white, size: 20),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 20),
            // Icône Clé
            Center(
              child: Container(
                width: 80, height: 80,
                decoration: BoxDecoration(color: primaryColor.withOpacity(0.05), shape: BoxShape.circle),
                child: const Icon(Icons.vpn_key_outlined, size: 36, color: primaryColor),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Mot de passe oublié',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              'Ne vous inquiétez pas, cela arrive.\nEntrez votre email pour recevoir un\nlien de réinitialisation.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600, height: 1.4),
            ),
            const SizedBox(height: 40),

            // Champ Email
            const Text('Adresse e-mail', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            TextField(
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                hintText: 'exemple@email.com',
                prefixIcon: const Icon(Icons.email_outlined),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
              ),
            ),
            const SizedBox(height: 24),

            // Bouton Envoyer
            ElevatedButton(
              onPressed: () {
                // Logique d'envoi d'email à venir
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Lien envoyé !')));
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Envoyer le lien', style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold)),
                  SizedBox(width: 8),
                  Icon(Icons.arrow_forward, color: Colors.white, size: 20),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Bouton Retour connexion
            TextButton(
              onPressed: () => context.pop(),
              child: Text('Retour à la connexion', style: TextStyle(color: Colors.grey.shade700, fontWeight: FontWeight.w600)),
            ),

            const Spacer(),

            // Footer text
            Text(
              'Si vous n\'avez pas reçu l\'email dans les 2 minutes,\nvérifiez votre dossier de courrier indésirable.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade400, fontSize: 11),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}