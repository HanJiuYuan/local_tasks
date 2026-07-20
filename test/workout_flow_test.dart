import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:local_tasks/widget/workout/workout_page.dart';
import 'package:local_tasks/widget/workout/workout_store.dart';

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

  testWidgets('walks through the workout flow to today summary', (
    tester,
  ) async {
    await WorkoutStore().clear();
    await tester.pumpWidget(const MaterialApp(home: WorkoutAssistantPage()));
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
        await tester.ensureVisible(find.text('进入“完成动作”').first);
        await tester.tap(find.text('进入“完成动作”').first);
        await tester.pumpAndSettle();
        expect(find.text('完成这一组后，系统会自动开启组间休息。'), findsOneWidget);

        final confirmButton = find.textContaining('确认完成第').first;
        await tester.ensureVisible(confirmButton);
        await tester.tap(confirmButton);
        await tester.pump();
        expect(find.text('休息结束后再继续，保持动作质量。'), findsOneWidget);

        await tester.pump(const Duration(milliseconds: 350));
        await tester.ensureVisible(find.text('跳过休息'));
        await tester.tap(find.text('跳过休息'));
        await tester.pumpAndSettle();
      }
    }

    expect(find.text('今日训练完成'), findsOneWidget);
    await tester.ensureVisible(find.text('查看历史训练数据'));
    await tester.tap(find.text('查看历史训练数据'));
    await tester.pumpAndSettle();
    expect(find.text('历史训练数据'), findsOneWidget);
    expect(find.text('累计训练'), findsOneWidget);
  });
}
