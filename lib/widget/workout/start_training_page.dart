import 'package:flutter/material.dart';
import 'workout_models.dart';
import 'workout_theme.dart';

class StartTrainingPage extends StatelessWidget {
  const StartTrainingPage({
    super.key,
    required this.exercises,
    required this.onBack,
    required this.onStart,
  });

  final List<WorkoutExercise> exercises;
  final VoidCallback onBack;
  final VoidCallback onStart;

  int get totalSets =>
      exercises.fold(0, (total, exercise) => total + exercise.sets);

  double get volume => exercises.fold(
    0,
    (total, exercise) =>
        total + exercise.weight * exercise.sets * exercise.reps,
  );

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 700),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '开始今日训练',
              style: TextStyle(
                color: WorkoutColors.text,
                fontSize: 28,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 7),
            const Text(
              '准备好了吗？接下来每次只关注一个动作和一组。',
              style: TextStyle(color: WorkoutColors.muted, fontSize: 13),
            ),
            const SizedBox(height: 22),
            workoutPanel(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Container(
                    width: 76,
                    height: 76,
                    decoration: BoxDecoration(
                      color: WorkoutColors.greenDark,
                      borderRadius: BorderRadius.circular(23),
                    ),
                    child: const Icon(
                      Icons.play_arrow_rounded,
                      color: WorkoutColors.green,
                      size: 44,
                    ),
                  ),
                  const SizedBox(height: 15),
                  const Text(
                    '今天的训练计划已准备好',
                    style: TextStyle(
                      color: WorkoutColors.text,
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 7),
                  const Text(
                    '完成一组后会自动进入组间休息，休息结束再继续下一组。',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: WorkoutColors.muted, fontSize: 12),
                  ),
                  const SizedBox(height: 22),
                  workoutMetricStrip([
                    workoutMetric(label: '动作', value: '${exercises.length} 个'),
                    workoutMetric(label: '总组数', value: '$totalSets 组'),
                    workoutMetric(
                      label: '预计容量',
                      value: '${volume.toStringAsFixed(0)} kg',
                    ),
                  ]),
                  const SizedBox(height: 22),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: workoutSectionTitle(Icons.list_alt_rounded, '训练顺序'),
                  ),
                  const SizedBox(height: 12),
                  for (var index = 0; index < exercises.length; index++)
                    _orderItem(exercises[index], index),
                  const SizedBox(height: 22),
                  workoutPrimaryButton(
                    label: '进入当前动作',
                    icon: Icons.arrow_forward_rounded,
                    onPressed: onStart,
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: workoutSecondaryButton(
                      label: '返回选择动作',
                      onPressed: onBack,
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

  Widget _orderItem(WorkoutExercise exercise, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      decoration: BoxDecoration(
        color: WorkoutColors.background,
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: WorkoutColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 25,
            height: 25,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: WorkoutColors.panelSoft,
              borderRadius: BorderRadius.circular(7),
            ),
            child: Text(
              '${index + 1}',
              style: const TextStyle(
                color: WorkoutColors.green,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              exercise.name,
              style: const TextStyle(
                color: WorkoutColors.text,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Text(
            exercise.planLabel,
            style: const TextStyle(color: WorkoutColors.muted, fontSize: 11),
          ),
        ],
      ),
    );
  }
}
