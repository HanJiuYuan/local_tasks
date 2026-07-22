import 'package:flutter/material.dart';
import '../workout/workout_theme.dart';
import 'nutrition_models.dart';
import 'nutrition_store.dart';

class NutritionHistoryPage extends StatefulWidget {
  const NutritionHistoryPage({super.key, required this.store});

  final NutritionStore store;

  @override
  State<NutritionHistoryPage> createState() => _NutritionHistoryPageState();
}

class _NutritionHistoryPageState extends State<NutritionHistoryPage> {
  late Future<List<FoodEntry>> _historyFuture;

  @override
  void initState() {
    super.initState();
    _historyFuture = widget.store.loadHistory();
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
              constraints: const BoxConstraints(maxWidth: 760),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _header(),
                  const SizedBox(height: 20),
                  FutureBuilder<List<FoodEntry>>(
                    future: _historyFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState != ConnectionState.done) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(48),
                            child: CircularProgressIndicator(),
                          ),
                        );
                      }
                      if (snapshot.hasError) return _errorState();
                      return _historyList(snapshot.data ?? const []);
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _header() {
    return Row(
      children: [
        IconButton(
          tooltip: '返回今日记录',
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(
            Icons.arrow_back_rounded,
            color: WorkoutColors.muted,
          ),
        ),
        const SizedBox(width: 4),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '饮食历史',
                style: TextStyle(
                  color: WorkoutColors.text,
                  fontSize: 21,
                  fontWeight: FontWeight.w800,
                ),
              ),
              SizedBox(height: 3),
              Text(
                '今天的数据单独记录，昨天及更早的记录会保存在这里。',
                style: TextStyle(color: WorkoutColors.muted, fontSize: 12),
              ),
            ],
          ),
        ),
        const Icon(Icons.history_rounded, color: WorkoutColors.green, size: 25),
      ],
    );
  }

  Widget _historyList(List<FoodEntry> entries) {
    if (entries.isEmpty) return _emptyState();

    final days = _groupByDay(entries);
    return Column(
      children: [
        for (final day in days) ...[
          _dayCard(day),
          if (day != days.last) const SizedBox(height: 12),
        ],
      ],
    );
  }

  List<_NutritionDay> _groupByDay(List<FoodEntry> entries) {
    final grouped = <DateTime, List<FoodEntry>>{};
    for (final entry in entries) {
      final day = DateTime(
        entry.createdAt.year,
        entry.createdAt.month,
        entry.createdAt.day,
      );
      grouped.putIfAbsent(day, () => []).add(entry);
    }
    final days = [
      for (final item in grouped.entries)
        _NutritionDay(date: item.key, entries: item.value),
    ];
    days.sort((a, b) => b.date.compareTo(a.date));
    return days;
  }

  Widget _dayCard(_NutritionDay day) {
    final totals = NutritionTotals.fromEntries(day.entries);
    return workoutPanel(
      padding: const EdgeInsets.fromLTRB(16, 14, 12, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.event_rounded,
                color: WorkoutColors.green,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                _formatDate(day.date),
                style: const TextStyle(
                  color: WorkoutColors.text,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Spacer(),
              Text(
                '${day.entries.length} 条记录',
                style: const TextStyle(
                  color: WorkoutColors.muted,
                  fontSize: 11,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
            decoration: BoxDecoration(
              color: WorkoutColors.background,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: WorkoutColors.border),
            ),
            child: Text(
              '${_formatNumber(totals.calories)} kcal  ·  '
              '蛋白质 ${_formatNumber(totals.protein)}g  ·  '
              '碳水 ${_formatNumber(totals.carbs)}g  ·  '
              '脂肪 ${_formatNumber(totals.fat)}g',
              style: const TextStyle(
                color: WorkoutColors.text,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          for (final entry in day.entries) _entryTile(entry),
        ],
      ),
    );
  }

  Widget _entryTile(FoodEntry entry) {
    final amountLabel =
        entry.grams > 0 ? '${_formatNumber(entry.grams)}g' : '本次摄入';
    return Padding(
      padding: const EdgeInsets.only(top: 9, left: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '${entry.meal.label} · ${entry.name} · $amountLabel',
              style: const TextStyle(color: WorkoutColors.muted, fontSize: 11),
            ),
          ),
          Text(
            '${_formatNumber(entry.calories)} kcal',
            style: const TextStyle(
              color: WorkoutColors.green,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyState() {
    return workoutPanel(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 60),
      child: const Column(
        children: [
          Icon(Icons.history_rounded, color: WorkoutColors.muted, size: 48),
          SizedBox(height: 16),
          Text(
            '暂无历史饮食数据',
            style: TextStyle(
              color: WorkoutColors.text,
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: 8),
          Text(
            '昨天及更早的饮食记录会显示在这里。',
            textAlign: TextAlign.center,
            style: TextStyle(color: WorkoutColors.muted, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _errorState() {
    return workoutPanel(
      padding: const EdgeInsets.all(24),
      child: const Text(
        '历史记录加载失败，请稍后重试。',
        style: TextStyle(color: WorkoutColors.muted, fontSize: 12),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final today = DateTime.now();
    final yesterday = DateTime(
      today.year,
      today.month,
      today.day,
    ).subtract(const Duration(days: 1));
    if (date == yesterday) return '昨天';
    return '${date.year}年${date.month}月${date.day}日';
  }

  String _formatNumber(double value) =>
      value == value.roundToDouble()
          ? value.toInt().toString()
          : value.toStringAsFixed(1);
}

class _NutritionDay {
  const _NutritionDay({required this.date, required this.entries});

  final DateTime date;
  final List<FoodEntry> entries;
}
