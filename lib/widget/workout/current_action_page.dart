import 'package:flutter/material.dart';
import 'workout_models.dart';
import 'workout_theme.dart';

class CurrentActionPage extends StatelessWidget {
  const CurrentActionPage({
    super.key,
    required this.exercise,
    required this.actionNumber,
    required this.totalActions,
    required this.onCompleteAction,
    required this.onBack,
  });

  final WorkoutExercise exercise;
  final int actionNumber;
  final int totalActions;
  final VoidCallback onCompleteAction;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final progress =
        exercise.sets == 0 ? 0.0 : exercise.completedSets / exercise.sets;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _stepLabel(),
            const SizedBox(height: 16),
            workoutPanel(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 11,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: WorkoutColors.greenDark,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Text(
                          '当前动作',
                          style: TextStyle(
                            color: WorkoutColors.green,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '$actionNumber / $totalActions',
                        style: const TextStyle(
                          color: WorkoutColors.muted,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),
                  Text(
                    exercise.name,
                    style: const TextStyle(
                      color: WorkoutColors.text,
                      fontSize: 30,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    exercise.planLabel,
                    style: const TextStyle(
                      color: WorkoutColors.muted,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 22),
                  _progressBar(progress),
                  const SizedBox(height: 24),
                  workoutMetricStrip([
                    workoutMetric(label: '当前重量', value: exercise.weightLabel),
                    workoutMetric(label: '目标次数', value: '${exercise.reps} 个'),
                    workoutMetric(
                      label: '组间休息',
                      value: '${exercise.restSeconds} 秒',
                    ),
                  ]),
                  const SizedBox(height: 35),
                  Center(
                    child: SizedBox(
                      width: 190,
                      height: 190,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          SizedBox(
                            width: 170,
                            height: 170,
                            child: CircularProgressIndicator(
                              value: progress,
                              strokeWidth: 10,
                              backgroundColor: WorkoutColors.panelSoft,
                              valueColor: const AlwaysStoppedAnimation(
                                WorkoutColors.green,
                              ),
                            ),
                          ),
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text(
                                '已完成组数',
                                style: TextStyle(
                                  color: WorkoutColors.muted,
                                  fontSize: 11,
                                ),
                              ),
                              Text(
                                '${exercise.completedSets}',
                                style: const TextStyle(
                                  color: WorkoutColors.text,
                                  fontSize: 46,
                                  height: 1.05,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              Text(
                                '/ 目标 ${exercise.sets} 组',
                                style: const TextStyle(
                                  color: WorkoutColors.muted,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  workoutMetricStrip([
                    workoutMetric(
                      label: '已完成组数',
                      value: '${exercise.completedSets} 组',
                      color: WorkoutColors.green,
                    ),
                    workoutMetric(
                      label: '剩余去做',
                      value: '${exercise.sets - exercise.completedSets} 组',
                      color: WorkoutColors.amber,
                    ),
                    workoutMetric(
                      label: '剩余总个数',
                      value:
                          '${(exercise.sets - exercise.completedSets) * exercise.reps} 个',
                      color: WorkoutColors.blue,
                    ),
                  ]),
                  const SizedBox(height: 28),
                  workoutPrimaryButton(
                    label: '进入“完成动作”',
                    icon: Icons.check_rounded,
                    onPressed: onCompleteAction,
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: workoutSecondaryButton(
                      label: '返回训练准备',
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

  Widget _stepLabel() {
    return Row(
      children: [
        const Icon(
          Icons.radio_button_checked,
          color: WorkoutColors.green,
          size: 18,
        ),
        const SizedBox(width: 8),
        const Text(
          '专注当前动作',
          style: TextStyle(
            color: WorkoutColors.text,
            fontSize: 17,
            fontWeight: FontWeight.w800,
          ),
        ),
        const Spacer(),
        Text(
          '动作 $actionNumber / $totalActions',
          style: const TextStyle(color: WorkoutColors.muted, fontSize: 11),
        ),
      ],
    );
  }

  Widget _progressBar(double progress) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              '动作进度',
              style: TextStyle(color: WorkoutColors.muted, fontSize: 11),
            ),
            const Spacer(),
            Text(
              '${(progress * 100).round()}%',
              style: const TextStyle(
                color: WorkoutColors.green,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 8,
            backgroundColor: WorkoutColors.panelSoft,
            valueColor: const AlwaysStoppedAnimation(WorkoutColors.green),
          ),
        ),
      ],
    );
  }
}
