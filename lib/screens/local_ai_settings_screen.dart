import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../config/local_ai_config.dart';
import '../providers/local_ai_provider.dart';
import '../widgets/animated_async_value.dart';
import '../l10n/l10n_extensions.dart';

const Color _kPrimaryColor = Color(0xFF6B66FF);

/// Réglages de l'IA locale (scan + chat coach via Gemma3n, exécuté sur
/// l'appareil). Fonctionnalité opt-in : jamais activée par défaut, jamais
/// derrière un abonnement PRO — l'objectif est justement de réduire la
/// charge sur le quota IA cloud partagé, donc la rendre gratuite pour tout
/// le monde sert directement ce but.
class LocalAiSettingsScreen extends ConsumerWidget {
  const LocalAiSettingsScreen({super.key});

  Future<void> _confirmAndDownload(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.localAiSettingsDownloadDialogTitle),
        content: Text(
          context.l10n.localAiSettingsDownloadDialogBody(LocalAiConfig.approxSizeLabel),
        ),
        actions: [
          TextButton(onPressed: () => context.pop(false), child: Text(context.l10n.localAiSettingsCancelButton)),
          TextButton(
            onPressed: () => context.pop(true),
            child: Text(context.l10n.localAiSettingsDownloadButton, style: const TextStyle(color: _kPrimaryColor)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await ref.read(localAiSettingsProvider.notifier).startDownload();
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.localAiSettingsDownloadFailedError(e.toString()))),
        );
      }
    }
  }

  Future<void> _confirmAndDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.localAiSettingsDeleteDialogTitle),
        content: Text(
          context.l10n.localAiSettingsDeleteDialogBody,
        ),
        actions: [
          TextButton(onPressed: () => context.pop(false), child: Text(context.l10n.localAiSettingsCancelButton)),
          TextButton(
            onPressed: () => context.pop(true),
            child: Text(context.l10n.localAiSettingsDeleteButton, style: const TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(localAiSettingsProvider.notifier).deleteModel();
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(localAiSettingsProvider);

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
          context.l10n.localAiSettingsTitle,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black),
        ),
        centerTitle: true,
      ),
      body: settingsAsync.animatedWhen(
        loading: () => const Center(child: CircularProgressIndicator(color: _kPrimaryColor)),
        error: (error, stackTrace) => Center(
          child: Padding(
            padding: const EdgeInsets.all(40.0),
            child: Text(
              context.l10n.localAiSettingsLoadError,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ),
        ),
        data: (settings) => ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          children: [
            Text(
              context.l10n.localAiSettingsIntro,
              style: TextStyle(color: Colors.grey.shade600, height: 1.4),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: _kPrimaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.memory_rounded, color: _kPrimaryColor),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      context.l10n.localAiSettingsEnableLabel,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                  ),
                  Switch(
                    value: settings.enabled,
                    activeThumbColor: _kPrimaryColor,
                    onChanged: (value) => ref.read(localAiSettingsProvider.notifier).setEnabled(value),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            if (settings.enabled) _ModelStatusCard(settings: settings, onDownload: () => _confirmAndDownload(context, ref), onDelete: () => _confirmAndDelete(context, ref)),
          ],
        ),
      ),
    );
  }
}

class _ModelStatusCard extends StatelessWidget {
  final LocalAiSettings settings;
  final VoidCallback onDownload;
  final VoidCallback onDelete;

  const _ModelStatusCard({
    required this.settings,
    required this.onDownload,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: _kPrimaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  settings.isDownloaded ? Icons.check_circle_rounded : Icons.download_for_offline_outlined,
                  color: _kPrimaryColor,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      settings.isDownloaded ? context.l10n.localAiSettingsModelDownloadedLabel : context.l10n.localAiSettingsModelNotDownloadedLabel,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    Text(
                      LocalAiConfig.approxSizeLabel,
                      style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (settings.isDownloading) ...[
            LinearProgressIndicator(
              value: settings.downloadProgress,
              color: _kPrimaryColor,
              backgroundColor: _kPrimaryColor.withValues(alpha: 0.1),
            ),
            const SizedBox(height: 8),
            Text(
              context.l10n.localAiSettingsDownloadProgressLabel((settings.downloadProgress * 100).toStringAsFixed(0)),
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
            ),
          ] else if (settings.isDownloaded)
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
                label: Text(context.l10n.localAiSettingsDeleteModelButton, style: const TextStyle(color: Colors.redAccent)),
                style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.redAccent)),
              ),
            )
          else
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onDownload,
                icon: const Icon(Icons.download_rounded, color: Colors.white),
                label: Text(context.l10n.localAiSettingsDownloadButton, style: const TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(backgroundColor: _kPrimaryColor),
              ),
            ),
        ],
      ),
    );
  }
}
