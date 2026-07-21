import 'dart:io';
import 'dart:convert';

import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'workout_models.dart';

class WorkoutStoredState {
  const WorkoutStoredState({
    required this.profile,
    required this.exercises,
    required this.history,
  });

  final TrainingProfile? profile;
  final List<WorkoutExercise> exercises;
  final List<WorkoutHistoryRecord> history;
}

class WorkoutStore {
  static Database? _sharedDatabase;
  static WorkoutStoredState? _testState;
  Database? _database;
  Future<void> _writeQueue = Future.value();

  static bool get _isFlutterTest =>
      Platform.environment['FLUTTER_TEST'] == 'true';

  Future<Database> get _db async {
    final existing = _database ?? _sharedDatabase;
    if (existing != null) return existing;

    final databasePath = await _databasePath();
    final opened = await openDatabase(
      databasePath,
      version: 4,
      onCreate: (database, _) async {
        await database.execute('''
CREATE TABLE workout_profile (
  id INTEGER PRIMARY KEY,
  body_weight REAL NOT NULL,
  height_cm REAL NOT NULL,
  body_fat REAL NOT NULL,
  training_days INTEGER NOT NULL,
  experience INTEGER NOT NULL
)
''');
        await database.execute('''
CREATE TABLE workout_exercises (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL,
  weight REAL NOT NULL,
  sets INTEGER NOT NULL,
  reps INTEGER NOT NULL,
  body_part TEXT NOT NULL DEFAULT '其他',
  rest_seconds INTEGER NOT NULL,
  selected INTEGER NOT NULL,
  is_bodyweight INTEGER NOT NULL,
  weight_pending INTEGER NOT NULL,
  estimate_coefficient REAL,
  first_test_weight REAL,
  first_test_reps INTEGER,
  next_recommended_weight REAL,
  completed_sets INTEGER NOT NULL,
  rir_feedback TEXT NOT NULL,
  sort_order INTEGER NOT NULL
)
''');
        await database.execute('''
CREATE TABLE workout_history (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  training_date INTEGER NOT NULL,
  exercise_count INTEGER NOT NULL,
  completed_sets INTEGER NOT NULL,
  volume REAL NOT NULL,
  duration_seconds INTEGER NOT NULL,
  is_partial INTEGER NOT NULL DEFAULT 0,
  details_json TEXT NOT NULL DEFAULT '[]'
)
''');
      },
      onUpgrade: (database, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await database.execute(
            'ALTER TABLE workout_history ADD COLUMN '
            'is_partial INTEGER NOT NULL DEFAULT 0',
          );
        }
        if (oldVersion < 3) {
          await database.execute(
            'ALTER TABLE workout_history ADD COLUMN '
            "details_json TEXT NOT NULL DEFAULT '[]'",
          );
        }
        if (oldVersion < 4) {
          await database.execute(
            'ALTER TABLE workout_exercises ADD COLUMN '
            "body_part TEXT NOT NULL DEFAULT '其他'",
          );
        }
      },
    );
    _sharedDatabase = opened;
    _database = opened;
    return _database!;
  }

  Future<String> _databasePath() async {
    if (Platform.environment['FLUTTER_TEST'] == 'true') {
      return inMemoryDatabasePath;
    }
    final directory = await getApplicationDocumentsDirectory();
    return path.join(directory.path, 'workout.db');
  }

  Future<WorkoutStoredState?> load() async {
    if (_isFlutterTest) return _cloneState(_testState);
    final database = await _db;
    final profileRows = await database.query(
      'workout_profile',
      where: 'id = 1',
      limit: 1,
    );
    final exerciseRows = await database.query(
      'workout_exercises',
      orderBy: 'sort_order ASC, id ASC',
    );
    final historyRows = await database.query(
      'workout_history',
      orderBy: 'training_date DESC, id DESC',
    );
    if (profileRows.isEmpty && exerciseRows.isEmpty && historyRows.isEmpty) {
      return null;
    }

    return WorkoutStoredState(
      profile: profileRows.isEmpty ? null : _profileFromRow(profileRows.first),
      exercises: exerciseRows.map(_exerciseFromRow).toList(),
      history: historyRows.map(_historyFromRow).toList(),
    );
  }

  Future<void> saveState({
    required TrainingProfile? profile,
    required List<WorkoutExercise> exercises,
    required List<WorkoutHistoryRecord> history,
  }) async {
    final queued = _writeQueue.then(
      (_) =>
          _saveState(profile: profile, exercises: exercises, history: history),
    );
    _writeQueue = queued;
    await queued;
  }

  Future<void> _saveState({
    required TrainingProfile? profile,
    required List<WorkoutExercise> exercises,
    required List<WorkoutHistoryRecord> history,
  }) async {
    if (_isFlutterTest) {
      _testState = WorkoutStoredState(
        profile: profile,
        exercises: exercises.map(_cloneExercise).toList(),
        history: history.map(_cloneHistoryRecord).toList(),
      );
      return;
    }
    final database = await _db;
    await database.transaction((transaction) async {
      await transaction.delete('workout_profile');
      await transaction.delete('workout_exercises');
      await transaction.delete('workout_history');

      if (profile != null) {
        await transaction.insert('workout_profile', _profileToRow(profile));
      }
      for (final indexedExercise in exercises.indexed) {
        await transaction.insert(
          'workout_exercises',
          _exerciseToRow(indexedExercise.$2, sortOrder: indexedExercise.$1),
        );
      }
      for (final record in history) {
        await transaction.insert('workout_history', _historyToRow(record));
      }
    });
  }

  Future<void> clear() async {
    if (_isFlutterTest) {
      _testState = null;
      return;
    }
    final database = await _db;
    await database.transaction((transaction) async {
      await transaction.delete('workout_profile');
      await transaction.delete('workout_exercises');
      await transaction.delete('workout_history');
    });
  }

  TrainingProfile _profileFromRow(Map<String, Object?> row) {
    final experienceIndex = (row['experience'] as int? ?? 0).clamp(
      0,
      TrainingExperience.values.length - 1,
    );
    return TrainingProfile(
      bodyWeightKg: (row['body_weight'] as num?)?.toDouble() ?? 0,
      heightCm: (row['height_cm'] as num?)?.toDouble() ?? 0,
      bodyFatPercent: (row['body_fat'] as num?)?.toDouble() ?? 0,
      trainingDays: row['training_days'] as int? ?? 0,
      experience: TrainingExperience.values[experienceIndex],
    );
  }

  WorkoutExercise _exerciseFromRow(Map<String, Object?> row) {
    final storedWeight = (row['weight'] as num?)?.toDouble() ?? 0;
    final isBodyweight = (row['is_bodyweight'] as int? ?? 0) == 1;
    final feedback =
        (row['rir_feedback'] as String? ?? '')
            .split(',')
            .where((value) => value.trim().isNotEmpty)
            .map(int.tryParse)
            .whereType<int>()
            .toList();
    final exercise = WorkoutExercise(
      name: row['name'] as String? ?? '',
      weight: storedWeight,
      sets: row['sets'] as int? ?? 0,
      reps: row['reps'] as int? ?? 0,
      bodyPart: _storedBodyPart(
        row['name'] as String? ?? '',
        row['body_part'] as String?,
      ),
      restSeconds: row['rest_seconds'] as int? ?? 90,
      selected: (row['selected'] as int? ?? 0) == 1,
      isBodyweight: isBodyweight,
      weightPending:
          (row['weight_pending'] as int? ?? 0) == 1 ||
          (storedWeight <= 0 && !isBodyweight),
      estimateCoefficient: (row['estimate_coefficient'] as num?)?.toDouble(),
      firstTestWeight: (row['first_test_weight'] as num?)?.toDouble(),
      firstTestReps: row['first_test_reps'] as int?,
      nextRecommendedWeight:
          (row['next_recommended_weight'] as num?)?.toDouble(),
      rirFeedback: feedback,
    );
    exercise.completedSets = row['completed_sets'] as int? ?? 0;
    return exercise;
  }

  String _storedBodyPart(String name, String? storedBodyPart) {
    if (storedBodyPart != null && storedBodyPart != '其他') {
      return storedBodyPart;
    }
    return switch (name) {
      '杠铃卧推' || '上斜哑铃卧推' || '双杠臂屈伸' || '俯卧撑' || '器械夹胸' => '胸',
      '杠铃划船' || '高位下拉' || '坐姿划船' || '引体向上' => '背',
      '哑铃推肩' || '哑铃侧平举' || '杠铃推举' => '肩',
      '杠铃深蹲' || '罗马尼亚硬拉' || '腿举' || '腿弯举' => '腿',
      '哑铃弯举' || '绳索下压' || '锤式弯举' => '手臂',
      _ => storedBodyPart ?? '其他',
    };
  }

  WorkoutHistoryRecord _historyFromRow(Map<String, Object?> row) {
    return WorkoutHistoryRecord(
      date: DateTime.fromMillisecondsSinceEpoch(
        (row['training_date'] as num?)?.toInt() ?? 0,
      ),
      exerciseCount: row['exercise_count'] as int? ?? 0,
      completedSets: row['completed_sets'] as int? ?? 0,
      volume: (row['volume'] as num?)?.toDouble() ?? 0,
      duration: Duration(seconds: row['duration_seconds'] as int? ?? 0),
      exercises: _historyExercisesFromJson(row['details_json'] as String?),
      isPartial: (row['is_partial'] as int? ?? 0) == 1,
    );
  }

  List<WorkoutHistoryExercise> _historyExercisesFromJson(String? value) {
    if (value == null || value.isEmpty) return const [];
    try {
      final decoded = jsonDecode(value);
      if (decoded is! List) return const [];
      return [
        for (final item in decoded)
          if (item is Map<String, dynamic>)
            WorkoutHistoryExercise(
              name: item['name'] as String? ?? '',
              weight: (item['weight'] as num?)?.toDouble() ?? 0,
              sets: item['sets'] as int? ?? 0,
              reps: item['reps'] as int? ?? 0,
              completedSets: item['completedSets'] as int? ?? 0,
              restSeconds: item['restSeconds'] as int? ?? 90,
              rirFeedback: [
                for (final rir in (item['rirFeedback'] as List? ?? const []))
                  if (rir is num) rir.toInt(),
              ],
              isBodyweight: item['isBodyweight'] == true,
            ),
      ];
    } on FormatException {
      return const [];
    }
  }

  Map<String, Object?> _profileToRow(TrainingProfile profile) {
    return {
      'id': 1,
      'body_weight': profile.bodyWeightKg,
      'height_cm': profile.heightCm,
      'body_fat': profile.bodyFatPercent,
      'training_days': profile.trainingDays,
      'experience': profile.experience.index,
    };
  }

  Map<String, Object?> _exerciseToRow(
    WorkoutExercise exercise, {
    required int sortOrder,
  }) {
    return {
      'name': exercise.name,
      'weight': exercise.weight,
      'sets': exercise.sets,
      'reps': exercise.reps,
      'body_part': exercise.bodyPart,
      'rest_seconds': exercise.restSeconds,
      'selected': exercise.selected ? 1 : 0,
      'is_bodyweight': exercise.isBodyweight ? 1 : 0,
      'weight_pending': exercise.weightPending ? 1 : 0,
      'estimate_coefficient': exercise.estimateCoefficient,
      'first_test_weight': exercise.firstTestWeight,
      'first_test_reps': exercise.firstTestReps,
      'next_recommended_weight': exercise.nextRecommendedWeight,
      'completed_sets': exercise.completedSets,
      'rir_feedback': exercise.rirFeedback.join(','),
      'sort_order': sortOrder,
    };
  }

  Map<String, Object?> _historyToRow(WorkoutHistoryRecord record) {
    return {
      'training_date': record.date.millisecondsSinceEpoch,
      'exercise_count': record.exerciseCount,
      'completed_sets': record.completedSets,
      'volume': record.volume,
      'duration_seconds': record.duration.inSeconds,
      'is_partial': record.isPartial ? 1 : 0,
      'details_json': jsonEncode([
        for (final exercise in record.exercises)
          {
            'name': exercise.name,
            'weight': exercise.weight,
            'sets': exercise.sets,
            'reps': exercise.reps,
            'completedSets': exercise.completedSets,
            'restSeconds': exercise.restSeconds,
            'rirFeedback': exercise.rirFeedback,
            'isBodyweight': exercise.isBodyweight,
          },
      ]),
    };
  }

  WorkoutStoredState? _cloneState(WorkoutStoredState? state) {
    if (state == null) return null;
    return WorkoutStoredState(
      profile: state.profile,
      exercises: state.exercises.map(_cloneExercise).toList(),
      history: state.history.map(_cloneHistoryRecord).toList(),
    );
  }

  WorkoutHistoryRecord _cloneHistoryRecord(WorkoutHistoryRecord source) {
    return WorkoutHistoryRecord(
      date: source.date,
      exerciseCount: source.exerciseCount,
      completedSets: source.completedSets,
      volume: source.volume,
      duration: source.duration,
      exercises: [
        for (final exercise in source.exercises)
          WorkoutHistoryExercise(
            name: exercise.name,
            weight: exercise.weight,
            sets: exercise.sets,
            reps: exercise.reps,
            completedSets: exercise.completedSets,
            restSeconds: exercise.restSeconds,
            rirFeedback: [...exercise.rirFeedback],
            isBodyweight: exercise.isBodyweight,
          ),
      ],
      isPartial: source.isPartial,
    );
  }

  WorkoutExercise _cloneExercise(WorkoutExercise source) {
    final copy = WorkoutExercise(
      name: source.name,
      weight: source.weight,
      sets: source.sets,
      reps: source.reps,
      bodyPart: source.bodyPart,
      restSeconds: source.restSeconds,
      selected: source.selected,
      isBodyweight: source.isBodyweight,
      weightPending: source.weightPending,
      estimateCoefficient: source.estimateCoefficient,
      firstTestWeight: source.firstTestWeight,
      firstTestReps: source.firstTestReps,
      nextRecommendedWeight: source.nextRecommendedWeight,
      rirFeedback: source.rirFeedback,
    );
    copy.completedSets = source.completedSets;
    return copy;
  }
}
