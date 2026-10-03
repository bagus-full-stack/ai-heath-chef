import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../l10n/l10n_extensions.dart';
import '../local_db/local_data_purge.dart';
import '../local_db/local_db_provider.dart';
import '../providers/auth_provider.dart';
import '../services/purchase_service.dart';

const _kAppleSubscriptionsUrl = 'https://apps.apple.com/account/subscriptions';
const _kGoogleSubscriptionsUrl = 'https://play.google.com/store/account/subscriptions';

/// Écran de confirmation de suppression de compte (Profil > Sécurité >
/// "Supprimer mon compte"), exigence Google Play. Remplace l'ancienne FAQ
/// "écris-nous pour supprimer ton compte" (help_center_screen.dart) par un
/// vrai parcours in-app.
class DeleteAccountScreen extends ConsumerStatefulWidget {
  const DeleteAccountScreen({super.key});

  @override
  ConsumerState<DeleteAccountScreen> createState() => _DeleteAccountScreenState();
}

class _DeleteAccountScreenState extends ConsumerState<DeleteAccountScreen> {
  final _confirmController = TextEditingController();
  bool _isDeleting = false;
  bool _isPro = false;

  @override
  void initState() {
    super.initState();
    PurchaseService.instance.isEntitledToPro().then((isPro) {
      if (mounted) setState(() => _isPro = isPro);
    });
  }

  @override
  void dispose() {
    _confirmController.dispose();
    super.dispose();
  }

  bool _confirmationMatches(String expectedWord) {
    return _confirmController.text.trim().toUpperCase() == expectedWord.toUpperCase();
  }

  Future<void> _deleteAccount() async {
    if (_isDeleting) return;
    final expectedWord = context.l10n.deleteAccountConfirmWord;
    if (!_confirmationMatches(expectedWord)) {
      _showMessage(context.l10n.deleteAccountConfirmMismatch, isError: true);
      return;
    }

    setState(() => _isDeleting = true);
    try {
      await ref.read(authServiceProvider).deleteAccount(
            lang: Localizations.localeOf(context).languageCode,
          );

      // Le compte est déjà supprimé côté serveur à ce stade : la purge
      // locale et la déconnexion sont best-effort, on ne peut plus revenir
      // en arrière même si l'une d'elles échoue.
      await purgeLocalUserData(ref.read(appDatabaseProvider));
      await ref.read(authServiceProvider).signOut();

      if (!mounted) return;
      context.go('/');
    } catch (e) {
      // Échec réseau/serveur : le compte n'est probablement pas supprimé,
      // on ne déconnecte donc pas l'utilisateur, pour lui permettre de
      // réessayer depuis cet écran.
      _showMessage(e.toString().replaceAll('Exception: ', ''), isError: true);
      if (mounted) setState(() => _isDeleting = false);
    }
  }

  void _showMessage(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: isError ? Colors.redAccent : Colors.green),
    );
  }

  Future<void> _openSubscriptionManagement() async {
    final url = Platform.isIOS ? _kAppleSubscriptionsUrl : _kGoogleSubscriptionsUrl;
    await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final expectedWord = l10n.deleteAccountConfirmWord;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          l10n.deleteAccountAppBarTitle,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 1.2),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.redAccent.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.redAccent.withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.warning_amber_rounded, color: Colors.redAccent),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          l10n.deleteAccountWarningTitle,
                          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.redAccent),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.deleteAccountWarningBody,
                    style: const TextStyle(height: 1.4, fontSize: 13),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Text(
              l10n.deleteAccountDataListTitle,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 10),
            Text(
              l10n.deleteAccountDataListBody,
              style: TextStyle(color: Colors.grey.shade700, height: 1.5, fontSize: 13),
            ),
            if (_isPro) ...[
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.credit_card_outlined, color: Colors.orange),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            l10n.deleteAccountSubscriptionWarningTitle,
                            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.orange),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l10n.deleteAccountSubscriptionWarningBody,
                      style: const TextStyle(height: 1.4, fontSize: 13),
                    ),
                    const SizedBox(height: 10),
                    OutlinedButton(
                      onPressed: _openSubscriptionManagement,
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.orange),
                        foregroundColor: Colors.orange,
                      ),
                      child: Text(l10n.deleteAccountManageSubscriptionButton),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 24),
            Text(
              l10n.deleteAccountConfirmInstructions(expectedWord),
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _confirmController,
              textCapitalization: TextCapitalization.characters,
              decoration: InputDecoration(
                labelText: l10n.deleteAccountConfirmFieldLabel,
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
                focusedBorder: const OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(14)),
                  borderSide: BorderSide(color: Colors.redAccent, width: 1.4),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isDeleting ? null : _deleteAccount,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                minimumSize: const Size(double.infinity, 54),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                elevation: 0,
              ),
              child: _isDeleting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : Text(
                      l10n.deleteAccountButton,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
