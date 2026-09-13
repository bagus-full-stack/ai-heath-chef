import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import 'about_screen.dart' show kSupportEmail;

const Color _kPrimaryColor = Color(0xFF6B66FF);

class _FaqItem {
  final String question;
  final String answer;

  const _FaqItem(this.question, this.answer);
}

class _FaqSection {
  final String title;
  final List<_FaqItem> items;

  const _FaqSection(this.title, this.items);
}

const List<_FaqSection> _faqSections = [
  _FaqSection('Repas & analyse IA', [
    _FaqItem(
      'Comment enregistrer un repas ?',
      'Depuis le Dashboard, appuie sur le bouton caméra en bas à droite pour '
          'prendre en photo ton assiette. L’IA identifie les ingrédients et '
          'estime les calories et macros ; tu peux ajuster les quantités, '
          'ajouter ou retirer un ingrédient avant de valider.',
    ),
    _FaqItem(
      'L’estimation des calories est-elle exacte ?',
      'L’analyse est faite par un modèle d’IA (Google Gemini) à partir de la '
          'photo : c’est une estimation, pas une mesure exacte. Ajuste les '
          'quantités si besoin, ou ajoute un ingrédient manuellement avec ses '
          'valeurs exactes via "Ajouter un ingrédient".',
    ),
    _FaqItem(
      'Où voir les repas que j’ai enregistrés aujourd’hui ?',
      'Le Dashboard affiche le "Journal des repas" du jour, avec les totaux '
          'de calories et macros. Il se réinitialise chaque jour à minuit.',
    ),
  ]),
  _FaqSection('Coach IA & idées de repas', [
    _FaqItem(
      'Comment parler au Coach IA ?',
      'Depuis l’onglet Coach, appuie sur le bouton "Coach IA" en bas de '
          'l’écran pour ouvrir le chat. Tu peux lui poser des questions sur '
          'ta nutrition, tes objectifs ou lui demander des conseils.',
    ),
    _FaqItem(
      'Comment obtenir de nouvelles idées de repas ?',
      'L’onglet Coach propose des idées de repas générées selon ton profil '
          'et ton objectif. Appuie sur "Tout voir" pour la liste complète, '
          'puis sur l’icône de rafraîchissement (ou tire l’écran vers le bas) '
          'pour en générer de nouvelles.',
    ),
  ]),
  _FaqSection('Rappels & notifications', [
    _FaqItem(
      'Comment activer les rappels de repas ?',
      'Va dans Profil > Notifications. Active l’interrupteur du repas '
          'souhaité (petit-déjeuner, déjeuner, dîner) et choisis l’heure du '
          'rappel en appuyant sur l’horaire affiché.',
    ),
    _FaqItem(
      'Je n’ai reçu aucune notification, que faire ?',
      'Vérifie que les notifications sont autorisées pour l’app dans les '
          'réglages de ton téléphone. Sur certains téléphones Android, il '
          'faut aussi désactiver l’optimisation de batterie pour l’app afin '
          'que les rappels sonnent à l’heure prévue.',
    ),
  ]),
  _FaqSection('Compte & abonnement', [
    _FaqItem(
      'Comment modifier mon profil ou mes objectifs ?',
      'Va dans Profil > Compte pour modifier tes informations, ou Profil > '
          'Mes objectifs pour ajuster ton objectif (perte de poids, prise de '
          'muscle, maintien) et tes données physiques.',
    ),
    _FaqItem(
      'Comment gérer ou annuler mon abonnement PRO ?',
      'Ton abonnement est géré directement par l’App Store ou le Google '
          'Play Store (selon ton appareil), pas par l’app elle-même. Rends-toi '
          'dans les réglages d’abonnements de ton compte Apple/Google pour le '
          'modifier ou le résilier.',
    ),
    _FaqItem(
      'Comment supprimer mon compte ?',
      'Écris-nous à $kSupportEmail depuis l’adresse email associée à ton '
          'compte, on s’occupe de la suppression de tes données.',
    ),
  ]),
];

/// FAQ groupée par thème + un lien de contact en bas pour les questions non
/// couvertes. Le contenu reflète les fonctionnalités réelles de l'app à date
/// (à mettre à jour si les écrans évoluent).
class HelpCenterScreen extends StatelessWidget {
  const HelpCenterScreen({super.key});

  Future<void> _contactSupport() async {
    final uri = Uri(scheme: 'mailto', path: kSupportEmail, query: 'subject=Question AI Health Chef');
    await launchUrl(uri);
  }

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
          'Centre d’aide',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          children: [
            for (final section in _faqSections) ...[
              Padding(
                padding: const EdgeInsets.only(top: 16, bottom: 8),
                child: Text(
                  section.title.toUpperCase(),
                  style: TextStyle(
                    color: Colors.grey.shade500,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  children: [
                    for (var i = 0; i < section.items.length; i++) ...[
                      if (i > 0) const Divider(height: 1),
                      Theme(
                        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                        child: ExpansionTile(
                          title: Text(
                            section.items[i].question,
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                          ),
                          iconColor: _kPrimaryColor,
                          collapsedIconColor: Colors.grey.shade400,
                          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                          expandedCrossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              section.items[i].answer,
                              style: TextStyle(color: Colors.grey.shade600, height: 1.45, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: _kPrimaryColor.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: _kPrimaryColor.withValues(alpha: 0.15)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Tu n’as pas trouvé ta réponse ?',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Écris-nous, on te répond directement.',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                  ),
                  const SizedBox(height: 14),
                  ElevatedButton.icon(
                    onPressed: _contactSupport,
                    icon: const Icon(Icons.mail_outline_rounded, size: 18),
                    label: const Text('Contacter le support'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _kPrimaryColor,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 48),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
