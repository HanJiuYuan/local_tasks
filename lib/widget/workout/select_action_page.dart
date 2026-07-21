import 'package:flutter/material.dart';
import 'workout_models.dart';
import 'workout_theme.dart';

class SelectActionPage extends StatelessWidget {
  const SelectActionPage({
    super.key,
    required this.exercises,
    required this.quickExercises,
    required this.profile,
    required this.onProfileChanged,
    required this.onToggleExercise,
    required this.onAddQuickExercise,
    required this.onAddCustomExercise,
    required this.onAdjustExercise,
    required this.onDeleteExercise,
    required this.onStartTraining,
    required this.onHistory,
    required this.selectedBodyPart,
    required this.onBodyPartChanged,
  });

  final List<WorkoutExercise> exercises;
  final List<QuickExercise> quickExercises;
  final TrainingProfile? profile;
  final ValueChanged<TrainingProfile> onProfileChanged;
  final ValueChanged<WorkoutExercise> onToggleExercise;
  final ValueChanged<QuickExercise> onAddQuickExercise;
  final VoidCallback onAddCustomExercise;
  final ValueChanged<WorkoutExercise> onAdjustExercise;
  final ValueChanged<WorkoutExercise> onDeleteExercise;
  final VoidCallback onStartTraining;
  final VoidCallback onHistory;
  final String? selectedBodyPart;
  final ValueChanged<String?> onBodyPartChanged;

  static const _bodyParts = ['全部', '胸', '背', '肩', '腿', '手臂', '核心', '其他'];

  List<WorkoutExercise> get selectedExercises =>
      exercises.where((exercise) => exercise.selected).toList();

  int get selectedSets =>
      selectedExercises.fold(0, (total, exercise) => total + exercise.sets);

  List<WorkoutExercise> get pendingWeightExercises =>
      selectedExercises
          .where((exercise) => !exercise.isBodyweight && exercise.weightPending)
          .toList();

  Map<String, List<QuickExercise>> get groupedQuickExercises {
    final grouped = <String, List<QuickExercise>>{};
    for (final exercise in quickExercises) {
      grouped.putIfAbsent(exercise.bodyPart, () => []).add(exercise);
    }
    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final desktop = constraints.maxWidth >= 760;
        final plan = _planPanel();
        final side = Column(
          children: [
            _selectedPanel(),
            const SizedBox(height: 16),
            _quickPanel(),
          ],
        );
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _intro(),
            const SizedBox(height: 22),
            if (desktop)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: plan),
                  const SizedBox(width: 18),
                  SizedBox(width: 310, child: side),
                ],
              )
            else ...[
              plan,
              const SizedBox(height: 16),
              side,
            ],
          ],
        );
      },
    );
  }

  Widget _intro() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '选择今天要练的动作',
                style: TextStyle(
                  color: WorkoutColors.text,
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                ),
              ),
              SizedBox(height: 7),
              Text(
                '先选好动作和训练参数，开始后只需要专注于当前这一组。',
                style: TextStyle(color: WorkoutColors.muted, fontSize: 14),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        OutlinedButton.icon(
          onPressed: onHistory,
          icon: const Icon(Icons.history_rounded, size: 17),
          label: const Text('历史记录'),
          style: OutlinedButton.styleFrom(
            foregroundColor: WorkoutColors.text,
            side: const BorderSide(color: WorkoutColors.border),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(11),
            ),
            textStyle: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }

  Widget _planPanel() {
    final bodyProfile = profile;
    return workoutPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          workoutSectionTitle(
            Icons.checklist_rounded,
            '今日动作计划',
            trailing: Text(
              '${selectedExercises.length} 个动作  ·  $selectedSets 组',
              style: const TextStyle(color: WorkoutColors.muted, fontSize: 12),
            ),
          ),
          const SizedBox(height: 17),
          if (bodyProfile != null) ...[
            _bodyDataStrip(bodyProfile),
            const SizedBox(height: 14),
          ],
          for (var index = 0; index < exercises.length; index++) ...[
            _exerciseTile(exercises[index], index),
            if (index != exercises.length - 1) const SizedBox(height: 10),
          ],
          const SizedBox(height: 15),
          InkWell(
            onTap: onAddCustomExercise,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              height: 42,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: WorkoutColors.border),
              ),
              child: const Text(
                '+  自定义新增动作',
                style: TextStyle(
                  color: WorkoutColors.muted,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _bodyDataStrip(TrainingProfile bodyProfile) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 10),
      decoration: BoxDecoration(
        color: WorkoutColors.background,
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: WorkoutColors.border),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.monitor_weight_outlined,
            color: WorkoutColors.green,
            size: 16,
          ),
          const SizedBox(width: 7),
          const Text(
            '身体数据',
            style: TextStyle(
              color: WorkoutColors.muted,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Wrap(
              alignment: WrapAlignment.end,
              spacing: 10,
              runSpacing: 3,
              children: [
                Text(
                  '体重 ${_formatMetric(bodyProfile.bodyWeightKg)} kg',
                  style: const TextStyle(
                    color: WorkoutColors.text,
                    fontSize: 11,
                  ),
                ),
                Text(
                  '身高 ${_formatMetric(bodyProfile.heightCm)} cm',
                  style: const TextStyle(
                    color: WorkoutColors.text,
                    fontSize: 11,
                  ),
                ),
                Text(
                  '体脂 ${bodyProfile.bodyFatPercent.toStringAsFixed(1)}%',
                  style: const TextStyle(
                    color: WorkoutColors.text,
                    fontSize: 11,
                  ),
                ),
                Text(
                  '训练 ${bodyProfile.trainingDays} 天',
                  style: const TextStyle(
                    color: WorkoutColors.text,
                    fontSize: 11,
                  ),
                ),
                Text(
                  '经验 ${bodyProfile.experience.label}',
                  style: const TextStyle(
                    color: WorkoutColors.text,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatMetric(double value) =>
      value == value.roundToDouble()
          ? value.toInt().toString()
          : value.toStringAsFixed(1);

  Widget _exerciseTile(WorkoutExercise exercise, int index) {
    return InkWell(
      onTap: () => onToggleExercise(exercise),
      borderRadius: BorderRadius.circular(13),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.fromLTRB(11, 9, 8, 9),
        decoration: BoxDecoration(
          color:
              exercise.selected ? WorkoutColors.panelSoft : Colors.transparent,
          borderRadius: BorderRadius.circular(13),
          border: Border.all(
            color:
                exercise.selected ? WorkoutColors.green : WorkoutColors.border,
          ),
        ),
        child: Row(
          children: [
            Checkbox(
              value: exercise.selected,
              onChanged: (_) => onToggleExercise(exercise),
              activeColor: WorkoutColors.green,
              checkColor: WorkoutColors.background,
              side: const BorderSide(color: WorkoutColors.muted),
            ),
            const SizedBox(width: 3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          exercise.name,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: WorkoutColors.text,
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: WorkoutColors.greenDark,
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Text(
                          exercise.bodyPart,
                          style: const TextStyle(
                            color: WorkoutColors.green,
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    exercise.planLabel,
                    style: const TextStyle(
                      color: WorkoutColors.muted,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: '调整 ${exercise.name} 参数',
              onPressed: () => onAdjustExercise(exercise),
              icon: const Icon(
                Icons.tune_rounded,
                color: WorkoutColors.muted,
                size: 18,
              ),
            ),
            IconButton(
              tooltip: '删除 ${exercise.name}',
              onPressed: () => onDeleteExercise(exercise),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints.tightFor(width: 30, height: 34),
              icon: const Icon(
                Icons.delete_outline_rounded,
                color: Color(0xFFB66F7C),
                size: 18,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _selectedPanel() {
    return workoutPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          workoutSectionTitle(Icons.flag_rounded, '本次训练'),
          const SizedBox(height: 14),
          Text(
            selectedExercises.isEmpty
                ? '还没有选择动作'
                : '已选择 ${selectedExercises.length} 个动作',
            style: const TextStyle(
              color: WorkoutColors.text,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            selectedExercises.isEmpty
                ? '至少选择一个动作后才能开始训练。'
                : '共 $selectedSets 组，完成后会自动生成今日数据。',
            style: const TextStyle(color: WorkoutColors.muted, fontSize: 12),
          ),
          if (pendingWeightExercises.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
              decoration: BoxDecoration(
                color: WorkoutColors.amber.withValues(alpha: .12),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: WorkoutColors.amber.withValues(alpha: .35),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.warning_amber_rounded,
                    color: WorkoutColors.amber,
                    size: 17,
                  ),
                  const SizedBox(width: 7),
                  Expanded(
                    child: Text(
                      '有 ${pendingWeightExercises.length} 个动作未设置重量，请先填写身体数据或调整重量。',
                      style: const TextStyle(
                        color: WorkoutColors.text,
                        fontSize: 11,
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 18),
          workoutPrimaryButton(
            label: '开始今日训练',
            icon: Icons.play_arrow_rounded,
            onPressed: selectedExercises.isEmpty ? null : onStartTraining,
          ),
        ],
      ),
    );
  }

  Widget _quickPanel() {
    return workoutPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '快捷动作（点击加入）',
            style: TextStyle(
              color: WorkoutColors.muted,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 5),
          const Text(
            '按训练部位选择动作，点击后即可加入今日计划。',
            style: TextStyle(color: WorkoutColors.muted, fontSize: 11),
          ),
          const SizedBox(height: 7),
          TrainingProfileEditor(profile: profile, onApply: onProfileChanged),
          const SizedBox(height: 10),
          _bodyPartFilters(),
          const SizedBox(height: 10),
          if (_visibleQuickGroups().isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 18),
              child: Center(
                child: Text(
                  '这个部位暂无快捷动作，可以新增自定义动作。',
                  style: TextStyle(color: WorkoutColors.muted, fontSize: 11),
                ),
              ),
            )
          else
            for (final group in _visibleQuickGroups())
              _quickGroup(group.key, group.value),
        ],
      ),
    );
  }

  List<MapEntry<String, List<QuickExercise>>> _visibleQuickGroups() {
    return groupedQuickExercises.entries
        .where(
          (group) => selectedBodyPart == null || group.key == selectedBodyPart,
        )
        .toList();
  }

  Widget _bodyPartFilters() {
    return Wrap(
      spacing: 7,
      runSpacing: 7,
      children: [
        for (final bodyPart in _bodyParts)
          FilterChip(
            label: Text(bodyPart),
            selected:
                bodyPart == '全部'
                    ? selectedBodyPart == null
                    : selectedBodyPart == bodyPart,
            onSelected:
                (_) => onBodyPartChanged(bodyPart == '全部' ? null : bodyPart),
            selectedColor: WorkoutColors.greenDark,
            backgroundColor: WorkoutColors.background,
            checkmarkColor: WorkoutColors.green,
            side: const BorderSide(color: WorkoutColors.border),
            labelStyle: TextStyle(
              color:
                  (bodyPart == '全部'
                          ? selectedBodyPart == null
                          : selectedBodyPart == bodyPart)
                      ? WorkoutColors.green
                      : WorkoutColors.muted,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 3),
            visualDensity: VisualDensity.compact,
          ),
      ],
    );
  }

  Widget _quickGroup(String bodyPart, List<QuickExercise> items) {
    final icon = switch (bodyPart) {
      '胸' => Icons.fitness_center_rounded,
      '背' => Icons.accessibility_new_rounded,
      '肩' => Icons.self_improvement_rounded,
      '腿' => Icons.directions_run_rounded,
      '手臂' => Icons.sports_martial_arts_rounded,
      '核心' => Icons.radio_button_checked_rounded,
      _ => Icons.fitness_center_rounded,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: WorkoutColors.green, size: 16),
            const SizedBox(width: 8),
            Text(
              bodyPart,
              style: const TextStyle(
                color: WorkoutColors.text,
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              '${items.length} 个动作',
              style: const TextStyle(color: WorkoutColors.muted, fontSize: 11),
            ),
          ],
        ),
        const SizedBox(height: 8),
        GridView.builder(
          itemCount: items.length,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            mainAxisExtent: 54,
          ),
          itemBuilder: (context, index) {
            final item = items[index];
            return InkWell(
              onTap: () => onAddQuickExercise(item),
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
                decoration: BoxDecoration(
                  color: WorkoutColors.background,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: WorkoutColors.border),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.name,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: WorkoutColors.text,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${item.weightLabel} · ${item.sets}组',
                      style: const TextStyle(
                        color: WorkoutColors.muted,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

class TrainingProfileEditor extends StatefulWidget {
  const TrainingProfileEditor({
    super.key,
    required this.profile,
    required this.onApply,
  });

  final TrainingProfile? profile;
  final ValueChanged<TrainingProfile> onApply;

  @override
  State<TrainingProfileEditor> createState() => _TrainingProfileEditorState();
}

class _TrainingProfileEditorState extends State<TrainingProfileEditor> {
  late final TextEditingController _weightController;
  late final TextEditingController _heightController;
  late final TextEditingController _bodyFatController;
  late final TextEditingController _trainingDaysController;
  TrainingExperience? _experience;
  String? _error;

  @override
  void initState() {
    super.initState();
    _weightController = TextEditingController(
      text: _formatValue(widget.profile?.bodyWeightKg),
    );
    _heightController = TextEditingController(
      text: _formatValue(widget.profile?.heightCm),
    );
    _bodyFatController = TextEditingController(
      text: _formatValue(widget.profile?.bodyFatPercent),
    );
    _trainingDaysController = TextEditingController(
      text: widget.profile?.trainingDays.toString() ?? '',
    );
    _experience = widget.profile?.experience;
  }

  @override
  void dispose() {
    _weightController.dispose();
    _heightController.dispose();
    _bodyFatController.dispose();
    _trainingDaysController.dispose();
    super.dispose();
  }

  static String _formatValue(double? value) =>
      value == null
          ? ''
          : value == value.roundToDouble()
          ? value.toInt().toString()
          : value.toStringAsFixed(1);

  void _apply() {
    final weight = double.tryParse(_weightController.text.trim());
    final height = double.tryParse(_heightController.text.trim());
    final bodyFat = double.tryParse(_bodyFatController.text.trim());
    final trainingDays = int.tryParse(_trainingDaysController.text.trim());
    if (weight == null ||
        height == null ||
        bodyFat == null ||
        trainingDays == null ||
        _experience == null) {
      setState(() => _error = '请输入有效数字');
      return;
    }
    if (weight < 30 || weight > 300) {
      setState(() => _error = '体重请输入 30–300 kg');
      return;
    }
    if (height < 100 || height > 230) {
      setState(() => _error = '身高请输入 100–230 cm');
      return;
    }
    if (bodyFat < 3 || bodyFat > 60) {
      setState(() => _error = '体脂率请输入 3–60%');
      return;
    }
    if (trainingDays < 0 || trainingDays > 10000) {
      setState(() => _error = '训练天数请输入 0–10000 天');
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() => _error = null);
    widget.onApply(
      TrainingProfile(
        bodyWeightKg: weight,
        heightCm: height,
        bodyFatPercent: bodyFat,
        trainingDays: trainingDays,
        experience: _experience!,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '输入身体数据，自动估算快捷动作重量',
          style: TextStyle(
            color: WorkoutColors.text,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 7),
        Row(
          children: [
            Expanded(child: _field(_weightController, '体重 kg')),
            const SizedBox(width: 7),
            Expanded(child: _field(_heightController, '身高 cm')),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(child: _field(_bodyFatController, '体脂 %')),
            const SizedBox(width: 7),
            Expanded(
              child: _field(_trainingDaysController, '训练天数', integerOnly: true),
            ),
          ],
        ),
        const SizedBox(height: 8),
        _experienceField(),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          height: 36,
          child: OutlinedButton.icon(
            onPressed: _apply,
            style: OutlinedButton.styleFrom(
              foregroundColor: WorkoutColors.green,
              side: const BorderSide(color: WorkoutColors.greenDark),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(9),
              ),
              padding: EdgeInsets.zero,
            ),
            icon: const Icon(Icons.refresh_rounded, size: 15),
            label: const Text(
              '应用并重新估算',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
            ),
          ),
        ),
        const SizedBox(height: 5),
        const Text(
          '训练天数越少，建议起始重量越保守。',
          style: TextStyle(color: WorkoutColors.muted, fontSize: 11),
        ),
        if (_error != null) ...[
          const SizedBox(height: 5),
          Text(
            _error!,
            style: const TextStyle(color: Color(0xFFFF8294), fontSize: 11),
          ),
        ],
      ],
    );
  }

  Widget _field(
    TextEditingController controller,
    String label, {
    bool integerOnly = false,
  }) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.numberWithOptions(decimal: !integerOnly),
      style: const TextStyle(color: WorkoutColors.text, fontSize: 13),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: WorkoutColors.muted, fontSize: 10),
        floatingLabelBehavior: FloatingLabelBehavior.always,
        filled: true,
        fillColor: WorkoutColors.background,
        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: WorkoutColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: WorkoutColors.green),
        ),
      ),
      onSubmitted: (_) => _apply(),
    );
  }

  Widget _experienceField() {
    return DropdownButtonFormField<TrainingExperience>(
      value: _experience,
      isExpanded: true,
      dropdownColor: WorkoutColors.panelSoft,
      style: const TextStyle(color: WorkoutColors.text, fontSize: 13),
      decoration: InputDecoration(
        labelText: '训练经验',
        labelStyle: const TextStyle(color: WorkoutColors.muted, fontSize: 10),
        hintText: '请选择训练经验',
        hintStyle: const TextStyle(color: WorkoutColors.muted, fontSize: 12),
        filled: true,
        fillColor: WorkoutColors.background,
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: WorkoutColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: WorkoutColors.green),
        ),
      ),
      items: [
        for (final experience in TrainingExperience.values)
          DropdownMenuItem<TrainingExperience>(
            value: experience,
            child: Text(experience.label),
          ),
      ],
      onChanged: (value) => setState(() => _experience = value),
    );
  }
}
