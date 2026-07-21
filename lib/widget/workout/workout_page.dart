import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'add_custom_action_dialog.dart';
import 'adjust_exercise_dialog.dart';
import 'history_page.dart';
import 'select_action_page.dart';
import 'start_training_page.dart';
import 'switch_action_dialog.dart';
import 'today_summary_page.dart';
import 'training_session_page.dart';
import 'workout_models.dart';
import 'workout_store.dart';
import 'workout_theme.dart';

const _countdownSoundChannel = MethodChannel('local_tasks/countdown_sound');

enum _WorkoutStep {
  selectAction,
  startTraining,
  currentAction,
  rest,
  todaySummary,
  history,
}

enum _TrainingMenuAction { adjust, switchAction, addAction, savePartial }

class WorkoutAssistantPage extends StatefulWidget {
  const WorkoutAssistantPage({super.key});

  @override
  State<WorkoutAssistantPage> createState() => _WorkoutAssistantPageState();
}

class _WorkoutAssistantPageState extends State<WorkoutAssistantPage> {
  double? _bodyWeightKg;
  double? _heightCm;
  double? _bodyFatPercent;
  int? _trainingDays;
  TrainingExperience? _experience;

  TrainingProfile? get _profile {
    final weight = _bodyWeightKg;
    final height = _heightCm;
    final bodyFat = _bodyFatPercent;
    final trainingDays = _trainingDays;
    final experience = _experience;
    if (weight == null ||
        height == null ||
        bodyFat == null ||
        trainingDays == null ||
        experience == null) {
      return null;
    }
    return TrainingProfile(
      bodyWeightKg: weight,
      heightCm: height,
      bodyFatPercent: bodyFat,
      trainingDays: trainingDays,
      experience: experience,
    );
  }

  static const _quickExerciseTemplates = <QuickExerciseTemplate>[
    QuickExerciseTemplate(
      bodyPart: '胸',
      name: '杠铃卧推',
      exerciseCoefficient: .85,
      sets: 4,
    ),
    QuickExerciseTemplate(
      bodyPart: '胸',
      name: '上斜哑铃卧推',
      exerciseCoefficient: .18,
      sets: 4,
    ),
    QuickExerciseTemplate.bodyweight(bodyPart: '胸', name: '双杠臂屈伸', sets: 3),
    QuickExerciseTemplate.bodyweight(bodyPart: '胸', name: '俯卧撑', sets: 3),
    QuickExerciseTemplate(
      bodyPart: '胸',
      name: '器械夹胸',
      exerciseCoefficient: .35,
      sets: 3,
    ),
    QuickExerciseTemplate(
      bodyPart: '胸',
      name: '下斜哑铃卧推',
      exerciseCoefficient: .20,
      sets: 4,
    ),
    QuickExerciseTemplate(
      bodyPart: '胸',
      name: '绳索夹胸',
      exerciseCoefficient: .22,
      sets: 3,
    ),
    QuickExerciseTemplate.bodyweight(bodyPart: '胸', name: '窄距俯卧撑', sets: 3),
    QuickExerciseTemplate(
      bodyPart: '背',
      name: '杠铃划船',
      exerciseCoefficient: .70,
      sets: 4,
    ),
    QuickExerciseTemplate(
      bodyPart: '背',
      name: '高位下拉',
      exerciseCoefficient: .75,
      sets: 4,
    ),
    QuickExerciseTemplate(
      bodyPart: '背',
      name: '坐姿划船',
      exerciseCoefficient: .65,
      sets: 3,
    ),
    QuickExerciseTemplate.bodyweight(bodyPart: '背', name: '引体向上', sets: 4),
    QuickExerciseTemplate(
      bodyPart: '背',
      name: '单臂哑铃划船',
      exerciseCoefficient: .30,
      sets: 3,
    ),
    QuickExerciseTemplate(
      bodyPart: '背',
      name: '直臂下压',
      exerciseCoefficient: .25,
      sets: 3,
    ),
    QuickExerciseTemplate(
      bodyPart: '背',
      name: 'T 杠划船',
      exerciseCoefficient: .65,
      sets: 4,
    ),
    QuickExerciseTemplate(
      bodyPart: '背',
      name: '哑铃上拉',
      exerciseCoefficient: .20,
      sets: 3,
    ),
    QuickExerciseTemplate(
      bodyPart: '背',
      name: '胸托划船',
      exerciseCoefficient: .45,
      sets: 3,
    ),
    QuickExerciseTemplate(
      bodyPart: '肩',
      name: '哑铃推肩',
      exerciseCoefficient: .20,
      sets: 4,
    ),
    QuickExerciseTemplate(
      bodyPart: '肩',
      name: '哑铃侧平举',
      exerciseCoefficient: .08,
      sets: 4,
    ),
    QuickExerciseTemplate(
      bodyPart: '肩',
      name: '绳索面拉',
      exerciseCoefficient: .30,
      sets: 3,
    ),
    QuickExerciseTemplate(
      bodyPart: '肩',
      name: '杠铃推举',
      exerciseCoefficient: .45,
      sets: 4,
    ),
    QuickExerciseTemplate(
      bodyPart: '肩',
      name: '反向飞鸟',
      exerciseCoefficient: .08,
      sets: 3,
    ),
    QuickExerciseTemplate(
      bodyPart: '肩',
      name: '阿诺德推举',
      exerciseCoefficient: .18,
      sets: 3,
    ),
    QuickExerciseTemplate(
      bodyPart: '肩',
      name: '哑铃前平举',
      exerciseCoefficient: .08,
      sets: 3,
    ),
    QuickExerciseTemplate(
      bodyPart: '肩',
      name: '单臂绳索侧平举',
      exerciseCoefficient: .06,
      sets: 3,
    ),
    QuickExerciseTemplate(
      bodyPart: '腿',
      name: '杠铃深蹲',
      exerciseCoefficient: 1.10,
      sets: 4,
    ),
    QuickExerciseTemplate(
      bodyPart: '腿',
      name: '罗马尼亚硬拉',
      exerciseCoefficient: .90,
      sets: 4,
    ),
    QuickExerciseTemplate(
      bodyPart: '腿',
      name: '腿举',
      exerciseCoefficient: 1.90,
      sets: 3,
    ),
    QuickExerciseTemplate(
      bodyPart: '腿',
      name: '腿弯举',
      exerciseCoefficient: .50,
      sets: 3,
    ),
    QuickExerciseTemplate(
      bodyPart: '腿',
      name: '保加利亚分腿蹲',
      exerciseCoefficient: .25,
      sets: 3,
    ),
    QuickExerciseTemplate(
      bodyPart: '腿',
      name: '腿屈伸',
      exerciseCoefficient: .55,
      sets: 3,
    ),
    QuickExerciseTemplate(
      bodyPart: '腿',
      name: '站姿提踵',
      exerciseCoefficient: .80,
      sets: 4,
    ),
    QuickExerciseTemplate(
      bodyPart: '腿',
      name: '杠铃臀推',
      exerciseCoefficient: .85,
      sets: 4,
    ),
    QuickExerciseTemplate(
      bodyPart: '腿',
      name: '哈克深蹲',
      exerciseCoefficient: 1.15,
      sets: 3,
    ),
    QuickExerciseTemplate(
      bodyPart: '腿',
      name: '行走弓步',
      exerciseCoefficient: .22,
      sets: 3,
    ),
    QuickExerciseTemplate(
      bodyPart: '腿',
      name: '坐姿提踵',
      exerciseCoefficient: .55,
      sets: 4,
    ),
    QuickExerciseTemplate(
      bodyPart: '手臂',
      name: '哑铃弯举',
      exerciseCoefficient: .17,
      sets: 3,
    ),
    QuickExerciseTemplate(
      bodyPart: '手臂',
      name: '绳索下压',
      exerciseCoefficient: .30,
      sets: 3,
    ),
    QuickExerciseTemplate(
      bodyPart: '手臂',
      name: '锤式弯举',
      exerciseCoefficient: .17,
      sets: 3,
    ),
    QuickExerciseTemplate(
      bodyPart: '手臂',
      name: '杠铃弯举',
      exerciseCoefficient: .30,
      sets: 3,
    ),
    QuickExerciseTemplate(
      bodyPart: '手臂',
      name: '仰卧臂屈伸',
      exerciseCoefficient: .25,
      sets: 3,
    ),
    QuickExerciseTemplate(
      bodyPart: '手臂',
      name: '上斜哑铃弯举',
      exerciseCoefficient: .12,
      sets: 3,
    ),
    QuickExerciseTemplate(
      bodyPart: '手臂',
      name: '牧师椅弯举',
      exerciseCoefficient: .16,
      sets: 3,
    ),
    QuickExerciseTemplate(
      bodyPart: '手臂',
      name: '绳索过顶臂屈伸',
      exerciseCoefficient: .20,
      sets: 3,
    ),
    QuickExerciseTemplate.bodyweight(bodyPart: '核心', name: '平板支撑', sets: 3),
    QuickExerciseTemplate.bodyweight(bodyPart: '核心', name: '悬垂举腿', sets: 3),
    QuickExerciseTemplate.bodyweight(bodyPart: '核心', name: '俄罗斯转体', sets: 3),
    QuickExerciseTemplate.bodyweight(bodyPart: '核心', name: '登山跑', sets: 3),
    QuickExerciseTemplate.bodyweight(bodyPart: '核心', name: '死虫式', sets: 3),
    QuickExerciseTemplate.bodyweight(bodyPart: '核心', name: '侧平板支撑', sets: 3),
    QuickExerciseTemplate.bodyweight(bodyPart: '核心', name: '仰卧卷腹', sets: 3),
    QuickExerciseTemplate(
      bodyPart: '核心',
      name: '绳索卷腹',
      exerciseCoefficient: .35,
      sets: 3,
    ),
    QuickExerciseTemplate(
      bodyPart: '核心',
      name: '腹轮 rollout',
      exerciseCoefficient: .08,
      sets: 3,
    ),
  ];

  List<QuickExercise> get _quickExercises => [
    for (final template in _quickExerciseTemplates) template.resolve(_profile),
  ];

  final _store = WorkoutStore();
  late List<WorkoutExercise> _exercises = [
    _estimatedExercise('杠铃卧推', .85, 4, 12, bodyPart: '胸'),
    _estimatedExercise('杠铃深蹲', 1.10, 4, 10, bodyPart: '腿'),
    _estimatedExercise('哑铃弯举', .17, 3, 12, bodyPart: '手臂'),
  ];
  final _history = <WorkoutHistoryRecord>[];
  final _flowScrollController = ScrollController();

  _WorkoutStep _step = _WorkoutStep.selectAction;
  Timer? _restClock;
  int _restSeconds = 0;
  int _currentRir = 2;
  int _activeIndex = 0;
  bool _soundEnabled = true;
  bool _historyRecorded = false;
  bool _partialSessionSaved = false;
  DateTime? _trainingStartedAt;
  _WorkoutStep _historyReturnStep = _WorkoutStep.todaySummary;
  String? _selectedBodyPart = '胸';

  @override
  void initState() {
    super.initState();
    _loadStoredWorkout();
  }

  Future<void> _loadStoredWorkout() async {
    final stored = await _store.load();
    if (!mounted || stored == null) return;
    setState(() {
      final profile = stored.profile;
      if (profile != null) {
        _bodyWeightKg = profile.bodyWeightKg;
        _heightCm = profile.heightCm;
        _bodyFatPercent = profile.bodyFatPercent;
        _trainingDays = profile.trainingDays;
        _experience = profile.experience;
      }
      if (stored.exercises.isNotEmpty) {
        _exercises = stored.exercises;
        for (final exercise in _exercises) {
          if (!exercise.isBodyweight && exercise.weight <= 0) {
            exercise.weightPending = true;
          }
        }
      }
      _history
        ..clear()
        ..addAll(stored.history);
    });
  }

  Future<void> _persistWorkout() {
    return _store.saveState(
      profile: _profile,
      exercises: _exercises,
      history: _history,
    );
  }

  List<WorkoutExercise> get _selectedExercises =>
      _exercises.where((exercise) => exercise.selected).toList();

  WorkoutExercise _estimatedExercise(
    String name,
    double coefficient,
    int sets,
    int reps, {
    required String bodyPart,
  }) {
    final profile = _profile;
    final estimatedWeight =
        profile == null
            ? null
            : TrainingWeightEstimator.estimateKg(
              profile: profile,
              exerciseCoefficient: coefficient,
            );
    return WorkoutExercise(
      name: name,
      weight: estimatedWeight ?? 0,
      sets: sets,
      reps: reps,
      bodyPart: bodyPart,
      weightPending: estimatedWeight == null,
      estimateCoefficient: coefficient,
    );
  }

  void _applyProfile(TrainingProfile profile) {
    setState(() {
      _bodyWeightKg = profile.bodyWeightKg;
      _heightCm = profile.heightCm;
      _bodyFatPercent = profile.bodyFatPercent;
      _trainingDays = profile.trainingDays;
      _experience = profile.experience;
      for (final exercise in _exercises) {
        final coefficient = exercise.estimateCoefficient;
        if (coefficient == null ||
            (!exercise.weightPending && exercise.weight > 0)) {
          continue;
        }
        exercise.weight = TrainingWeightEstimator.estimateKg(
          profile: profile,
          exerciseCoefficient: coefficient,
        );
        exercise.weightPending = false;
      }
    });
    unawaited(_persistWorkout());
  }

  WorkoutExercise get _activeExercise => _exercises[_activeIndex];

  List<int> get _selectedIndexes => [
    for (var index = 0; index < _exercises.length; index++)
      if (_exercises[index].selected) index,
  ];

  int get _activeActionNumber {
    final position = _selectedIndexes.indexOf(_activeIndex);
    return position < 0 ? 1 : position + 1;
  }

  int get _completedSets =>
      _exercises.fold(0, (total, exercise) => total + exercise.completedSets);

  double get _volume => _exercises.fold(
    0,
    (total, exercise) =>
        total + exercise.completedSets * exercise.weight * exercise.reps,
  );

  Duration get _trainingDuration {
    final start = _trainingStartedAt;
    return start == null ? Duration.zero : DateTime.now().difference(start);
  }

  bool get _isLastSet => _activeExercise.completedSets >= _activeExercise.sets;

  bool get _isLastAction => _activeActionNumber >= _selectedExercises.length;

  @override
  void dispose() {
    _restClock?.cancel();
    _flowScrollController.dispose();
    super.dispose();
  }

  void _animateFlowToTop() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_flowScrollController.hasClients) return;
      _flowScrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
      );
    });
  }

  void _transitionTo(_WorkoutStep step, {VoidCallback? update}) {
    final wasInTrainingSession =
        _step == _WorkoutStep.currentAction || _step == _WorkoutStep.rest;
    final willStayInTrainingSession =
        step == _WorkoutStep.currentAction || step == _WorkoutStep.rest;
    setState(() {
      update?.call();
      _step = step;
    });
    if (!(wasInTrainingSession && willStayInTrainingSession)) {
      _animateFlowToTop();
    }
  }

  void _toggleSound() => setState(() => _soundEnabled = !_soundEnabled);

  void _toggleExercise(WorkoutExercise exercise) {
    setState(() => exercise.selected = !exercise.selected);
    unawaited(_persistWorkout());
  }

  void _addQuickExercise(QuickExercise quick) {
    final existingIndex = _exercises.indexWhere(
      (item) => item.name == quick.name,
    );
    if (existingIndex >= 0) {
      setState(() {
        final existing = _exercises[existingIndex];
        existing.selected = true;
        if (!quick.isBodyweight && existing.weight <= 0) {
          if (quick.weightKg == null) {
            existing.weightPending = true;
          } else {
            existing.weight = quick.weightKg!;
            existing.weightPending = false;
          }
        }
      });
      unawaited(_persistWorkout());
      return;
    }

    setState(() {
      _exercises.add(
        WorkoutExercise(
          name: quick.name,
          weight: quick.weightKg ?? 0,
          sets: quick.sets,
          reps: 12,
          bodyPart: quick.bodyPart,
          isBodyweight: quick.isBodyweight,
          weightPending: quick.weightKg == null && !quick.isBodyweight,
          estimateCoefficient: quick.exerciseCoefficient,
        ),
      );
    });
    unawaited(_persistWorkout());
  }

  Future<void> _addCustomExercise() async {
    final exercise = await showDialog<WorkoutExercise>(
      context: context,
      barrierColor: Colors.black54,
      builder: (_) => const AddCustomActionDialog(),
    );
    if (!mounted || exercise == null) return;
    setState(() => _exercises.add(exercise));
    unawaited(_persistWorkout());
  }

  void _deleteExercise(WorkoutExercise exercise) {
    setState(() {
      _exercises.remove(exercise);
      if (_exercises.isEmpty) {
        _activeIndex = 0;
      } else if (_activeIndex >= _exercises.length) {
        _activeIndex = _exercises.length - 1;
      }
    });
    unawaited(_persistWorkout());
  }

  Future<void> _adjustExercise(WorkoutExercise exercise) async {
    final updated = await showDialog<WorkoutExercise>(
      context: context,
      builder: (_) => AdjustExerciseDialog(exercise: exercise),
    );
    if (!mounted || updated == null) return;
    setState(() {
      exercise.weight = updated.weight;
      exercise.sets = updated.sets;
      exercise.reps = updated.reps;
      exercise.restSeconds = updated.restSeconds;
      exercise.firstTestWeight = updated.firstTestWeight;
      exercise.firstTestReps = updated.firstTestReps;
      exercise.nextRecommendedWeight = null;
      exercise.completedSets =
          exercise.completedSets.clamp(0, updated.sets).toInt();
      exercise.weightPending = false;
      exercise.estimateCoefficient = null;
    });
    unawaited(_persistWorkout());
  }

  void _startTrainingPreparation() {
    if (_selectedExercises.isEmpty) return;
    final pending =
        _selectedExercises
            .where(
              (exercise) => !exercise.isBodyweight && exercise.weightPending,
            )
            .toList();
    if (pending.isNotEmpty) {
      final names = pending.map((exercise) => exercise.name).join('、');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('$names 尚未设置训练重量，请先填写身体数据或调整重量。')));
      return;
    }
    _transitionTo(_WorkoutStep.startTraining);
  }

  void _beginTraining() {
    final first = _selectedIndexes.firstOrNull;
    if (first == null) return;
    _trainingStartedAt ??= DateTime.now();
    _transitionTo(
      _WorkoutStep.currentAction,
      update: () {
        _activeIndex = first;
        _partialSessionSaved = false;
      },
    );
  }

  void _confirmCompletedSet() {
    if (_activeExercise.completedSets >= _activeExercise.sets) return;
    _trainingStartedAt ??= DateTime.now();
    _transitionTo(
      _WorkoutStep.rest,
      update: () {
        _activeExercise.completedSets++;
        _activeExercise.rirFeedback.add(_currentRir);
        _restSeconds = _activeExercise.restSeconds;
      },
    );
    unawaited(_persistWorkout());
    _startRestClock();
  }

  void _startRestClock() {
    _restClock?.cancel();
    _restClock = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || _restSeconds <= 0) return;
      final nextSeconds = _restSeconds - 1;
      setState(() => _restSeconds = nextSeconds);
      if (_soundEnabled && nextSeconds > 0 && nextSeconds <= 10) {
        unawaited(_playRestCountdownSound());
      }
    });
  }

  Future<void> _playRestCountdownSound() async {
    try {
      await _countdownSoundChannel.invokeMethod<void>('playCountdown');
    } catch (_) {
      // Android and unsupported platforms fall back to the system alert sound.
      try {
        await SystemSound.play(SystemSoundType.alert);
        await HapticFeedback.mediumImpact();
      } catch (_) {
        // Some platforms do not expose a system alert sound.
      }
    }
  }

  void _openHistory({required _WorkoutStep returnStep}) {
    _historyReturnStep = returnStep;
    _transitionTo(_WorkoutStep.history);
  }

  void _continueAfterRest() {
    _restClock?.cancel();
    _restSeconds = 0;
    if (_isLastSet) {
      _moveToNextActionOrSummary();
    } else {
      _transitionTo(_WorkoutStep.currentAction);
    }
  }

  void _moveToNextActionOrSummary() {
    final indexes = _selectedIndexes;
    final currentPosition = indexes.indexOf(_activeIndex);
    if (currentPosition >= 0 && currentPosition < indexes.length - 1) {
      _transitionTo(
        _WorkoutStep.currentAction,
        update: () => _activeIndex = indexes[currentPosition + 1],
      );
      return;
    }

    _recordHistory();
    _partialSessionSaved = false;
    _transitionTo(_WorkoutStep.todaySummary);
  }

  void _recordHistory({bool isPartial = false}) {
    if (_historyRecorded) return;
    _historyRecorded = true;
    for (final exercise in _selectedExercises) {
      exercise.nextRecommendedWeight = WorkoutProgressionAlgorithm.nextWeight(
        exercise,
      );
    }
    final historyExercises = [
      for (final exercise in _selectedExercises)
        if (!isPartial || exercise.completedSets > 0)
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
    ];
    _history.insert(
      0,
      WorkoutHistoryRecord(
        date: DateTime.now(),
        exerciseCount:
            isPartial
                ? _selectedExercises
                    .where((exercise) => exercise.completedSets > 0)
                    .length
                : _selectedExercises.length,
        completedSets: _completedSets,
        volume: _volume,
        duration: _trainingDuration,
        exercises: historyExercises,
        isPartial: isPartial,
      ),
    );
    unawaited(_persistWorkout());
  }

  Future<void> _switchAction() async {
    final exercises = _selectedExercises;
    if (exercises.isEmpty) return;
    final selected = await showDialog<WorkoutExercise>(
      context: context,
      builder:
          (_) => SwitchActionDialog(
            exercises: exercises,
            activeExercise: _activeExercise,
          ),
    );
    if (!mounted || selected == null) return;
    final index = _exercises.indexOf(selected);
    if (index < 0) return;
    _restClock?.cancel();
    _transitionTo(
      _WorkoutStep.currentAction,
      update: () {
        _activeIndex = index;
        _restSeconds = 0;
      },
    );
  }

  void _savePartialTraining() {
    if (_completedSets == 0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('至少完成一组后，才能保存本次训练。')));
      return;
    }
    _restClock?.cancel();
    _recordHistory(isPartial: true);
    setState(() {
      _restSeconds = 0;
      _partialSessionSaved = true;
      _step = _WorkoutStep.todaySummary;
    });
    _animateFlowToTop();
  }

  void _handleTrainingMenu(_TrainingMenuAction action) {
    switch (action) {
      case _TrainingMenuAction.adjust:
        unawaited(_adjustExercise(_activeExercise));
      case _TrainingMenuAction.switchAction:
        unawaited(_switchAction());
      case _TrainingMenuAction.addAction:
        unawaited(_addCustomExercise());
      case _TrainingMenuAction.savePartial:
        _savePartialTraining();
    }
  }

  void _restartTraining() {
    _restClock?.cancel();
    setState(() {
      for (final exercise in _exercises) {
        exercise.completedSets = 0;
        if (exercise.nextRecommendedWeight != null) {
          exercise.weight = exercise.nextRecommendedWeight!;
        }
        exercise.nextRecommendedWeight = null;
        exercise.rirFeedback.clear();
      }
      _activeIndex = _selectedIndexes.firstOrNull ?? 0;
      _restSeconds = 0;
      _trainingStartedAt = null;
      _historyRecorded = false;
      _partialSessionSaved = false;
      _step = _WorkoutStep.selectAction;
    });
    unawaited(_persistWorkout());
    _animateFlowToTop();
  }

  void _backStep() {
    switch (_step) {
      case _WorkoutStep.startTraining:
        _transitionTo(_WorkoutStep.selectAction);
      case _WorkoutStep.currentAction:
        _transitionTo(_WorkoutStep.startTraining);
      case _WorkoutStep.history:
        _transitionTo(_WorkoutStep.todaySummary);
      case _WorkoutStep.rest:
      case _WorkoutStep.todaySummary:
      case _WorkoutStep.selectAction:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WorkoutColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _header(),
            Expanded(
              child: SingleChildScrollView(
                controller: _flowScrollController,
                padding: const EdgeInsets.fromLTRB(16, 22, 16, 34),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1120),
                  child: AnimatedSize(
                    duration: const Duration(milliseconds: 320),
                    curve: Curves.easeOutCubic,
                    alignment: Alignment.topCenter,
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 360),
                      switchInCurve: Curves.easeOutCubic,
                      switchOutCurve: Curves.easeInCubic,
                      layoutBuilder: (currentChild, previousChildren) {
                        return Stack(
                          alignment: Alignment.topCenter,
                          clipBehavior: Clip.none,
                          children: [
                            ...previousChildren,
                            if (currentChild != null) currentChild,
                          ],
                        );
                      },
                      transitionBuilder: (child, animation) {
                        final slide = Tween<Offset>(
                          begin: const Offset(0, .025),
                          end: Offset.zero,
                        ).animate(animation);
                        return FadeTransition(
                          opacity: animation,
                          child: SlideTransition(position: slide, child: child),
                        );
                      },
                      child: _buildStep(),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _header() {
    final labels = <_WorkoutStep, String>{
      _WorkoutStep.selectAction: '选择动作',
      _WorkoutStep.startTraining: '开始今日训练',
      _WorkoutStep.currentAction: '当前动作',
      _WorkoutStep.rest: '组间休息',
      _WorkoutStep.todaySummary: '今日数据',
      _WorkoutStep.history: '历史数据',
    };
    final stepIndex = _WorkoutStep.values.indexOf(_step);
    final showAssistantTitle = _step == _WorkoutStep.selectAction;
    final trainingActive = switch (_step) {
      _WorkoutStep.currentAction || _WorkoutStep.rest => true,
      _ => false,
    };
    return Container(
      decoration: const BoxDecoration(
        color: WorkoutColors.panel,
        border: Border(bottom: BorderSide(color: WorkoutColors.border)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1120),
        child: Row(
          children: [
            if (_step != _WorkoutStep.selectAction)
              IconButton(
                tooltip: '返回上一步',
                onPressed:
                    _step == _WorkoutStep.rest ||
                            _step == _WorkoutStep.todaySummary
                        ? null
                        : _backStep,
                icon: const Icon(
                  Icons.arrow_back_rounded,
                  color: WorkoutColors.muted,
                ),
              ),
            if (showAssistantTitle) ...[
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: WorkoutColors.green,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: const [
                    BoxShadow(color: Color(0x3500C98B), blurRadius: 15),
                  ],
                ),
                child: const Icon(
                  Icons.fitness_center_rounded,
                  color: WorkoutColors.background,
                ),
              ),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (showAssistantTitle)
                    const Text(
                      '健身助手',
                      style: TextStyle(
                        color: WorkoutColors.text,
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  if (showAssistantTitle) const SizedBox(height: 3),
                  Text(
                    labels[_step]!,
                    style: const TextStyle(
                      color: WorkoutColors.muted,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            if (trainingActive)
              const Padding(
                padding: EdgeInsets.only(right: 12),
                child: Text(
                  '训练中',
                  style: TextStyle(
                    color: WorkoutColors.green,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            if (trainingActive)
              PopupMenuButton<_TrainingMenuAction>(
                tooltip: '训练中操作',
                onSelected: _handleTrainingMenu,
                icon: const Icon(
                  Icons.more_horiz_rounded,
                  color: WorkoutColors.muted,
                ),
                itemBuilder:
                    (_) => const [
                      PopupMenuItem(
                        value: _TrainingMenuAction.adjust,
                        child: Text('调整当前动作'),
                      ),
                      PopupMenuItem(
                        value: _TrainingMenuAction.switchAction,
                        child: Text('切换动作'),
                      ),
                      PopupMenuItem(
                        value: _TrainingMenuAction.addAction,
                        child: Text('添加动作'),
                      ),
                      PopupMenuDivider(),
                      PopupMenuItem(
                        value: _TrainingMenuAction.savePartial,
                        child: Text('结束并保存本次训练'),
                      ),
                    ],
              ),
            IconButton(
              tooltip: '训练提示音',
              onPressed: _toggleSound,
              icon: Icon(
                _soundEnabled
                    ? Icons.volume_up_rounded
                    : Icons.volume_off_rounded,
                color:
                    _soundEnabled ? WorkoutColors.green : WorkoutColors.muted,
              ),
            ),
            const SizedBox(width: 9),
            SizedBox(
              width: 100,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${stepIndex + 1} / ${_WorkoutStep.values.length}',
                    style: const TextStyle(
                      color: WorkoutColors.muted,
                      fontSize: 10,
                    ),
                  ),
                  const SizedBox(height: 5),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value: (stepIndex + 1) / _WorkoutStep.values.length,
                      minHeight: 5,
                      backgroundColor: WorkoutColors.panelSoft,
                      valueColor: const AlwaysStoppedAnimation(
                        WorkoutColors.green,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep() {
    switch (_step) {
      case _WorkoutStep.selectAction:
        return SelectActionPage(
          key: const ValueKey('select-action'),
          exercises: _exercises,
          quickExercises: _quickExercises,
          profile: _profile,
          onProfileChanged: _applyProfile,
          onToggleExercise: _toggleExercise,
          onAddQuickExercise: _addQuickExercise,
          onAddCustomExercise: _addCustomExercise,
          onAdjustExercise: _adjustExercise,
          onDeleteExercise: _deleteExercise,
          onStartTraining: _startTrainingPreparation,
          onHistory: () => _openHistory(returnStep: _WorkoutStep.selectAction),
          selectedBodyPart: _selectedBodyPart,
          onBodyPartChanged:
              (bodyPart) => setState(() => _selectedBodyPart = bodyPart),
        );
      case _WorkoutStep.startTraining:
        return StartTrainingPage(
          key: const ValueKey('start-training'),
          exercises: _selectedExercises,
          onBack: () => _transitionTo(_WorkoutStep.selectAction),
          onStart: _beginTraining,
        );
      case _WorkoutStep.currentAction:
      case _WorkoutStep.rest:
        return TrainingSessionPage(
          key: ValueKey('training-session-$_activeIndex'),
          isResting: _step == _WorkoutStep.rest,
          exercise: _activeExercise,
          actionNumber: _activeActionNumber,
          totalActions: _selectedExercises.length,
          isLastSet: _isLastSet,
          isLastAction: _isLastAction,
          restSeconds: _restSeconds,
          rir: _currentRir,
          onRirChanged: (value) => setState(() => _currentRir = value),
          onConfirmSet: _confirmCompletedSet,
          onContinue: _continueAfterRest,
          onSkip: _continueAfterRest,
          onAdjust: () => unawaited(_adjustExercise(_activeExercise)),
          onSwitchAction: () => unawaited(_switchAction()),
          onAddAction: () => unawaited(_addCustomExercise()),
          onBack: () => _transitionTo(_WorkoutStep.startTraining),
        );
      case _WorkoutStep.todaySummary:
        return TodaySummaryPage(
          key: const ValueKey('today-summary'),
          exercises:
              _partialSessionSaved
                  ? _selectedExercises
                      .where((exercise) => exercise.completedSets > 0)
                      .toList()
                  : _selectedExercises,
          completedSets: _completedSets,
          volume: _volume,
          duration: _trainingDuration,
          isPartial: _partialSessionSaved,
          onHistory: () => _transitionTo(_WorkoutStep.history),
          onRestart: _restartTraining,
        );
      case _WorkoutStep.history:
        return HistoryPage(
          key: const ValueKey('history'),
          records: _history,
          onBack: () => _transitionTo(_historyReturnStep),
        );
    }
  }
}
