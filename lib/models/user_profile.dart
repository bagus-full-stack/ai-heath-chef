class UserProfile {
  final String userId;
  final String fullName;
  final String email;
  final String sex;
  final int age;
  final double currentWeight;
  final double targetWeight;
  final String goal;
  final String? avatarUrl;
  final DateTime? updatedAt;

  const UserProfile({
    required this.userId,
    required this.fullName,
    required this.email,
    required this.sex,
    required this.age,
    required this.currentWeight,
    required this.targetWeight,
    required this.goal,
    this.avatarUrl,
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
      goal: (json['goal'] as String?) ?? 'maintain',
      avatarUrl: json['avatar_url'] as String?,
      updatedAt: json['updated_at'] == null
          ? null
          : DateTime.tryParse(json['updated_at'] as String),
    );
  }

  String get sexLabel {
    switch (sex) {
      case 'male':
        return 'Homme';
      case 'female':
        return 'Femme';
      default:
        return 'Autre';
    }
  }

  String get goalLabel {
    switch (goal) {
      case 'loseWeight':
        return 'Perte de poids';
      case 'gainMuscle':
        return 'Prise de masse';
      default:
        return 'Maintien';
    }
  }
}
