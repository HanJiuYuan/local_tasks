import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:local_tasks/main.dart';
import 'package:local_tasks/widget/nutrition/nutrition_store.dart';

void main() {
  testWidgets('adds a food entry and updates today totals', (tester) async {
    await NutritionStore().clear();
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('饮食记录'));
    await tester.pumpAndSettle();
    expect(find.text('饮食记录'), findsNWidgets(2));
    expect(find.text('今日摄入'), findsOneWidget);

    await tester.tap(find.text('添加食物'));
    await tester.pumpAndSettle();
    expect(find.text('添加饮食记录'), findsOneWidget);

    await tester.enterText(
      find.byKey(const ValueKey('food-name-input')),
      '鸡胸肉',
    );
    await tester.enterText(
      find.byKey(const ValueKey('food-grams-input')),
      '200',
    );
    await tester.tap(find.text('保存记录'));
    await tester.pumpAndSettle();

    expect(find.text('鸡胸肉（熟）'), findsOneWidget);
    expect(find.text('330 kcal'), findsOneWidget);
    expect(find.textContaining('200g'), findsOneWidget);
    expect(find.text('62 g'), findsOneWidget);
  });
}
