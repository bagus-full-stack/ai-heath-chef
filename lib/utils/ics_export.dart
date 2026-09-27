import '../models/meal_suggestion.dart';

/// Heure de repas par défaut selon la position dans la journée — l'IA
/// renvoie déjà les repas dans l'ordre chronologique (petit-déj/déjeuner/
/// dîner, voir supabase/functions/meal-suggestions/index.ts).
///
/// ponytail: heuristique par position plutôt que par lecture du champ
/// `timeSlot` (libellé libre généré par l'IA, ex. "Petit-déjeuner" ou
/// "Breakfast" selon la langue — pas fiable à parser). À affiner si l'IA
/// renvoie un jour une heure exacte.
const _defaultMealTimes = [
  (hour: 8, minute: 0),
  (hour: 12, minute: 30),
  (hour: 19, minute: 30),
  (hour: 16, minute: 0),
];

/// Construit un calendrier iCalendar (.ics) avec un événement par repas du
/// plan hebdomadaire IA, sur la semaine démarrant à [weekStart] (lundi, voir
/// weekStartKey) — importable dans Google/Apple/Outlook Calendar via le
/// partage natif (voir exportWeeklyMealPlanIcs dans journal_export.dart).
String buildWeeklyMealPlanIcs(List<MealSuggestion> plan, DateTime weekStart) {
  final byDay = <int, List<MealSuggestion>>{};
  for (final meal in plan) {
    byDay.putIfAbsent(meal.day ?? 1, () => []).add(meal);
  }

  final buffer = StringBuffer()
    ..writeln('BEGIN:VCALENDAR')
    ..writeln('VERSION:2.0')
    ..writeln('PRODID:-//AI Health Chef//Weekly Meal Plan//FR');

  for (final dayEntry in byDay.entries) {
    final dayDate = weekStart.add(Duration(days: dayEntry.key - 1));
    final meals = dayEntry.value;
    for (var i = 0; i < meals.length; i++) {
      final meal = meals[i];
      final time = _defaultMealTimes[i % _defaultMealTimes.length];
      final start = DateTime(dayDate.year, dayDate.month, dayDate.day, time.hour, time.minute);
      final end = start.add(const Duration(minutes: 30));
      buffer
        ..writeln('BEGIN:VEVENT')
        ..writeln('UID:${start.millisecondsSinceEpoch}-$i@aihealthchef.app')
        ..writeln('DTSTART:${_icsDateTime(start)}')
        ..writeln('DTEND:${_icsDateTime(end)}')
        ..writeln('SUMMARY:${_icsEscape('${meal.timeSlot} : ${meal.title}')}')
        ..writeln('DESCRIPTION:${_icsEscape(meal.description)}')
        ..writeln('END:VEVENT');
    }
  }

  buffer.writeln('END:VCALENDAR');
  return buffer.toString();
}

String _icsDateTime(DateTime d) {
  String p(int v) => v.toString().padLeft(2, '0');
  return '${d.year}${p(d.month)}${p(d.day)}T${p(d.hour)}${p(d.minute)}${p(d.second)}';
}

String _icsEscape(String value) => value
    .replaceAll('\\', '\\\\')
    .replaceAll(',', '\\,')
    .replaceAll(';', '\\;')
    .replaceAll('\n', '\\n');
