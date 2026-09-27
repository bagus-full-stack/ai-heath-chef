/// Lundi de la semaine contenant [now], au format `AAAA-MM-JJ` — clé de
/// cache pour le plan de repas hebdomadaire (voir weekly_meal_plan_provider.dart).
/// `DateTime.weekday` : 1 = lundi ... 7 = dimanche.
String weekStartKey(DateTime now) {
  final monday = now.subtract(Duration(days: now.weekday - 1));
  final month = monday.month.toString().padLeft(2, '0');
  final day = monday.day.toString().padLeft(2, '0');
  return '${monday.year}-$month-$day';
}
