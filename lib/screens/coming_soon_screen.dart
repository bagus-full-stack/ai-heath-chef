import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../l10n/l10n_extensions.dart';
import '../config/app_colors.dart';

/// Paramètres d'affichage pour [ComingSoonScreen], passés via `extra` du
/// GoRoute '/coming-soon'. `message` reste optionnel : quand non fourni,
/// l'écran affiche `context.l10n.comingSoonDefaultMessage`.
class ComingSoonArgs {
  final String title;
  final String? message;
  final IconData icon;

  const ComingSoonArgs({
    required this.title,
    this.message,
    this.icon = Icons.hourglass_top_rounded,
  });
}

/// Écran générique pour les entrées de menu dont la fonctionnalité n'est pas
/// encore implémentée, afin d'éviter des `onTap` silencieusement vides.
class ComingSoonScreen extends StatelessWidget {
  final ComingSoonArgs? args;

  const ComingSoonScreen({super.key, this.args});

  @override
  Widget build(BuildContext context) {
    final resolved = args ?? ComingSoonArgs(title: context.l10n.comingSoonDefaultTitle);
    final message = resolved.message ?? context.l10n.comingSoonDefaultMessage;

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(tooltip: MaterialLocalizations.of(context).backButtonTooltip, 
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => context.pop(),
        ),
        title: Text(
          resolved.title,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 84,
                height: 84,
                decoration: BoxDecoration(
                  color: AppColors.brand.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(resolved.icon, color: AppColors.brand, size: 38),
              ),
              const SizedBox(height: 20),
              Text(
                resolved.title,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.grey600, height: 1.4),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
