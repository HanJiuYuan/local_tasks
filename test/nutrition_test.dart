import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:local_tasks/main.dart';
import 'package:local_tasks/widget/nutrition/nutrition_models.dart';
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

    await tester.tap(find.byKey(const ValueKey('more-nutrition-button')));
    await tester.pumpAndSettle();
    expect(find.text('膳食纤维'), findsOneWidget);
    expect(find.text('糖分'), findsOneWidget);
    expect(find.text('钠'), findsOneWidget);
    expect(find.text('148 mg'), findsOneWidget);
  });

  testWidgets('records a custom food with manually entered nutrition values', (
    tester,
  ) async {
    await NutritionStore().clear();
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('饮食记录'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('添加食物'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('custom-food-toggle')));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey('food-name-input')),
      '自制燕麦能量棒',
    );
    await tester.enterText(
      find.byKey(const ValueKey('custom-food-calories-input')),
      '200',
    );
    await tester.enterText(
      find.byKey(const ValueKey('custom-food-protein-input')),
      '10',
    );
    await tester.enterText(
      find.byKey(const ValueKey('custom-food-carbs-input')),
      '20',
    );
    await tester.enterText(
      find.byKey(const ValueKey('custom-food-fat-input')),
      '5',
    );
    await tester.enterText(
      find.byKey(const ValueKey('food-grams-input')),
      '150',
    );
    await tester.ensureVisible(find.text('保存记录'));
    await tester.tap(find.text('保存记录'));
    await tester.pumpAndSettle();

    expect(find.text('自制燕麦能量棒'), findsOneWidget);
    expect(find.text('300 kcal'), findsOneWidget);
  });

  testWidgets('records custom nutrition as this serving total', (tester) async {
    await NutritionStore().clear();
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('饮食记录'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('添加食物'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('custom-food-toggle')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('custom-total-input-choice')));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey('food-name-input')),
      '餐馆自制拌饭',
    );
    await tester.enterText(
      find.byKey(const ValueKey('custom-food-calories-input')),
      '420',
    );
    await tester.enterText(
      find.byKey(const ValueKey('custom-food-protein-input')),
      '25',
    );
    await tester.enterText(
      find.byKey(const ValueKey('custom-food-carbs-input')),
      '50',
    );
    await tester.enterText(
      find.byKey(const ValueKey('custom-food-fat-input')),
      '10',
    );
    await tester.enterText(find.byKey(const ValueKey('food-grams-input')), '');
    await tester.ensureVisible(find.text('保存记录'));
    await tester.tap(find.text('保存记录'));
    await tester.pumpAndSettle();

    expect(find.text('餐馆自制拌饭'), findsOneWidget);
    expect(find.text('420 kcal'), findsOneWidget);
  });

  test(
    'keeps today and history records separated by local calendar day',
    () async {
      final store = NutritionStore();
      await store.clear();
      final now = DateTime.now();
      final yesterday = now.subtract(const Duration(days: 1));

      await store.insert(_entry('昨天的鸡胸肉', yesterday));
      await store.insert(_entry('今天的米饭', now));

      final todayEntries = await store.loadForDate(now);
      final historyEntries = await store.loadHistory(before: now);

      expect(todayEntries.map((entry) => entry.name), ['今天的米饭']);
      expect(historyEntries.map((entry) => entry.name), ['昨天的鸡胸肉']);
    },
  );

  test('finds the expanded food list and keeps categories correct', () {
    final foodsToCheck = <String, FoodCategory>{
      '糙米': FoodCategory.staple,
      '牛排': FoodCategory.protein,
      '低脂牛奶': FoodCategory.dairyAndSoy,
      '花菜': FoodCategory.vegetables,
      '奇异果': FoodCategory.fruits,
      '核桃': FoodCategory.nutsAndOils,
      '无糖绿茶': FoodCategory.beverages,
      '藜麦': FoodCategory.staple,
      '鲈鱼': FoodCategory.protein,
      '火龙果': FoodCategory.fruits,
      '椰肉': FoodCategory.nutsAndOils,
    };

    for (final item in foodsToCheck.entries) {
      final food = FoodDatabase.find(item.key);
      expect(food, isNotNull, reason: '找不到 ${item.key}');
      expect(FoodDatabase.categoryFor(food!), item.value);
      expect(food.calculate(200).calories, greaterThanOrEqualTo(0));
    }

    final oats = FoodDatabase.find('燕麦')!.calculate(100);
    expect(oats.fiber, 10.1);
    expect(oats.sodium, 2);

    final corn = FoodDatabase.find('带芯玉米')!.calculate(100);
    expect(FoodDatabase.find('玉米')!.name, '玉米（熟）');
    expect(corn.calories, closeTo(96, .001));
  });

  testWidgets('opens nutrition history and shows previous-day records', (
    tester,
  ) async {
    final store = NutritionStore();
    await store.clear();
    await store.insert(
      _entry('昨天的鸡胸肉', DateTime.now().subtract(const Duration(days: 1))),
    );

    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();
    await tester.tap(find.text('饮食记录'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('查看历史记录'));
    await tester.pumpAndSettle();

    expect(find.text('饮食历史'), findsOneWidget);
    expect(find.text('昨天'), findsOneWidget);
    expect(find.textContaining('昨天的鸡胸肉'), findsOneWidget);
  });
}

FoodEntry _entry(String name, DateTime createdAt) {
  return FoodEntry(
    name: name,
    meal: MealType.lunch,
    grams: 100,
    calories: 100,
    protein: 20,
    carbs: 10,
    fat: 5,
    createdAt: createdAt,
  );
}
