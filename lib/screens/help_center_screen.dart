import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../l10n/l10n_extensions.dart';
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

List<_FaqSection> _faqSections(BuildContext context) {
  final l10n = context.l10n;
  return [
    _FaqSection(l10n.helpCenterSectionMealsTitle, [
      _FaqItem(l10n.helpCenterMealsQ1Question, l10n.helpCenterMealsQ1Answer),
      _FaqItem(l10n.helpCenterMealsQ2Question, l10n.helpCenterMealsQ2Answer),
      _FaqItem(l10n.helpCenterMealsQ3Question, l10n.helpCenterMealsQ3Answer),
    ]),
    _FaqSection(l10n.helpCenterSectionCoachTitle, [
      _FaqItem(l10n.helpCenterCoachQ1Question, l10n.helpCenterCoachQ1Answer),
      _FaqItem(l10n.helpCenterCoachQ2Question, l10n.helpCenterCoachQ2Answer),
    ]),
    _FaqSection(l10n.helpCenterSectionRemindersTitle, [
      _FaqItem(l10n.helpCenterRemindersQ1Question, l10n.helpCenterRemindersQ1Answer),
      _FaqItem(l10n.helpCenterRemindersQ2Question, l10n.helpCenterRemindersQ2Answer),
    ]),
    _FaqSection(l10n.helpCenterSectionAccountTitle, [
      _FaqItem(l10n.helpCenterAccountQ1Question, l10n.helpCenterAccountQ1Answer),
      _FaqItem(l10n.helpCenterAccountQ2Question, l10n.helpCenterAccountQ2Answer),
      _FaqItem(l10n.helpCenterAccountQ3Question, l10n.helpCenterAccountQ3Answer(kSupportEmail)),
    ]),
  ];
}

/// FAQ groupée par thème + un lien de contact en bas pour les questions non
/// couvertes. Le contenu reflète les fonctionnalités réelles de l'app à date
/// (à mettre à jour si les écrans évoluent).
class HelpCenterScreen extends StatelessWidget {
  const HelpCenterScreen({super.key});

  Future<void> _contactSupport(BuildContext context) async {
    final uri = Uri(scheme: 'mailto', path: kSupportEmail, query: 'subject=${context.l10n.helpCenterMailtoSubject}');
    bool launched = false;
    try {
      launched = await launchUrl(uri);
    } catch (_) {
      launched = false;
    }
    if (!launched && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.helpCenterNoMailAppSnackbar(kSupportEmail))),
      );
    }
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
        title: Text(
          context.l10n.helpCenterAppBarTitle,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          children: [
            for (final section in _faqSections(context)) ...[
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
                  Text(
                    context.l10n.helpCenterNotFoundTitle,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    context.l10n.helpCenterNotFoundSubtitle,
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                  ),
                  const SizedBox(height: 14),
                  ElevatedButton.icon(
                    onPressed: () => _contactSupport(context),
                    icon: const Icon(Icons.mail_outline_rounded, size: 18),
                    label: Text(context.l10n.helpCenterContactButtonLabel),
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
