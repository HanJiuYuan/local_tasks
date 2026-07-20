import 'package:flutter/material.dart';
import 'workout_models.dart';
import 'workout_theme.dart';

class CompleteActionPage extends StatelessWidget {
  const CompleteActionPage({
    super.key,
    required this.exercise,
    required this.rir,
    required this.onRirChanged,
    required this.onConfirm,
    required this.onBack,
  });

  final WorkoutExercise exercise;
  final int rir;
  final ValueChanged<int> onRirChanged;
  final VoidCallback onConfirm;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final setNumber = exercise.completedSets + 1;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 610),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '完成动作',
              style: TextStyle(
                color: WorkoutColors.text,
                fontSize: 28,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 7),
            const Text(
              '完成这一组后，系统会自动开启组间休息。',
              style: TextStyle(color: WorkoutColors.muted, fontSize: 13),
            ),
            const SizedBox(height: 22),
            workoutPanel(
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
              child: Column(
                children: [
                  Container(
                    width: 86,
                    height: 86,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: WorkoutColors.greenDark,
                      border: Border.all(color: WorkoutColors.green, width: 2),
                    ),
                    child: const Icon(
                      Icons.done_rounded,
                      color: WorkoutColors.green,
                      size: 45,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    exercise.name,
                    style: const TextStyle(
                      color: WorkoutColors.text,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    '准备确认第 $setNumber / ${exercise.sets} 组',
                    style: const TextStyle(
                      color: WorkoutColors.muted,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 22),
                  workoutMetricStrip([
                    workoutMetric(label: '重量', value: exercise.weightLabel),
                    workoutMetric(label: '本组次数', value: '${exercise.reps} 个'),
                    workoutMetric(
                      label: '完成后休息',
                      value: '${exercise.restSeconds} 秒',
                    ),
                  ]),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Text(
                        '本组 RIR',
                        style: TextStyle(
                          color: WorkoutColors.text,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(child: _rirField()),
                    ],
                  ),
                  const SizedBox(height: 16),
                  workoutPrimaryButton(
                    label: '确认完成第 $setNumber 组',
                    icon: Icons.check_circle_rounded,
                    onPressed: onConfirm,
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: workoutSecondaryButton(
                      label: '返回当前动作',
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

  Widget _rirField() {
    return DropdownButtonFormField<int>(
      value: rir,
      isExpanded: true,
      dropdownColor: WorkoutColors.panelSoft,
      style: const TextStyle(color: WorkoutColors.text, fontSize: 13),
      decoration: InputDecoration(
        filled: true,
        fillColor: WorkoutColors.background,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(9),
          borderSide: const BorderSide(color: WorkoutColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(9),
          borderSide: const BorderSide(color: WorkoutColors.green),
        ),
      ),
      items: [
        for (var value = 0; value <= 4; value++)
          DropdownMenuItem<int>(
            value: value,
            child: Text('$value  ·  ${_rirLabel(value)}'),
          ),
      ],
      onChanged: (value) {
        if (value != null) onRirChanged(value);
      },
    );
  }

  String _rirLabel(int value) => switch (value) {
    0 => '已经力竭',
    1 => '还可完成 1 次',
    2 => '还可完成 2 次',
    3 => '还可完成 3 次',
    _ => '还可完成 4 次以上',
  };
}
