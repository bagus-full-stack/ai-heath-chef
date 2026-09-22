class Ingredient {
  final String id;
  final String name;
  final int weight;
  final double kcalPer100g;
  final double protPer100g;
  final double glucPer100g;
  final double lipPer100g;
  final double fiberPer100g;
  final double sugarPer100g;
  final double satFatPer100g;

  Ingredient({
    required this.id,
    required this.name,
    required this.weight,
    required this.kcalPer100g,
    required this.protPer100g,
    required this.glucPer100g,
    required this.lipPer100g,
    this.fiberPer100g = 0,
    this.sugarPer100g = 0,
    this.satFatPer100g = 0,
  });

  Ingredient copyWith({int? weight}) {
    return Ingredient(
      id: id,
      name: name,
      weight: weight ?? this.weight,
      kcalPer100g: kcalPer100g,
      protPer100g: protPer100g,
      glucPer100g: glucPer100g,
      lipPer100g: lipPer100g,
      fiberPer100g: fiberPer100g,
      sugarPer100g: sugarPer100g,
      satFatPer100g: satFatPer100g,
    );
  }

  // Calculs dynamiques basés sur le poids actuel
  int get currentKcal => (kcalPer100g * weight / 100).round();
  double get currentProt => (protPer100g * weight / 100);
  double get currentGluc => (glucPer100g * weight / 100);
  double get currentLip => (lipPer100g * weight / 100);
  double get currentFiber => (fiberPer100g * weight / 100);
  double get currentSugar => (sugarPer100g * weight / 100);
  double get currentSatFat => (satFatPer100g * weight / 100);

  // Utile pour convertir facilement l'objet en JSON pour Supabase
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'weight': weight,
      'kcal': currentKcal,
      'prot': currentProt,
      'gluc': currentGluc,
      'lip': currentLip,
      'fiber': currentFiber,
      'sugar': currentSugar,
      'satFat': currentSatFat,
    };
  }
}