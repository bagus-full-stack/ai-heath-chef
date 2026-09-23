import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../l10n/l10n_extensions.dart';

const Color _kPrimaryColor = Color(0xFF6B66FF);
const String kSupportEmail = 'support@aihealthchef.app';

/// Écran "À propos" : identité de l'app, version installée (lue en direct
/// via package_info_plus plutôt que codée en dur, pour rester juste après un
/// changement de version) et liens vers l'aide / les conditions d'utilisation.
class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  Future<void> _contactSupport(BuildContext context) async {
    final uri = Uri(scheme: 'mailto', path: kSupportEmail, query: 'subject=${context.l10n.aboutMailtoSubject}');
    bool launched = false;
    try {
      launched = await launchUrl(uri);
    } catch (_) {
      launched = false;
    }
    if (!launched && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.aboutNoMailAppSnackbar(kSupportEmail))),
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
          context.l10n.aboutAppBarTitle,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          children: [
            Center(
              child: Column(
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: const Icon(Icons.bolt, color: Colors.white, size: 36),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    context.l10n.aboutAppName,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  FutureBuilder<PackageInfo>(
                    future: PackageInfo.fromPlatform(),
                    builder: (context, snapshot) {
                      final info = snapshot.data;
                      final versionLabel = info == null
                          ? context.l10n.aboutVersionLoading
                          : context.l10n.aboutVersionLabel(info.version, info.buildNumber);
                      return Text(
                        versionLabel,
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
            Text(
              context.l10n.aboutDescription,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade700, height: 1.5),
            ),
            const SizedBox(height: 28),
            _AboutLinkTile(
              icon: Icons.help_outline_rounded,
              title: context.l10n.aboutHelpCenterLinkTitle,
              onTap: () => context.push('/help'),
            ),
            _AboutLinkTile(
              icon: Icons.description_outlined,
              title: context.l10n.aboutTermsLinkTitle,
              onTap: () => context.push('/terms'),
            ),
            _AboutLinkTile(
              icon: Icons.mail_outline_rounded,
              title: context.l10n.aboutContactLinkTitle,
              subtitle: kSupportEmail,
              onTap: () => _contactSupport(context),
            ),
            const SizedBox(height: 28),
            Center(
              child: Text(
                context.l10n.aboutCopyright(DateTime.now().year),
                style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AboutLinkTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  const _AboutLinkTile({
    required this.icon,
    required this.title,
    required this.onTap,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: _kPrimaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: _kPrimaryColor, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(subtitle!, style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                  ],
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }
}
