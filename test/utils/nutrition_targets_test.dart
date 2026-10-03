import 'package:flutter_test/flutter_test.dart';

import 'package:ai_health_chef/models/user_profile.dart';
import 'package:ai_health_chef/utils/nutrition_targets.dart';

UserProfile _profile({
  String sex = 'male',
  int age = 30,
  double currentWeight = 80,
  double heightCm = 0,
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
    heightCm: heightCm,
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

    test('floors a low-weight female weight-loss profile at 1200 kcal', () {
      final targets = computeNutritionTargets(
        _profile(sex: 'female', age: 30, currentWeight: 45, heightCm: 150, goal: 'loseWeight'),
      );

      expect(targets.kcal, greaterThanOrEqualTo(kMinCaloriesFemale));
      expect(targets.flooredByMinimum, isTrue);
    });

    test('floors an extreme small-male weight-loss profile at 1500 kcal', () {
      final targets = computeNutritionTargets(
        _profile(sex: 'male', age: 25, currentWeight: 50, heightCm: 150, goal: 'loseWeight'),
      );

      expect(targets.kcal, greaterThanOrEqualTo(kMinCaloriesMale));
      expect(targets.flooredByMinimum, isTrue);
    });

    test('caps the deficit at 1000 kcal/day for a very high-TDEE profile', () {
      final maintain = computeNutritionTargets(
        _profile(sex: 'male', age: 20, currentWeight: 300, heightCm: 250, goal: 'maintain'),
      );
      final loseWeight = computeNutritionTargets(
        _profile(sex: 'male', age: 20, currentWeight: 300, heightCm: 250, goal: 'loseWeight'),
      );

      expect(maintain.kcal - loseWeight.kcal, lessThanOrEqualTo(kMaxDeficitKcal));
      expect(loseWeight.flooredByMinimum, isFalse);
    });

    test('applies no numeric weight-loss deficit for a minor', () {
      final maintain = computeNutritionTargets(_profile(age: 15, goal: 'maintain'));
      final loseWeight = computeNutritionTargets(_profile(age: 15, goal: 'loseWeight'));

      expect(loseWeight.kcal, equals(maintain.kcal));
    });

    test('falls back to defaults for an out-of-range age', () {
      final targets = computeNutritionTargets(_profile(age: 150));
      expect(targets.kcal, NutritionTargets.fallback.kcal);
    });

    test('falls back to defaults for an out-of-range weight', () {
      final targets = computeNutritionTargets(_profile(currentWeight: 500));
      expect(targets.kcal, NutritionTargets.fallback.kcal);
    });
  });
}
