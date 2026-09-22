import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

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
final List<_TermsSection> _sections = [
  const _TermsSection(
    '1. Mentions légales',
    'Éditeur : [Nom de l’éditeur à compléter] — projet actuellement développé '
        'à titre personnel, sans société immatriculée à ce jour.\n'
        'Contact : $kSupportEmail\n'
        'Hébergement des données et du backend : Supabase Inc. (infrastructure '
        'cloud tierce). Application distribuée via l’App Store (Apple) et le '
        'Google Play Store.',
  ),
  const _TermsSection(
    '2. Objet',
    'Les présentes Conditions d’Utilisation (« CGU ») régissent l’accès et '
        'l’usage de l’application mobile AI Health Chef (« l’Application »). '
        'En créant un compte ou en utilisant l’Application, tu acceptes '
        'l’intégralité des présentes CGU.',
  ),
  const _TermsSection(
    '3. Description du service',
    'AI Health Chef permet de : suivre ses repas et ses macronutriments au '
        'quotidien ; analyser une photo de repas via intelligence artificielle '
        'pour estimer les ingrédients et valeurs nutritionnelles ; échanger '
        'avec un coach nutritionnel conversationnel basé sur l’IA ; recevoir '
        'des idées de repas personnalisées ; configurer des rappels de repas ; '
        'et, via un abonnement PRO optionnel, débloquer des fonctionnalités '
        'additionnelles.',
  ),
  const _TermsSection(
    '4. Ce n’est pas un avis médical',
    'AI Health Chef fournit des informations et estimations à titre '
        'purement informatif et ne constitue en aucun cas un avis médical, '
        'un diagnostic ou une prescription. Les calculs de calories, macros '
        'et objectifs nutritionnels sont des estimations générales. '
        'Consulte un médecin ou un·e diététicien·ne avant tout changement '
        'alimentaire significatif, en particulier en cas de pathologie, de '
        'grossesse, ou de trouble du comportement alimentaire. '
        'L’Application ne doit pas être utilisée comme seul outil de suivi '
        'dans un contexte médical.',
  ),
  const _TermsSection(
    '5. Contenu généré par intelligence artificielle',
    'Les ingrédients détectés sur photo, les valeurs nutritionnelles '
        'estimées, les réponses du coach IA et les idées de repas sont '
        'générés par des modèles d’IA tiers (actuellement Google Gemini) et '
        'peuvent contenir des erreurs, imprécisions ou approximations. '
        'Vérifie et ajuste les informations avant de t’y fier, en '
        'particulier en cas d’allergie ou de restriction alimentaire.',
  ),
  const _TermsSection(
    '6. Compte utilisateur',
    'L’utilisation de l’Application nécessite la création d’un compte. Tu '
        'es responsable de l’exactitude des informations fournies et de la '
        'confidentialité de tes identifiants de connexion. Toute activité '
        'réalisée depuis ton compte est présumée effectuée par toi.',
  ),
  const _TermsSection(
    '7. Abonnement PRO',
    'Certaines fonctionnalités sont réservées aux utilisateurs abonnés '
        '(« PRO »). L’achat, le renouvellement automatique et l’annulation de '
        'l’abonnement sont intégralement gérés par la plateforme de '
        'paiement de ton appareil (App Store ou Google Play), pas '
        'directement par l’éditeur. L’abonnement se renouvelle '
        'automatiquement sauf annulation au moins 24h avant la fin de la '
        'période en cours, depuis les réglages de ton compte Apple ou '
        'Google. Les demandes de remboursement relèvent des politiques '
        'd’Apple/Google, pas de l’éditeur.',
  ),
  const _TermsSection(
    '8. Données personnelles',
    'L’Application traite notamment : ton email et ton mot de passe '
        '(authentification) ; des données de profil santé (sexe, âge, '
        'poids, taille, objectif) ; les photos de repas que tu prends et '
        'les données nutritionnelles associées ; ta photo de profil ; et '
        'l’historique de tes échanges avec le coach IA. Ces données sont '
        'utilisées uniquement pour fournir le service (calcul de tes '
        'objectifs, analyse de tes repas, suivi de ton historique) et sont '
        'hébergées par Supabase. Les photos de repas sont transmises à '
        'Google (modèle Gemini) le temps de l’analyse. Aucune donnée n’est '
        'vendue à des tiers. Tu peux demander l’accès, la rectification ou '
        'la suppression de tes données à tout moment en écrivant à '
        '$kSupportEmail.',
  ),
  const _TermsSection(
    '9. Propriété intellectuelle',
    'Le nom, le logo et les éléments graphiques de l’Application '
        'appartiennent à l’éditeur. Le contenu que tu crées (photos, '
        'messages) reste ta propriété ; tu accordes à l’éditeur le droit de '
        'le traiter uniquement dans le cadre du fonctionnement du service '
        '(ex. envoi à un fournisseur d’IA pour analyse).',
  ),
  const _TermsSection(
    '10. Responsabilité',
    'L’Application est fournie « en l’état ». L’éditeur ne garantit pas '
        'l’exactitude, la disponibilité continue ou l’absence d’erreur du '
        'service, notamment des estimations générées par IA. L’usage de '
        'l’Application se fait sous ta seule responsabilité.',
  ),
  const _TermsSection(
    '11. Résiliation',
    'Tu peux cesser d’utiliser l’Application et demander la suppression de '
        'ton compte à tout moment en écrivant à $kSupportEmail. L’éditeur '
        'peut suspendre ou supprimer un compte en cas d’usage abusif ou de '
        'non-respect des présentes CGU.',
  ),
  const _TermsSection(
    '12. Modification des CGU',
    'Les présentes CGU peuvent évoluer, notamment en fonction des '
        'fonctionnalités ajoutées à l’Application. La version en vigueur est '
        'toujours celle consultable dans l’Application.',
  ),
  const _TermsSection(
    '13. Droit applicable',
    'Les présentes CGU sont soumises au droit français.',
  ),
  const _TermsSection(
    '14. Contact',
    'Pour toute question relative à ces CGU ou à tes données : '
        '$kSupportEmail.',
  ),
];

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
        title: const Text(
          'Conditions d’utilisation',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black),
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
                      'Brouillon : ce document décrit honnêtement le service, mais '
                      'n’a pas encore été relu par un professionnel du droit et '
                      'l’identité légale de l’éditeur reste à compléter. À finaliser '
                      'avant toute publication publique de l’app.',
                      style: TextStyle(color: const Color(0xFF7A5310), fontSize: 12.5, height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Dernière mise à jour : ${_formatDate(DateTime.now())}',
              style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
            ),
            const SizedBox(height: 16),
            for (final section in _sections) ...[
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

  String _formatDate(DateTime date) {
    const months = [
      'janvier', 'février', 'mars', 'avril', 'mai', 'juin',
      'juillet', 'août', 'septembre', 'octobre', 'novembre', 'décembre',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}
