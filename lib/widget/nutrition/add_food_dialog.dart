import 'package:flutter/material.dart';
import '../workout/workout_theme.dart';
import 'nutrition_models.dart';

class AddFoodDialog extends StatefulWidget {
  const AddFoodDialog({super.key, this.initialMeal = MealType.breakfast});

  final MealType initialMeal;

  @override
  State<AddFoodDialog> createState() => _AddFoodDialogState();
}

class _AddFoodDialogState extends State<AddFoodDialog> {
  late MealType _meal;
  var _selectedCategory = FoodCategory.staple;
  final _nameController = TextEditingController();
  final _gramsController = TextEditingController(text: '100');
  String? _error;

  FoodNutrition? get _food => FoodDatabase.find(_nameController.text);

  double? get _grams => double.tryParse(_gramsController.text.trim());

  NutritionValues? get _calculated {
    final food = _food;
    final grams = _grams;
    if (food == null || grams == null || grams <= 0) return null;
    return food.calculate(grams);
  }

  List<FoodNutrition> get _categoryFoods =>
      FoodDatabase.foodsFor(_selectedCategory);

  @override
  void initState() {
    super.initState();
    _meal = widget.initialMeal;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _gramsController.dispose();
    super.dispose();
  }

  void _selectFood(FoodNutrition food) {
    _nameController.text = food.name;
    _nameController.selection = TextSelection.collapsed(
      offset: _nameController.text.length,
    );
    setState(() {
      _selectedCategory = FoodDatabase.categoryFor(food);
      _error = null;
    });
  }

  void _selectCategory(FoodCategory category) {
    setState(() {
      _selectedCategory = category;
      _error = null;
    });
  }

  void _save() {
    final food = _food;
    final grams = _grams;
    final values = _calculated;
    if (food == null || grams == null || grams <= 0 || values == null) {
      setState(() => _error = '请输入克数，并选择或输入可识别的常见食物');
      return;
    }

    Navigator.pop(
      context,
      FoodEntry(
        name: food.name,
        meal: _meal,
        grams: grams,
        calories: values.calories,
        protein: values.protein,
        carbs: values.carbs,
        fat: values.fat,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final food = _food;
    final values = _calculated;
    final viewInsets = MediaQuery.of(context).viewInsets;
    final availableHeight =
        (MediaQuery.of(context).size.height - viewInsets.bottom - 32)
            .clamp(240.0, double.infinity)
            .toDouble();

    return Dialog(
      backgroundColor: WorkoutColors.panel,
      insetPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: 420, maxHeight: availableHeight),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '添加饮食记录',
                style: TextStyle(color: WorkoutColors.text, fontSize: 17),
              ),
              const SizedBox(height: 14),
              _field(
                _nameController,
                '食物名称',
                hint: '例如：鸡胸肉、米饭、牛奶',
                key: const ValueKey('food-name-input'),
                onChanged: (_) => setState(() => _error = null),
              ),
              const SizedBox(height: 9),
              const Text(
                '食物分类',
                style: TextStyle(color: WorkoutColors.muted, fontSize: 11),
              ),
              const SizedBox(height: 6),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    for (final category in FoodCategory.values) ...[
                      ChoiceChip(
                        label: Text(category.label),
                        selected: category == _selectedCategory,
                        onSelected: (_) => _selectCategory(category),
                        selectedColor: WorkoutColors.greenDark,
                        backgroundColor: WorkoutColors.background,
                        side: BorderSide(
                          color:
                              category == _selectedCategory
                                  ? WorkoutColors.green
                                  : WorkoutColors.border,
                        ),
                        labelStyle: TextStyle(
                          color:
                              category == _selectedCategory
                                  ? WorkoutColors.text
                                  : WorkoutColors.muted,
                          fontSize: 11,
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 3),
                        showCheckmark: false,
                      ),
                      if (category != FoodCategory.values.last)
                        const SizedBox(width: 6),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${_selectedCategory.label}食物',
                style: const TextStyle(
                  color: WorkoutColors.text,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final suggestion in _categoryFoods)
                    ActionChip(
                      label: Text(suggestion.name),
                      onPressed: () => _selectFood(suggestion),
                      labelStyle: const TextStyle(
                        color: WorkoutColors.muted,
                        fontSize: 11,
                      ),
                      backgroundColor: WorkoutColors.background,
                      side: const BorderSide(color: WorkoutColors.border),
                      padding: const EdgeInsets.symmetric(horizontal: 3),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _numberField(
                      _gramsController,
                      '食物重量（g）',
                      key: const ValueKey('food-grams-input'),
                      onChanged: (_) => setState(() => _error = null),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: DropdownButtonFormField<MealType>(
                      value: _meal,
                      dropdownColor: WorkoutColors.panelSoft,
                      style: const TextStyle(
                        color: WorkoutColors.text,
                        fontSize: 13,
                      ),
                      decoration: _decoration('餐次'),
                      items: [
                        for (final meal in MealType.values)
                          DropdownMenuItem(
                            value: meal,
                            child: Text(meal.label),
                          ),
                      ],
                      onChanged: (value) {
                        if (value != null) setState(() => _meal = value);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (food != null && values != null)
                _preview(food, values)
              else
                const Text(
                  '选择常见食物后，会根据克数自动计算大概营养值。',
                  style: TextStyle(color: WorkoutColors.muted, fontSize: 11),
                ),
              if (_error != null) ...[
                const SizedBox(height: 8),
                Text(
                  _error!,
                  style: const TextStyle(
                    color: Color(0xFFFF8294),
                    fontSize: 11,
                  ),
                ),
              ],
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      '取消',
                      style: TextStyle(color: WorkoutColors.muted),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: _save,
                    style: FilledButton.styleFrom(
                      backgroundColor: WorkoutColors.green,
                      foregroundColor: WorkoutColors.background,
                    ),
                    child: const Text('保存记录'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _preview(FoodNutrition food, NutritionValues values) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 10),
      decoration: BoxDecoration(
        color: WorkoutColors.background,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: WorkoutColors.greenDark),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${food.name} · 按 ${_grams!.toStringAsFixed(0)}g 估算',
            style: const TextStyle(
              color: WorkoutColors.green,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${_format(values.calories)} kcal  ·  '
            '蛋白质 ${_format(values.protein)}g  ·  '
            '碳水 ${_format(values.carbs)}g  ·  '
            '脂肪 ${_format(values.fat)}g',
            style: const TextStyle(color: WorkoutColors.text, fontSize: 11),
          ),
          const SizedBox(height: 5),
          const Text(
            '仅为常见食材估算，品牌和烹饪方式会造成差异。',
            style: TextStyle(color: WorkoutColors.muted, fontSize: 10),
          ),
        ],
      ),
    );
  }

  Widget _field(
    TextEditingController controller,
    String label, {
    String? hint,
    Key? key,
    ValueChanged<String>? onChanged,
  }) {
    return TextField(
      key: key,
      controller: controller,
      onChanged: onChanged,
      style: const TextStyle(color: WorkoutColors.text, fontSize: 13),
      decoration: _decoration(label, hint: hint),
    );
  }

  Widget _numberField(
    TextEditingController controller,
    String label, {
    Key? key,
    ValueChanged<String>? onChanged,
  }) {
    return TextField(
      key: key,
      controller: controller,
      onChanged: onChanged,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      style: const TextStyle(color: WorkoutColors.text, fontSize: 13),
      decoration: _decoration(label),
    );
  }

  InputDecoration _decoration(String label, {String? hint}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      labelStyle: const TextStyle(color: WorkoutColors.muted, fontSize: 11),
      hintStyle: const TextStyle(color: WorkoutColors.muted, fontSize: 11),
      filled: true,
      fillColor: WorkoutColors.background,
      contentPadding: const EdgeInsets.symmetric(horizontal: 11, vertical: 10),
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

  String _format(double value) =>
      value == value.roundToDouble()
          ? value.toInt().toString()
          : value.toStringAsFixed(1);
}
