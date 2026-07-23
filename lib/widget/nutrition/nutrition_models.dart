import '../workout/workout_models.dart';

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
    double? calories,
    double? protein,
    double? carbs,
    double? fat,
    double? fiber,
    double? sugar,
    double? sodium,
    this.nutritionPer100g,
    DateTime? createdAt,
  }) : _legacyNutrition = Nutrition(
         calories: calories ?? 0,
         protein: protein ?? 0,
         carbs: carbs ?? 0,
         fat: fat ?? 0,
         fiber: fiber ?? 0,
         sugar: sugar ?? 0,
         sodium: sodium ?? 0,
       ),
       createdAt = createdAt ?? DateTime.now();

  final int? id;
  final String name;
  final MealType meal;
  final double grams;

  /// The source nutrition label, always expressed per 100g when available.
  ///
  /// Custom entries recorded as a serving total do not have a meaningful
  /// per-100g value, so they keep [nutrition] in [_legacyNutrition].
  final Nutrition? nutritionPer100g;
  final Nutrition _legacyNutrition;
  final DateTime createdAt;

  /// Nutrition actually consumed for this entry.
  Nutrition get nutrition =>
      nutritionPer100g != null && grams > 0
          ? nutritionPer100g!.calculateByWeight(grams)
          : _legacyNutrition;

  double get calories => nutrition.calories;
  double get protein => nutrition.protein;
  double get carbs => nutrition.carbs;
  double get fat => nutrition.fat;
  double get fiber => nutrition.fiber;
  double get sugar => nutrition.sugar;
  double get sodium => nutrition.sodium;

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
      fiber: fiber,
      sugar: sugar,
      sodium: sodium,
      nutritionPer100g: nutritionPer100g,
      createdAt: createdAt,
    );
  }
}

class Nutrition {
  const Nutrition({
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    this.fiber = 0,
    this.sugar = 0,
    this.sodium = 0,
  });

  final double calories;
  final double protein;
  final double carbs;
  final double fat;
  final double fiber;
  final double sugar;
  final double sodium;

  Nutrition calculateByWeight(double grams) {
    final ratio = grams / 100.0;
    return Nutrition(
      calories: calories * ratio,
      protein: protein * ratio,
      carbs: carbs * ratio,
      fat: fat * ratio,
      fiber: fiber * ratio,
      sugar: sugar * ratio,
      sodium: sodium * ratio,
    );
  }
}

typedef NutritionValues = Nutrition;

class FoodNutrition {
  const FoodNutrition({
    required this.name,
    required this.aliases,
    required this.caloriesPer100g,
    required this.proteinPer100g,
    required this.carbsPer100g,
    required this.fatPer100g,
    this.fiberPer100g,
    this.sugarPer100g,
    this.sodiumPer100g,
  });

  final String name;
  final List<String> aliases;
  final double caloriesPer100g;
  final double proteinPer100g;
  final double carbsPer100g;
  final double fatPer100g;
  final double? fiberPer100g;
  final double? sugarPer100g;
  final double? sodiumPer100g;

  Nutrition get nutritionPer100g {
    final extras = FoodDatabase._nutritionExtrasByName[name];
    return Nutrition(
      calories: caloriesPer100g,
      protein: proteinPer100g,
      carbs: carbsPer100g,
      fat: fatPer100g,
      fiber: fiberPer100g ?? extras?.fiber ?? 0,
      sugar: sugarPer100g ?? extras?.sugar ?? 0,
      sodium: sodiumPer100g ?? extras?.sodium ?? 0,
    );
  }

  NutritionValues calculate(double grams) =>
      nutritionPer100g.calculateByWeight(grams);
}

class NutritionExtras {
  const NutritionExtras({this.fiber = 0, this.sugar = 0, this.sodium = 0});

  final double fiber;
  final double sugar;
  final double sodium;
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
    '糙米饭（熟）': FoodCategory.staple,
    '杂粮饭（熟）': FoodCategory.staple,
    '荞麦面（熟）': FoodCategory.staple,
    '意大利面（熟）': FoodCategory.staple,
    '米粉（熟）': FoodCategory.staple,
    '紫薯（熟）': FoodCategory.staple,
    '山药（熟）': FoodCategory.staple,
    '南瓜（熟）': FoodCategory.staple,
    '藜麦（熟）': FoodCategory.staple,
    '燕麦粥（熟）': FoodCategory.staple,
    '粉丝（熟）': FoodCategory.staple,
    '饺子（熟）': FoodCategory.staple,
    '馄饨（熟）': FoodCategory.staple,
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
    '鸭胸肉（熟）': FoodCategory.protein,
    '猪瘦肉（熟）': FoodCategory.protein,
    '牛排（熟）': FoodCategory.protein,
    '羊肉（熟）': FoodCategory.protein,
    '鳕鱼': FoodCategory.protein,
    '鱿鱼（熟）': FoodCategory.protein,
    '牡蛎': FoodCategory.protein,
    '火鸡胸肉（熟）': FoodCategory.protein,
    '鸡蛋清': FoodCategory.protein,
    '牛腩（熟）': FoodCategory.protein,
    '鸭肉（熟）': FoodCategory.protein,
    '鸡翅肉（熟）': FoodCategory.protein,
    '鲈鱼（熟）': FoodCategory.protein,
    '鳗鱼（熟）': FoodCategory.protein,
    '扇贝肉（熟）': FoodCategory.protein,
    '蛤蜊肉（熟）': FoodCategory.protein,
    '蟹肉（熟）': FoodCategory.protein,
    '牛奶': FoodCategory.dairyAndSoy,
    '豆腐': FoodCategory.dairyAndSoy,
    '乳清蛋白粉': FoodCategory.dairyAndSoy,
    '无糖酸奶': FoodCategory.dairyAndSoy,
    '无糖豆浆': FoodCategory.dairyAndSoy,
    '毛豆': FoodCategory.dairyAndSoy,
    '低脂牛奶': FoodCategory.dairyAndSoy,
    '低脂酸奶': FoodCategory.dairyAndSoy,
    '奶酪': FoodCategory.dairyAndSoy,
    '豆皮（熟）': FoodCategory.dairyAndSoy,
    '纳豆': FoodCategory.dairyAndSoy,
    '无糖希腊酸奶': FoodCategory.dairyAndSoy,
    '豆腐干': FoodCategory.dairyAndSoy,
    '鹰嘴豆（熟）': FoodCategory.dairyAndSoy,
    '红豆（熟）': FoodCategory.dairyAndSoy,
    '黑豆（熟）': FoodCategory.dairyAndSoy,
    '西兰花': FoodCategory.vegetables,
    '菠菜': FoodCategory.vegetables,
    '西红柿': FoodCategory.vegetables,
    '黄瓜': FoodCategory.vegetables,
    '胡萝卜': FoodCategory.vegetables,
    '蘑菇': FoodCategory.vegetables,
    '生菜': FoodCategory.vegetables,
    '菜花': FoodCategory.vegetables,
    '芦笋': FoodCategory.vegetables,
    '芹菜': FoodCategory.vegetables,
    '白菜': FoodCategory.vegetables,
    '紫甘蓝': FoodCategory.vegetables,
    '青椒': FoodCategory.vegetables,
    '茄子': FoodCategory.vegetables,
    '洋葱': FoodCategory.vegetables,
    '秋葵': FoodCategory.vegetables,
    '绿豆芽': FoodCategory.vegetables,
    '海带': FoodCategory.vegetables,
    '莲藕（熟）': FoodCategory.vegetables,
    '西葫芦': FoodCategory.vegetables,
    '冬瓜': FoodCategory.vegetables,
    '丝瓜': FoodCategory.vegetables,
    '苦瓜': FoodCategory.vegetables,
    '油麦菜': FoodCategory.vegetables,
    '菜心': FoodCategory.vegetables,
    '莴笋': FoodCategory.vegetables,
    '茭白': FoodCategory.vegetables,
    '木耳（泡发）': FoodCategory.vegetables,
    '香蕉': FoodCategory.fruits,
    '苹果': FoodCategory.fruits,
    '橙子': FoodCategory.fruits,
    '蓝莓': FoodCategory.fruits,
    '草莓': FoodCategory.fruits,
    '牛油果': FoodCategory.fruits,
    '梨': FoodCategory.fruits,
    '葡萄': FoodCategory.fruits,
    '西瓜': FoodCategory.fruits,
    '猕猴桃': FoodCategory.fruits,
    '菠萝': FoodCategory.fruits,
    '芒果': FoodCategory.fruits,
    '柚子': FoodCategory.fruits,
    '桃子': FoodCategory.fruits,
    '樱桃': FoodCategory.fruits,
    '哈密瓜': FoodCategory.fruits,
    '火龙果': FoodCategory.fruits,
    '柿子': FoodCategory.fruits,
    '荔枝': FoodCategory.fruits,
    '榴莲肉': FoodCategory.fruits,
    '桑葚': FoodCategory.fruits,
    '石榴籽': FoodCategory.fruits,
    '花生': FoodCategory.nutsAndOils,
    '橄榄油': FoodCategory.nutsAndOils,
    '杏仁': FoodCategory.nutsAndOils,
    '腰果': FoodCategory.nutsAndOils,
    '芝麻酱': FoodCategory.nutsAndOils,
    '核桃': FoodCategory.nutsAndOils,
    '开心果': FoodCategory.nutsAndOils,
    '南瓜子': FoodCategory.nutsAndOils,
    '葵花籽': FoodCategory.nutsAndOils,
    '亚麻籽': FoodCategory.nutsAndOils,
    '松子': FoodCategory.nutsAndOils,
    '榛子': FoodCategory.nutsAndOils,
    '夏威夷果': FoodCategory.nutsAndOils,
    '椰肉': FoodCategory.nutsAndOils,
    '黑咖啡': FoodCategory.beverages,
    '绿茶': FoodCategory.beverages,
    '红茶': FoodCategory.beverages,
    '无糖气泡水': FoodCategory.beverages,
    '椰子水': FoodCategory.beverages,
    '无糖可乐': FoodCategory.beverages,
    '无糖乌龙茶': FoodCategory.beverages,
  };

  // Values are approximate per 100 g (sodium is in mg). They are intended
  // for daily tracking, not medical or clinical nutrition advice.
  static const _nutritionExtrasByName = <String, NutritionExtras>{
    '米饭（熟）': NutritionExtras(fiber: .4, sugar: .1, sodium: 1),
    '燕麦': NutritionExtras(fiber: 10.1, sugar: .9, sodium: 2),
    '土豆（熟）': NutritionExtras(fiber: 1.8, sugar: .8, sodium: 7),
    '全麦面包': NutritionExtras(fiber: 6.8, sugar: 6, sodium: 400),
    '面条（熟）': NutritionExtras(fiber: 1.2, sugar: .4, sodium: 5),
    '馒头': NutritionExtras(fiber: 1.3, sugar: 1.5, sodium: 200),
    '红薯（熟）': NutritionExtras(fiber: 3, sugar: 6.5, sodium: 36),
    '玉米（熟）': NutritionExtras(fiber: 2.4, sugar: 4.5, sodium: 1),
    '小米粥': NutritionExtras(fiber: .1, sugar: .1, sodium: 1),
    '糙米饭（熟）': NutritionExtras(fiber: 1.8, sugar: .2, sodium: 1),
    '杂粮饭（熟）': NutritionExtras(fiber: 2.5, sugar: .3, sodium: 2),
    '荞麦面（熟）': NutritionExtras(fiber: 2.7, sugar: .4, sodium: 4),
    '意大利面（熟）': NutritionExtras(fiber: 1.8, sugar: .6, sodium: 1),
    '米粉（熟）': NutritionExtras(fiber: .9, sugar: .1, sodium: 3),
    '紫薯（熟）': NutritionExtras(fiber: 2.3, sugar: 5.5, sodium: 1),
    '山药（熟）': NutritionExtras(fiber: 1.9, sugar: .8, sodium: 5),
    '南瓜（熟）': NutritionExtras(fiber: 1.1, sugar: 2.1, sodium: 1),
    '鸡胸肉（熟）': NutritionExtras(sodium: 74),
    '鸡蛋': NutritionExtras(sugar: .7, sodium: 142),
    '瘦牛肉（熟）': NutritionExtras(sodium: 72),
    '牛腱子（熟）': NutritionExtras(sodium: 60),
    '牛嫩肩（熟）': NutritionExtras(sodium: 65),
    '牛霖（熟）': NutritionExtras(sodium: 60),
    '三文鱼': NutritionExtras(sodium: 59),
    '猪里脊（熟）': NutritionExtras(sodium: 60),
    '鸡腿肉（熟）': NutritionExtras(sodium: 84),
    '虾仁（熟）': NutritionExtras(sodium: 111),
    '金枪鱼（水浸）': NutritionExtras(sodium: 300),
    '鸭胸肉（熟）': NutritionExtras(sodium: 80),
    '猪瘦肉（熟）': NutritionExtras(sodium: 60),
    '牛排（熟）': NutritionExtras(sodium: 60),
    '羊肉（熟）': NutritionExtras(sodium: 70),
    '鳕鱼': NutritionExtras(sodium: 54),
    '鱿鱼（熟）': NutritionExtras(sugar: 1.5, sodium: 44),
    '牡蛎': NutritionExtras(sugar: .5, sodium: 90),
    '火鸡胸肉（熟）': NutritionExtras(sodium: 60),
    '鸡蛋清': NutritionExtras(sugar: .7, sodium: 166),
    '牛奶': NutritionExtras(sugar: 4.8, sodium: 43),
    '豆腐': NutritionExtras(fiber: .3, sugar: .6, sodium: 7),
    '乳清蛋白粉': NutritionExtras(sugar: 5, sodium: 300),
    '无糖酸奶': NutritionExtras(sugar: 3.6, sodium: 36),
    '无糖豆浆': NutritionExtras(fiber: .4, sugar: 1.2, sodium: 15),
    '毛豆': NutritionExtras(fiber: 5.2, sugar: 2.2, sodium: 6),
    '低脂牛奶': NutritionExtras(sugar: 4.9, sodium: 43),
    '低脂酸奶': NutritionExtras(sugar: 7, sodium: 50),
    '奶酪': NutritionExtras(sugar: 2.4, sodium: 600),
    '豆皮（熟）': NutritionExtras(fiber: 1.5, sugar: .8, sodium: 10),
    '纳豆': NutritionExtras(fiber: 5.4, sugar: 1.1, sodium: 2),
    '西兰花': NutritionExtras(fiber: 2.6, sugar: 1.4, sodium: 33),
    '菠菜': NutritionExtras(fiber: 2.2, sugar: .4, sodium: 79),
    '西红柿': NutritionExtras(fiber: 1.2, sugar: 2.6, sodium: 5),
    '黄瓜': NutritionExtras(fiber: .5, sugar: 1.7, sodium: 2),
    '胡萝卜': NutritionExtras(fiber: 2.8, sugar: 4.7, sodium: 69),
    '蘑菇': NutritionExtras(fiber: 1, sugar: .3, sodium: 5),
    '生菜': NutritionExtras(fiber: 1.2, sugar: .8, sodium: 28),
    '菜花': NutritionExtras(fiber: 2, sugar: 1.9, sodium: 30),
    '芦笋': NutritionExtras(fiber: 2.1, sugar: 1.9, sodium: 2),
    '芹菜': NutritionExtras(fiber: 1.6, sugar: 1.3, sodium: 80),
    '白菜': NutritionExtras(fiber: 1.2, sugar: 1.2, sodium: 6),
    '紫甘蓝': NutritionExtras(fiber: 2.1, sugar: 3.8, sodium: 27),
    '青椒': NutritionExtras(fiber: 1.7, sugar: 2.4, sodium: 3),
    '茄子': NutritionExtras(fiber: 3, sugar: 3.5, sodium: 2),
    '洋葱': NutritionExtras(fiber: 1.7, sugar: 4.2, sodium: 4),
    '秋葵': NutritionExtras(fiber: 3.2, sugar: 1.2, sodium: 7),
    '绿豆芽': NutritionExtras(fiber: 1.8, sugar: 4.1, sodium: 6),
    '海带': NutritionExtras(fiber: 1.3, sugar: .6, sodium: 233),
    '莲藕（熟）': NutritionExtras(fiber: 3.1, sugar: .7, sodium: 40),
    '香蕉': NutritionExtras(fiber: 2.6, sugar: 12.2, sodium: 1),
    '苹果': NutritionExtras(fiber: 2.4, sugar: 10.4, sodium: 1),
    '橙子': NutritionExtras(fiber: 2.4, sugar: 9.4, sodium: 0),
    '蓝莓': NutritionExtras(fiber: 2.4, sugar: 10, sodium: 1),
    '草莓': NutritionExtras(fiber: 2, sugar: 4.9, sodium: 1),
    '牛油果': NutritionExtras(fiber: 6.7, sugar: .7, sodium: 7),
    '梨': NutritionExtras(fiber: 3.1, sugar: 9.8, sodium: 1),
    '葡萄': NutritionExtras(fiber: .9, sugar: 15.5, sodium: 2),
    '西瓜': NutritionExtras(fiber: .4, sugar: 6.2, sodium: 1),
    '猕猴桃': NutritionExtras(fiber: 3, sugar: 8.9, sodium: 3),
    '菠萝': NutritionExtras(fiber: 1.4, sugar: 9.9, sodium: 1),
    '芒果': NutritionExtras(fiber: 1.6, sugar: 13.7, sodium: 1),
    '柚子': NutritionExtras(fiber: 1, sugar: 6.9, sodium: 0),
    '桃子': NutritionExtras(fiber: 1.5, sugar: 8.4, sodium: 0),
    '樱桃': NutritionExtras(fiber: 2.1, sugar: 12.8, sodium: 0),
    '哈密瓜': NutritionExtras(fiber: .9, sugar: 7.9, sodium: 16),
    '花生': NutritionExtras(fiber: 8.5, sugar: 4.7, sodium: 18),
    '橄榄油': NutritionExtras(sodium: 2),
    '杏仁': NutritionExtras(fiber: 12.5, sugar: 4.4, sodium: 1),
    '腰果': NutritionExtras(fiber: 3.3, sugar: 5.9, sodium: 12),
    '芝麻酱': NutritionExtras(fiber: 9.3, sugar: .5, sodium: 115),
    '核桃': NutritionExtras(fiber: 6.7, sugar: 2.6, sodium: 2),
    '开心果': NutritionExtras(fiber: 10.3, sugar: 7.7, sodium: 1),
    '南瓜子': NutritionExtras(fiber: 6, sugar: 1.4, sodium: 7),
    '葵花籽': NutritionExtras(fiber: 8.6, sugar: 2.6, sodium: 9),
    '亚麻籽': NutritionExtras(fiber: 27.3, sugar: 1.6, sodium: 30),
    '黑咖啡': NutritionExtras(sodium: 5),
    '绿茶': NutritionExtras(sodium: 1),
    '红茶': NutritionExtras(sodium: 1),
    '无糖气泡水': NutritionExtras(),
    '椰子水': NutritionExtras(sugar: 2.6, sodium: 105),
    '无糖可乐': NutritionExtras(sodium: 10),
    '藜麦（熟）': NutritionExtras(fiber: 2.8, sugar: .9, sodium: 7),
    '燕麦粥（熟）': NutritionExtras(fiber: 1.7, sugar: .3, sodium: 49),
    '粉丝（熟）': NutritionExtras(fiber: .5, sodium: 3),
    '饺子（熟）': NutritionExtras(fiber: 1.5, sugar: .8, sodium: 300),
    '馄饨（熟）': NutritionExtras(fiber: 1, sugar: .5, sodium: 300),
    '牛腩（熟）': NutritionExtras(sodium: 65),
    '鸭肉（熟）': NutritionExtras(sodium: 70),
    '鸡翅肉（熟）': NutritionExtras(sodium: 80),
    '鲈鱼（熟）': NutritionExtras(sodium: 60),
    '鳗鱼（熟）': NutritionExtras(sodium: 70),
    '扇贝肉（熟）': NutritionExtras(sugar: 1.5, sodium: 450),
    '蛤蜊肉（熟）': NutritionExtras(sugar: 1.5, sodium: 450),
    '蟹肉（熟）': NutritionExtras(sodium: 395),
    '无糖希腊酸奶': NutritionExtras(sugar: 3.9, sodium: 36),
    '豆腐干': NutritionExtras(fiber: 1.2, sugar: 1, sodium: 300),
    '鹰嘴豆（熟）': NutritionExtras(fiber: 7.6, sugar: 4.8, sodium: 7),
    '红豆（熟）': NutritionExtras(fiber: 7.4, sugar: .3, sodium: 2),
    '黑豆（熟）': NutritionExtras(fiber: 8.7, sugar: .3, sodium: 2),
    '西葫芦': NutritionExtras(fiber: 1, sugar: 2.5, sodium: 8),
    '冬瓜': NutritionExtras(fiber: .6, sugar: 1.2, sodium: 2),
    '丝瓜': NutritionExtras(fiber: .6, sugar: 2.2, sodium: 2),
    '苦瓜': NutritionExtras(fiber: 2.8, sugar: .6, sodium: 6),
    '油麦菜': NutritionExtras(fiber: 1.5, sugar: .5, sodium: 50),
    '菜心': NutritionExtras(fiber: 1.6, sugar: 1, sodium: 30),
    '莴笋': NutritionExtras(fiber: 1.5, sugar: 1.3, sodium: 3),
    '茭白': NutritionExtras(fiber: 1.9, sugar: 1.2, sodium: 7),
    '木耳（泡发）': NutritionExtras(fiber: 3.2, sugar: .2, sodium: 7),
    '火龙果': NutritionExtras(fiber: 3.1, sugar: 8, sodium: 1),
    '柿子': NutritionExtras(fiber: 3.6, sugar: 12.5, sodium: 1),
    '荔枝': NutritionExtras(fiber: 1.3, sugar: 15.2, sodium: 1),
    '榴莲肉': NutritionExtras(fiber: 3.8, sugar: 19.7, sodium: 2),
    '桑葚': NutritionExtras(fiber: 1.7, sugar: 8.1, sodium: 10),
    '石榴籽': NutritionExtras(fiber: 4, sugar: 13.7, sodium: 3),
    '松子': NutritionExtras(fiber: 3.7, sugar: 3.6, sodium: 2),
    '榛子': NutritionExtras(fiber: 9.7, sugar: 4.3, sodium: 0),
    '夏威夷果': NutritionExtras(fiber: 8.6, sugar: 4.6, sodium: 5),
    '椰肉': NutritionExtras(fiber: 9, sugar: 6.2, sodium: 20),
    '无糖乌龙茶': NutritionExtras(sodium: 1),
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
      aliases: [
        '玉米（熟）',
        '玉米粒（熟，去芯）',
        '玉米',
        '玉米粒',
        '熟玉米',
        '去芯玉米',
        '整根玉米',
        '带芯玉米',
        '玉米棒',
        '玉米（带芯）',
      ],
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
    FoodNutrition(
      name: '糙米饭（熟）',
      aliases: ['糙米饭', '糙米', '熟糙米'],
      caloriesPer100g: 111,
      proteinPer100g: 2.6,
      carbsPer100g: 23,
      fatPer100g: .9,
    ),
    FoodNutrition(
      name: '杂粮饭（熟）',
      aliases: ['杂粮饭', '杂粮米饭'],
      caloriesPer100g: 120,
      proteinPer100g: 3,
      carbsPer100g: 24,
      fatPer100g: 1,
    ),
    FoodNutrition(
      name: '荞麦面（熟）',
      aliases: ['荞麦面', '熟荞麦面'],
      caloriesPer100g: 99,
      proteinPer100g: 4.5,
      carbsPer100g: 21.4,
      fatPer100g: .1,
    ),
    FoodNutrition(
      name: '意大利面（熟）',
      aliases: ['意大利面', '通心粉', '熟意面'],
      caloriesPer100g: 158,
      proteinPer100g: 5.8,
      carbsPer100g: 30.9,
      fatPer100g: .9,
    ),
    FoodNutrition(
      name: '米粉（熟）',
      aliases: ['米粉', '河粉', '熟米粉'],
      caloriesPer100g: 109,
      proteinPer100g: 1.9,
      carbsPer100g: 24.9,
      fatPer100g: .2,
    ),
    FoodNutrition(
      name: '紫薯（熟）',
      aliases: ['紫薯', '熟紫薯'],
      caloriesPer100g: 132,
      proteinPer100g: 1.6,
      carbsPer100g: 31.7,
      fatPer100g: .2,
    ),
    FoodNutrition(
      name: '山药（熟）',
      aliases: ['山药', '熟山药'],
      caloriesPer100g: 118,
      proteinPer100g: 1.5,
      carbsPer100g: 27.9,
      fatPer100g: .2,
    ),
    FoodNutrition(
      name: '南瓜（熟）',
      aliases: ['南瓜', '熟南瓜'],
      caloriesPer100g: 20,
      proteinPer100g: .7,
      carbsPer100g: 4.9,
      fatPer100g: .1,
    ),
    FoodNutrition(
      name: '鸭胸肉（熟）',
      aliases: ['鸭胸肉', '熟鸭胸'],
      caloriesPer100g: 201,
      proteinPer100g: 23.5,
      carbsPer100g: 0,
      fatPer100g: 11,
    ),
    FoodNutrition(
      name: '猪瘦肉（熟）',
      aliases: ['猪瘦肉', '瘦猪肉', '熟猪肉'],
      caloriesPer100g: 143,
      proteinPer100g: 26,
      carbsPer100g: 0,
      fatPer100g: 4.9,
    ),
    FoodNutrition(
      name: '牛排（熟）',
      aliases: ['牛排', '熟牛排'],
      caloriesPer100g: 271,
      proteinPer100g: 25,
      carbsPer100g: 0,
      fatPer100g: 18,
    ),
    FoodNutrition(
      name: '羊肉（熟）',
      aliases: ['羊肉', '熟羊肉'],
      caloriesPer100g: 258,
      proteinPer100g: 25,
      carbsPer100g: 0,
      fatPer100g: 17,
    ),
    FoodNutrition(
      name: '鳕鱼',
      aliases: ['鳕鱼', '银鳕鱼'],
      caloriesPer100g: 82,
      proteinPer100g: 18,
      carbsPer100g: 0,
      fatPer100g: .7,
    ),
    FoodNutrition(
      name: '鱿鱼（熟）',
      aliases: ['鱿鱼', '熟鱿鱼'],
      caloriesPer100g: 92,
      proteinPer100g: 15.6,
      carbsPer100g: 3.1,
      fatPer100g: 1.4,
    ),
    FoodNutrition(
      name: '牡蛎',
      aliases: ['牡蛎', '生蚝', '蚝'],
      caloriesPer100g: 81,
      proteinPer100g: 9,
      carbsPer100g: 4.9,
      fatPer100g: 2.3,
    ),
    FoodNutrition(
      name: '火鸡胸肉（熟）',
      aliases: ['火鸡胸肉', '熟火鸡胸'],
      caloriesPer100g: 135,
      proteinPer100g: 29,
      carbsPer100g: 0,
      fatPer100g: 1.6,
    ),
    FoodNutrition(
      name: '鸡蛋清',
      aliases: ['蛋清', '鸡蛋白', '蛋白'],
      caloriesPer100g: 52,
      proteinPer100g: 10.9,
      carbsPer100g: .7,
      fatPer100g: .2,
    ),
    FoodNutrition(
      name: '低脂牛奶',
      aliases: ['低脂奶', '脱脂牛奶'],
      caloriesPer100g: 46,
      proteinPer100g: 3.4,
      carbsPer100g: 4.9,
      fatPer100g: 1.5,
    ),
    FoodNutrition(
      name: '低脂酸奶',
      aliases: ['低脂酸奶', '低脂优格'],
      caloriesPer100g: 63,
      proteinPer100g: 5.3,
      carbsPer100g: 7,
      fatPer100g: 1.5,
    ),
    FoodNutrition(
      name: '奶酪',
      aliases: ['奶酪', '芝士', '起司'],
      caloriesPer100g: 350,
      proteinPer100g: 22,
      carbsPer100g: 2.4,
      fatPer100g: 28,
    ),
    FoodNutrition(
      name: '豆皮（熟）',
      aliases: ['豆皮', '腐皮', '熟豆皮'],
      caloriesPer100g: 202,
      proteinPer100g: 20,
      carbsPer100g: 8,
      fatPer100g: 10,
    ),
    FoodNutrition(
      name: '纳豆',
      aliases: ['纳豆'],
      caloriesPer100g: 211,
      proteinPer100g: 19,
      carbsPer100g: 12,
      fatPer100g: 11,
    ),
    FoodNutrition(
      name: '菜花',
      aliases: ['菜花', '花菜', '白花菜'],
      caloriesPer100g: 25,
      proteinPer100g: 1.9,
      carbsPer100g: 5,
      fatPer100g: .3,
    ),
    FoodNutrition(
      name: '芦笋',
      aliases: ['芦笋'],
      caloriesPer100g: 20,
      proteinPer100g: 2.2,
      carbsPer100g: 3.9,
      fatPer100g: .1,
    ),
    FoodNutrition(
      name: '芹菜',
      aliases: ['芹菜'],
      caloriesPer100g: 16,
      proteinPer100g: .7,
      carbsPer100g: 3,
      fatPer100g: .2,
    ),
    FoodNutrition(
      name: '白菜',
      aliases: ['白菜', '大白菜'],
      caloriesPer100g: 13,
      proteinPer100g: 1.5,
      carbsPer100g: 2.2,
      fatPer100g: .2,
    ),
    FoodNutrition(
      name: '紫甘蓝',
      aliases: ['紫甘蓝', '紫包菜'],
      caloriesPer100g: 31,
      proteinPer100g: 1.4,
      carbsPer100g: 7.4,
      fatPer100g: .2,
    ),
    FoodNutrition(
      name: '青椒',
      aliases: ['青椒', '甜椒'],
      caloriesPer100g: 20,
      proteinPer100g: .9,
      carbsPer100g: 4.6,
      fatPer100g: .2,
    ),
    FoodNutrition(
      name: '茄子',
      aliases: ['茄子'],
      caloriesPer100g: 25,
      proteinPer100g: 1,
      carbsPer100g: 5.9,
      fatPer100g: .2,
    ),
    FoodNutrition(
      name: '洋葱',
      aliases: ['洋葱'],
      caloriesPer100g: 40,
      proteinPer100g: 1.1,
      carbsPer100g: 9.3,
      fatPer100g: .1,
    ),
    FoodNutrition(
      name: '秋葵',
      aliases: ['秋葵'],
      caloriesPer100g: 33,
      proteinPer100g: 1.9,
      carbsPer100g: 7.5,
      fatPer100g: .2,
    ),
    FoodNutrition(
      name: '绿豆芽',
      aliases: ['绿豆芽', '豆芽'],
      caloriesPer100g: 30,
      proteinPer100g: 3,
      carbsPer100g: 5.9,
      fatPer100g: .2,
    ),
    FoodNutrition(
      name: '海带',
      aliases: ['海带', '昆布'],
      caloriesPer100g: 43,
      proteinPer100g: 1.7,
      carbsPer100g: 9.6,
      fatPer100g: .6,
    ),
    FoodNutrition(
      name: '莲藕（熟）',
      aliases: ['莲藕', '藕', '熟莲藕'],
      caloriesPer100g: 74,
      proteinPer100g: 2.6,
      carbsPer100g: 17,
      fatPer100g: .1,
    ),
    FoodNutrition(
      name: '梨',
      aliases: ['梨', '雪梨'],
      caloriesPer100g: 57,
      proteinPer100g: .4,
      carbsPer100g: 15.2,
      fatPer100g: .1,
    ),
    FoodNutrition(
      name: '葡萄',
      aliases: ['葡萄'],
      caloriesPer100g: 69,
      proteinPer100g: .7,
      carbsPer100g: 18.1,
      fatPer100g: .2,
    ),
    FoodNutrition(
      name: '西瓜',
      aliases: ['西瓜'],
      caloriesPer100g: 30,
      proteinPer100g: .6,
      carbsPer100g: 7.6,
      fatPer100g: .2,
    ),
    FoodNutrition(
      name: '猕猴桃',
      aliases: ['猕猴桃', '奇异果'],
      caloriesPer100g: 61,
      proteinPer100g: 1.1,
      carbsPer100g: 14.7,
      fatPer100g: .5,
    ),
    FoodNutrition(
      name: '菠萝',
      aliases: ['菠萝', '凤梨'],
      caloriesPer100g: 50,
      proteinPer100g: .5,
      carbsPer100g: 13.1,
      fatPer100g: .1,
    ),
    FoodNutrition(
      name: '芒果',
      aliases: ['芒果'],
      caloriesPer100g: 60,
      proteinPer100g: .8,
      carbsPer100g: 15,
      fatPer100g: .4,
    ),
    FoodNutrition(
      name: '柚子',
      aliases: ['柚子', '西柚'],
      caloriesPer100g: 38,
      proteinPer100g: .8,
      carbsPer100g: 9.6,
      fatPer100g: .2,
    ),
    FoodNutrition(
      name: '桃子',
      aliases: ['桃子', '水蜜桃'],
      caloriesPer100g: 39,
      proteinPer100g: .9,
      carbsPer100g: 9.5,
      fatPer100g: .3,
    ),
    FoodNutrition(
      name: '樱桃',
      aliases: ['樱桃', '车厘子'],
      caloriesPer100g: 63,
      proteinPer100g: 1.1,
      carbsPer100g: 16,
      fatPer100g: .2,
    ),
    FoodNutrition(
      name: '哈密瓜',
      aliases: ['哈密瓜', '甜瓜'],
      caloriesPer100g: 34,
      proteinPer100g: .8,
      carbsPer100g: 8.2,
      fatPer100g: .2,
    ),
    FoodNutrition(
      name: '核桃',
      aliases: ['核桃'],
      caloriesPer100g: 654,
      proteinPer100g: 15.2,
      carbsPer100g: 13.7,
      fatPer100g: 65.2,
    ),
    FoodNutrition(
      name: '开心果',
      aliases: ['开心果'],
      caloriesPer100g: 562,
      proteinPer100g: 20.2,
      carbsPer100g: 27.5,
      fatPer100g: 45.4,
    ),
    FoodNutrition(
      name: '南瓜子',
      aliases: ['南瓜子', '南瓜籽'],
      caloriesPer100g: 559,
      proteinPer100g: 30.2,
      carbsPer100g: 10.7,
      fatPer100g: 49,
    ),
    FoodNutrition(
      name: '葵花籽',
      aliases: ['葵花籽', '瓜子'],
      caloriesPer100g: 584,
      proteinPer100g: 20.8,
      carbsPer100g: 20,
      fatPer100g: 51.5,
    ),
    FoodNutrition(
      name: '亚麻籽',
      aliases: ['亚麻籽', '亚麻籽粉'],
      caloriesPer100g: 534,
      proteinPer100g: 18.3,
      carbsPer100g: 28.9,
      fatPer100g: 42.2,
    ),
    FoodNutrition(
      name: '绿茶',
      aliases: ['绿茶', '无糖绿茶'],
      caloriesPer100g: 1,
      proteinPer100g: 0,
      carbsPer100g: 0,
      fatPer100g: 0,
    ),
    FoodNutrition(
      name: '红茶',
      aliases: ['红茶', '无糖红茶'],
      caloriesPer100g: 1,
      proteinPer100g: 0,
      carbsPer100g: 0,
      fatPer100g: 0,
    ),
    FoodNutrition(
      name: '无糖气泡水',
      aliases: ['气泡水', '苏打水', '无糖苏打水'],
      caloriesPer100g: 0,
      proteinPer100g: 0,
      carbsPer100g: 0,
      fatPer100g: 0,
    ),
    FoodNutrition(
      name: '椰子水',
      aliases: ['椰子水'],
      caloriesPer100g: 19,
      proteinPer100g: .7,
      carbsPer100g: 3.7,
      fatPer100g: .2,
    ),
    FoodNutrition(
      name: '无糖可乐',
      aliases: ['无糖可乐', '零度可乐', '可乐（无糖）'],
      caloriesPer100g: 0,
      proteinPer100g: 0,
      carbsPer100g: 0,
      fatPer100g: 0,
    ),
    FoodNutrition(
      name: '藜麦（熟）',
      aliases: ['藜麦', '熟藜麦'],
      caloriesPer100g: 120,
      proteinPer100g: 4.4,
      carbsPer100g: 21.3,
      fatPer100g: 1.9,
    ),
    FoodNutrition(
      name: '燕麦粥（熟）',
      aliases: ['燕麦粥', '熟燕麦粥'],
      caloriesPer100g: 68,
      proteinPer100g: 2.4,
      carbsPer100g: 12,
      fatPer100g: 1.4,
    ),
    FoodNutrition(
      name: '粉丝（熟）',
      aliases: ['粉丝', '熟粉丝'],
      caloriesPer100g: 77,
      proteinPer100g: .2,
      carbsPer100g: 18,
      fatPer100g: .1,
    ),
    FoodNutrition(
      name: '饺子（熟）',
      aliases: ['饺子', '水饺', '熟饺子'],
      caloriesPer100g: 180,
      proteinPer100g: 7,
      carbsPer100g: 25,
      fatPer100g: 5,
    ),
    FoodNutrition(
      name: '馄饨（熟）',
      aliases: ['馄饨', '云吞', '熟馄饨'],
      caloriesPer100g: 150,
      proteinPer100g: 6,
      carbsPer100g: 20,
      fatPer100g: 5,
    ),
    FoodNutrition(
      name: '牛腩（熟）',
      aliases: ['牛腩', '熟牛腩'],
      caloriesPer100g: 250,
      proteinPer100g: 26,
      carbsPer100g: 0,
      fatPer100g: 15,
    ),
    FoodNutrition(
      name: '鸭肉（熟）',
      aliases: ['鸭肉', '熟鸭肉'],
      caloriesPer100g: 240,
      proteinPer100g: 19,
      carbsPer100g: 0,
      fatPer100g: 18,
    ),
    FoodNutrition(
      name: '鸡翅肉（熟）',
      aliases: ['鸡翅肉', '去骨鸡翅', '熟鸡翅肉'],
      caloriesPer100g: 203,
      proteinPer100g: 24,
      carbsPer100g: 0,
      fatPer100g: 11,
    ),
    FoodNutrition(
      name: '鲈鱼（熟）',
      aliases: ['鲈鱼', '熟鲈鱼'],
      caloriesPer100g: 124,
      proteinPer100g: 24.5,
      carbsPer100g: 0,
      fatPer100g: 2.6,
    ),
    FoodNutrition(
      name: '鳗鱼（熟）',
      aliases: ['鳗鱼', '鳗鲡', '熟鳗鱼'],
      caloriesPer100g: 184,
      proteinPer100g: 18.6,
      carbsPer100g: 0,
      fatPer100g: 11.7,
    ),
    FoodNutrition(
      name: '扇贝肉（熟）',
      aliases: ['扇贝肉', '熟扇贝'],
      caloriesPer100g: 111,
      proteinPer100g: 20.5,
      carbsPer100g: 5.4,
      fatPer100g: 1.5,
    ),
    FoodNutrition(
      name: '蛤蜊肉（熟）',
      aliases: ['蛤蜊肉', '花甲肉', '熟蛤蜊'],
      caloriesPer100g: 148,
      proteinPer100g: 25.6,
      carbsPer100g: 5.1,
      fatPer100g: 2.4,
    ),
    FoodNutrition(
      name: '蟹肉（熟）',
      aliases: ['蟹肉', '熟蟹肉'],
      caloriesPer100g: 97,
      proteinPer100g: 19.2,
      carbsPer100g: 0,
      fatPer100g: 1.5,
    ),
    FoodNutrition(
      name: '无糖希腊酸奶',
      aliases: ['希腊酸奶', '无糖希腊酸奶'],
      caloriesPer100g: 73,
      proteinPer100g: 9.9,
      carbsPer100g: 3.9,
      fatPer100g: 2,
    ),
    FoodNutrition(
      name: '豆腐干',
      aliases: ['豆腐干', '香干'],
      caloriesPer100g: 140,
      proteinPer100g: 16,
      carbsPer100g: 6,
      fatPer100g: 7,
    ),
    FoodNutrition(
      name: '鹰嘴豆（熟）',
      aliases: ['鹰嘴豆', '熟鹰嘴豆'],
      caloriesPer100g: 164,
      proteinPer100g: 8.9,
      carbsPer100g: 27.4,
      fatPer100g: 2.6,
    ),
    FoodNutrition(
      name: '红豆（熟）',
      aliases: ['红豆', '熟红豆'],
      caloriesPer100g: 127,
      proteinPer100g: 8.7,
      carbsPer100g: 22.8,
      fatPer100g: .5,
    ),
    FoodNutrition(
      name: '黑豆（熟）',
      aliases: ['黑豆', '熟黑豆'],
      caloriesPer100g: 132,
      proteinPer100g: 8.9,
      carbsPer100g: 23.7,
      fatPer100g: .5,
    ),
    FoodNutrition(
      name: '西葫芦',
      aliases: ['西葫芦', '角瓜'],
      caloriesPer100g: 17,
      proteinPer100g: 1.2,
      carbsPer100g: 3.1,
      fatPer100g: .3,
    ),
    FoodNutrition(
      name: '冬瓜',
      aliases: ['冬瓜'],
      caloriesPer100g: 13,
      proteinPer100g: .4,
      carbsPer100g: 3,
      fatPer100g: .2,
    ),
    FoodNutrition(
      name: '丝瓜',
      aliases: ['丝瓜'],
      caloriesPer100g: 20,
      proteinPer100g: 1,
      carbsPer100g: 4.2,
      fatPer100g: .2,
    ),
    FoodNutrition(
      name: '苦瓜',
      aliases: ['苦瓜'],
      caloriesPer100g: 17,
      proteinPer100g: 1,
      carbsPer100g: 3.7,
      fatPer100g: .2,
    ),
    FoodNutrition(
      name: '油麦菜',
      aliases: ['油麦菜'],
      caloriesPer100g: 15,
      proteinPer100g: 1.4,
      carbsPer100g: 2.8,
      fatPer100g: .2,
    ),
    FoodNutrition(
      name: '菜心',
      aliases: ['菜心', '广东菜心'],
      caloriesPer100g: 22,
      proteinPer100g: 2.5,
      carbsPer100g: 3.4,
      fatPer100g: .4,
    ),
    FoodNutrition(
      name: '莴笋',
      aliases: ['莴笋', '莴苣'],
      caloriesPer100g: 15,
      proteinPer100g: 1.2,
      carbsPer100g: 2.9,
      fatPer100g: .2,
    ),
    FoodNutrition(
      name: '茭白',
      aliases: ['茭白'],
      caloriesPer100g: 23,
      proteinPer100g: 1.2,
      carbsPer100g: 5,
      fatPer100g: .2,
    ),
    FoodNutrition(
      name: '木耳（泡发）',
      aliases: ['木耳', '黑木耳', '泡发木耳'],
      caloriesPer100g: 21,
      proteinPer100g: 1.5,
      carbsPer100g: 6,
      fatPer100g: .2,
    ),
    FoodNutrition(
      name: '火龙果',
      aliases: ['火龙果'],
      caloriesPer100g: 50,
      proteinPer100g: 1.1,
      carbsPer100g: 13.5,
      fatPer100g: .4,
    ),
    FoodNutrition(
      name: '柿子',
      aliases: ['柿子'],
      caloriesPer100g: 70,
      proteinPer100g: .6,
      carbsPer100g: 18.6,
      fatPer100g: .2,
    ),
    FoodNutrition(
      name: '荔枝',
      aliases: ['荔枝'],
      caloriesPer100g: 66,
      proteinPer100g: .8,
      carbsPer100g: 16.5,
      fatPer100g: .4,
    ),
    FoodNutrition(
      name: '榴莲肉',
      aliases: ['榴莲', '榴莲肉'],
      caloriesPer100g: 147,
      proteinPer100g: 1.5,
      carbsPer100g: 27.1,
      fatPer100g: 5.3,
    ),
    FoodNutrition(
      name: '桑葚',
      aliases: ['桑葚', '桑椹'],
      caloriesPer100g: 43,
      proteinPer100g: 1.4,
      carbsPer100g: 9.8,
      fatPer100g: .4,
    ),
    FoodNutrition(
      name: '石榴籽',
      aliases: ['石榴', '石榴籽'],
      caloriesPer100g: 83,
      proteinPer100g: 1.7,
      carbsPer100g: 18.7,
      fatPer100g: 1.2,
    ),
    FoodNutrition(
      name: '松子',
      aliases: ['松子', '松仁'],
      caloriesPer100g: 673,
      proteinPer100g: 13.7,
      carbsPer100g: 13.1,
      fatPer100g: 68.4,
    ),
    FoodNutrition(
      name: '榛子',
      aliases: ['榛子'],
      caloriesPer100g: 628,
      proteinPer100g: 14.9,
      carbsPer100g: 16.7,
      fatPer100g: 60.8,
    ),
    FoodNutrition(
      name: '夏威夷果',
      aliases: ['夏威夷果', '澳洲坚果'],
      caloriesPer100g: 718,
      proteinPer100g: 7.9,
      carbsPer100g: 13.8,
      fatPer100g: 75.8,
    ),
    FoodNutrition(
      name: '椰肉',
      aliases: ['椰肉', '椰子肉'],
      caloriesPer100g: 354,
      proteinPer100g: 3.3,
      carbsPer100g: 15.2,
      fatPer100g: 33.5,
    ),
    FoodNutrition(
      name: '无糖乌龙茶',
      aliases: ['乌龙茶', '无糖乌龙茶'],
      caloriesPer100g: 1,
      proteinPer100g: 0,
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

enum NutritionGoal { fatLoss, maintenance, muscleGain }

extension NutritionGoalDetails on NutritionGoal {
  String get label => switch (this) {
    NutritionGoal.fatLoss => '减脂',
    NutritionGoal.maintenance => '维持',
    NutritionGoal.muscleGain => '增肌',
  };

  String get description => switch (this) {
    NutritionGoal.fatLoss => '热量小幅赤字，优先保留瘦体重',
    NutritionGoal.maintenance => '围绕当前体重维持热量平衡',
    NutritionGoal.muscleGain => '温和热量盈余，支持训练恢复',
  };
}

/// Product-owned nutrition strategy parameters.
///
/// Keep these values in one object so a future remote configuration can
/// replace them without changing the calculation pipeline.
class NutritionStrategyConfig {
  const NutritionStrategyConfig({
    this.fatLossCalorieFactor = .85,
    this.maintenanceCalorieFactor = 1.0,
    this.muscleGainCalorieFactor = 1.08,
    this.fatLossProteinPerLeanMassKg = 2.3,
    this.defaultProteinPerBodyWeightKg = 1.6,
    this.fatCalorieRatio = .25,
  });

  final double fatLossCalorieFactor;
  final double maintenanceCalorieFactor;
  final double muscleGainCalorieFactor;
  final double fatLossProteinPerLeanMassKg;
  final double defaultProteinPerBodyWeightKg;
  final double fatCalorieRatio;

  double calorieFactorFor(NutritionGoal goal) => switch (goal) {
    NutritionGoal.fatLoss => fatLossCalorieFactor,
    NutritionGoal.maintenance => maintenanceCalorieFactor,
    NutritionGoal.muscleGain => muscleGainCalorieFactor,
  };
}

class DailyNutritionTarget {
  const DailyNutritionTarget({
    required this.goal,
    required this.leanBodyMassKg,
    required this.restingMetabolicRate,
    required this.activityFactor,
    required this.totalDailyEnergyExpenditure,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
  });

  final NutritionGoal goal;
  final double leanBodyMassKg;
  final double restingMetabolicRate;
  final double activityFactor;
  final double totalDailyEnergyExpenditure;
  final double calories;
  final double protein;
  final double carbs;
  final double fat;
}

class DailyNutritionCalculator {
  const DailyNutritionCalculator._();

  static double activityFactor(int trainingDays) {
    if (trainingDays <= 0) return 1.20;
    if (trainingDays <= 2) return 1.30;
    if (trainingDays <= 4) return 1.40;
    if (trainingDays <= 6) return 1.50;
    return 1.55;
  }

  static DailyNutritionTarget calculate({
    required TrainingProfile profile,
    NutritionGoal goal = NutritionGoal.fatLoss,
    NutritionStrategyConfig config = const NutritionStrategyConfig(),
  }) {
    final leanBodyMassKg =
        profile.bodyWeightKg * (1 - profile.bodyFatPercent / 100);
    final restingMetabolicRate = 370 + 21.6 * leanBodyMassKg;
    final activity = activityFactor(profile.trainingDays);
    final totalDailyEnergyExpenditure = restingMetabolicRate * activity;
    final calories =
        totalDailyEnergyExpenditure * config.calorieFactorFor(goal);
    final protein =
        goal == NutritionGoal.fatLoss
            ? leanBodyMassKg * config.fatLossProteinPerLeanMassKg
            : profile.bodyWeightKg * config.defaultProteinPerBodyWeightKg;
    final fat = calories * config.fatCalorieRatio / 9;
    final carbs = (calories - protein * 4 - fat * 9) / 4;

    return DailyNutritionTarget(
      goal: goal,
      leanBodyMassKg: leanBodyMassKg,
      restingMetabolicRate: restingMetabolicRate,
      activityFactor: activity,
      totalDailyEnergyExpenditure: totalDailyEnergyExpenditure,
      calories: calories,
      protein: protein,
      carbs: carbs,
      fat: fat,
    );
  }
}

class NutritionTotals {
  const NutritionTotals({
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.fiber,
    required this.sugar,
    required this.sodium,
  });

  factory NutritionTotals.fromEntries(Iterable<FoodEntry> entries) {
    var calories = 0.0;
    var protein = 0.0;
    var carbs = 0.0;
    var fat = 0.0;
    var fiber = 0.0;
    var sugar = 0.0;
    var sodium = 0.0;
    for (final entry in entries) {
      calories += entry.calories;
      protein += entry.protein;
      carbs += entry.carbs;
      fat += entry.fat;
      fiber += entry.fiber;
      sugar += entry.sugar;
      sodium += entry.sodium;
    }
    return NutritionTotals(
      calories: calories,
      protein: protein,
      carbs: carbs,
      fat: fat,
      fiber: fiber,
      sugar: sugar,
      sodium: sodium,
    );
  }

  final double calories;
  final double protein;
  final double carbs;
  final double fat;
  final double fiber;
  final double sugar;
  final double sodium;
}
