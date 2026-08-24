import 'package:flutter_riverpod/flutter_riverpod.dart';

enum OnboardingSex { male, female, other }

enum OnboardingGoal { loseWeight, gainMuscle, maintain }

class OnboardingProfile {
  final OnboardingSex? sex;
  final int? age;
  final double? currentWeight;
  final double? targetWeight;
  final OnboardingGoal? goal;

  const OnboardingProfile({
    this.sex,
    this.age,
    this.currentWeight,
    this.targetWeight,
    this.goal,
  });

  bool get isComplete =>
      sex != null &&
      age != null &&
      currentWeight != null &&
      targetWeight != null &&
      goal != null;

  OnboardingProfile copyWith({
    OnboardingSex? sex,
    int? age,
    double? currentWeight,
    double? targetWeight,
    OnboardingGoal? goal,
  }) {
    return OnboardingProfile(
      sex: sex ?? this.sex,
      age: age ?? this.age,
      currentWeight: currentWeight ?? this.currentWeight,
      targetWeight: targetWeight ?? this.targetWeight,
      goal: goal ?? this.goal,
    );
  }
}

class OnboardingNotifier extends Notifier<OnboardingProfile> {
  @override
  OnboardingProfile build() {
    return const OnboardingProfile();
  }

  void setSex(OnboardingSex sex) {
    state = state.copyWith(sex: sex);
  }

  void setAge(int age) {
    state = state.copyWith(age: age);
  }

  void setCurrentWeight(double weight) {
    state = state.copyWith(currentWeight: weight);
  }

  void setTargetWeight(double weight) {
    state = state.copyWith(targetWeight: weight);
  }

  void setGoal(OnboardingGoal goal) {
    state = state.copyWith(goal: goal);
  }

  void saveProfile({
    required OnboardingSex sex,
    required int age,
    required double currentWeight,
    required double targetWeight,
    required OnboardingGoal goal,
  }) {
    state = OnboardingProfile(
      sex: sex,
      age: age,
      currentWeight: currentWeight,
      targetWeight: targetWeight,
      goal: goal,
    );
  }
}

final onboardingProvider =
    NotifierProvider<OnboardingNotifier, OnboardingProfile>(() {
  return OnboardingNotifier();
});
