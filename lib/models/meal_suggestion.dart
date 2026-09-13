class MealSuggestion {
  final String timeSlot;
  final String title;
  final int kcal;
  final double prot;
  final double gluc;
  final double lip;
  final String description;

  const MealSuggestion({
    required this.timeSlot,
    required this.title,
    required this.kcal,
    required this.prot,
    required this.gluc,
    required this.lip,
    required this.description,
  });

  factory MealSuggestion.fromJson(Map<String, dynamic> json) {
    return MealSuggestion(
      timeSlot: json['timeSlot'] as String? ?? 'Repas',
      title: json['title'] as String? ?? 'Idée repas',
      kcal: (json['kcal'] as num?)?.toInt() ?? 0,
      prot: (json['prot'] as num?)?.toDouble() ?? 0,
      gluc: (json['gluc'] as num?)?.toDouble() ?? 0,
      lip: (json['lip'] as num?)?.toDouble() ?? 0,
      description: json['description'] as String? ?? '',
    );
  }
}
