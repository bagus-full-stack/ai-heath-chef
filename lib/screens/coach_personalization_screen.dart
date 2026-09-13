import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/auth_provider.dart';
import '../providers/profile_provider.dart';

const Color _kPrimaryColor = Color(0xFF6B66FF);

const List<(String value, String label, String description, IconData icon)> _kToneOptions = [
  (
    'motivant',
    'Motivant & énergique',
    'Encourageant, dynamique, te pousse à avancer.',
    Icons.bolt_rounded,
  ),
  (
    'bienveillant',
    'Bienveillant & calme',
    'Doux, rassurant, sans jugement sur tes écarts.',
    Icons.favorite_rounded,
  ),
  (
    'direct',
    'Direct & concis',
    'Droit au but, des conseils actionnables sans détour.',
    Icons.bolt_outlined,
  ),
  (
    'humoristique',
    'Humoristique',
    'Léger et avec humour, tout en restant utile.',
    Icons.emoji_emotions_rounded,
  ),
];

/// Choix du ton adopté par le Coach IA dans ses réponses (chat) — sauvegardé
/// sur le profil et transmis à l'Edge Function `coach-chat`.
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

  Future<void> _select(String tone) async {
    if (tone == _coachTone) {
      return;
    }
    setState(() {
      _coachTone = tone;
      _saving = true;
    });
    try {
      await ref.read(authServiceProvider).updateCoachTone(tone);
      ref.invalidate(profileProvider);
    } catch (e) {
      if (mounted) {
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
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black, size: 20),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Coach IA',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black),
        ),
        centerTitle: true,
        actions: [
          if (_saving)
            const Padding(
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
              'Choisis le ton que le Coach IA adopte dans ses réponses.',
              style: TextStyle(color: Colors.grey.shade600, height: 1.4),
            ),
            const SizedBox(height: 20),
            for (final option in _kToneOptions) ...[
              _ToneCard(
                icon: option.$4,
                label: option.$2,
                description: option.$3,
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
          border: Border.all(color: selected ? _kPrimaryColor : Colors.grey.shade200, width: selected ? 1.6 : 1),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: selected ? _kPrimaryColor : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: selected ? Colors.white : Colors.grey.shade600),
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
                      color: selected ? _kPrimaryColor : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(description, style: TextStyle(color: Colors.grey.shade600, fontSize: 12.5)),
                ],
              ),
            ),
            if (selected) const Icon(Icons.check_circle_rounded, color: _kPrimaryColor, size: 22),
          ],
        ),
      ),
    );
  }
}
