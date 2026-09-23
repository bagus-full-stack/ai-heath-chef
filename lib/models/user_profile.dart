import 'package:flutter/widgets.dart';

import '../l10n/l10n_extensions.dart';

class UserProfile {
  final String userId;
  final String fullName;
  final String email;
  final String sex;
  final int age;
  final double currentWeight;
  final double targetWeight;
  final double heightCm;
  final String goal;
  final String? avatarUrl;
  final String dietType;
  final List<String> allergies;
  final String coachTone;
  final bool isAdmin;
  final DateTime? updatedAt;

  const UserProfile({
    required this.userId,
    required this.fullName,
    required this.email,
    required this.sex,
    required this.age,
    required this.currentWeight,
    required this.targetWeight,
    this.heightCm = 0,
    required this.goal,
    this.avatarUrl,
    this.dietType = 'none',
    this.allergies = const [],
    this.coachTone = 'motivant',
    this.isAdmin = false,
    this.updatedAt,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      userId: json['user_id'] as String,
      fullName: (json['full_name'] as String?) ?? 'Utilisateur',
      email: (json['email'] as String?) ?? '',
      sex: (json['sex'] as String?) ?? 'other',
      age: (json['age'] as num?)?.toInt() ?? 0,
      currentWeight: (json['current_weight'] as num?)?.toDouble() ?? 0,
      targetWeight: (json['target_weight'] as num?)?.toDouble() ?? 0,
      heightCm: (json['height_cm'] as num?)?.toDouble() ?? 0,
      goal: (json['goal'] as String?) ?? 'maintain',
      avatarUrl: json['avatar_url'] as String?,
      dietType: (json['diet_type'] as String?) ?? 'none',
      allergies: (json['allergies'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? const [],
      coachTone: (json['coach_tone'] as String?) ?? 'motivant',
      isAdmin: json['is_admin'] as bool? ?? false,
      updatedAt: json['updated_at'] == null
          ? null
          : DateTime.tryParse(json['updated_at'] as String),
    );
  }

  String sexLabel(BuildContext context) {
    switch (sex) {
      case 'male':
        return context.l10n.accountSexMale;
      case 'female':
        return context.l10n.accountSexFemale;
      default:
        return context.l10n.accountSexOther;
    }
  }

  String goalLabel(BuildContext context) {
    switch (goal) {
      case 'loseWeight':
        return context.l10n.accountGoalLoseWeight;
      case 'gainMuscle':
        return context.l10n.accountGoalGainMuscle;
      default:
        return context.l10n.accountGoalMaintain;
    }
  }

  String dietTypeLabel(BuildContext context) {
    switch (dietType) {
      case 'vegetarian':
        return context.l10n.dietaryPreferencesDietVegetarian;
      case 'vegan':
        return context.l10n.dietaryPreferencesDietVegan;
      case 'pescetarian':
        return context.l10n.dietaryPreferencesDietPescetarian;
      case 'halal':
        return context.l10n.dietaryPreferencesDietHalal;
      case 'kosher':
        return context.l10n.dietaryPreferencesDietKosher;
      default:
        return context.l10n.dietaryPreferencesDietNone;
    }
  }

  String coachToneLabel(BuildContext context) {
    switch (coachTone) {
      case 'bienveillant':
        return context.l10n.coachPersonalizationToneBienveillantLabel;
      case 'direct':
        return context.l10n.coachPersonalizationToneDirectLabel;
      case 'humoristique':
        return context.l10n.coachPersonalizationToneHumoristiqueLabel;
      default:
        return context.l10n.coachPersonalizationToneMotivantLabel;
    }
  }
}
