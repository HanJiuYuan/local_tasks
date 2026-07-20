import 'package:flutter/material.dart';
import 'workout_models.dart';
import 'workout_theme.dart';

class HistoryPage extends StatelessWidget {
  const HistoryPage({super.key, required this.records, required this.onBack});

  final List<WorkoutHistoryRecord> records;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
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
                        records.isEmpty ? '完成第一次训练后，数据会保存在这里。' : '每一次训练都值得被记录。',
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
              for (final record in records) ...[
                _recordCard(record),
                const SizedBox(height: 12),
              ],
            ],
          ],
        ),
      ),
    );
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

  Widget _recordCard(WorkoutHistoryRecord record) {
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
        ],
      ),
    );
  }
}
