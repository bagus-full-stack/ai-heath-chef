import 'package:flutter_test/flutter_test.dart';

import 'package:ai_health_chef/models/user_profile.dart';
import 'package:ai_health_chef/utils/nutrition_targets.dart';

UserProfile _profile({
  String sex = 'male',
  int age = 30,
  double currentWeight = 80,
  String goal = 'maintain',
}) {
  return UserProfile(
    userId: 'u1',
    fullName: 'Test',
    email: 't@example.com',
    sex: sex,
    age: age,
    currentWeight: currentWeight,
    targetWeight: currentWeight,
    goal: goal,
  );
}

void main() {
  group('computeNutritionTargets', () {
    test('falls back to defaults when profile is null', () {
      final targets = computeNutritionTargets(null);
      expect(targets.kcal, NutritionTargets.fallback.kcal);
    });

    test('falls back to defaults when profile is incomplete', () {
      final targets = computeNutritionTargets(_profile(age: 0));
      expect(targets.kcal, NutritionTargets.fallback.kcal);
    });

    test('lowers the target for a weight-loss goal vs. maintenance', () {
      final maintain = computeNutritionTargets(_profile(goal: 'maintain'));
      final loseWeight = computeNutritionTargets(_profile(goal: 'loseWeight'));

      expect(loseWeight.kcal, lessThan(maintain.kcal));
    });

    test('raises the target for a muscle-gain goal vs. maintenance', () {
      final maintain = computeNutritionTargets(_profile(goal: 'maintain'));
      final gainMuscle = computeNutritionTargets(_profile(goal: 'gainMuscle'));

      expect(gainMuscle.kcal, greaterThan(maintain.kcal));
    });

    test('macro grams are consistent with the kcal target (~4/4/9 split)', () {
      final targets = computeNutritionTargets(_profile());
      final reconstructedKcal =
          targets.protein * 4 + targets.carbs * 4 + targets.fat * 9;

      expect(reconstructedKcal, closeTo(targets.kcal, 1));
    });
  });
}
