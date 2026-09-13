import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/auth_provider.dart';
import '../providers/profile_provider.dart';

const Color _kPrimaryColor = Color(0xFF6B66FF);

const List<(String value, String label, IconData icon)> _kDietOptions = [
  ('none', 'Aucune restriction', Icons.restaurant_rounded),
  ('vegetarian', 'Végétarien', Icons.eco_rounded),
  ('vegan', 'Végétalien', Icons.spa_rounded),
  ('pescetarian', 'Pescétarien', Icons.set_meal_rounded),
  ('halal', 'Halal', Icons.mosque_rounded),
  ('kosher', 'Kasher', Icons.synagogue_rounded),
];

const List<String> _kCommonAllergies = [
  'Gluten',
  'Lactose',
  'Fruits à coque',
  'Arachides',
  'Œufs',
  'Fruits de mer',
  'Crustacés',
  'Soja',
];

/// Régime alimentaire + allergies/intolérances déclarées. Sauvegardés sur le
/// profil et pris en compte par l'IA pour les idées de repas et le Coach.
class DietaryPreferencesScreen extends ConsumerStatefulWidget {
  const DietaryPreferencesScreen({super.key});

  @override
  ConsumerState<DietaryPreferencesScreen> createState() => _DietaryPreferencesScreenState();
}

class _DietaryPreferencesScreenState extends ConsumerState<DietaryPreferencesScreen> {
  late String _dietType;
  late Set<String> _allergies;
  final _customAllergyController = TextEditingController();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final profile = ref.read(profileProvider).value;
    _dietType = profile?.dietType ?? 'none';
    _allergies = {...(profile?.allergies ?? const [])};
  }

  @override
  void dispose() {
    _customAllergyController.dispose();
    super.dispose();
  }

  void _addCustomAllergy() {
    final value = _customAllergyController.text.trim();
    if (value.isEmpty) {
      return;
    }
    setState(() {
      _allergies.add(value);
      _customAllergyController.clear();
    });
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await ref.read(authServiceProvider).updateDietaryPreferences(
            dietType: _dietType,
            allergies: _allergies.toList(),
          );
      ref.invalidate(profileProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Préférences enregistrées !'), backgroundColor: Color(0xFF45C48C)),
        );
        context.pop();
      }
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
          'Préférences alimentaires',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          children: [
            const Text('RÉGIME', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12, letterSpacing: 0.8, color: Colors.grey)),
            const SizedBox(height: 12),
            for (final option in _kDietOptions) ...[
              _SelectableRow(
                icon: option.$3,
                label: option.$2,
                selected: _dietType == option.$1,
                onTap: () => setState(() => _dietType = option.$1),
              ),
              const SizedBox(height: 10),
            ],
            const SizedBox(height: 12),
            const Text('ALLERGIES & INTOLÉRANCES', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12, letterSpacing: 0.8, color: Colors.grey)),
            const SizedBox(height: 4),
            Text(
              'Elles seront évitées dans les idées de repas proposées par l’IA. Ne remplace pas la vigilance en cas d’allergie sévère.',
              style: TextStyle(color: Colors.grey.shade500, fontSize: 12, height: 1.4),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final allergy in _kCommonAllergies)
                  FilterChip(
                    label: Text(allergy),
                    selected: _allergies.contains(allergy),
                    onSelected: (selected) => setState(() {
                      if (selected) {
                        _allergies.add(allergy);
                      } else {
                        _allergies.remove(allergy);
                      }
                    }),
                    selectedColor: _kPrimaryColor.withValues(alpha: 0.15),
                    checkmarkColor: _kPrimaryColor,
                    labelStyle: TextStyle(
                      color: _allergies.contains(allergy) ? _kPrimaryColor : Colors.black87,
                      fontWeight: FontWeight.w600,
                    ),
                    side: BorderSide(color: _allergies.contains(allergy) ? _kPrimaryColor : Colors.grey.shade300),
                  ),
                for (final allergy in _allergies.where((a) => !_kCommonAllergies.contains(a)))
                  FilterChip(
                    label: Text(allergy),
                    selected: true,
                    onSelected: (_) => setState(() => _allergies.remove(allergy)),
                    selectedColor: _kPrimaryColor.withValues(alpha: 0.15),
                    checkmarkColor: _kPrimaryColor,
                    labelStyle: const TextStyle(color: _kPrimaryColor, fontWeight: FontWeight.w600),
                    side: const BorderSide(color: _kPrimaryColor),
                  ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _customAllergyController,
                    textCapitalization: TextCapitalization.sentences,
                    onSubmitted: (_) => _addCustomAllergy(),
                    decoration: InputDecoration(
                      hintText: 'Autre allergie...',
                      filled: true,
                      fillColor: Colors.grey.shade50,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: Colors.grey.shade200),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                IconButton(
                  onPressed: _addCustomAllergy,
                  icon: const Icon(Icons.add_circle, color: _kPrimaryColor, size: 30),
                ),
              ],
            ),
            const SizedBox(height: 28),
            ElevatedButton(
              onPressed: _saving ? null : _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: _kPrimaryColor,
                minimumSize: const Size(double.infinity, 54),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
              child: _saving
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white),
                    )
                  : const Text('Enregistrer', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }
}

class _SelectableRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _SelectableRow({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected ? _kPrimaryColor.withValues(alpha: 0.08) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: selected ? _kPrimaryColor : Colors.grey.shade200, width: selected ? 1.6 : 1),
        ),
        child: Row(
          children: [
            Icon(icon, color: selected ? _kPrimaryColor : Colors.grey.shade600),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: selected ? _kPrimaryColor : Colors.black87,
                ),
              ),
            ),
            if (selected) const Icon(Icons.check_circle_rounded, color: _kPrimaryColor, size: 20),
          ],
        ),
      ),
    );
  }
}
