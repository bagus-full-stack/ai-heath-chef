import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../models/user_profile.dart';
import '../providers/auth_provider.dart';
import '../providers/onboarding_provider.dart';
import '../providers/profile_provider.dart';

/// Écran d'édition du profil (identité + objectifs), ouvert depuis "Compte"
/// et "Mes objectifs" dans lib/screens/profile_screen.dart.
class AccountScreen extends ConsumerStatefulWidget {
  const AccountScreen({super.key});

  @override
  ConsumerState<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends ConsumerState<AccountScreen> {
  static const Color _primaryColor = Color(0xFF6B66FF);

  final _fullNameController = TextEditingController();
  final _ageController = TextEditingController();
  final _currentWeightController = TextEditingController();
  final _targetWeightController = TextEditingController();

  OnboardingSex _sex = OnboardingSex.other;
  OnboardingGoal _goal = OnboardingGoal.maintain;
  String? _avatarUrl;
  bool _isSaving = false;
  bool _isUploadingAvatar = false;
  bool _prefilled = false;

  @override
  void dispose() {
    _fullNameController.dispose();
    _ageController.dispose();
    _currentWeightController.dispose();
    _targetWeightController.dispose();
    super.dispose();
  }

  void _prefill(UserProfile profile) {
    if (_prefilled) {
      return;
    }
    _prefilled = true;
    _fullNameController.text = profile.fullName;
    _ageController.text = profile.age == 0 ? '' : profile.age.toString();
    _currentWeightController.text =
        profile.currentWeight == 0 ? '' : profile.currentWeight.toString();
    _targetWeightController.text =
        profile.targetWeight == 0 ? '' : profile.targetWeight.toString();
    _sex = OnboardingSex.values.firstWhere(
      (s) => s.name == profile.sex,
      orElse: () => OnboardingSex.other,
    );
    _goal = OnboardingGoal.values.firstWhere(
      (g) => g.name == profile.goal,
      orElse: () => OnboardingGoal.maintain,
    );
    _avatarUrl = profile.avatarUrl;
  }

  Future<void> _changeAvatar() async {
    if (_isUploadingAvatar) {
      return;
    }

    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Prendre une photo'),
              onTap: () => Navigator.of(context).pop(ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choisir dans la galerie'),
              onTap: () => Navigator.of(context).pop(ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source == null) {
      return;
    }

    final picked = await ImagePicker().pickImage(source: source, imageQuality: 90);
    if (picked == null || !mounted) {
      return;
    }

    setState(() => _isUploadingAvatar = true);
    try {
      final authService = ref.read(authServiceProvider);
      final url = await authService.uploadAvatar(File(picked.path));

      final age = int.tryParse(_ageController.text.trim());
      final currentWeight =
          double.tryParse(_currentWeightController.text.trim().replaceAll(',', '.'));
      final targetWeight =
          double.tryParse(_targetWeightController.text.trim().replaceAll(',', '.'));

      if (age != null && currentWeight != null && targetWeight != null) {
        await authService.upsertProfile(
          fullName: _fullNameController.text.trim(),
          sex: _sex.name,
          age: age,
          currentWeight: currentWeight,
          targetWeight: targetWeight,
          goal: _goal.name,
          avatarUrl: url,
        );
        ref.invalidate(profileProvider);
      }

      if (!mounted) {
        return;
      }
      setState(() => _avatarUrl = url);
    } catch (e) {
      _showError('$e');
    } finally {
      if (mounted) {
        setState(() => _isUploadingAvatar = false);
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

  String _goalLabel(OnboardingGoal goal) {
    switch (goal) {
      case OnboardingGoal.loseWeight:
        return 'Perte de poids';
      case OnboardingGoal.gainMuscle:
        return 'Prise de masse';
      case OnboardingGoal.maintain:
        return 'Maintien';
    }
  }

  Future<void> _save() async {
    if (_isSaving) {
      return;
    }

    final age = int.tryParse(_ageController.text.trim());
    final currentWeight =
        double.tryParse(_currentWeightController.text.trim().replaceAll(',', '.'));
    final targetWeight =
        double.tryParse(_targetWeightController.text.trim().replaceAll(',', '.'));

    if (_fullNameController.text.trim().isEmpty) {
      _showError('Ton nom ne peut pas être vide.');
      return;
    }
    if (age == null || age < 10 || age > 120) {
      _showError('Entre un âge valide.');
      return;
    }
    if (currentWeight == null || currentWeight <= 0 || currentWeight > 400) {
      _showError('Entre ton poids actuel.');
      return;
    }
    if (targetWeight == null || targetWeight <= 0 || targetWeight > 400) {
      _showError('Entre un poids cible valide.');
      return;
    }

    setState(() => _isSaving = true);
    try {
      await ref.read(authServiceProvider).upsertProfile(
            fullName: _fullNameController.text.trim(),
            sex: _sex.name,
            age: age,
            currentWeight: currentWeight,
            targetWeight: targetWeight,
            goal: _goal.name,
            avatarUrl: _avatarUrl,
          );
      ref.invalidate(profileProvider);
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profil mis à jour.')),
      );
      context.pop();
    } catch (e) {
      _showError('Impossible d’enregistrer : $e');
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.redAccent),
    );
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(profileProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'MON COMPTE',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 1.2),
        ),
        centerTitle: true,
      ),
      body: profileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text('Impossible de charger le profil : $error', textAlign: TextAlign.center),
          ),
        ),
        data: (profile) {
          if (profile != null) {
            _prefill(profile);
          }
          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: GestureDetector(
                    onTap: _changeAvatar,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        CircleAvatar(
                          radius: 48,
                          backgroundColor: Colors.grey.shade200,
                          backgroundImage: _avatarUrl != null ? NetworkImage(_avatarUrl!) : null,
                          child: _avatarUrl == null
                              ? Icon(Icons.person, size: 48, color: Colors.grey.shade500)
                              : null,
                        ),
                        Positioned(
                          right: -4,
                          bottom: -4,
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: _primaryColor,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2.5),
                            ),
                            child: _isUploadingAvatar
                                ? const Padding(
                                    padding: EdgeInsets.all(7),
                                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                  )
                                : const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 16),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                const Text('Nom complet', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                TextField(
                  controller: _fullNameController,
                  textCapitalization: TextCapitalization.words,
                  decoration: _decoration(),
                ),
                const SizedBox(height: 18),
                const Text('Sexe', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 10,
                  children: OnboardingSex.values.map((sex) {
                    return ChoiceChip(
                      label: Text(_sexLabel(sex)),
                      selected: _sex == sex,
                      selectedColor: _primaryColor.withValues(alpha: 0.16),
                      onSelected: (_) => setState(() => _sex = sex),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Âge', style: TextStyle(fontWeight: FontWeight.w600)),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _ageController,
                            keyboardType: TextInputType.number,
                            decoration: _decoration(suffixText: 'ans'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Poids actuel', style: TextStyle(fontWeight: FontWeight.w600)),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _currentWeightController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: _decoration(suffixText: 'kg'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Poids cible', style: TextStyle(fontWeight: FontWeight.w600)),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _targetWeightController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: _decoration(suffixText: 'kg'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                const Text('Objectif principal', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: OnboardingGoal.values.map((goal) {
                    return ChoiceChip(
                      label: Text(_goalLabel(goal)),
                      selected: _goal == goal,
                      selectedColor: _primaryColor.withValues(alpha: 0.16),
                      onSelected: (_) => setState(() => _goal = goal),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 28),
                ElevatedButton(
                  onPressed: _isSaving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primaryColor,
                    minimumSize: const Size(double.infinity, 54),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                    elevation: 0,
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text(
                          'Enregistrer',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  InputDecoration _decoration({String? suffixText}) {
    return InputDecoration(
      suffixText: suffixText,
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: _primaryColor, width: 1.4),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    );
  }
}
