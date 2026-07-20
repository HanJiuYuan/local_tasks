enum TrainingExperience { beginner, novice, intermediate, advanced }

extension TrainingExperienceDetails on TrainingExperience {
  String get label => switch (this) {
    TrainingExperience.beginner => '小白 / 刚开始',
    TrainingExperience.novice => '初级',
    TrainingExperience.intermediate => '中级',
    TrainingExperience.advanced => '高级',
  };

  double get factor => switch (this) {
    TrainingExperience.beginner => .50,
    TrainingExperience.novice => .68,
    TrainingExperience.intermediate => .84,
    TrainingExperience.advanced => 1.0,
  };
}

class TrainingProfile {
  const TrainingProfile({
    required this.bodyWeightKg,
    required this.heightCm,
    required this.bodyFatPercent,
    required this.trainingDays,
    required this.experience,
  });

  final double bodyWeightKg;
  final double heightCm;
  final double bodyFatPercent;
  final int trainingDays;
  final TrainingExperience experience;

  double get leanMassKg {
    final fatRatio = (bodyFatPercent / 100).clamp(.03, .60);
    return bodyWeightKg * (1 - fatRatio);
  }

  double get experienceFactor {
    final daysFactor =
        trainingDays <= 7
            ? .50
            : trainingDays <= 30
            ? .60
            : trainingDays <= 90
            ? .72
            : trainingDays <= 180
            ? .82
            : trainingDays <= 365
            ? .92
            : 1.0;
    return daysFactor < experience.factor ? daysFactor : experience.factor;
  }

  // 用瘦体重、身高和训练经验做归一化，再乘一个保守起始系数。
  // 这只是试重量的起点，不代表最大力量或安全上限。
  double get conservativeFactor {
    final leanMassFactor = (leanMassKg / 70).clamp(.65, 1.10);
    final heightFactor = (heightCm / 175).clamp(.92, 1.08);
    return (leanMassFactor * heightFactor * .80 * experienceFactor).clamp(
      .30,
      .95,
    );
  }
}

class TrainingWeightEstimator {
  const TrainingWeightEstimator._();

  static double estimateKg({
    required TrainingProfile profile,
    required double exerciseCoefficient,
  }) {
    final rawWeight =
        profile.bodyWeightKg * exerciseCoefficient * profile.conservativeFactor;
    return (rawWeight / 2.5).round() * 2.5;
  }
}

class WorkoutExercise {
  WorkoutExercise({
    required this.name,
    required this.weight,
    required this.sets,
    required this.reps,
    this.restSeconds = 90,
    this.selected = true,
    this.isBodyweight = false,
    this.weightPending = false,
    this.estimateCoefficient,
    this.firstTestWeight,
    this.firstTestReps,
    this.nextRecommendedWeight,
    List<int>? rirFeedback,
  }) : rirFeedback = List<int>.from(rirFeedback ?? const []);

  final String name;
  double weight;
  int sets;
  int reps;
  int restSeconds;
  int completedSets = 0;
  bool selected;
  final bool isBodyweight;
  bool weightPending;
  double? estimateCoefficient;
  double? firstTestWeight;
  int? firstTestReps;
  double? nextRecommendedWeight;
  final List<int> rirFeedback;

  double? get firstTestOneRepMax {
    final testWeight = firstTestWeight;
    final testReps = firstTestReps;
    if (testWeight == null || testReps == null || testReps < 1) return null;
    return testWeight * (1 + testReps / 30);
  }

  double? get averageRir {
    if (rirFeedback.isEmpty) return null;
    return rirFeedback.reduce((total, rir) => total + rir) / rirFeedback.length;
  }

  String get weightLabel =>
      isBodyweight
          ? '自重'
          : weightPending
          ? '待估算'
          : weight == weight.roundToDouble()
          ? '${weight.toInt()} kg'
          : '${weight.toStringAsFixed(1)} kg';

  String get planLabel => '$weightLabel  ·  $sets组 × $reps次';
}

class WorkoutProgressionAlgorithm {
  const WorkoutProgressionAlgorithm._();

  static double? nextWeight(WorkoutExercise exercise) {
    if (exercise.isBodyweight ||
        exercise.weightPending ||
        exercise.rirFeedback.isEmpty ||
        exercise.weight <= 0) {
      return null;
    }

    final averageRir = exercise.averageRir!;
    final adjustment =
        averageRir >= 2.5
            ? .05
            : averageRir >= 2
            ? .025
            : averageRir < 1
            ? -.05
            : 0.0;
    var next = exercise.weight * (1 + adjustment);

    final estimatedOneRepMax = exercise.firstTestOneRepMax;
    if (estimatedOneRepMax != null) {
      final trainingMax = estimatedOneRepMax * .80;
      if (next > trainingMax) next = trainingMax;
    }

    return (next / 2.5).round() * 2.5;
  }
}

class QuickExercise {
  const QuickExercise({
    required this.bodyPart,
    required this.name,
    required this.weightKg,
    required this.sets,
    this.isBodyweight = false,
    this.exerciseCoefficient,
  });

  final String bodyPart;
  final String name;
  final double? weightKg;
  final int sets;
  final bool isBodyweight;
  final double? exerciseCoefficient;

  String get weightLabel {
    if (isBodyweight) return '自重';
    final weight = weightKg;
    if (weight == null) return '待估算';
    return weight == weight.roundToDouble()
        ? '${weight.toInt()}kg'
        : '${weight.toStringAsFixed(1)}kg';
  }
}

class QuickExerciseTemplate {
  const QuickExerciseTemplate({
    required this.bodyPart,
    required this.name,
    required this.exerciseCoefficient,
    required this.sets,
    this.isBodyweight = false,
  });

  const QuickExerciseTemplate.bodyweight({
    required String bodyPart,
    required String name,
    required int sets,
  }) : this(
         bodyPart: bodyPart,
         name: name,
         exerciseCoefficient: 0,
         sets: sets,
         isBodyweight: true,
       );

  final String bodyPart;
  final String name;
  final double exerciseCoefficient;
  final int sets;
  final bool isBodyweight;

  QuickExercise resolve(TrainingProfile? profile) {
    return QuickExercise(
      bodyPart: bodyPart,
      name: name,
      weightKg:
          isBodyweight
              ? 0
              : profile == null
              ? null
              : TrainingWeightEstimator.estimateKg(
                profile: profile,
                exerciseCoefficient: exerciseCoefficient,
              ),
      sets: sets,
      isBodyweight: isBodyweight,
      exerciseCoefficient: isBodyweight ? null : exerciseCoefficient,
    );
  }
}

class WorkoutHistoryRecord {
  const WorkoutHistoryRecord({
    required this.date,
    required this.exerciseCount,
    required this.completedSets,
    required this.volume,
    required this.duration,
  });

  final DateTime date;
  final int exerciseCount;
  final int completedSets;
  final double volume;
  final Duration duration;
}
