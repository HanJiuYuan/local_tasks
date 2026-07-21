import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:local_tasks/widget/workout/workout_page.dart';
import 'package:local_tasks/widget/workout/workout_models.dart';
import 'package:local_tasks/widget/workout/workout_store.dart';

Future<void> _seedReadyWorkout() {
  return WorkoutStore().saveState(
    profile: const TrainingProfile(
      bodyWeightKg: 77,
      heightCm: 173,
      bodyFatPercent: 26.3,
      trainingDays: 30,
      experience: TrainingExperience.novice,
    ),
    exercises: [
      WorkoutExercise(
        name: '杠铃卧推',
        weight: 25,
        sets: 4,
        reps: 12,
        bodyPart: '胸',
      ),
      WorkoutExercise(
        name: '杠铃深蹲',
        weight: 40,
        sets: 4,
        reps: 10,
        bodyPart: '腿',
      ),
      WorkoutExercise(
        name: '哑铃弯举',
        weight: 7.5,
        sets: 3,
        reps: 12,
        bodyPart: '手臂',
      ),
    ],
    history: const [],
  );
}

void main() {
  testWidgets('adds a custom action with the new action dialog', (
    tester,
  ) async {
    await WorkoutStore().clear();
    await tester.pumpWidget(const MaterialApp(home: WorkoutAssistantPage()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('+  自定义新增动作'));
    await tester.pumpAndSettle();
    expect(find.text('新建自定义动作'), findsOneWidget);
    expect(find.text('目标组数（组）'), findsOneWidget);
    expect(find.text('休息时间（秒）'), findsOneWidget);

    final dialogTextField = find.descendant(
      of: find.byType(Dialog),
      matching: find.byType(TextField),
    );
    await tester.enterText(dialogTextField, '哑铃侧平举');
    await tester.pump();
    await tester.tap(find.text('确认加入计划'));
    await tester.pumpAndSettle();
    expect(find.text('哑铃侧平举'), findsOneWidget);
  });

  testWidgets('warns before starting when a weighted action has no weight', (
    tester,
  ) async {
    await WorkoutStore().clear();
    await tester.pumpWidget(const MaterialApp(home: WorkoutAssistantPage()));
    await tester.pumpAndSettle();

    expect(find.textContaining('待设置'), findsWidgets);
    await tester.tap(find.text('开始今日训练'));
    await tester.pump();

    expect(find.textContaining('尚未设置训练重量'), findsOneWidget);
    expect(find.text('准备好了吗？接下来每次只关注一个动作和一组。'), findsNothing);
  });

  testWidgets('walks through the workout flow to today summary', (
    tester,
  ) async {
    await WorkoutStore().clear();
    await _seedReadyWorkout();
    await tester.pumpWidget(const MaterialApp(home: WorkoutAssistantPage()));
    await tester.pumpAndSettle();

    expect(find.text('选择今天要练的动作'), findsOneWidget);
    await tester.tap(find.text('历史记录'));
    await tester.pumpAndSettle();
    expect(find.text('暂无历史记录'), findsOneWidget);
    await tester.tap(find.byTooltip('返回今日数据'));
    await tester.pumpAndSettle();
    expect(find.text('选择今天要练的动作'), findsOneWidget);

    await tester.tap(find.text('开始今日训练'));
    await tester.pumpAndSettle();
    expect(find.text('准备好了吗？接下来每次只关注一个动作和一组。'), findsOneWidget);

    await tester.ensureVisible(find.text('进入当前动作'));
    await tester.tap(find.text('进入当前动作'));
    await tester.pumpAndSettle();
    expect(find.text('杠铃卧推'), findsOneWidget);
    expect(find.text('健身助手'), findsNothing);

    const plans = [(4, '杠铃卧推'), (4, '杠铃深蹲'), (3, '哑铃弯举')];
    for (final plan in plans) {
      for (var set = 1; set <= plan.$1; set++) {
        final confirmButton = find.textContaining('确认完成第').first;
        await tester.ensureVisible(confirmButton);
        await tester.tap(confirmButton);
        await tester.pump();
        expect(find.text('休息结束后再继续，保持动作质量。'), findsOneWidget);

        await tester.pump(const Duration(milliseconds: 350));
        final skipButton = find.widgetWithText(OutlinedButton, '跳过休息');
        await tester.ensureVisible(skipButton);
        await tester.tap(skipButton);
        await tester.pumpAndSettle();
      }
    }

    expect(find.text('今日训练完成'), findsOneWidget);
    await tester.ensureVisible(find.text('查看历史训练数据'));
    await tester.tap(find.text('查看历史训练数据'));
    await tester.pumpAndSettle();
    expect(find.text('历史训练数据'), findsOneWidget);
    expect(find.text('累计训练'), findsOneWidget);
    expect(find.text('查看详细'), findsOneWidget);
    await tester.tap(find.text('查看详细'));
    await tester.pumpAndSettle();
    expect(find.text('训练详细数据'), findsOneWidget);
    expect(find.text('4/4 组 · 每组 12 次 · 休息 90 秒'), findsOneWidget);
    await tester.tap(find.byTooltip('关闭详情'));
    await tester.pumpAndSettle();
    expect(find.text('历史训练数据'), findsOneWidget);
  });

  testWidgets('adjusts, switches, and saves a partial training session', (
    tester,
  ) async {
    await WorkoutStore().clear();
    await _seedReadyWorkout();
    await tester.pumpWidget(const MaterialApp(home: WorkoutAssistantPage()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('开始今日训练'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('进入当前动作'));
    await tester.tap(find.text('进入当前动作'));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('调整本动作'));
    await tester.tap(find.text('调整本动作'));
    await tester.pumpAndSettle();
    expect(find.text('调整训练参数'), findsOneWidget);
    await tester.tap(find.text('取消'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('切换动作'));
    await tester.pumpAndSettle();
    expect(find.text('切换当前动作'), findsOneWidget);
    await tester.tap(find.text('杠铃深蹲'));
    await tester.pumpAndSettle();
    expect(find.text('杠铃深蹲'), findsOneWidget);

    await tester.ensureVisible(find.textContaining('确认完成第').first);
    await tester.tap(find.textContaining('确认完成第').first);
    await tester.pump();
    final skipButton = find.widgetWithText(OutlinedButton, '跳过休息');
    await tester.ensureVisible(skipButton);
    await tester.tap(skipButton);
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('训练中操作'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('结束并保存本次训练'));
    await tester.pumpAndSettle();
    expect(find.text('本次训练已保存'), findsOneWidget);
    expect(find.text('已保存部分训练'), findsOneWidget);
  });
}
