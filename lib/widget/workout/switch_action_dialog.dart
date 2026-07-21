import 'package:flutter/material.dart';
import 'workout_models.dart';
import 'workout_theme.dart';

class SwitchActionDialog extends StatelessWidget {
  const SwitchActionDialog({
    super.key,
    required this.exercises,
    required this.activeExercise,
  });

  final List<WorkoutExercise> exercises;
  final WorkoutExercise activeExercise;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: WorkoutColors.panel,
      title: const Text(
        '切换当前动作',
        style: TextStyle(
          color: WorkoutColors.text,
          fontSize: 17,
          fontWeight: FontWeight.w800,
        ),
      ),
      content: SizedBox(
        width: 360,
        child: ListView.separated(
          shrinkWrap: true,
          itemCount: exercises.length,
          separatorBuilder: (_, _) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final exercise = exercises[index];
            final isActive = identical(exercise, activeExercise);
            return InkWell(
              borderRadius: BorderRadius.circular(11),
              onTap: () => Navigator.pop(context, exercise),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 11,
                ),
                decoration: BoxDecoration(
                  color:
                      isActive
                          ? WorkoutColors.greenDark
                          : WorkoutColors.background,
                  borderRadius: BorderRadius.circular(11),
                  border: Border.all(
                    color:
                        isActive ? WorkoutColors.green : WorkoutColors.border,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      isActive
                          ? Icons.radio_button_checked_rounded
                          : Icons.radio_button_unchecked_rounded,
                      color:
                          isActive ? WorkoutColors.green : WorkoutColors.muted,
                      size: 19,
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            exercise.name,
                            style: const TextStyle(
                              color: WorkoutColors.text,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            '${exercise.weightLabel} · '
                            '${exercise.completedSets}/${exercise.sets} 组',
                            style: const TextStyle(
                              color: WorkoutColors.muted,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isActive)
                      const Text(
                        '当前',
                        style: TextStyle(
                          color: WorkoutColors.green,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消', style: TextStyle(color: WorkoutColors.muted)),
        ),
      ],
    );
  }
}
