import 'package:flutter/material.dart';

enum BmiCategory { underweight, normal, overweight, obese }

/// Résultat du calcul d'IMC : la valeur brute et sa catégorie selon les
/// seuils standards de l'OMS.
class BmiResult {
  final double value;
  final BmiCategory category;

  const BmiResult({required this.value, required this.category});

  String get label {
    switch (category) {
      case BmiCategory.underweight:
        return 'Insuffisance pondérale';
      case BmiCategory.normal:
        return 'Corpulence normale';
      case BmiCategory.overweight:
        return 'Surpoids';
      case BmiCategory.obese:
        return 'Obésité';
    }
  }

  String get rangeLabel {
    switch (category) {
      case BmiCategory.underweight:
        return '< 18.5';
      case BmiCategory.normal:
        return '18.5 – 24.9';
      case BmiCategory.overweight:
        return '25 – 29.9';
      case BmiCategory.obese:
        return '≥ 30';
    }
  }

  Color get color {
    switch (category) {
      case BmiCategory.underweight:
        return const Color(0xFF4A90D9);
      case BmiCategory.normal:
        return const Color(0xFF45C48C);
      case BmiCategory.overweight:
        return const Color(0xFFFFB54A);
      case BmiCategory.obese:
        return const Color(0xFFE9634B);
    }
  }
}

/// Calcule l'IMC (poids en kg / taille en m²) et sa catégorie OMS.
/// Retourne `null` tant que le poids ou la taille ne sont pas renseignés.
BmiResult? computeBmi({required double weightKg, required double heightCm}) {
  if (weightKg <= 0 || heightCm <= 0) {
    return null;
  }

  final heightM = heightCm / 100;
  final value = weightKg / (heightM * heightM);

  final BmiCategory category;
  if (value < 18.5) {
    category = BmiCategory.underweight;
  } else if (value < 25) {
    category = BmiCategory.normal;
  } else if (value < 30) {
    category = BmiCategory.overweight;
  } else {
    category = BmiCategory.obese;
  }

  return BmiResult(value: value, category: category);
}
