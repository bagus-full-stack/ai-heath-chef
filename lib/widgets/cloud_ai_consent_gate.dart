import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../l10n/l10n_extensions.dart';
import '../providers/ai_consent_provider.dart';

const _primaryColor = Color(0xFF6B66FF);

class _ConsentExplanation extends StatelessWidget {
  final VoidCallback onAccept;
  final VoidCallback onDecline;

  const _ConsentExplanation({required this.onAccept, required this.onDecline});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Icon(Icons.cloud_outlined, size: 40, color: Colors.grey),
        const SizedBox(height: 16),
        Text(
          context.l10n.cloudAiConsentTitle,
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 10),
        Text(
          context.l10n.cloudAiConsentBody,
          style: TextStyle(
            color: Colors.grey.shade700,
            height: 1.5,
            fontSize: 13.5,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 22),
        ElevatedButton(
          onPressed: onAccept,
          style: ElevatedButton.styleFrom(
            backgroundColor: _primaryColor,
            minimumSize: const Size.fromHeight(50),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: Text(
            context.l10n.cloudAiConsentAccept,
            style: const TextStyle(color: Colors.white),
          ),
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: onDecline,
          child: Text(context.l10n.cloudAiConsentDecline),
        ),
      ],
    );
  }
}

/// Bloque [child] tant que l'utilisateur n'a pas explicitement accepté
/// l'envoi de photo/texte à l'IA cloud (voir ai_consent_provider.dart) — à
/// poser en tête du build() des écrans qui déclenchent systématiquement
/// analyze-meal/menu/pantry/product, meal-suggestions ou meal-images dès
/// leur ouverture. [onGranted] (optionnel) ne se déclenche qu'une fois, la
/// première fois que le consentement est constaté accordé — utile pour
/// lancer l'appel IA qu'on ne voulait justement pas déclencher avant.
class CloudAiConsentGate extends ConsumerStatefulWidget {
  final Widget child;
  final VoidCallback? onGranted;

  /// Certains écrans ne déclenchent un appel cloud que pour une partie de
  /// leurs flux (ex. meal_analysis_screen.dart : une photo part vers l'IA
  /// cloud, un code-barres ou une saisie manuelle non). Passer `false` dans
  /// ces cas-là pour court-circuiter entièrement le gate plutôt que de
  /// dupliquer l'écran.
  final bool enabled;

  const CloudAiConsentGate({
    super.key,
    required this.child,
    this.onGranted,
    this.enabled = true,
  });

  @override
  ConsumerState<CloudAiConsentGate> createState() => _CloudAiConsentGateState();
}

class _CloudAiConsentGateState extends ConsumerState<CloudAiConsentGate> {
  bool _fired = false;

  void _fireOnGrantedOnce() {
    if (_fired) return;
    _fired = true;
    final callback = widget.onGranted;
    if (callback != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => callback());
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) return widget.child;
    final consent = ref.watch(cloudAiConsentProvider);
    return consent.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (_, _) {
        // Best-effort : une erreur de lecture locale ne doit pas bloquer
        // l'écran (SharedPreferences indisponible est un cas limite rare).
        _fireOnGrantedOnce();
        return widget.child;
      },
      data: (given) {
        if (!given) {
          return Scaffold(
            backgroundColor: Colors.white,
            appBar: AppBar(
              backgroundColor: Colors.white,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(
                  Icons.arrow_back_ios,
                  color: Colors.black,
                  size: 20,
                ),
                onPressed: () => context.pop(),
              ),
            ),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: _ConsentExplanation(
                  onAccept: () =>
                      ref.read(cloudAiConsentProvider.notifier).accept(),
                  onDecline: () => context.pop(),
                ),
              ),
            ),
          );
        }
        _fireOnGrantedOnce();
        return widget.child;
      },
    );
  }
}

/// Variante imperative de [CloudAiConsentGate], pour les écrans où l'appel
/// cloud n'est pas systématique à l'ouverture mais déclenché par un geste
/// explicite (ex. bouton "envoyer" du chat coach) — bloquer tout l'écran
/// serait trop large, on ne bloque que ce geste précis.
Future<bool> ensureCloudAiConsent(BuildContext context, WidgetRef ref) async {
  final current = ref.read(cloudAiConsentProvider).value;
  if (current == true) return true;

  final accepted = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: _ConsentExplanation(
          onAccept: () => Navigator.pop(dialogContext, true),
          onDecline: () => Navigator.pop(dialogContext, false),
        ),
      ),
    ),
  );

  if (accepted == true) {
    await ref.read(cloudAiConsentProvider.notifier).accept();
    return true;
  }
  return false;
}
