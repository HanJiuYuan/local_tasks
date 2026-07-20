import 'package:flutter/material.dart';
import 'workout_models.dart';
import 'workout_theme.dart';

class AddCustomActionDialog extends StatefulWidget {
  const AddCustomActionDialog({super.key});

  @override
  State<AddCustomActionDialog> createState() => _AddCustomActionDialogState();
}

class _AddCustomActionDialogState extends State<AddCustomActionDialog> {
  final _nameController = TextEditingController();
  int _sets = 4;
  int _reps = 12;
  int _weight = 40;
  int _restSeconds = 90;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;
    Navigator.pop(
      context,
      WorkoutExercise(
        name: name,
        weight: _weight.toDouble(),
        sets: _sets,
        reps: _reps,
        restSeconds: _restSeconds,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
      backgroundColor: Colors.transparent,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 15, 16, 16),
          decoration: BoxDecoration(
            color: WorkoutColors.panel,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: WorkoutColors.border),
            boxShadow: const [
              BoxShadow(
                color: Color(0x66000000),
                blurRadius: 28,
                offset: Offset(0, 14),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.auto_awesome_rounded,
                    color: WorkoutColors.green,
                    size: 17,
                  ),
                  const SizedBox(width: 7),
                  const Expanded(
                    child: Text(
                      '新建自定义动作',
                      style: TextStyle(
                        color: WorkoutColors.text,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: '关闭',
                    onPressed: () => Navigator.pop(context),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints.tightFor(
                      width: 24,
                      height: 24,
                    ),
                    icon: const Icon(
                      Icons.close_rounded,
                      color: WorkoutColors.muted,
                      size: 19,
                    ),
                  ),
                ],
              ),
              const Divider(color: WorkoutColors.border, height: 17),
              _label('动作名称'),
              const SizedBox(height: 6),
              TextField(
                controller: _nameController,
                autofocus: true,
                onChanged: (_) => setState(() {}),
                onSubmitted: (_) => _submit(),
                style: const TextStyle(color: WorkoutColors.text, fontSize: 13),
                decoration: _inputDecoration('输入如：哑铃侧平举'),
              ),
              const SizedBox(height: 14),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _stepperField(
                      label: '目标组数（组）',
                      value: _sets,
                      onDecrease:
                          () =>
                              setState(() => _sets = (_sets - 1).clamp(1, 20)),
                      onIncrease:
                          () =>
                              setState(() => _sets = (_sets + 1).clamp(1, 20)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _stepperField(
                      label: '每组次数（次）',
                      value: _reps,
                      onDecrease:
                          () =>
                              setState(() => _reps = (_reps - 1).clamp(1, 100)),
                      onIncrease:
                          () =>
                              setState(() => _reps = (_reps + 1).clamp(1, 100)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 13),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _stepperField(
                      label: '使用重量（kg）',
                      value: _weight,
                      onDecrease:
                          () => setState(
                            () => _weight = (_weight - 5).clamp(0, 500),
                          ),
                      onIncrease:
                          () => setState(
                            () => _weight = (_weight + 5).clamp(0, 500),
                          ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: _restField()),
                ],
              ),
              const SizedBox(height: 15),
              SizedBox(
                width: double.infinity,
                height: 42,
                child: FilledButton(
                  onPressed:
                      _nameController.text.trim().isEmpty ? null : _submit,
                  style: FilledButton.styleFrom(
                    backgroundColor: WorkoutColors.green,
                    disabledBackgroundColor: WorkoutColors.greenDark,
                    foregroundColor: WorkoutColors.background,
                    disabledForegroundColor: WorkoutColors.muted,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(11),
                    ),
                  ),
                  child: const Text(
                    '确认加入计划',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _label(String text) {
    return Text(
      text,
      style: const TextStyle(color: WorkoutColors.muted, fontSize: 11),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: WorkoutColors.muted, fontSize: 13),
      filled: true,
      fillColor: WorkoutColors.background,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(9),
        borderSide: const BorderSide(color: WorkoutColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(9),
        borderSide: const BorderSide(color: WorkoutColors.green),
      ),
    );
  }

  Widget _stepperField({
    required String label,
    required int value,
    required VoidCallback onDecrease,
    required VoidCallback onIncrease,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label(label),
        const SizedBox(height: 6),
        Container(
          height: 40,
          decoration: BoxDecoration(
            color: WorkoutColors.background,
            borderRadius: BorderRadius.circular(9),
            border: Border.all(color: WorkoutColors.border),
          ),
          child: Row(
            children: [
              _stepperButton(Icons.remove_rounded, onDecrease),
              Expanded(
                child: Center(
                  child: Text(
                    '$value',
                    style: const TextStyle(
                      color: WorkoutColors.text,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              _stepperButton(Icons.add_rounded, onIncrease),
            ],
          ),
        ),
      ],
    );
  }

  Widget _stepperButton(IconData icon, VoidCallback onPressed) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        width: 34,
        height: double.infinity,
        child: Icon(icon, color: WorkoutColors.muted, size: 16),
      ),
    );
  }

  Widget _restField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label('休息时间（秒）'),
        const SizedBox(height: 6),
        Container(
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: WorkoutColors.background,
            borderRadius: BorderRadius.circular(9),
            border: Border.all(color: WorkoutColors.border),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<int>(
              value: _restSeconds,
              isExpanded: true,
              dropdownColor: WorkoutColors.panelSoft,
              icon: const Icon(
                Icons.keyboard_arrow_down_rounded,
                color: WorkoutColors.text,
                size: 19,
              ),
              style: const TextStyle(color: WorkoutColors.text, fontSize: 12),
              items:
                  const [60, 90, 120, 180]
                      .map(
                        (value) => DropdownMenuItem<int>(
                          value: value,
                          child: Text(value == 90 ? '90 秒（经典）' : '$value 秒'),
                        ),
                      )
                      .toList(),
              onChanged: (value) {
                if (value != null) setState(() => _restSeconds = value);
              },
            ),
          ),
        ),
      ],
    );
  }
}
