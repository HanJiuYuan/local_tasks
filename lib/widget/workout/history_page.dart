import 'package:flutter/material.dart';
import 'workout_models.dart';
import 'workout_theme.dart';

class HistoryPage extends StatelessWidget {
  const HistoryPage({super.key, required this.records, required this.onBack});

  final List<WorkoutHistoryRecord> records;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final days = _groupedDays;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '历史训练数据',
                        style: TextStyle(
                          color: WorkoutColors.text,
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 7),
                      Text(
                        records.isEmpty
                            ? '完成第一次训练后，数据会保存在这里。'
                            : '同一天的多次训练会自动合并显示。',
                        style: const TextStyle(
                          color: WorkoutColors.muted,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: '返回今日数据',
                  onPressed: onBack,
                  icon: const Icon(
                    Icons.close_rounded,
                    color: WorkoutColors.muted,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 22),
            if (records.isEmpty)
              _emptyState()
            else ...[
              _totalCard(),
              const SizedBox(height: 14),
              for (final day in days) ...[
                _recordCard(context, day),
                const SizedBox(height: 12),
              ],
            ],
          ],
        ),
      ),
    );
  }

  List<_HistoryDaySummary> get _groupedDays {
    final grouped = <String, List<WorkoutHistoryRecord>>{};
    for (final record in records) {
      final key = '${record.date.year}-${record.date.month}-${record.date.day}';
      grouped.putIfAbsent(key, () => []).add(record);
    }
    return grouped.values.map(_HistoryDaySummary.from).toList();
  }

  Widget _emptyState() {
    return workoutPanel(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 70),
      child: Column(
        children: [
          const Icon(
            Icons.history_rounded,
            color: WorkoutColors.muted,
            size: 48,
          ),
          const SizedBox(height: 16),
          const Text(
            '暂无历史记录',
            style: TextStyle(
              color: WorkoutColors.text,
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '完成今天的第一次训练后，训练时长、组数和容量会显示在这里。',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: WorkoutColors.muted,
              fontSize: 12,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _totalCard() {
    final totalSets = records.fold(
      0,
      (total, record) => total + record.completedSets,
    );
    final totalVolume = records.fold<double>(
      0,
      (total, record) => total + record.volume,
    );
    return workoutPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          workoutSectionTitle(Icons.insights_rounded, '累计训练'),
          const SizedBox(height: 14),
          workoutMetricStrip([
            workoutMetric(label: '训练次数', value: '${records.length} 次'),
            workoutMetric(
              label: '完成组数',
              value: '$totalSets 组',
              color: WorkoutColors.green,
            ),
            workoutMetric(
              label: '总容量',
              value: '${totalVolume.toStringAsFixed(0)} kg',
              color: WorkoutColors.blue,
            ),
          ]),
        ],
      ),
    );
  }

  Widget _recordCard(BuildContext context, _HistoryDaySummary day) {
    final record = day.record;
    final date =
        '${record.date.year}/${record.date.month.toString().padLeft(2, '0')}/${record.date.day.toString().padLeft(2, '0')}';
    return workoutPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.event_rounded,
                color: WorkoutColors.green,
                size: 17,
              ),
              const SizedBox(width: 8),
              Text(
                date,
                style: const TextStyle(
                  color: WorkoutColors.text,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Spacer(),
              if (record.isPartial) ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: WorkoutColors.amber.withValues(alpha: .14),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    '部分训练',
                    style: TextStyle(
                      color: WorkoutColors.amber,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              if (day.sessions > 1) ...[
                Text(
                  '${day.sessions} 次训练',
                  style: const TextStyle(
                    color: WorkoutColors.muted,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Text(
                workoutFormatDuration(record.duration),
                style: const TextStyle(
                  color: WorkoutColors.muted,
                  fontSize: 11,
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          workoutMetricStrip([
            workoutMetric(label: '动作', value: '${record.exerciseCount} 个'),
            workoutMetric(
              label: '组数',
              value: '${record.completedSets} 组',
              color: WorkoutColors.green,
            ),
            workoutMetric(
              label: '容量',
              value: '${record.volume.toStringAsFixed(0)} kg',
              color: WorkoutColors.blue,
            ),
          ]),
          if (record.exercises.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Divider(color: WorkoutColors.border, height: 1),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _showDetails(context, record),
                icon: const Icon(Icons.open_in_new_rounded, size: 16),
                label: const Text('查看详细'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: WorkoutColors.text,
                  side: const BorderSide(color: WorkoutColors.border),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(11),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ] else ...[
            const SizedBox(height: 12),
            const Text(
              '这条记录创建于详情功能上线前，暂无动作明细。',
              style: TextStyle(color: WorkoutColors.muted, fontSize: 11),
            ),
          ],
        ],
      ),
    );
  }

  void _showDetails(BuildContext context, WorkoutHistoryRecord record) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _HistoryDetailSheet(record: record),
    );
  }
}

class _HistoryDaySummary {
  const _HistoryDaySummary({
    required this.date,
    required this.sessions,
    required this.exerciseCount,
    required this.completedSets,
    required this.volume,
    required this.duration,
    required this.exercises,
    required this.isPartial,
  });

  factory _HistoryDaySummary.from(List<WorkoutHistoryRecord> records) {
    final details = [for (final record in records) ...record.exercises];
    final actionNames = <String>{};
    for (final exercise in details) {
      actionNames.add(exercise.name);
    }
    final exerciseCount =
        details.isEmpty
            ? records.fold(0, (total, record) => total + record.exerciseCount)
            : actionNames.length;
    return _HistoryDaySummary(
      date: records.first.date,
      sessions: records.length,
      exerciseCount: exerciseCount,
      completedSets: records.fold(
        0,
        (total, record) => total + record.completedSets,
      ),
      volume: records.fold<double>(0, (total, record) => total + record.volume),
      duration: records.fold(
        Duration.zero,
        (total, record) => total + record.duration,
      ),
      exercises: details,
      isPartial: records.any((record) => record.isPartial),
    );
  }

  final DateTime date;
  final int sessions;
  final int exerciseCount;
  final int completedSets;
  final double volume;
  final Duration duration;
  final List<WorkoutHistoryExercise> exercises;
  final bool isPartial;

  WorkoutHistoryRecord get record => WorkoutHistoryRecord(
    date: date,
    exerciseCount: exerciseCount,
    completedSets: completedSets,
    volume: volume,
    duration: duration,
    exercises: exercises,
    isPartial: isPartial,
  );
}

class _HistoryDetailSheet extends StatelessWidget {
  const _HistoryDetailSheet({required this.record});

  final WorkoutHistoryRecord record;

  @override
  Widget build(BuildContext context) {
    final date =
        '${record.date.year}/${record.date.month.toString().padLeft(2, '0')}/${record.date.day.toString().padLeft(2, '0')}';
    return DraggableScrollableSheet(
      initialChildSize: .78,
      minChildSize: .52,
      maxChildSize: .94,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: WorkoutColors.panel,
            borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              children: [
                const SizedBox(height: 10),
                Container(
                  width: 38,
                  height: 4,
                  decoration: BoxDecoration(
                    color: WorkoutColors.border,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 12, 0),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Text(
                          '训练详细数据',
                          style: TextStyle(
                            color: WorkoutColors.text,
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: '关闭详情',
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(
                          Icons.close_rounded,
                          color: WorkoutColors.muted,
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 2, 20, 14),
                  child: Row(
                    children: [
                      Text(
                        date,
                        style: const TextStyle(
                          color: WorkoutColors.muted,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        workoutFormatDuration(record.duration),
                        style: const TextStyle(
                          color: WorkoutColors.muted,
                          fontSize: 12,
                        ),
                      ),
                      if (record.isPartial) ...[
                        const SizedBox(width: 10),
                        const Text(
                          '部分训练',
                          style: TextStyle(
                            color: WorkoutColors.amber,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const Divider(color: WorkoutColors.border, height: 1),
                Expanded(
                  child: ListView.separated(
                    controller: scrollController,
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 26),
                    itemCount: record.exercises.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder:
                        (_, index) => _exerciseDetail(record.exercises[index]),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _exerciseDetail(WorkoutHistoryExercise exercise) {
    final averageRir = exercise.averageRir;
    final rirText =
        averageRir == null
            ? '未记录 RIR'
            : '平均 RIR ${averageRir.toStringAsFixed(1)}';
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.fromLTRB(11, 10, 11, 10),
      decoration: BoxDecoration(
        color: WorkoutColors.background,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: WorkoutColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  exercise.name,
                  style: const TextStyle(
                    color: WorkoutColors.text,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Text(
                exercise.weightLabel,
                style: const TextStyle(
                  color: WorkoutColors.green,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '${exercise.completedSets}/${exercise.sets} 组 · 每组 ${exercise.reps} 次 · 休息 ${exercise.restSeconds} 秒',
            style: const TextStyle(color: WorkoutColors.muted, fontSize: 11),
          ),
          const SizedBox(height: 4),
          Text(
            '$rirText${exercise.rirFeedback.isEmpty ? '' : ' · ${exercise.rirFeedback.join(' / ')}'}',
            style: const TextStyle(color: WorkoutColors.muted, fontSize: 11),
          ),
        ],
      ),
    );
  }
}
