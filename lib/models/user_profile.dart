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

  String get dietTypeLabel {
    switch (dietType) {
      case 'vegetarian':
        return 'Végétarien';
      case 'vegan':
        return 'Végétalien';
      case 'pescetarian':
        return 'Pescétarien';
      case 'halal':
        return 'Halal';
      case 'kosher':
        return 'Kasher';
      default:
        return 'Aucune restriction';
    }
  }

  String get coachToneLabel {
    switch (coachTone) {
      case 'bienveillant':
        return 'Bienveillant & calme';
      case 'direct':
        return 'Direct & concis';
      case 'humoristique':
        return 'Humoristique';
      default:
        return 'Motivant & énergique';
    }
  }
}
