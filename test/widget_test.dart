import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:local_tasks/main.dart';

void main() {
  setUp(() async {
    final localBackup = Directory('LocalTasks');
    if (await localBackup.exists()) {
      await localBackup.delete(recursive: true);
    }
  });

  testWidgets('renders, edits, and locally restores tasks', (tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    expect(find.text('LocalTasks'), findsOneWidget);
    expect(find.text('保持井然有序。所有数据安全保存在您的设备上。'), findsOneWidget);
    expect(find.text('需要做什么？'), findsOneWidget);
    expect(find.text('添加标签'), findsOneWidget);
    expect(find.text('设置提醒'), findsOneWidget);

    final taskTitle = '买菜-${DateTime.now().microsecondsSinceEpoch}';

    await tester.tap(find.text('添加标签'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const ValueKey('tag-input')), '家庭');

    await tester.tap(find.text('设置提醒'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('reminder-input')),
      '明天 09:00',
    );

    await tester.enterText(find.byKey(const ValueKey('task-input')), taskTitle);
    await tester.tap(find.byTooltip('添加任务'));
    await tester.pumpAndSettle();

    expect(find.text(taskTitle), findsOneWidget);
    expect(find.text('家庭'), findsOneWidget);
    expect(find.text('明天 09:00'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();

    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    expect(find.text(taskTitle), findsOneWidget);
    expect(find.text('家庭'), findsOneWidget);
    expect(find.text('明天 09:00'), findsOneWidget);

    await tester.tap(find.byTooltip('删除任务').first);
    await tester.pumpAndSettle();
    expect(find.text(taskTitle), findsNothing);

    final completedTitle = '完成-${DateTime.now().microsecondsSinceEpoch}';
    await tester.enterText(
      find.byKey(const ValueKey('task-input')),
      completedTitle,
    );
    await tester.tap(find.byTooltip('添加任务'));
    await tester.pumpAndSettle();

    await tester.tap(find.text(completedTitle));
    await tester.pumpAndSettle();
  });
}
