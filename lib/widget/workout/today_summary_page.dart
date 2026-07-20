import 'package:flutter/material.dart';
import 'workout_models.dart';
import 'workout_theme.dart';

class TodaySummaryPage extends StatelessWidget {
  const TodaySummaryPage({
    super.key,
    required this.exercises,
    required this.completedSets,
    required this.volume,
    required this.duration,
    required this.onHistory,
    required this.onRestart,
  });

  final List<WorkoutExercise> exercises;
  final int completedSets;
  final double volume;
  final Duration duration;
  final VoidCallback onHistory;
  final VoidCallback onRestart;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '今日训练完成',
              style: TextStyle(
                color: WorkoutColors.text,
                fontSize: 28,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 7),
            const Text(
              '做得很好，今天的训练数据已经整理好了。',
              style: TextStyle(color: WorkoutColors.muted, fontSize: 13),
            ),
            const SizedBox(height: 22),
            workoutPanel(
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
              child: Column(
                children: [
                  Container(
                    width: 78,
                    height: 78,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: WorkoutColors.greenDark,
                      border: Border.all(color: WorkoutColors.green, width: 2),
                    ),
                    child: const Icon(
                      Icons.emoji_events_rounded,
                      color: WorkoutColors.green,
                      size: 40,
                    ),
                  ),
                  const SizedBox(height: 15),
                  const Text(
                    '完成全部训练！',
                    style: TextStyle(
                      color: WorkoutColors.text,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 7),
                  const Text(
                    '每一组都被准确记录，明天继续保持。',
                    style: TextStyle(color: WorkoutColors.muted, fontSize: 12),
                  ),
                  const SizedBox(height: 22),
                  workoutMetricStrip([
                    workoutMetric(
                      label: '完成动作',
                      value: '${exercises.length} 个',
                      color: WorkoutColors.green,
                    ),
                    workoutMetric(
                      label: '完成组数',
                      value: '$completedSets 组',
                      color: WorkoutColors.blue,
                    ),
                    workoutMetric(
                      label: '训练时长',
                      value: workoutFormatDuration(duration),
                      color: WorkoutColors.amber,
                    ),
                  ]),
                  const SizedBox(height: 13),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      '总容量  ${volume.toStringAsFixed(0)} kg',
                      style: const TextStyle(
                        color: WorkoutColors.muted,
                        fontSize: 11,
                      ),
                    ),
                  ),
                  const SizedBox(height: 22),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: workoutSectionTitle(
                      Icons.fact_check_outlined,
                      '动作完成情况',
                    ),
                  ),
                  const SizedBox(height: 12),
                  for (final exercise in exercises) _exerciseRow(exercise),
                  const SizedBox(height: 22),
                  workoutPrimaryButton(
                    label: '查看历史训练数据',
                    icon: Icons.history_rounded,
                    onPressed: onHistory,
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: workoutSecondaryButton(
                      label: '再开始一次训练',
                      icon: Icons.refresh_rounded,
                      onPressed: onRestart,
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

  Widget _exerciseRow(WorkoutExercise exercise) {
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
          const Icon(
            Icons.check_circle_rounded,
            color: WorkoutColors.green,
            size: 19,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  exercise.name,
                  style: const TextStyle(
                    color: WorkoutColors.text,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${exercise.completedSets}/${exercise.sets} 组'
                  '${exercise.averageRir == null ? '' : '  ·  平均 RIR ${exercise.averageRir!.toStringAsFixed(1)}'}',
                  style: const TextStyle(
                    color: WorkoutColors.muted,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          if (exercise.nextRecommendedWeight != null)
            Text(
              '下次 ${_weightLabel(exercise.nextRecommendedWeight!)}',
              style: const TextStyle(
                color: WorkoutColors.green,
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
        ],
      ),
    );
  }

  String _weightLabel(double weight) =>
      weight == weight.roundToDouble()
          ? '${weight.toInt()} kg'
          : '${weight.toStringAsFixed(1)} kg';
}
