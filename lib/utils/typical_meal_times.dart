import '../models/meal_reminder.dart';

/// Classe une heure de la journée (0-23) dans le créneau repas le plus
/// probable ; `null` pour la nuit profonde (0h-4h), trop ambigu pour être
/// rattaché à un repas.
MealReminderSlot? mealSlotForHour(int hour) {
  if (hour >= 4 && hour < 11) return MealReminderSlot.breakfast;
  if (hour >= 11 && hour < 16) return MealReminderSlot.lunch;
  if (hour >= 16) return MealReminderSlot.dinner;
  return null;
}

/// Heure moyenne par créneau à partir des minutes depuis minuit de chaque
/// repas loggé ([minutesSinceMidnightBySlot]) — un créneau n'apparaît dans le
/// résultat que s'il a au moins [minSamples] repas (sinon la moyenne ne
/// serait pas fiable). Extrait de [MealRepository.getTypicalMealTimes] (voir
/// meal_repository.dart) pour être testable sans base de données.
Map<MealReminderSlot, ({int hour, int minute})> typicalMealTimesFromMinutes(
  Map<MealReminderSlot, List<int>> minutesSinceMidnightBySlot, {
  int minSamples = 3,
}) {
  final result = <MealReminderSlot, ({int hour, int minute})>{};
  for (final entry in minutesSinceMidnightBySlot.entries) {
    if (entry.value.length < minSamples) continue;
    final avg = entry.value.reduce((a, b) => a + b) ~/ entry.value.length;
    result[entry.key] = (hour: avg ~/ 60, minute: avg % 60);
  }
  return result;
}
