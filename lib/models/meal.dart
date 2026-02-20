class Meal {
  final String id;
  final String name;
  final int totalKcal;
  final double totalProt;
  final double totalGluc;
  final double totalLip;
  final DateTime createdAt;

  Meal({
    required this.id,
    required this.name,
    required this.totalKcal,
    required this.totalProt,
    required this.totalGluc,
    required this.totalLip,
    required this.createdAt,
  });

  // Cette fonction "factory" prend le JSON brut de Supabase et le transforme en bel objet Dart
  factory Meal.fromJson(Map<String, dynamic> json) {
    return Meal(
      id: json['id'] as String,
      name: json['name'] as String,
      totalKcal: (json['total_kcal'] as num).toInt(),
      totalProt: (json['total_prot'] as num).toDouble(),
      totalGluc: (json['total_gluc'] as num).toDouble(),
      totalLip: (json['total_lip'] as num).toDouble(),
      createdAt: DateTime.parse(json['created_at']).toLocal(),
    );
  }
}