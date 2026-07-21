import 'package:flutter/material.dart';
import 'workout_models.dart';
import 'workout_theme.dart';

class CurrentActionPage extends StatelessWidget {
  const CurrentActionPage({
    super.key,
    required this.exercise,
    required this.actionNumber,
    required this.totalActions,
    required this.rir,
    required this.onRirChanged,
    required this.onConfirmSet,
    required this.onAdjust,
    required this.onSwitchAction,
    required this.onAddAction,
    required this.onBack,
    this.showStepLabel = true,
  });

  final WorkoutExercise exercise;
  final int actionNumber;
  final int totalActions;
  final int rir;
  final ValueChanged<int> onRirChanged;
  final VoidCallback onConfirmSet;
  final VoidCallback onAdjust;
  final VoidCallback onSwitchAction;
  final VoidCallback onAddAction;
  final VoidCallback onBack;
  final bool showStepLabel;

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
            if (showStepLabel) ...[_stepLabel(), const SizedBox(height: 16)],
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
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      const Text(
                        '本组 RIR',
                        style: TextStyle(
                          color: WorkoutColors.text,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(child: _rirField()),
                    ],
                  ),
                  const SizedBox(height: 28),
                  workoutPrimaryButton(
                    label: '确认完成第 ${exercise.completedSets + 1} 组',
                    icon: Icons.check_circle_rounded,
                    onPressed: onConfirmSet,
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      OutlinedButton.icon(
                        onPressed: onAdjust,
                        icon: const Icon(Icons.tune_rounded, size: 16),
                        label: const Text('调整本动作'),
                        style: _smallActionStyle(),
                      ),
                      OutlinedButton.icon(
                        onPressed: onSwitchAction,
                        icon: const Icon(Icons.swap_horiz_rounded, size: 16),
                        label: const Text('切换动作'),
                        style: _smallActionStyle(),
                      ),
                      OutlinedButton.icon(
                        onPressed: onAddAction,
                        icon: const Icon(Icons.add_rounded, size: 16),
                        label: const Text('添加动作'),
                        style: _smallActionStyle(),
                      ),
                    ],
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

  ButtonStyle _smallActionStyle() {
    return OutlinedButton.styleFrom(
      foregroundColor: WorkoutColors.muted,
      side: const BorderSide(color: WorkoutColors.border),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      textStyle: const TextStyle(fontSize: 11),
    );
  }

  Widget _rirField() {
    return DropdownButtonFormField<int>(
      value: rir,
      isExpanded: true,
      decoration: InputDecoration(
        filled: true,
        fillColor: WorkoutColors.panelSoft,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 10,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: WorkoutColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: WorkoutColors.border),
        ),
      ),
      dropdownColor: WorkoutColors.panel,
      style: const TextStyle(color: WorkoutColors.text, fontSize: 13),
      items: List.generate(
        5,
        (index) => DropdownMenuItem(
          value: index,
          child: Text('$index · ${_rirLabel(index)}'),
        ),
      ),
      onChanged: (value) {
        if (value != null) onRirChanged(value);
      },
    );
  }

  String _rirLabel(int value) {
    switch (value) {
      case 0:
        return '已经力竭';
      case 1:
        return '还能做 1 次';
      case 2:
        return '还能做 2 次';
      case 3:
        return '还能做 3 次';
      default:
        return '还能做 4 次以上';
    }
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
