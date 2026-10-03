import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../l10n/l10n_extensions.dart';

class _Attribution {
  final String name;
  final String body;
  final String? url;

  const _Attribution({required this.name, required this.body, this.url});
}

/// Attributions qu'aucune licence de package Flutter ne couvre : données
/// Open Food Facts (ODbL), modèle Gemma3n (conditions Google, distinctes de
/// la licence MIT du plugin flutter_gemma), modèle FLUX.1 [schnell]
/// (Apache 2.0, via Cloudflare Workers AI), Pollinations.ai. Les licences des
/// dépendances pub.dev elles-mêmes sont couvertes par showLicensePage
/// ci-dessous (toutes MIT/BSD/Apache-2.0, vérifié dans cette tâche).
List<_Attribution> _attributions(BuildContext context) => [
  _Attribution(
    name: 'Open Food Facts',
    body: context.l10n.licensesOpenFoodFactsBody,
    url: 'https://world.openfoodfacts.org',
  ),
  _Attribution(
    name: 'Gemma 3n',
    body: context.l10n.licensesGemmaBody,
    url: 'https://ai.google.dev/gemma/terms',
  ),
  _Attribution(name: 'FLUX.1 [schnell]', body: context.l10n.licensesFluxBody),
  _Attribution(
    name: 'Pollinations.ai',
    body: context.l10n.licensesPollinationsBody,
    url: 'https://pollinations.ai',
  ),
];

class LicensesScreen extends StatelessWidget {
  const LicensesScreen({super.key});

  Future<void> _openUrl(String url) async {
    try {
      await launchUrl(Uri.parse(url));
    } catch (_) {
      // Best-effort : pas de connexion ou pas de navigateur disponible.
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
          context.l10n.licensesAppBarTitle,
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
            Text(
              context.l10n.licensesIntro,
              style: TextStyle(
                color: Colors.grey.shade700,
                height: 1.5,
                fontSize: 13.5,
              ),
            ),
            const SizedBox(height: 20),
            for (final attribution in _attributions(context)) ...[
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      attribution.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      attribution.body,
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        height: 1.4,
                        fontSize: 13,
                      ),
                    ),
                    if (attribution.url != null) ...[
                      const SizedBox(height: 8),
                      InkWell(
                        onTap: () => _openUrl(attribution.url!),
                        child: Text(
                          attribution.url!,
                          style: const TextStyle(
                            color: Color(0xFF6B66FF),
                            fontSize: 12.5,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: () async {
                final info = await PackageInfo.fromPlatform();
                if (!context.mounted) return;
                showLicensePage(
                  context: context,
                  applicationName: context.l10n.aboutAppName,
                  applicationVersion: info.version,
                );
              },
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 54),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
              child: Text(context.l10n.licensesOpenSourceButton),
            ),
          ],
        ),
      ),
    );
  }
}
