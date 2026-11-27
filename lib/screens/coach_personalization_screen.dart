import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../l10n/l10n_extensions.dart';
import '../providers/auth_provider.dart';
import '../providers/profile_provider.dart';
import '../config/app_colors.dart';

Color get _kPrimaryColor => AppColors.brand;

const List<(String value, IconData icon)> _kToneOptions = [
  ('motivant', Icons.bolt_rounded),
  ('bienveillant', Icons.favorite_rounded),
  ('direct', Icons.arrow_forward_rounded),
  ('humoristique', Icons.emoji_emotions_rounded),
];

/// Choix du ton adopté par le Coach IA dans ses réponses (chat) — sauvegardé
/// sur le profil et transmis à l'Edge Function `hc-coach-chat`.
class CoachPersonalizationScreen extends ConsumerStatefulWidget {
  const CoachPersonalizationScreen({super.key});

  @override
  ConsumerState<CoachPersonalizationScreen> createState() => _CoachPersonalizationScreenState();
}

class _CoachPersonalizationScreenState extends ConsumerState<CoachPersonalizationScreen> {
  late String _coachTone;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _coachTone = ref.read(profileProvider).value?.coachTone ?? 'motivant';
  }

  (String label, String description) _toneCopy(String tone) {
    return switch (tone) {
      'motivant' => (
          context.l10n.coachPersonalizationToneMotivantLabel,
          context.l10n.coachPersonalizationToneMotivantDescription,
        ),
      'bienveillant' => (
          context.l10n.coachPersonalizationToneBienveillantLabel,
          context.l10n.coachPersonalizationToneBienveillantDescription,
        ),
      'direct' => (
          context.l10n.coachPersonalizationToneDirectLabel,
          context.l10n.coachPersonalizationToneDirectDescription,
        ),
      'humoristique' => (
          context.l10n.coachPersonalizationToneHumoristiqueLabel,
          context.l10n.coachPersonalizationToneHumoristiqueDescription,
        ),
      _ => (tone, ''),
    };
  }

  Future<void> _select(String tone) async {
    if (tone == _coachTone) {
      return;
    }
    final previousTone = _coachTone;
    setState(() {
      _coachTone = tone;
      _saving = true;
    });
    try {
      await ref.read(authServiceProvider).updateCoachTone(
            tone,
            lang: Localizations.localeOf(context).languageCode,
          );
      ref.invalidate(profileProvider);
    } catch (e) {
      if (mounted) {
        setState(() => _coachTone = previousTone);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.redAccent),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(tooltip: MaterialLocalizations.of(context).backButtonTooltip, 
          icon: Icon(Icons.arrow_back_ios, color: AppColors.ink, size: 20),
          onPressed: () => context.pop(),
        ),
        title: Text(
          context.l10n.coachPersonalizationAppBarTitle,
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.ink),
        ),
        centerTitle: true,
        actions: [
          if (_saving)
            Padding(
              padding: EdgeInsets.only(right: 20),
              child: Center(
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: _kPrimaryColor),
                ),
              ),
            ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          children: [
            Text(
              context.l10n.coachPersonalizationIntro,
              style: TextStyle(color: AppColors.grey600, height: 1.4),
            ),
            const SizedBox(height: 20),
            for (final option in _kToneOptions) ...[
              _ToneCard(
                icon: option.$2,
                label: _toneCopy(option.$1).$1,
                description: _toneCopy(option.$1).$2,
                selected: _coachTone == option.$1,
                onTap: () => _select(option.$1),
              ),
              const SizedBox(height: 12),
            ],
          ],
        ),
      ),
    );
  }
}

class _ToneCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String description;
  final bool selected;
  final VoidCallback onTap;

  const _ToneCard({
    required this.icon,
    required this.label,
    required this.description,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected ? _kPrimaryColor.withValues(alpha: 0.08) : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: selected ? _kPrimaryColor : AppColors.grey200, width: selected ? 1.6 : 1),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: selected ? _kPrimaryColor : AppColors.grey100,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: selected ? Colors.white : AppColors.grey600),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: selected ? _kPrimaryColor : AppColors.ink87,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(description, style: TextStyle(color: AppColors.grey600, fontSize: 12.5)),
                ],
              ),
            ),
            if (selected) Icon(Icons.check_circle_rounded, color: _kPrimaryColor, size: 22),
          ],
        ),
      ),
    );
  }
}
