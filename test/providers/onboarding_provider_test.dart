import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ai_health_chef/providers/onboarding_provider.dart';

void main() {
  group('OnboardingNotifier', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('starts incomplete', () {
      final profile = container.read(onboardingProvider);
      expect(profile.isComplete, isFalse);
    });

    test('individual setters update state without completing it', () {
      final notifier = container.read(onboardingProvider.notifier);

      notifier.setSex(OnboardingSex.male);
      notifier.setAge(30);

      final profile = container.read(onboardingProvider);
      expect(profile.sex, OnboardingSex.male);
      expect(profile.age, 30);
      expect(profile.isComplete, isFalse);
    });

    test('saveProfile fills every field and completes the profile', () {
      final notifier = container.read(onboardingProvider.notifier);

      notifier.saveProfile(
        sex: OnboardingSex.female,
        age: 27,
        currentWeight: 65.0,
        targetWeight: 60.0,
        goal: OnboardingGoal.loseWeight,
      );

      final profile = container.read(onboardingProvider);
      expect(profile.isComplete, isTrue);
      expect(profile.sex, OnboardingSex.female);
      expect(profile.age, 27);
      expect(profile.currentWeight, 65.0);
      expect(profile.targetWeight, 60.0);
      expect(profile.goal, OnboardingGoal.loseWeight);
    });
  });
}
