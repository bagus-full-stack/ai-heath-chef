import '../models/meal.dart';

/// Totaux nutritionnels agrégés pour un jour donné (tendances nutritionnelles
/// et export PDF du bilan hebdomadaire, voir journal_export.dart).
class DailyNutritionSummary {
  final DateTime day;
  int kcal = 0;
  double prot = 0;
  double gluc = 0;
  double lip = 0;
  double fiber = 0;
  double sugar = 0;
  double satFat = 0;

  DailyNutritionSummary(this.day);
}

/// Regroupe [meals] par jour sur les [days] derniers jours (aujourd'hui
/// inclus), avec un jour à zéro si aucun repas n'y a été loggé.
List<DailyNutritionSummary> buildDailyNutritionSummaries(
  List<Meal> meals, {
  int days = 7,
}) {
  final today = DateTime.now();
  final daySummaries = List.generate(days, (i) {
    final d = DateTime(
      today.year,
      today.month,
      today.day,
    ).subtract(Duration(days: days - 1 - i));
    return DailyNutritionSummary(d);
  });

  for (final meal in meals) {
    final key = DateTime(
      meal.createdAt.year,
      meal.createdAt.month,
      meal.createdAt.day,
    );
    final summary = daySummaries.firstWhere(
      (d) => d.day == key,
      orElse: () => DailyNutritionSummary(key),
    );
    summary.kcal += meal.totalKcal;
    summary.prot += meal.totalProt;
    summary.gluc += meal.totalGluc;
    summary.lip += meal.totalLip;
    summary.fiber += meal.totalFiber;
    summary.sugar += meal.totalSugar;
    summary.satFat += meal.totalSatFat;
  }
  return daySummaries;
}
