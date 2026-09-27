import 'package:flutter_test/flutter_test.dart';

import 'package:ai_health_chef/models/meal_reminder.dart';
import 'package:ai_health_chef/utils/typical_meal_times.dart';

void main() {
  group('mealSlotForHour', () {
    test('classifies each window correctly', () {
      expect(mealSlotForHour(7), MealReminderSlot.breakfast);
      expect(mealSlotForHour(13), MealReminderSlot.lunch);
      expect(mealSlotForHour(20), MealReminderSlot.dinner);
      expect(mealSlotForHour(2), isNull);
    });
  });

  group('typicalMealTimesFromMinutes', () {
    test('averages minutes and converts back to hour/minute', () {
      final result = typicalMealTimesFromMinutes({
        MealReminderSlot.breakfast: [7 * 60, 7 * 60 + 30, 8 * 60 + 30],
      });
      expect(result[MealReminderSlot.breakfast], (hour: 7, minute: 40));
    });

    test('drops slots without enough samples', () {
      final result = typicalMealTimesFromMinutes({
        MealReminderSlot.lunch: [12 * 60, 12 * 60 + 30],
      }, minSamples: 3);
      expect(result.containsKey(MealReminderSlot.lunch), isFalse);
    });
  });
}
