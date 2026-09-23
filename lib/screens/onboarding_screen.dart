import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../l10n/l10n_extensions.dart';
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
  final TextEditingController _heightController = TextEditingController();

  bool _isSubmitting = false;
  OnboardingSex? _selectedSex;
  OnboardingGoal? _selectedGoal;

  static const Color _primaryColor = Color(0xFF6B66FF);

  @override
  void dispose() {
    _ageController.dispose();
    _weightController.dispose();
    _heightController.dispose();
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
      _showError(context.l10n.onboardingErrorSexRequired);
      return;
    }

    final age = int.tryParse(_ageController.text.trim());
    if (age == null || age < 10 || age > 120) {
      _showError(context.l10n.onboardingErrorInvalidAge);
      return;
    }

    final weight = double.tryParse(_weightController.text.trim().replaceAll(',', '.'));
    if (weight == null || weight <= 0 || weight > 400) {
      _showError(context.l10n.onboardingErrorInvalidWeight);
      return;
    }

    final height = double.tryParse(_heightController.text.trim().replaceAll(',', '.'));
    if (height == null || height < 100 || height > 250) {
      _showError(context.l10n.onboardingErrorInvalidHeight);
      return;
    }

    if (_selectedGoal == null) {
      _showError(context.l10n.onboardingErrorGoalRequired);
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
            heightCm: height,
            goal: goal,
          );

      final authService = ref.read(authServiceProvider);
      if (authService.currentUser != null) {
        await authService.upsertProfile(
          sex: sex.name,
          age: age,
          currentWeight: weight,
          targetWeight: weight,
          heightCm: height,
          goal: goal.name,
          lang: Localizations.localeOf(context).languageCode,
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
            content: Text(context.l10n.onboardingErrorSaveProfile(e.toString())),
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
        return context.l10n.onboardingSexMale;
      case OnboardingSex.female:
        return context.l10n.onboardingSexFemale;
      case OnboardingSex.other:
        return context.l10n.onboardingSexOther;
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
        return context.l10n.onboardingGoalLoseWeight;
      case OnboardingGoal.gainMuscle:
        return context.l10n.onboardingGoalGainMuscle;
      case OnboardingGoal.maintain:
        return context.l10n.onboardingGoalMaintain;
    }
  }

  String _goalDescription(OnboardingGoal goal) {
    switch (goal) {
      case OnboardingGoal.loseWeight:
        return context.l10n.onboardingGoalLoseWeightDescription;
      case OnboardingGoal.gainMuscle:
        return context.l10n.onboardingGoalGainMuscleDescription;
      case OnboardingGoal.maintain:
        return context.l10n.onboardingGoalMaintainDescription;
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
                    child: Text(
                      context.l10n.onboardingStepIndicator,
                      style: const TextStyle(
                        color: _primaryColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    context.l10n.onboardingTitle,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      height: 1.15,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    context.l10n.onboardingSubtitle,
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.grey.shade600,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 28),
                  _SectionHeader(icon: Icons.people_alt_outlined, label: context.l10n.onboardingSexSectionLabel),
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
                            _SectionHeader(icon: Icons.calendar_today_outlined, label: context.l10n.onboardingAgeSectionLabel),
                            const SizedBox(height: 10),
                            TextField(
                              controller: _ageController,
                              keyboardType: TextInputType.number,
                              textInputAction: TextInputAction.next,
                              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                              decoration: _fieldDecoration(hintText: '25', suffixText: context.l10n.onboardingAgeUnitSuffix),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _SectionHeader(icon: Icons.balance_outlined, label: context.l10n.onboardingWeightSectionLabel),
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
                  const SizedBox(height: 18),
                  _SectionHeader(icon: Icons.height_outlined, label: context.l10n.onboardingHeightSectionLabel),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _heightController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    textInputAction: TextInputAction.done,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    decoration: _fieldDecoration(hintText: '175', suffixText: 'cm'),
                  ),
                  const SizedBox(height: 24),
                  _SectionHeader(icon: Icons.track_changes_outlined, label: context.l10n.onboardingGoalSectionLabel),
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
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                context.l10n.onboardingSubmitButton,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 20),
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
