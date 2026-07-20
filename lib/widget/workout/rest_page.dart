import 'package:flutter/material.dart';
import 'workout_models.dart';
import 'workout_theme.dart';

class RestPage extends StatelessWidget {
  const RestPage({
    super.key,
    required this.exercise,
    required this.seconds,
    required this.isLastSet,
    required this.isLastAction,
    required this.onContinue,
    required this.onSkip,
  });

  final WorkoutExercise exercise;
  final int seconds;
  final bool isLastSet;
  final bool isLastAction;
  final VoidCallback onContinue;
  final VoidCallback onSkip;

  String get continueLabel {
    if (!isLastSet) return '进入下一组';
    if (!isLastAction) return '进入下一个动作';
    return '完成全部训练';
  }

  @override
  Widget build(BuildContext context) {
    final progress = seconds / exercise.restSeconds;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 610),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '组间休息',
              style: TextStyle(
                color: WorkoutColors.text,
                fontSize: 28,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 7),
            Text(
              seconds > 0 ? '休息结束后再继续，保持动作质量。' : '休息时间到了，可以继续训练。',
              style: const TextStyle(color: WorkoutColors.muted, fontSize: 13),
            ),
            const SizedBox(height: 22),
            workoutPanel(
              padding: const EdgeInsets.fromLTRB(24, 30, 24, 24),
              child: Column(
                children: [
                  const Icon(
                    Icons.timer_outlined,
                    color: WorkoutColors.green,
                    size: 28,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    exercise.name,
                    style: const TextStyle(
                      color: WorkoutColors.text,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 190,
                        height: 190,
                        child: CircularProgressIndicator(
                          value: progress.clamp(0, 1),
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
                          Text(
                            workoutFormatTime(seconds),
                            style: const TextStyle(
                              color: WorkoutColors.text,
                              fontSize: 39,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 2,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            '剩余休息时间',
                            style: TextStyle(
                              color: WorkoutColors.muted,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  Text(
                    isLastSet
                        ? isLastAction
                            ? '这是最后一个动作的最后一组'
                            : '这个动作已经完成'
                        : '已完成第 ${exercise.completedSets} 组',
                    style: const TextStyle(
                      color: WorkoutColors.muted,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 22),
                  workoutPrimaryButton(
                    label: continueLabel,
                    icon:
                        isLastAction && isLastSet
                            ? Icons.emoji_events_rounded
                            : Icons.arrow_forward_rounded,
                    onPressed: seconds == 0 ? onContinue : null,
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: onSkip,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: WorkoutColors.muted,
                        side: const BorderSide(color: WorkoutColors.border),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(13),
                        ),
                      ),
                      child: const Text('跳过休息'),
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
}
