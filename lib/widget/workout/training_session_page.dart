import 'package:flutter/material.dart';
import 'current_action_page.dart';
import 'workout_models.dart';
import 'workout_theme.dart';

class TrainingSessionPage extends StatelessWidget {
  const TrainingSessionPage({
    super.key,
    required this.isResting,
    required this.exercise,
    required this.actionNumber,
    required this.totalActions,
    required this.restSeconds,
    required this.isLastSet,
    required this.isLastAction,
    required this.rir,
    required this.onRirChanged,
    required this.onConfirmSet,
    required this.onContinue,
    required this.onSkip,
    required this.onAdjust,
    required this.onSwitchAction,
    required this.onAddAction,
    required this.onBack,
  });

  final bool isResting;
  final WorkoutExercise exercise;
  final int actionNumber;
  final int totalActions;
  final int restSeconds;
  final bool isLastSet;
  final bool isLastAction;
  final int rir;
  final ValueChanged<int> onRirChanged;
  final VoidCallback onConfirmSet;
  final VoidCallback onContinue;
  final VoidCallback onSkip;
  final VoidCallback onAdjust;
  final VoidCallback onSwitchAction;
  final VoidCallback onAddAction;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sessionHeader(),
            const SizedBox(height: 12),
            AnimatedSize(
              duration: const Duration(milliseconds: 260),
              curve: Curves.easeOutCubic,
              alignment: Alignment.topCenter,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 240),
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
                child:
                    isResting
                        ? _restCard(key: const ValueKey('rest-card'))
                        : CurrentActionPage(
                          key: const ValueKey('current-action-card'),
                          exercise: exercise,
                          actionNumber: actionNumber,
                          totalActions: totalActions,
                          rir: rir,
                          onRirChanged: onRirChanged,
                          onConfirmSet: onConfirmSet,
                          onAdjust: onAdjust,
                          onSwitchAction: onSwitchAction,
                          onAddAction: onAddAction,
                          onBack: onBack,
                          showStepLabel: false,
                        ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sessionHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
      decoration: BoxDecoration(
        color: WorkoutColors.panel,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: WorkoutColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: WorkoutColors.greenDark,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              isResting ? Icons.timer_outlined : Icons.fitness_center_rounded,
              color: WorkoutColors.green,
              size: 19,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '训练中',
                  style: TextStyle(
                    color: WorkoutColors.text,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${exercise.name}  ·  动作 $actionNumber / $totalActions',
                  style: const TextStyle(
                    color: WorkoutColors.muted,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
            decoration: BoxDecoration(
              color: WorkoutColors.greenDark,
              borderRadius: BorderRadius.circular(9),
            ),
            child: Text(
              isResting ? '休息中' : '进行中',
              style: const TextStyle(
                color: WorkoutColors.green,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _restCard({Key? key}) {
    final progress = restSeconds / exercise.restSeconds;
    final continueLabel =
        !isLastSet
            ? '进入下一组'
            : !isLastAction
            ? '进入下一个动作'
            : '完成全部训练';
    final progressText =
        isLastSet
            ? isLastAction
                ? '这是最后一个动作的最后一组'
                : '这个动作已经完成'
            : '已完成第 ${exercise.completedSets} 组';

    return KeyedSubtree(
      key: key,
      child: workoutPanel(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
        child: Column(
          children: [
            Row(
              children: [
                const Icon(
                  Icons.hourglass_bottom_rounded,
                  color: WorkoutColors.green,
                  size: 21,
                ),
                const SizedBox(width: 8),
                const Text(
                  '组间休息',
                  style: TextStyle(
                    color: WorkoutColors.text,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const Spacer(),
                Text(
                  '${exercise.restSeconds} 秒设置',
                  style: const TextStyle(
                    color: WorkoutColors.muted,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: progress.clamp(0, 1),
                minHeight: 8,
                backgroundColor: WorkoutColors.panelSoft,
                valueColor: const AlwaysStoppedAnimation(WorkoutColors.green),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              workoutFormatTime(restSeconds),
              style: const TextStyle(
                color: WorkoutColors.text,
                fontSize: 42,
                fontWeight: FontWeight.w800,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 2),
            const Text(
              '剩余休息时间',
              style: TextStyle(color: WorkoutColors.muted, fontSize: 11),
            ),
            const SizedBox(height: 8),
            Text(
              restSeconds > 0 ? '休息结束后再继续，保持动作质量。' : '休息时间到了，可以继续训练。',
              style: const TextStyle(color: WorkoutColors.muted, fontSize: 12),
            ),
            const SizedBox(height: 14),
            Text(
              progressText,
              style: const TextStyle(color: WorkoutColors.muted, fontSize: 12),
            ),
            const SizedBox(height: 18),
            workoutPrimaryButton(
              label: continueLabel,
              icon:
                  isLastAction && isLastSet
                      ? Icons.emoji_events_rounded
                      : Icons.arrow_forward_rounded,
              onPressed: restSeconds == 0 ? onContinue : null,
            ),
            const SizedBox(height: 9),
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
    );
  }
}
