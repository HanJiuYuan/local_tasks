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
  var _isCustom = false;
  var _customUsesConsumedValues = false;
  final _nameController = TextEditingController();
  final _gramsController = TextEditingController(text: '100');
  final _caloriesController = TextEditingController();
  final _proteinController = TextEditingController();
  final _carbsController = TextEditingController();
  final _fatController = TextEditingController();
  final _fiberController = TextEditingController(text: '0');
  final _sugarController = TextEditingController(text: '0');
  final _sodiumController = TextEditingController(text: '0');
  String? _error;

  FoodNutrition? get _food => _isCustom ? _customFood : _commonFood;

  FoodNutrition? get _commonFood => FoodDatabase.find(_nameController.text);

  FoodNutrition? get _customFood {
    final name = _nameController.text.trim();
    final calories = _parse(_caloriesController);
    if (name.isEmpty || calories == null || calories < 0) return null;
    return FoodNutrition(
      name: name,
      aliases: const [],
      caloriesPer100g: calories,
      proteinPer100g: _optionalValue(_proteinController),
      carbsPer100g: _optionalValue(_carbsController),
      fatPer100g: _optionalValue(_fatController),
      fiberPer100g: _optionalValue(_fiberController),
      sugarPer100g: _optionalValue(_sugarController),
      sodiumPer100g: _optionalValue(_sodiumController),
    );
  }

  double? get _grams => double.tryParse(_gramsController.text.trim());

  NutritionValues? get _calculated {
    if (_isCustom && _customUsesConsumedValues) {
      return _customConsumedValues;
    }
    final food = _food;
    final grams = _grams;
    if (food == null || grams == null || grams <= 0) return null;
    return food.calculate(grams);
  }

  NutritionValues? get _customConsumedValues {
    final calories = _parse(_caloriesController);
    if (calories == null || calories < 0) return null;
    return NutritionValues(
      calories: calories,
      protein: _optionalValue(_proteinController),
      carbs: _optionalValue(_carbsController),
      fat: _optionalValue(_fatController),
      fiber: _optionalValue(_fiberController),
      sugar: _optionalValue(_sugarController),
      sodium: _optionalValue(_sodiumController),
    );
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
    _caloriesController.dispose();
    _proteinController.dispose();
    _carbsController.dispose();
    _fatController.dispose();
    _fiberController.dispose();
    _sugarController.dispose();
    _sodiumController.dispose();
    super.dispose();
  }

  void _selectFood(FoodNutrition food) {
    _nameController.text = food.name;
    _nameController.selection = TextSelection.collapsed(
      offset: _nameController.text.length,
    );
    setState(() {
      _isCustom = false;
      _selectedCategory = FoodDatabase.categoryFor(food);
      _error = null;
    });
  }

  void _enableCustom() {
    setState(() {
      _isCustom = true;
      _error = null;
    });
  }

  void _setCustomInputMode(bool usesConsumedValues) {
    setState(() {
      _customUsesConsumedValues = usesConsumedValues;
      _error = null;
    });
  }

  void _useCommonFoods() {
    setState(() {
      _isCustom = false;
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
    final weightIsValid =
        _isCustom && _customUsesConsumedValues
            ? grams == null || grams >= 0
            : grams != null && grams > 0;
    if (food == null || !weightIsValid || values == null) {
      setState(
        () => _error = _isCustom ? '请填写食物名称、热量和有效的重量' : '请输入克数，并选择或输入可识别的常见食物',
      );
      return;
    }

    Navigator.pop(
      context,
      FoodEntry(
        name: food.name,
        meal: _meal,
        grams: grams ?? 0,
        calories: values.calories,
        protein: values.protein,
        carbs: values.carbs,
        fat: values.fat,
        fiber: values.fiber,
        sugar: values.sugar,
        sodium: values.sodium,
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
              const SizedBox(height: 6),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  key: const ValueKey('custom-food-toggle'),
                  onPressed: _isCustom ? _useCommonFoods : _enableCustom,
                  style: TextButton.styleFrom(
                    foregroundColor: WorkoutColors.green,
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(0, 32),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  icon: Icon(
                    _isCustom
                        ? Icons.list_alt_rounded
                        : Icons.edit_note_rounded,
                    size: 17,
                  ),
                  label: Text(
                    _isCustom ? '返回常见食物' : '没有这个食物？自定义营养值',
                    style: const TextStyle(fontSize: 11),
                  ),
                ),
              ),
              if (_isCustom)
                _customNutritionFields()
              else ...[
                const SizedBox(height: 3),
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
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 116),
                  child: SingleChildScrollView(
                    child: Wrap(
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
                  ),
                ),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _numberField(
                      _gramsController,
                      _isCustom && _customUsesConsumedValues
                          ? '本次重量（g，可选）'
                          : '可食重量（g）',
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
              else if (_isCustom)
                Text(
                  _customUsesConsumedValues
                      ? '请填写这次实际摄入的热量；其他营养项不清楚时可以留空。'
                      : '请填写每 100g 的热量；其他营养项不清楚时可以留空。',
                  style: TextStyle(color: WorkoutColors.muted, fontSize: 11),
                )
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

  Widget _customNutritionFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '营养值填写方式',
          style: TextStyle(color: WorkoutColors.muted, fontSize: 11),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          children: [
            ChoiceChip(
              label: const Text('每 100g'),
              selected: !_customUsesConsumedValues,
              onSelected: (_) => _setCustomInputMode(false),
              selectedColor: WorkoutColors.greenDark,
              backgroundColor: WorkoutColors.background,
              side: BorderSide(
                color:
                    !_customUsesConsumedValues
                        ? WorkoutColors.green
                        : WorkoutColors.border,
              ),
              labelStyle: TextStyle(
                color:
                    !_customUsesConsumedValues
                        ? WorkoutColors.text
                        : WorkoutColors.muted,
                fontSize: 11,
              ),
              showCheckmark: false,
            ),
            ChoiceChip(
              key: const ValueKey('custom-total-input-choice'),
              label: const Text('本次摄入总量'),
              selected: _customUsesConsumedValues,
              onSelected: (_) => _setCustomInputMode(true),
              selectedColor: WorkoutColors.greenDark,
              backgroundColor: WorkoutColors.background,
              side: BorderSide(
                color:
                    _customUsesConsumedValues
                        ? WorkoutColors.green
                        : WorkoutColors.border,
              ),
              labelStyle: TextStyle(
                color:
                    _customUsesConsumedValues
                        ? WorkoutColors.text
                        : WorkoutColors.muted,
                fontSize: 11,
              ),
              showCheckmark: false,
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          _customUsesConsumedValues
              ? '直接填写这一次吃下去的总营养值，不会再按克数换算。'
              : '按食品包装或食谱填写每 100g 营养值。',
          style: const TextStyle(color: WorkoutColors.muted, fontSize: 11),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _numberField(
                _caloriesController,
                _customLabel('热量/100g（kcal）*', '本次热量（kcal）*'),
                key: const ValueKey('custom-food-calories-input'),
                onChanged: (_) => setState(() => _error = null),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _numberField(
                _proteinController,
                _customLabel('蛋白质/100g（g）', '本次蛋白质（g）'),
                key: const ValueKey('custom-food-protein-input'),
                onChanged: (_) => setState(() => _error = null),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _numberField(
                _carbsController,
                _customLabel('碳水/100g（g）', '本次碳水（g）'),
                key: const ValueKey('custom-food-carbs-input'),
                onChanged: (_) => setState(() => _error = null),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _numberField(
                _fatController,
                _customLabel('脂肪/100g（g）', '本次脂肪（g）'),
                key: const ValueKey('custom-food-fat-input'),
                onChanged: (_) => setState(() => _error = null),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _numberField(
                _fiberController,
                _customLabel('膳食纤维/100g（g）', '本次膳食纤维（g）'),
                key: const ValueKey('custom-food-fiber-input'),
                onChanged: (_) => setState(() => _error = null),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _numberField(
                _sugarController,
                _customLabel('糖分/100g（g）', '本次糖分（g）'),
                key: const ValueKey('custom-food-sugar-input'),
                onChanged: (_) => setState(() => _error = null),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        _numberField(
          _sodiumController,
          _customLabel('钠/100g（mg）', '本次钠（mg）'),
          key: const ValueKey('custom-food-sodium-input'),
          onChanged: (_) => setState(() => _error = null),
        ),
      ],
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
            _customUsesConsumedValues
                ? '${food.name} · 本次实际摄入'
                : '${food.name} · 按 ${_grams!.toStringAsFixed(0)}g 估算',
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
          Text(
            _customUsesConsumedValues
                ? '按本次填写的总量记录；重量仅用于辅助备注。'
                : '按去皮、去核、去壳、去骨后的可食部分估算；品牌和烹饪方式会造成差异。',
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

  double? _parse(TextEditingController controller) =>
      double.tryParse(controller.text.trim());

  String _customLabel(String per100g, String consumed) =>
      _customUsesConsumedValues ? consumed : per100g;

  double _optionalValue(TextEditingController controller) {
    final value = _parse(controller);
    return value != null && value >= 0 ? value : 0;
  }
}
