import 'package:flutter/material.dart';
import '../workout/workout_theme.dart';
import 'add_food_dialog.dart';
import 'nutrition_history_page.dart';
import 'nutrition_models.dart';
import 'nutrition_store.dart';

class NutritionPage extends StatefulWidget {
  const NutritionPage({super.key});

  @override
  State<NutritionPage> createState() => _NutritionPageState();
}

class _NutritionPageState extends State<NutritionPage>
    with WidgetsBindingObserver {
  final _store = NutritionStore();
  var _today = _nutritionDayStart(DateTime.now());
  var _entries = <FoodEntry>[];
  var _showMoreNutrition = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadEntries();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _loadEntries();
  }

  Future<void> _loadEntries() async {
    final today = _nutritionDayStart(DateTime.now());
    final entries = await _store.loadForDate(today);
    if (!mounted) return;
    setState(() {
      _today = today;
      _entries = entries;
    });
  }

  NutritionTotals get _totals => NutritionTotals.fromEntries(_entries);

  Future<void> _addFood({MealType meal = MealType.breakfast}) async {
    final entry = await showDialog<FoodEntry>(
      context: context,
      builder: (_) => AddFoodDialog(initialMeal: meal),
    );
    if (!mounted || entry == null) return;
    await _store.insert(entry);
    if (!mounted) return;
    await _loadEntries();
  }

  void _openHistory() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => NutritionHistoryPage(store: _store)),
    );
  }

  Future<void> _removeFood(FoodEntry entry) async {
    await _store.delete(entry.id);
    if (!mounted) return;
    setState(() => _entries = _entries.where((item) => item != entry).toList());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WorkoutColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1120),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _header(),
                  const SizedBox(height: 20),
                  _summaryPanel(),
                  const SizedBox(height: 16),
                  _mealList(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _header() {
    final now = _today;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: WorkoutColors.green,
            borderRadius: BorderRadius.circular(14),
            boxShadow: const [
              BoxShadow(color: Color(0x3500C98B), blurRadius: 15),
            ],
          ),
          child: const Icon(
            Icons.restaurant_rounded,
            color: WorkoutColors.background,
            size: 25,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '饮食记录',
                style: TextStyle(
                  color: WorkoutColors.text,
                  fontSize: 21,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                '${now.month}月${now.day}日 · 记录今天吃了什么',
                style: const TextStyle(
                  color: WorkoutColors.muted,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          tooltip: '查看历史记录',
          onPressed: _openHistory,
          icon: const Icon(Icons.history_rounded, color: WorkoutColors.muted),
        ),
        const SizedBox(width: 2),
        FilledButton.icon(
          onPressed: _addFood,
          style: FilledButton.styleFrom(
            backgroundColor: WorkoutColors.green,
            foregroundColor: WorkoutColors.background,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(11),
            ),
          ),
          icon: const Icon(Icons.add_rounded, size: 18),
          label: const Text(
            '添加食物',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
          ),
        ),
      ],
    );
  }

  Widget _summaryPanel() {
    final totals = _totals;
    return workoutPanel(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  '今日摄入',
                  style: TextStyle(
                    color: WorkoutColors.text,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Text(
                '${_entries.length} 条记录',
                style: const TextStyle(
                  color: WorkoutColors.muted,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          const Text(
            '按已记录的食物自动汇总，不记录就不会计入今日数据。',
            style: TextStyle(color: WorkoutColors.muted, fontSize: 12),
          ),
          const SizedBox(height: 18),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _formatNumber(totals.calories),
                style: const TextStyle(
                  color: WorkoutColors.text,
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(left: 6, bottom: 5),
                child: Text(
                  'kcal',
                  style: TextStyle(color: WorkoutColors.muted, fontSize: 13),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final gap = 8.0;
              final width = (constraints.maxWidth - gap * 2) / 3;
              return Wrap(
                spacing: gap,
                runSpacing: gap,
                children: [
                  _macroCard(
                    '蛋白质',
                    totals.protein,
                    'g',
                    WorkoutColors.green,
                    width,
                  ),
                  _macroCard(
                    '碳水',
                    totals.carbs,
                    'g',
                    WorkoutColors.blue,
                    width,
                  ),
                  _macroCard('脂肪', totals.fat, 'g', WorkoutColors.amber, width),
                ],
              );
            },
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              key: const ValueKey('more-nutrition-button'),
              onPressed: () {
                setState(() => _showMoreNutrition = !_showMoreNutrition);
              },
              style: TextButton.styleFrom(
                foregroundColor: WorkoutColors.muted,
                padding: EdgeInsets.zero,
                minimumSize: const Size(0, 32),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              icon: Icon(
                _showMoreNutrition
                    ? Icons.keyboard_arrow_up_rounded
                    : Icons.keyboard_arrow_down_rounded,
                size: 18,
              ),
              label: Text(
                _showMoreNutrition ? '收起更多营养数据' : '更多营养数据',
                style: const TextStyle(fontSize: 12),
              ),
            ),
          ),
          if (_showMoreNutrition) ...[
            const SizedBox(height: 4),
            _extraNutritionCards(totals),
          ],
        ],
      ),
    );
  }

  Widget _extraNutritionCards(NutritionTotals totals) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = 8.0;
        final width = (constraints.maxWidth - gap * 2) / 3;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            _macroCard(
              '膳食纤维',
              totals.fiber,
              'g',
              const Color(0xFF8A72E8),
              width,
            ),
            _macroCard('糖分', totals.sugar, 'g', const Color(0xFFF078A5), width),
            _macroCard(
              '钠',
              totals.sodium,
              'mg',
              const Color(0xFF5A8DEE),
              width,
            ),
          ],
        );
      },
    );
  }

  Widget _macroCard(
    String label,
    double value,
    String unit,
    Color color,
    double width,
  ) {
    return SizedBox(
      width: width,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 10),
        decoration: BoxDecoration(
          color: WorkoutColors.background,
          borderRadius: BorderRadius.circular(11),
          border: Border.all(color: WorkoutColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(color: WorkoutColors.muted, fontSize: 11),
            ),
            const SizedBox(height: 5),
            Text(
              '${_formatNumber(value)} $unit',
              style: TextStyle(
                color: color,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _mealList() {
    return Column(
      children: [
        for (final meal in MealType.values) ...[
          _mealSection(meal),
          if (meal != MealType.values.last) const SizedBox(height: 12),
        ],
      ],
    );
  }

  Widget _mealSection(MealType meal) {
    final entries = _entries.where((entry) => entry.meal == meal).toList();
    return workoutPanel(
      padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
      child: Column(
        children: [
          Row(
            children: [
              Icon(_mealIcon(meal), color: WorkoutColors.green, size: 19),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      meal.label,
                      style: const TextStyle(
                        color: WorkoutColors.text,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      meal.subtitle,
                      style: const TextStyle(
                        color: WorkoutColors.muted,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: '添加${meal.label}',
                onPressed: () => _addFood(meal: meal),
                icon: const Icon(
                  Icons.add_circle_outline_rounded,
                  color: WorkoutColors.green,
                  size: 21,
                ),
              ),
            ],
          ),
          if (entries.isEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(27, 10, 8, 7),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '还没有记录，点击右侧加号添加${meal.label}。',
                  style: const TextStyle(
                    color: WorkoutColors.muted,
                    fontSize: 12,
                  ),
                ),
              ),
            )
          else
            for (final entry in entries) _foodTile(entry),
        ],
      ),
    );
  }

  Widget _foodTile(FoodEntry entry) {
    final amountLabel =
        entry.grams > 0 ? '${_formatNumber(entry.grams)}g' : '本次摄入';
    return Container(
      margin: const EdgeInsets.only(top: 7),
      padding: const EdgeInsets.fromLTRB(10, 9, 5, 9),
      decoration: BoxDecoration(
        color: WorkoutColors.background,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: WorkoutColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.name,
                  style: const TextStyle(
                    color: WorkoutColors.text,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$amountLabel  ·  '
                  '蛋白质 ${_formatNumber(entry.protein)}g  ·  '
                  '碳水 ${_formatNumber(entry.carbs)}g  ·  '
                  '脂肪 ${_formatNumber(entry.fat)}g',
                  style: const TextStyle(
                    color: WorkoutColors.muted,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${_formatNumber(entry.calories)} kcal',
            style: const TextStyle(
              color: WorkoutColors.green,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
          IconButton(
            tooltip: '删除${entry.name}',
            onPressed: () => _removeFood(entry),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints.tightFor(width: 30, height: 32),
            icon: const Icon(
              Icons.delete_outline_rounded,
              color: Color(0xFFB66F7C),
              size: 18,
            ),
          ),
        ],
      ),
    );
  }

  IconData _mealIcon(MealType meal) => switch (meal) {
    MealType.breakfast => Icons.wb_sunny_outlined,
    MealType.lunch => Icons.lunch_dining_outlined,
    MealType.dinner => Icons.dinner_dining_outlined,
    MealType.snack => Icons.cookie_outlined,
  };

  String _formatNumber(double value) =>
      value == value.roundToDouble()
          ? value.toInt().toString()
          : value.toStringAsFixed(1);
}

DateTime _nutritionDayStart(DateTime date) =>
    DateTime(date.year, date.month, date.day);
