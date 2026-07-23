import 'package:flutter_test/flutter_test.dart';
import 'package:local_tasks/widget/nutrition/nutrition_models.dart';
import 'package:local_tasks/widget/workout/workout_models.dart';

void main() {
  test('calculates daily targets from lean mass and training frequency', () {
    const profile = TrainingProfile(
      bodyWeightKg: 77,
      heightCm: 175,
      bodyFatPercent: 28,
      trainingDays: 4,
      experience: TrainingExperience.intermediate,
    );

    final target = DailyNutritionCalculator.calculate(
      profile: profile,
      goal: NutritionGoal.fatLoss,
    );

    expect(target.leanBodyMassKg, closeTo(55.44, .0001));
    expect(target.restingMetabolicRate, closeTo(1567.504, .001));
    expect(target.activityFactor, 1.4);
    expect(target.protein, closeTo(127.512, .001));
    expect(target.fat, closeTo(target.calories * .25 / 9, .001));
    expect(
      target.calories,
      closeTo(target.protein * 4 + target.fat * 9 + target.carbs * 4, .001),
    );
  });

  test('uses the product activity factor bands', () {
    expect(DailyNutritionCalculator.activityFactor(0), 1.2);
    expect(DailyNutritionCalculator.activityFactor(2), 1.3);
    expect(DailyNutritionCalculator.activityFactor(4), 1.4);
    expect(DailyNutritionCalculator.activityFactor(6), 1.5);
    expect(DailyNutritionCalculator.activityFactor(7), 1.55);
  });

  test('calculates every nutrition value from the per-100g source', () {
    const source = Nutrition(
      calories: 220,
      protein: 12,
      carbs: 20,
      fat: 10,
      fiber: 2,
      sugar: 3,
      sodium: 148,
    );

    final values = source.calculateByWeight(180);
    expect(values.calories, 396);
    expect(values.protein, closeTo(21.6, .001));
    expect(values.carbs, 36);
    expect(values.fat, 18);
    expect(values.fiber, closeTo(3.6, .001));
    expect(values.sugar, closeTo(5.4, .001));
    expect(values.sodium, closeTo(266.4, .001));
  });

  test('food entry derives consumed values from its raw source', () {
    final entry = FoodEntry(
      name: '山姆 Taco',
      meal: MealType.lunch,
      grams: 180,
      // Deliberately stale cached values: raw per-100g nutrition is canonical.
      calories: 1,
      protein: 1,
      carbs: 1,
      fat: 1,
      nutritionPer100g: const Nutrition(
        calories: 220,
        protein: 12,
        carbs: 20,
        fat: 10,
      ),
    );

    expect(entry.calories, 396);
    expect(entry.protein, closeTo(21.6, .001));
    expect(entry.carbs, 36);
    expect(entry.fat, 18);
  });
}
