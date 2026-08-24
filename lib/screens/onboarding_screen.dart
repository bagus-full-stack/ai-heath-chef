import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../providers/auth_provider.dart';
import '../providers/onboarding_provider.dart';

/// Ordre d'affichage des objectifs, aligné sur la maquette (Onboarding.png) :
/// Perdre du poids, Maintenir mon poids, Prendre de la masse.
const _goalDisplayOrder = [
  OnboardingGoal.loseWeight,
  OnboardingGoal.maintain,
  OnboardingGoal.gainMuscle,
];

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();

  bool _isSubmitting = false;
  OnboardingSex? _selectedSex;
  OnboardingGoal? _selectedGoal;

  static const Color _primaryColor = Color(0xFF6B66FF);

  @override
  void dispose() {
    _ageController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.redAccent),
    );
  }

  Future<void> _handleSubmit() async {
    if (_isSubmitting) {
      return;
    }

    if (_selectedSex == null) {
      _showError('Choisis ton sexe pour continuer.');
      return;
    }

    final age = int.tryParse(_ageController.text.trim());
    if (age == null || age < 10 || age > 120) {
      _showError('Entre un âge valide.');
      return;
    }

    final weight = double.tryParse(_weightController.text.trim().replaceAll(',', '.'));
    if (weight == null || weight <= 0 || weight > 400) {
      _showError('Entre ton poids.');
      return;
    }

    if (_selectedGoal == null) {
      _showError('Choisis ton objectif principal.');
      return;
    }

    final sex = _selectedSex!;
    final goal = _selectedGoal!;

    setState(() => _isSubmitting = true);

    try {
      // Le poids cible est initialisé au poids actuel (objectif "maintien"
      // par défaut) ; il pourra être ajusté ensuite depuis Profil > Mes
      // objectifs.
      ref.read(onboardingProvider.notifier).saveProfile(
            sex: sex,
            age: age,
            currentWeight: weight,
            targetWeight: weight,
            goal: goal,
          );

      final authService = ref.read(authServiceProvider);
      if (authService.currentUser != null) {
        await authService.upsertProfile(
          sex: sex.name,
          age: age,
          currentWeight: weight,
          targetWeight: weight,
          goal: goal.name,
        );
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('showOnboarding', false);

      if (!mounted) {
        return;
      }

      context.go('/');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Impossible d’enregistrer le profil : $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  String _sexLabel(OnboardingSex sex) {
    switch (sex) {
      case OnboardingSex.male:
        return 'Homme';
      case OnboardingSex.female:
        return 'Femme';
      case OnboardingSex.other:
        return 'Autre';
    }
  }

  IconData _sexIcon(OnboardingSex sex) {
    switch (sex) {
      case OnboardingSex.male:
        return Icons.male;
      case OnboardingSex.female:
        return Icons.female;
      case OnboardingSex.other:
        return Icons.transgender;
    }
  }

  String _goalLabel(OnboardingGoal goal) {
    switch (goal) {
      case OnboardingGoal.loseWeight:
        return 'Perdre du poids';
      case OnboardingGoal.gainMuscle:
        return 'Prendre de la masse';
      case OnboardingGoal.maintain:
        return 'Maintenir mon poids';
    }
  }

  String _goalDescription(OnboardingGoal goal) {
    switch (goal) {
      case OnboardingGoal.loseWeight:
        return 'Réduire l’apport calorique et brûler les graisses.';
      case OnboardingGoal.gainMuscle:
        return 'Augmenter l’apport pour prendre du muscle.';
      case OnboardingGoal.maintain:
        return 'Équilibrer les macros pour une santé stable.';
    }
  }

  IconData _goalIcon(OnboardingGoal goal) {
    switch (goal) {
      case OnboardingGoal.loseWeight:
        return Icons.trending_down;
      case OnboardingGoal.gainMuscle:
        return Icons.fitness_center;
      case OnboardingGoal.maintain:
        return Icons.track_changes;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            Positioned(
              top: -60,
              right: -40,
              child: Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  color: _primaryColor.withValues(alpha: 0.06),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Positioned(
              top: 200,
              left: -50,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.pinkAccent.withValues(alpha: 0.05),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: _primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: const Text(
                      'Étape 1 sur 2',
                      style: TextStyle(
                        color: _primaryColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'Apprenons à nous connaître',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      height: 1.15,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Ces informations permettent à notre IA de calculer votre besoin calorique précis.',
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.grey.shade600,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 28),
                  _SectionHeader(icon: Icons.people_alt_outlined, label: 'Vous êtes...'),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _sexCard(OnboardingSex.male),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _sexCard(OnboardingSex.female),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: _sexChip(OnboardingSex.other),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _SectionHeader(icon: Icons.calendar_today_outlined, label: 'Votre Âge'),
                            const SizedBox(height: 10),
                            TextField(
                              controller: _ageController,
                              keyboardType: TextInputType.number,
                              textInputAction: TextInputAction.next,
                              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                              decoration: _fieldDecoration(hintText: '25', suffixText: 'ans'),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _SectionHeader(icon: Icons.balance_outlined, label: 'Votre Poids'),
                            const SizedBox(height: 10),
                            TextField(
                              controller: _weightController,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              textInputAction: TextInputAction.done,
                              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                              decoration: _fieldDecoration(hintText: '70', suffixText: 'kg'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _SectionHeader(icon: Icons.track_changes_outlined, label: 'Quel est votre objectif ?'),
                  const SizedBox(height: 10),
                  for (final goal in _goalDisplayOrder) ...[
                    _goalCard(goal),
                    if (goal != _goalDisplayOrder.last) const SizedBox(height: 12),
                  ],
                  const SizedBox(height: 28),
                  ElevatedButton(
                    onPressed: _isSubmitting ? null : _handleSubmit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _primaryColor,
                      minimumSize: const Size(double.infinity, 56),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                      elevation: 0,
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Calculer mon plan',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              SizedBox(width: 8),
                              Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 20),
                            ],
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

  Widget _sexCard(OnboardingSex sex) {
    final selected = _selectedSex == sex;
    return InkWell(
      onTap: () => setState(() => _selectedSex = sex),
      borderRadius: BorderRadius.circular(18),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: selected ? _primaryColor.withValues(alpha: 0.08) : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected ? _primaryColor : Colors.grey.shade300,
            width: selected ? 1.6 : 1.2,
          ),
        ),
        child: Column(
          children: [
            Icon(_sexIcon(sex), color: selected ? _primaryColor : Colors.black54, size: 26),
            const SizedBox(height: 8),
            Text(
              _sexLabel(sex),
              style: TextStyle(
                color: selected ? _primaryColor : Colors.black87,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sexChip(OnboardingSex sex) {
    final selected = _selectedSex == sex;
    return InkWell(
      onTap: () => setState(() => _selectedSex = sex),
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? _primaryColor.withValues(alpha: 0.08) : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: selected ? _primaryColor : Colors.grey.shade300),
        ),
        child: Text(
          _sexLabel(sex),
          style: TextStyle(
            color: selected ? _primaryColor : Colors.grey.shade600,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _goalCard(OnboardingGoal goal) {
    final selected = _selectedGoal == goal;
    return InkWell(
      onTap: () => setState(() => _selectedGoal = goal),
      borderRadius: BorderRadius.circular(22),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected ? _primaryColor.withValues(alpha: 0.06) : Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: selected ? _primaryColor : Colors.grey.shade200,
            width: selected ? 1.6 : 1.2,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: selected ? _primaryColor : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(_goalIcon(goal), color: selected ? Colors.white : Colors.black54),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _goalLabel(goal),
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    _goalDescription(goal),
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600, height: 1.35),
                  ),
                ],
              ),
            ),
            if (selected) ...[
              const SizedBox(width: 8),
              const Icon(Icons.check_circle_rounded, color: _primaryColor, size: 22),
            ],
          ],
        ),
      ),
    );
  }

  InputDecoration _fieldDecoration({required String hintText, required String suffixText}) {
    return InputDecoration(
      hintText: hintText,
      suffixText: suffixText,
      filled: true,
      fillColor: Colors.grey.shade50,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: _primaryColor, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String label;

  const _SectionHeader({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.black54),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}
