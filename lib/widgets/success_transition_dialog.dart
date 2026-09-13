import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Dialogue modal affichant un indicateur de chargement, qui se transforme
/// en confirmation visuelle (cercle vert + check, avec un léger effet de
/// zoom) une fois [isSuccess] passé à `true`. Donne un vrai "moment de
/// récompense" aux actions importantes (sauvegarder un repas, valider un
/// achat) au lieu d'une coupure instantanée suivie d'un simple SnackBar.
///
/// Usage : créer un `ValueNotifier<bool>(false)`, l'utiliser comme
/// `isSuccess` dans `showDialog(builder: (_) => SuccessTransitionDialog(...))`,
/// puis une fois l'opération terminée, passer `notifier.value = true`,
/// attendre un court instant pour laisser l'animation se voir, puis fermer
/// le dialogue (`Navigator.pop`).
class SuccessTransitionDialog extends StatefulWidget {
  final ValueListenable<bool> isSuccess;
  final Color successColor;
  final Color loadingColor;

  /// Message optionnel affiché sous le check une fois le succès atteint
  /// (ex. "Bienvenue en PRO !"). Sans lui, seul le cercle animé s'affiche.
  final String? successMessage;

  const SuccessTransitionDialog({
    super.key,
    required this.isSuccess,
    this.successColor = const Color(0xFF45C48C),
    this.loadingColor = const Color(0xFF6B66FF),
    this.successMessage,
  });

  @override
  State<SuccessTransitionDialog> createState() =>
      _SuccessTransitionDialogState();
}

class _SuccessTransitionDialogState extends State<SuccessTransitionDialog> {
  @override
  void initState() {
    super.initState();
    widget.isSuccess.addListener(_onChange);
  }

  void _onChange() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    widget.isSuccess.removeListener(_onChange);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final success = widget.isSuccess.value;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 48),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          transitionBuilder: (child, animation) => ScaleTransition(
            scale: animation,
            child: FadeTransition(opacity: animation, child: child),
          ),
          child: success
              ? Column(
                  key: const ValueKey('success'),
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: widget.successColor,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check_rounded,
                        color: Colors.white,
                        size: 40,
                      ),
                    ),
                    if (widget.successMessage != null) ...[
                      const SizedBox(height: 16),
                      Text(
                        widget.successMessage!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ],
                )
              : SizedBox(
                  key: const ValueKey('loading'),
                  width: 48,
                  height: 48,
                  child: CircularProgressIndicator(color: widget.loadingColor),
                ),
        ),
      ),
    );
  }
}
