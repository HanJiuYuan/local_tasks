import 'package:flutter/material.dart';
import 'workout_models.dart';
import 'workout_theme.dart';

class AdjustExerciseDialog extends StatefulWidget {
  const AdjustExerciseDialog({super.key, required this.exercise});

  final WorkoutExercise exercise;

  @override
  State<AdjustExerciseDialog> createState() => _AdjustExerciseDialogState();
}

class _AdjustExerciseDialogState extends State<AdjustExerciseDialog> {
  late final TextEditingController _weightController;
  late final TextEditingController _setsController;
  late final TextEditingController _repsController;
  late final TextEditingController _firstTestWeightController;
  late final TextEditingController _firstTestRepsController;
  late int _restSeconds;

  @override
  void initState() {
    super.initState();
    _weightController = TextEditingController(
      text: widget.exercise.weight.toString(),
    );
    _setsController = TextEditingController(
      text: widget.exercise.sets.toString(),
    );
    _repsController = TextEditingController(
      text: widget.exercise.reps.toString(),
    );
    _firstTestWeightController = TextEditingController(
      text: widget.exercise.firstTestWeight?.toString() ?? '',
    );
    _firstTestRepsController = TextEditingController(
      text: widget.exercise.firstTestReps?.toString() ?? '',
    );
    _restSeconds = widget.exercise.restSeconds;
  }

  @override
  void dispose() {
    _weightController.dispose();
    _setsController.dispose();
    _repsController.dispose();
    _firstTestWeightController.dispose();
    _firstTestRepsController.dispose();
    super.dispose();
  }

  void _save() {
    final weight = double.tryParse(_weightController.text);
    final sets = int.tryParse(_setsController.text);
    final reps = int.tryParse(_repsController.text);
    final firstTestWeight = double.tryParse(
      _firstTestWeightController.text.trim(),
    );
    final firstTestReps = int.tryParse(_firstTestRepsController.text.trim());
    if (weight == null ||
        sets == null ||
        reps == null ||
        sets < 1 ||
        reps < 1 ||
        (!widget.exercise.isBodyweight && weight <= 0) ||
        (firstTestWeight == null) != (firstTestReps == null) ||
        (firstTestWeight != null &&
            (firstTestWeight <= 0 ||
                firstTestReps == null ||
                firstTestReps < 1 ||
                firstTestReps > 20))) {
      return;
    }

    Navigator.pop(
      context,
      WorkoutExercise(
        name: widget.exercise.name,
        weight: weight,
        sets: sets,
        reps: reps,
        bodyPart: widget.exercise.bodyPart,
        restSeconds: _restSeconds,
        selected: widget.exercise.selected,
        isBodyweight: widget.exercise.isBodyweight,
        firstTestWeight: firstTestWeight,
        firstTestReps: firstTestReps,
        rirFeedback: widget.exercise.rirFeedback,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: WorkoutColors.panelSoft,
      title: const Text('调整训练参数', style: TextStyle(color: WorkoutColors.text)),
      content: SingleChildScrollView(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 340),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _field(_weightController, '训练重量（kg）'),
              const SizedBox(height: 12),
              _field(_setsController, '目标组数'),
              const SizedBox(height: 12),
              _field(_repsController, '每组次数'),
              const SizedBox(height: 12),
              _restField(),
              const SizedBox(height: 16),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '首次力量测试（可选）',
                  style: TextStyle(
                    color: WorkoutColors.text,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: 5),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '填写一次标准动作的测试重量和完成次数，用于估算训练上限。',
                  style: TextStyle(color: WorkoutColors.muted, fontSize: 10),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _field(_firstTestWeightController, '测试重量（kg）'),
                  ),
                  const SizedBox(width: 10),
                  Expanded(child: _field(_firstTestRepsController, '测试次数')),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消', style: TextStyle(color: WorkoutColors.muted)),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: WorkoutColors.green),
          onPressed: _save,
          child: const Text(
            '保存',
            style: TextStyle(color: WorkoutColors.background),
          ),
        ),
      ],
    );
  }

  Widget _field(TextEditingController controller, String label) {
    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      style: const TextStyle(color: WorkoutColors.text),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: WorkoutColors.muted),
        enabledBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: WorkoutColors.border),
        ),
        focusedBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: WorkoutColors.green),
        ),
      ),
    );
  }

  Widget _restField() {
    final options = <int>{60, 90, 120, 180, _restSeconds}.toList()..sort();
    return DropdownButtonFormField<int>(
      value: _restSeconds,
      isExpanded: true,
      dropdownColor: WorkoutColors.panelSoft,
      style: const TextStyle(color: WorkoutColors.text, fontSize: 13),
      decoration: const InputDecoration(
        labelText: '组间休息（秒）',
        labelStyle: TextStyle(color: WorkoutColors.muted),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: WorkoutColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: WorkoutColors.green),
        ),
      ),
      items: [
        for (final seconds in options)
          DropdownMenuItem<int>(value: seconds, child: Text('$seconds 秒')),
      ],
      onChanged: (value) {
        if (value != null) setState(() => _restSeconds = value);
      },
    );
  }
}
