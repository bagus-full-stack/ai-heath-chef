import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../l10n/l10n_extensions.dart';
import 'about_screen.dart' show kSupportEmail;

/// Version du texte de la politique de confidentialité — même logique que
/// kTermsVersion dans terms_screen.dart, mais non reliée à un champ `profiles`
/// pour l'instant (pas de consentement "signature" distinct exigé ici).
const String kPrivacyPolicyVersion = '2026-10-03';

class _PrivacySection {
  final String title;
  final String body;

  const _PrivacySection(this.title, this.body);
}

// ============================================================================
// CONTENU — BROUILLON
// ----------------------------------------------------------------------------
// Résumé in-app de docs/PRIVACY_POLICY_DRAFT.md (voir ce fichier pour le
// détail complet, tableaux inclus, FR+EN). Produit à partir d'une lecture du
// code (pas du README). N'a PAS été relu par un professionnel du droit — voir
// bandeau affiché à l'écran et docs/STORE_CHECKLIST.md pour la liste des
// points à faire valider avant mise en ligne publique.
// ============================================================================
List<_PrivacySection> _sections(BuildContext context) {
  final l10n = context.l10n;
  return [
    _PrivacySection(
      l10n.privacySection1Title,
      l10n.privacySection1Body(kSupportEmail),
    ),
    _PrivacySection(l10n.privacySection2Title, l10n.privacySection2Body),
    _PrivacySection(l10n.privacySection3Title, l10n.privacySection3Body),
    _PrivacySection(l10n.privacySection4Title, l10n.privacySection4Body),
    _PrivacySection(l10n.privacySection5Title, l10n.privacySection5Body),
    _PrivacySection(l10n.privacySection6Title, l10n.privacySection6Body),
    _PrivacySection(
      l10n.privacySection7Title,
      l10n.privacySection7Body(kSupportEmail),
    ),
    _PrivacySection(l10n.privacySection8Title, l10n.privacySection8Body),
    _PrivacySection(l10n.privacySection9Title, l10n.privacySection9Body),
    _PrivacySection(
      l10n.privacySection10Title,
      l10n.privacySection10Body(kSupportEmail),
    ),
  ];
}

/// Politique de confidentialité — même pattern que terms_screen.dart
/// (bandeau de brouillon, sections numérotées via l10n). Contenu factuel
/// basé sur le code, reste un brouillon tant qu'un professionnel du droit ne
/// l'a pas relu — voir le bandeau et le commentaire au-dessus de [_sections].
class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

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
          context.l10n.privacyAppBarTitle,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
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
                  const Icon(
                    Icons.warning_amber_rounded,
                    color: Color(0xFFB8791A),
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      context.l10n.privacyDraftBanner,
                      style: TextStyle(
                        color: const Color(0xFF7A5310),
                        fontSize: 12.5,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Text(
              context.l10n.privacyLastUpdated(
                _formatDate(context, DateTime.now()),
              ),
              style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
            ),
            const SizedBox(height: 16),
            for (final section in _sections(context)) ...[
              Text(
                section.title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                section.body,
                style: TextStyle(
                  color: Colors.grey.shade700,
                  height: 1.5,
                  fontSize: 13.5,
                ),
              ),
              const SizedBox(height: 20),
            ],
          ],
        ),
      ),
    );
  }

  String _formatDate(BuildContext context, DateTime date) {
    return DateFormat.yMMMMd(
      Localizations.localeOf(context).toString(),
    ).format(date);
  }
}
