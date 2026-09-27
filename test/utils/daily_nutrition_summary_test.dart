import 'package:flutter_test/flutter_test.dart';

import 'package:ai_health_chef/models/meal.dart';
import 'package:ai_health_chef/utils/daily_nutrition_summary.dart';

Meal _meal(DateTime createdAt, {int kcal = 500}) {
  return Meal(
    id: 'm',
    name: 'test',
    totalKcal: kcal,
    totalProt: 10,
    totalGluc: 20,
    totalLip: 5,
    createdAt: createdAt,
  );
}

void main() {
  test('fills every day in range even with no meals logged', () {
    final summaries = buildDailyNutritionSummaries([], days: 3);
    expect(summaries.length, 3);
    expect(summaries.every((d) => d.kcal == 0), isTrue);
  });

  test('sums multiple meals on the same day', () {
    final today = DateTime.now();
    final meals = [
      _meal(DateTime(today.year, today.month, today.day, 8), kcal: 300),
      _meal(DateTime(today.year, today.month, today.day, 19), kcal: 600),
    ];
    final summaries = buildDailyNutritionSummaries(meals, days: 1);
    expect(summaries.single.kcal, 900);
  });
}
