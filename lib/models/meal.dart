class Meal {
  final String id;
  final String name;
  final int totalKcal;
  final double totalProt;
  final double totalGluc;
  final double totalLip;
  final double totalFiber;
  final double totalSugar;
  final double totalSatFat;
  final String? imageUrl;
  final DateTime createdAt;

  Meal({
    required this.id,
    required this.name,
    required this.totalKcal,
    required this.totalProt,
    required this.totalGluc,
    required this.totalLip,
    this.totalFiber = 0,
    this.totalSugar = 0,
    this.totalSatFat = 0,
    this.imageUrl,
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
      totalFiber: (json['total_fiber'] as num?)?.toDouble() ?? 0,
      totalSugar: (json['total_sugar'] as num?)?.toDouble() ?? 0,
      totalSatFat: (json['total_sat_fat'] as num?)?.toDouble() ?? 0,
      imageUrl: json['image_url'] as String?,
      createdAt: DateTime.parse(json['created_at']).toLocal(),
    );
  }
}
