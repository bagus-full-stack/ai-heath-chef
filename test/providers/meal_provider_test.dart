import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ai_health_chef/models/ingredient.dart';
import 'package:ai_health_chef/providers/meal_provider.dart';

Ingredient _sampleIngredient({String id = 'ing-1', int weight = 100}) {
  return Ingredient(
    id: id,
    name: 'Riz blanc',
    weight: weight,
    kcalPer100g: 130,
    protPer100g: 2.7,
    glucPer100g: 28,
    lipPer100g: 0.3,
  );
}

void main() {
  group('MealNotifier', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('starts empty', () async {
      final meals = await container.read(mealProvider.future);
      expect(meals, isEmpty);
    });

    test('addIngredient appends the ingredient', () async {
      await container.read(mealProvider.future);
      container.read(mealProvider.notifier).addIngredient(_sampleIngredient());

      final meals = container.read(mealProvider).value!;
      expect(meals, hasLength(1));
      expect(meals.first.name, 'Riz blanc');
    });

    test('increment adds 10g to the matching ingredient', () async {
      await container.read(mealProvider.future);
      final notifier = container.read(mealProvider.notifier);
      notifier.addIngredient(_sampleIngredient(weight: 100));

      notifier.increment('ing-1');

      final meals = container.read(mealProvider).value!;
      expect(meals.first.weight, 110);
    });

    test('decrement removes 10g and never goes below 0', () async {
      await container.read(mealProvider.future);
      final notifier = container.read(mealProvider.notifier);
      notifier.addIngredient(_sampleIngredient(weight: 5));

      notifier.decrement('ing-1');

      final meals = container.read(mealProvider).value!;
      expect(meals.first.weight, 0);
    });

    test('removeIngredient drops the matching ingredient', () async {
      await container.read(mealProvider.future);
      final notifier = container.read(mealProvider.notifier);
      notifier.addIngredient(_sampleIngredient(id: 'ing-1'));
      notifier.addIngredient(_sampleIngredient(id: 'ing-2'));

      notifier.removeIngredient('ing-1');

      final meals = container.read(mealProvider).value!;
      expect(meals, hasLength(1));
      expect(meals.single.id, 'ing-2');
    });
  });
}
