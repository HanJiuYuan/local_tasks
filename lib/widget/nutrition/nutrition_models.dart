enum FoodCategory {
  staple,
  protein,
  dairyAndSoy,
  vegetables,
  fruits,
  nutsAndOils,
  beverages,
}

extension FoodCategoryDetails on FoodCategory {
  String get label => switch (this) {
    FoodCategory.staple => '主食',
    FoodCategory.protein => '蛋白质',
    FoodCategory.dairyAndSoy => '奶豆类',
    FoodCategory.vegetables => '蔬菜',
    FoodCategory.fruits => '水果',
    FoodCategory.nutsAndOils => '坚果油脂',
    FoodCategory.beverages => '饮品',
  };
}

enum MealType { breakfast, lunch, dinner, snack }

extension MealTypeDetails on MealType {
  String get label => switch (this) {
    MealType.breakfast => '早餐',
    MealType.lunch => '午餐',
    MealType.dinner => '晚餐',
    MealType.snack => '加餐',
  };

  String get subtitle => switch (this) {
    MealType.breakfast => '开启今天的能量',
    MealType.lunch => '补充下午状态',
    MealType.dinner => '完成今日营养',
    MealType.snack => '训练前后补充',
  };

  int get iconCodePoint => switch (this) {
    MealType.breakfast => 0xe518,
    MealType.lunch => 0xe56c,
    MealType.dinner => 0xe532,
    MealType.snack => 0xe57a,
  };
}

class FoodEntry {
  FoodEntry({
    this.id,
    required this.name,
    required this.meal,
    required this.grams,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  final int? id;
  final String name;
  final MealType meal;
  final double grams;
  final double calories;
  final double protein;
  final double carbs;
  final double fat;
  final DateTime createdAt;

  FoodEntry copyWith({int? id}) {
    return FoodEntry(
      id: id ?? this.id,
      name: name,
      meal: meal,
      grams: grams,
      calories: calories,
      protein: protein,
      carbs: carbs,
      fat: fat,
      createdAt: createdAt,
    );
  }
}

class NutritionValues {
  const NutritionValues({
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
  });

  final double calories;
  final double protein;
  final double carbs;
  final double fat;
}

class FoodNutrition {
  const FoodNutrition({
    required this.name,
    required this.aliases,
    required this.caloriesPer100g,
    required this.proteinPer100g,
    required this.carbsPer100g,
    required this.fatPer100g,
  });

  final String name;
  final List<String> aliases;
  final double caloriesPer100g;
  final double proteinPer100g;
  final double carbsPer100g;
  final double fatPer100g;

  NutritionValues calculate(double grams) {
    final ratio = grams / 100;
    return NutritionValues(
      calories: caloriesPer100g * ratio,
      protein: proteinPer100g * ratio,
      carbs: carbsPer100g * ratio,
      fat: fatPer100g * ratio,
    );
  }
}

class FoodDatabase {
  const FoodDatabase._();

  static const _categoryByName = <String, FoodCategory>{
    '米饭（熟）': FoodCategory.staple,
    '燕麦': FoodCategory.staple,
    '土豆（熟）': FoodCategory.staple,
    '全麦面包': FoodCategory.staple,
    '面条（熟）': FoodCategory.staple,
    '馒头': FoodCategory.staple,
    '红薯（熟）': FoodCategory.staple,
    '玉米（熟）': FoodCategory.staple,
    '小米粥': FoodCategory.staple,
    '鸡胸肉（熟）': FoodCategory.protein,
    '鸡蛋': FoodCategory.protein,
    '瘦牛肉（熟）': FoodCategory.protein,
    '牛腱子（熟）': FoodCategory.protein,
    '牛嫩肩（熟）': FoodCategory.protein,
    '牛霖（熟）': FoodCategory.protein,
    '三文鱼': FoodCategory.protein,
    '猪里脊（熟）': FoodCategory.protein,
    '鸡腿肉（熟）': FoodCategory.protein,
    '虾仁（熟）': FoodCategory.protein,
    '金枪鱼（水浸）': FoodCategory.protein,
    '牛奶': FoodCategory.dairyAndSoy,
    '豆腐': FoodCategory.dairyAndSoy,
    '乳清蛋白粉': FoodCategory.dairyAndSoy,
    '无糖酸奶': FoodCategory.dairyAndSoy,
    '无糖豆浆': FoodCategory.dairyAndSoy,
    '毛豆': FoodCategory.dairyAndSoy,
    '西兰花': FoodCategory.vegetables,
    '菠菜': FoodCategory.vegetables,
    '西红柿': FoodCategory.vegetables,
    '黄瓜': FoodCategory.vegetables,
    '胡萝卜': FoodCategory.vegetables,
    '蘑菇': FoodCategory.vegetables,
    '生菜': FoodCategory.vegetables,
    '香蕉': FoodCategory.fruits,
    '苹果': FoodCategory.fruits,
    '橙子': FoodCategory.fruits,
    '蓝莓': FoodCategory.fruits,
    '草莓': FoodCategory.fruits,
    '牛油果': FoodCategory.fruits,
    '花生': FoodCategory.nutsAndOils,
    '橄榄油': FoodCategory.nutsAndOils,
    '杏仁': FoodCategory.nutsAndOils,
    '腰果': FoodCategory.nutsAndOils,
    '芝麻酱': FoodCategory.nutsAndOils,
    '黑咖啡': FoodCategory.beverages,
  };

  static const commonFoods = <FoodNutrition>[
    FoodNutrition(
      name: '米饭（熟）',
      aliases: ['米饭', '熟米饭', '白饭'],
      caloriesPer100g: 116,
      proteinPer100g: 2.6,
      carbsPer100g: 25.9,
      fatPer100g: .3,
    ),
    FoodNutrition(
      name: '鸡胸肉（熟）',
      aliases: ['鸡胸肉', '熟鸡胸'],
      caloriesPer100g: 165,
      proteinPer100g: 31,
      carbsPer100g: 0,
      fatPer100g: 3.6,
    ),
    FoodNutrition(
      name: '鸡蛋',
      aliases: ['鸡蛋', '全蛋'],
      caloriesPer100g: 143,
      proteinPer100g: 12.6,
      carbsPer100g: .7,
      fatPer100g: 9.5,
    ),
    FoodNutrition(
      name: '瘦牛肉（熟）',
      aliases: ['牛肉', '瘦牛肉', '熟牛肉'],
      caloriesPer100g: 250,
      proteinPer100g: 26,
      carbsPer100g: 0,
      fatPer100g: 15,
    ),
    FoodNutrition(
      name: '牛腱子（熟）',
      aliases: ['牛腱子', '牛腱', '熟牛腱子'],
      caloriesPer100g: 180,
      proteinPer100g: 31,
      carbsPer100g: 0,
      fatPer100g: 6,
    ),
    FoodNutrition(
      name: '牛嫩肩（熟）',
      aliases: ['牛嫩肩', '嫩肩牛肉', '熟牛嫩肩'],
      caloriesPer100g: 205,
      proteinPer100g: 27,
      carbsPer100g: 0,
      fatPer100g: 10,
    ),
    FoodNutrition(
      name: '牛霖（熟）',
      aliases: ['牛霖', '牛霖肉', '熟牛霖'],
      caloriesPer100g: 190,
      proteinPer100g: 29,
      carbsPer100g: 0,
      fatPer100g: 8,
    ),
    FoodNutrition(
      name: '三文鱼',
      aliases: ['鲑鱼', '三文鱼'],
      caloriesPer100g: 208,
      proteinPer100g: 20,
      carbsPer100g: 0,
      fatPer100g: 13,
    ),
    FoodNutrition(
      name: '燕麦',
      aliases: ['燕麦片', '燕麦'],
      caloriesPer100g: 389,
      proteinPer100g: 16.9,
      carbsPer100g: 66.3,
      fatPer100g: 6.9,
    ),
    FoodNutrition(
      name: '牛奶',
      aliases: ['纯牛奶', '牛奶'],
      caloriesPer100g: 61,
      proteinPer100g: 3.2,
      carbsPer100g: 4.8,
      fatPer100g: 3.3,
    ),
    FoodNutrition(
      name: '香蕉',
      aliases: ['香蕉'],
      caloriesPer100g: 89,
      proteinPer100g: 1.1,
      carbsPer100g: 22.8,
      fatPer100g: .3,
    ),
    FoodNutrition(
      name: '土豆（熟）',
      aliases: ['土豆', '马铃薯'],
      caloriesPer100g: 87,
      proteinPer100g: 1.9,
      carbsPer100g: 20.1,
      fatPer100g: .1,
    ),
    FoodNutrition(
      name: '全麦面包',
      aliases: ['全麦面包', '面包'],
      caloriesPer100g: 247,
      proteinPer100g: 13,
      carbsPer100g: 41,
      fatPer100g: 4.2,
    ),
    FoodNutrition(
      name: '豆腐',
      aliases: ['豆腐', '北豆腐'],
      caloriesPer100g: 76,
      proteinPer100g: 8.1,
      carbsPer100g: 1.9,
      fatPer100g: 4.2,
    ),
    FoodNutrition(
      name: '西兰花',
      aliases: ['西兰花', '绿花菜'],
      caloriesPer100g: 35,
      proteinPer100g: 2.4,
      carbsPer100g: 7.2,
      fatPer100g: .4,
    ),
    FoodNutrition(
      name: '花生',
      aliases: ['花生', '花生米'],
      caloriesPer100g: 567,
      proteinPer100g: 25.8,
      carbsPer100g: 16.1,
      fatPer100g: 49.2,
    ),
    FoodNutrition(
      name: '乳清蛋白粉',
      aliases: ['蛋白粉', '乳清蛋白'],
      caloriesPer100g: 400,
      proteinPer100g: 75,
      carbsPer100g: 10,
      fatPer100g: 7,
    ),
    FoodNutrition(
      name: '面条（熟）',
      aliases: ['面条', '熟面条'],
      caloriesPer100g: 138,
      proteinPer100g: 4.5,
      carbsPer100g: 25.2,
      fatPer100g: 2.1,
    ),
    FoodNutrition(
      name: '馒头',
      aliases: ['馒头', '白馒头'],
      caloriesPer100g: 223,
      proteinPer100g: 7,
      carbsPer100g: 47,
      fatPer100g: 1.1,
    ),
    FoodNutrition(
      name: '红薯（熟）',
      aliases: ['红薯', '地瓜', '熟红薯'],
      caloriesPer100g: 86,
      proteinPer100g: 1.6,
      carbsPer100g: 20.1,
      fatPer100g: .1,
    ),
    FoodNutrition(
      name: '玉米（熟）',
      aliases: ['玉米', '熟玉米'],
      caloriesPer100g: 96,
      proteinPer100g: 3.4,
      carbsPer100g: 21,
      fatPer100g: 1.5,
    ),
    FoodNutrition(
      name: '小米粥',
      aliases: ['小米粥'],
      caloriesPer100g: 46,
      proteinPer100g: 1.4,
      carbsPer100g: 8.4,
      fatPer100g: .7,
    ),
    FoodNutrition(
      name: '猪里脊（熟）',
      aliases: ['猪里脊', '里脊肉', '瘦猪肉'],
      caloriesPer100g: 190,
      proteinPer100g: 29,
      carbsPer100g: 0,
      fatPer100g: 8,
    ),
    FoodNutrition(
      name: '鸡腿肉（熟）',
      aliases: ['鸡腿肉', '熟鸡腿'],
      caloriesPer100g: 209,
      proteinPer100g: 26,
      carbsPer100g: 0,
      fatPer100g: 11,
    ),
    FoodNutrition(
      name: '虾仁（熟）',
      aliases: ['虾仁', '熟虾仁', '虾'],
      caloriesPer100g: 99,
      proteinPer100g: 24,
      carbsPer100g: .2,
      fatPer100g: .3,
    ),
    FoodNutrition(
      name: '金枪鱼（水浸）',
      aliases: ['金枪鱼', '水浸金枪鱼', '吞拿鱼'],
      caloriesPer100g: 116,
      proteinPer100g: 25.5,
      carbsPer100g: 0,
      fatPer100g: .8,
    ),
    FoodNutrition(
      name: '无糖酸奶',
      aliases: ['无糖酸奶', '酸奶'],
      caloriesPer100g: 59,
      proteinPer100g: 10.3,
      carbsPer100g: 3.6,
      fatPer100g: .4,
    ),
    FoodNutrition(
      name: '无糖豆浆',
      aliases: ['无糖豆浆', '豆浆'],
      caloriesPer100g: 33,
      proteinPer100g: 3,
      carbsPer100g: 1.8,
      fatPer100g: 1.6,
    ),
    FoodNutrition(
      name: '毛豆',
      aliases: ['毛豆', '青大豆'],
      caloriesPer100g: 122,
      proteinPer100g: 11.9,
      carbsPer100g: 8.9,
      fatPer100g: 5.2,
    ),
    FoodNutrition(
      name: '菠菜',
      aliases: ['菠菜'],
      caloriesPer100g: 23,
      proteinPer100g: 2.9,
      carbsPer100g: 3.6,
      fatPer100g: .4,
    ),
    FoodNutrition(
      name: '西红柿',
      aliases: ['西红柿', '番茄'],
      caloriesPer100g: 18,
      proteinPer100g: .9,
      carbsPer100g: 3.9,
      fatPer100g: .2,
    ),
    FoodNutrition(
      name: '黄瓜',
      aliases: ['黄瓜'],
      caloriesPer100g: 15,
      proteinPer100g: .7,
      carbsPer100g: 3.6,
      fatPer100g: .1,
    ),
    FoodNutrition(
      name: '胡萝卜',
      aliases: ['胡萝卜'],
      caloriesPer100g: 41,
      proteinPer100g: .9,
      carbsPer100g: 9.6,
      fatPer100g: .2,
    ),
    FoodNutrition(
      name: '蘑菇',
      aliases: ['蘑菇', '口蘑'],
      caloriesPer100g: 22,
      proteinPer100g: 3.1,
      carbsPer100g: 3.3,
      fatPer100g: .3,
    ),
    FoodNutrition(
      name: '生菜',
      aliases: ['生菜'],
      caloriesPer100g: 15,
      proteinPer100g: 1.4,
      carbsPer100g: 2.9,
      fatPer100g: .2,
    ),
    FoodNutrition(
      name: '苹果',
      aliases: ['苹果'],
      caloriesPer100g: 52,
      proteinPer100g: .3,
      carbsPer100g: 13.8,
      fatPer100g: .2,
    ),
    FoodNutrition(
      name: '橙子',
      aliases: ['橙子', '橙'],
      caloriesPer100g: 47,
      proteinPer100g: .9,
      carbsPer100g: 11.8,
      fatPer100g: .1,
    ),
    FoodNutrition(
      name: '蓝莓',
      aliases: ['蓝莓'],
      caloriesPer100g: 57,
      proteinPer100g: .7,
      carbsPer100g: 14.5,
      fatPer100g: .3,
    ),
    FoodNutrition(
      name: '草莓',
      aliases: ['草莓'],
      caloriesPer100g: 32,
      proteinPer100g: .7,
      carbsPer100g: 7.7,
      fatPer100g: .3,
    ),
    FoodNutrition(
      name: '牛油果',
      aliases: ['牛油果', '鳄梨'],
      caloriesPer100g: 160,
      proteinPer100g: 2,
      carbsPer100g: 8.5,
      fatPer100g: 14.7,
    ),
    FoodNutrition(
      name: '橄榄油',
      aliases: ['橄榄油'],
      caloriesPer100g: 884,
      proteinPer100g: 0,
      carbsPer100g: 0,
      fatPer100g: 100,
    ),
    FoodNutrition(
      name: '杏仁',
      aliases: ['杏仁'],
      caloriesPer100g: 579,
      proteinPer100g: 21.2,
      carbsPer100g: 21.6,
      fatPer100g: 49.9,
    ),
    FoodNutrition(
      name: '腰果',
      aliases: ['腰果'],
      caloriesPer100g: 553,
      proteinPer100g: 18.2,
      carbsPer100g: 30.2,
      fatPer100g: 43.9,
    ),
    FoodNutrition(
      name: '芝麻酱',
      aliases: ['芝麻酱'],
      caloriesPer100g: 595,
      proteinPer100g: 17,
      carbsPer100g: 21,
      fatPer100g: 53,
    ),
    FoodNutrition(
      name: '黑咖啡',
      aliases: ['黑咖啡', '咖啡'],
      caloriesPer100g: 2,
      proteinPer100g: .3,
      carbsPer100g: 0,
      fatPer100g: 0,
    ),
  ];

  static FoodCategory categoryFor(FoodNutrition food) =>
      _categoryByName[food.name] ?? FoodCategory.staple;

  static List<FoodNutrition> foodsFor(FoodCategory category) => commonFoods
      .where((food) => categoryFor(food) == category)
      .toList(growable: false);

  static FoodNutrition? find(String input) {
    final normalized = input.trim().toLowerCase();
    if (normalized.isEmpty) return null;
    for (final food in commonFoods) {
      if (normalized == food.name.toLowerCase() ||
          food.aliases.any((alias) => normalized == alias.toLowerCase())) {
        return food;
      }
    }
    for (final food in commonFoods) {
      if (food.aliases.any(
        (alias) => normalized.contains(alias.toLowerCase()),
      )) {
        return food;
      }
    }
    return null;
  }
}

class NutritionTotals {
  const NutritionTotals({
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
  });

  factory NutritionTotals.fromEntries(Iterable<FoodEntry> entries) {
    var calories = 0.0;
    var protein = 0.0;
    var carbs = 0.0;
    var fat = 0.0;
    for (final entry in entries) {
      calories += entry.calories;
      protein += entry.protein;
      carbs += entry.carbs;
      fat += entry.fat;
    }
    return NutritionTotals(
      calories: calories,
      protein: protein,
      carbs: carbs,
      fat: fat,
    );
  }

  final double calories;
  final double protein;
  final double carbs;
  final double fat;
}
