import 'package:flutter_test/flutter_test.dart';
import 'package:local_tasks/widget/workout/workout_models.dart';

void main() {
  test('beginner experience produces a conservative starting weight', () {
    const profile = TrainingProfile(
      bodyWeightKg: 77,
      heightCm: 173,
      bodyFatPercent: 26.3,
      trainingDays: 0,
      experience: TrainingExperience.beginner,
    );

    final startingWeight = TrainingWeightEstimator.estimateKg(
      profile: profile,
      exerciseCoefficient: .85,
    );

    expect(startingWeight, 20);
  });

  test('RIR feedback generates a progressive next weight', () {
    final exercise = WorkoutExercise(
      name: '杠铃卧推',
      weight: 40,
      sets: 3,
      reps: 10,
      firstTestWeight: 50,
      firstTestReps: 5,
    );
    exercise.rirFeedback.addAll([3, 3, 2]);

    expect(WorkoutProgressionAlgorithm.nextWeight(exercise), 42.5);
  });

  test('low RIR reduces the next recommended weight', () {
    final exercise = WorkoutExercise(
      name: '杠铃卧推',
      weight: 40,
      sets: 3,
      reps: 10,
    );
    exercise.rirFeedback.add(0);

    expect(WorkoutProgressionAlgorithm.nextWeight(exercise), 37.5);
  });
}
