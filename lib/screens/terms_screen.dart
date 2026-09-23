import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../l10n/l10n_extensions.dart';
import 'about_screen.dart' show kSupportEmail;

class _TermsSection {
  final String title;
  final String body;

  const _TermsSection(this.title, this.body);
}

// ============================================================================
// CONTENU JURIDIQUE — BROUILLON
// ----------------------------------------------------------------------------
// Ce texte décrit honnêtement ce que l'app fait réellement (fonctionnalités,
// sous-traitants techniques, absence de conseil médical, abonnement géré par
// les stores). Il n'a PAS été relu par un professionnel du droit et l'éditeur
// n'est pas encore identifié formellement (voir bandeau affiché à l'écran).
// À faire avant toute mise en ligne publique :
//   1. Faire relire/valider par un avocat (droit du numérique / santé).
//   2. Remplacer "[Nom de l'éditeur à compléter]" par l'identité légale réelle.
//   3. Mettre à jour l'email de contact si besoin (actuellement kSupportEmail).
// ============================================================================
List<_TermsSection> _sections(BuildContext context) {
  final l10n = context.l10n;
  return [
    _TermsSection(l10n.termsSection1Title, l10n.termsSection1Body(kSupportEmail)),
    _TermsSection(l10n.termsSection2Title, l10n.termsSection2Body),
    _TermsSection(l10n.termsSection3Title, l10n.termsSection3Body),
    _TermsSection(l10n.termsSection4Title, l10n.termsSection4Body),
    _TermsSection(l10n.termsSection5Title, l10n.termsSection5Body),
    _TermsSection(l10n.termsSection6Title, l10n.termsSection6Body),
    _TermsSection(l10n.termsSection7Title, l10n.termsSection7Body),
    _TermsSection(l10n.termsSection8Title, l10n.termsSection8Body(kSupportEmail)),
    _TermsSection(l10n.termsSection9Title, l10n.termsSection9Body),
    _TermsSection(l10n.termsSection10Title, l10n.termsSection10Body),
    _TermsSection(l10n.termsSection11Title, l10n.termsSection11Body(kSupportEmail)),
    _TermsSection(l10n.termsSection12Title, l10n.termsSection12Body),
    _TermsSection(l10n.termsSection13Title, l10n.termsSection13Body),
    _TermsSection(l10n.termsSection14Title, l10n.termsSection14Body(kSupportEmail)),
  ];
}

/// CGU + mentions légales de l'app. Contenu honnête sur ce que fait le
/// service, mais reste un brouillon tant que l'éditeur n'a pas d'identité
/// légale formelle et qu'un professionnel du droit ne l'a pas relu — voir le
/// bandeau affiché en haut de l'écran et le commentaire au-dessus de
/// [_sections].
class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black, size: 20),
          onPressed: () => context.pop(),
        ),
        title: Text(
          context.l10n.termsAppBarTitle,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF4E5),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFFFD9A0)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.warning_amber_rounded, color: Color(0xFFB8791A), size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      context.l10n.termsDraftBanner,
                      style: TextStyle(color: const Color(0xFF7A5310), fontSize: 12.5, height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Text(
              context.l10n.termsLastUpdated(_formatDate(context, DateTime.now())),
              style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
            ),
            const SizedBox(height: 16),
            for (final section in _sections(context)) ...[
              Text(
                section.title,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
              const SizedBox(height: 6),
              Text(
                section.body,
                style: TextStyle(color: Colors.grey.shade700, height: 1.5, fontSize: 13.5),
              ),
              const SizedBox(height: 20),
            ],
          ],
        ),
      ),
    );
  }

  String _formatDate(BuildContext context, DateTime date) {
    return DateFormat.yMMMMd(Localizations.localeOf(context).toString()).format(date);
  }
}
