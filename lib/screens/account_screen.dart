import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../l10n/l10n_extensions.dart';
import '../models/user_profile.dart';
import '../providers/auth_provider.dart';
import '../providers/onboarding_provider.dart';
import '../providers/profile_provider.dart';
import '../utils/bmi.dart';
import '../widgets/animated_async_value.dart';

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
  final _heightController = TextEditingController();

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
    _heightController.dispose();
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
    _heightController.text = profile.heightCm == 0 ? '' : profile.heightCm.toString();
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
              title: Text(context.l10n.accountTakePhoto),
              onTap: () => Navigator.of(context).pop(ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: Text(context.l10n.accountChooseFromGallery),
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
      final height = double.tryParse(_heightController.text.trim().replaceAll(',', '.'));

      if (age != null && currentWeight != null && targetWeight != null && height != null) {
        await authService.upsertProfile(
          fullName: _fullNameController.text.trim(),
          sex: _sex.name,
          age: age,
          currentWeight: currentWeight,
          targetWeight: targetWeight,
          heightCm: height,
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
      _showError(e.toString());
    } finally {
      if (mounted) {
        setState(() => _isUploadingAvatar = false);
      }
    }
  }

  String _sexLabel(BuildContext context, OnboardingSex sex) {
    switch (sex) {
      case OnboardingSex.male:
        return context.l10n.accountSexMale;
      case OnboardingSex.female:
        return context.l10n.accountSexFemale;
      case OnboardingSex.other:
        return context.l10n.accountSexOther;
    }
  }

  String _goalLabel(BuildContext context, OnboardingGoal goal) {
    switch (goal) {
      case OnboardingGoal.loseWeight:
        return context.l10n.accountGoalLoseWeight;
      case OnboardingGoal.gainMuscle:
        return context.l10n.accountGoalGainMuscle;
      case OnboardingGoal.maintain:
        return context.l10n.accountGoalMaintain;
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
    final height = double.tryParse(_heightController.text.trim().replaceAll(',', '.'));

    if (_fullNameController.text.trim().isEmpty) {
      _showError(context.l10n.accountErrorNameEmpty);
      return;
    }
    if (age == null || age < 10 || age > 120) {
      _showError(context.l10n.accountErrorInvalidAge);
      return;
    }
    if (currentWeight == null || currentWeight <= 0 || currentWeight > 400) {
      _showError(context.l10n.accountErrorInvalidCurrentWeight);
      return;
    }
    if (targetWeight == null || targetWeight <= 0 || targetWeight > 400) {
      _showError(context.l10n.accountErrorInvalidTargetWeight);
      return;
    }
    if (height == null || height < 100 || height > 250) {
      _showError(context.l10n.accountErrorInvalidHeight);
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
            heightCm: height,
            goal: _goal.name,
            avatarUrl: _avatarUrl,
          );
      ref.invalidate(profileProvider);
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.accountUpdateSuccess)),
      );
      context.pop();
    } catch (e) {
      _showError(context.l10n.accountSaveError(e.toString()));
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
        title: Text(
          context.l10n.accountTitle,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 1.2),
        ),
        centerTitle: true,
      ),
      body: profileAsync.animatedWhen(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(context.l10n.accountLoadError(error.toString()), textAlign: TextAlign.center),
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
                Text(context.l10n.accountFullNameLabel, style: const TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                TextField(
                  controller: _fullNameController,
                  textCapitalization: TextCapitalization.words,
                  decoration: _decoration(),
                ),
                const SizedBox(height: 18),
                Text(context.l10n.accountSexLabel, style: const TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 10,
                  children: OnboardingSex.values.map((sex) {
                    return ChoiceChip(
                      label: Text(_sexLabel(context, sex)),
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
                          Text(context.l10n.accountAgeLabel, style: const TextStyle(fontWeight: FontWeight.w600)),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _ageController,
                            keyboardType: TextInputType.number,
                            decoration: _decoration(suffixText: context.l10n.accountAgeSuffix),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(context.l10n.accountHeightLabel, style: const TextStyle(fontWeight: FontWeight.w600)),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _heightController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: _decoration(suffixText: context.l10n.accountHeightSuffix),
                            onChanged: (_) => setState(() {}),
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
                          Text(context.l10n.accountCurrentWeightLabel, style: const TextStyle(fontWeight: FontWeight.w600)),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _currentWeightController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: _decoration(suffixText: context.l10n.accountWeightSuffix),
                            onChanged: (_) => setState(() {}),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(context.l10n.accountTargetWeightLabel, style: const TextStyle(fontWeight: FontWeight.w600)),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _targetWeightController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: _decoration(suffixText: context.l10n.accountWeightSuffix),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                _buildBmiCard(),
                const SizedBox(height: 18),
                Text(context.l10n.accountMainGoalLabel, style: const TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: OnboardingGoal.values.map((goal) {
                    return ChoiceChip(
                      label: Text(_goalLabel(context, goal)),
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
                      : Text(
                          context.l10n.accountSaveButton,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  /// Affiche l'IMC calculé en direct à partir du poids actuel et de la
  /// taille saisis dans le formulaire (avant même l'enregistrement).
  Widget _buildBmiCard() {
    final weight = double.tryParse(_currentWeightController.text.trim().replaceAll(',', '.'));
    final height = double.tryParse(_heightController.text.trim().replaceAll(',', '.'));
    final bmi = (weight != null && height != null)
        ? computeBmi(weightKg: weight, heightCm: height)
        : null;

    return AnimatedSize(
      duration: const Duration(milliseconds: 250),
      alignment: Alignment.topCenter,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        child: bmi == null
            ? Container(
                key: const ValueKey('bmi-placeholder'),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.monitor_weight_outlined, color: Colors.grey.shade400),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        context.l10n.accountBmiPlaceholder,
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              )
            : Container(
                key: const ValueKey('bmi-value'),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: bmi.color.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: bmi.color.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(color: bmi.color, shape: BoxShape.circle),
                      child: Center(
                        child: Text(
                          bmi.value.toStringAsFixed(1),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            context.l10n.accountBmiLabel(bmi.label(context)),
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            context.l10n.accountBmiRangeLabel(bmi.label(context).toLowerCase(), bmi.rangeLabel),
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
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
