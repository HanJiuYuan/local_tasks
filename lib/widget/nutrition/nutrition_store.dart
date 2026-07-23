import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'nutrition_models.dart';

class NutritionStore {
  static Database? _sharedDatabase;
  static final _testEntries = <FoodEntry>[];
  static var _testNextId = 1;
  static NutritionGoal _testGoal = NutritionGoal.fatLoss;
  Database? _database;

  static bool get _isFlutterTest =>
      Platform.environment['FLUTTER_TEST'] == 'true';

  Future<Database> get _db async {
    final existing = _database ?? _sharedDatabase;
    if (existing != null) return existing;

    final databasePath = await _databasePath();
    final opened = await openDatabase(
      databasePath,
      version: 4,
      onCreate: (database, _) async {
        await database.execute('''
CREATE TABLE food_entries (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL,
  meal INTEGER NOT NULL,
  grams REAL NOT NULL,
  calories REAL NOT NULL,
  protein REAL NOT NULL,
  carbs REAL NOT NULL,
  fat REAL NOT NULL,
  fiber REAL NOT NULL DEFAULT 0,
  sugar REAL NOT NULL DEFAULT 0,
  sodium REAL NOT NULL DEFAULT 0,
  calories_per_100g REAL,
  protein_per_100g REAL,
  carbs_per_100g REAL,
  fat_per_100g REAL,
  fiber_per_100g REAL,
  sugar_per_100g REAL,
  sodium_per_100g REAL,
  created_at INTEGER NOT NULL
)
''');
        await database.execute(
          'CREATE INDEX idx_food_entries_created_at '
          'ON food_entries(created_at)',
        );
        await database.execute('''
CREATE TABLE nutrition_settings (
  id INTEGER PRIMARY KEY,
  goal INTEGER NOT NULL
)
''');
      },
      onUpgrade: (database, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await database.execute(
            'ALTER TABLE food_entries ADD COLUMN '
            'fiber REAL NOT NULL DEFAULT 0',
          );
          await database.execute(
            'ALTER TABLE food_entries ADD COLUMN '
            'sugar REAL NOT NULL DEFAULT 0',
          );
          await database.execute(
            'ALTER TABLE food_entries ADD COLUMN '
            'sodium REAL NOT NULL DEFAULT 0',
          );
        }
        if (oldVersion < 3) {
          for (final column in const [
            'calories_per_100g REAL',
            'protein_per_100g REAL',
            'carbs_per_100g REAL',
            'fat_per_100g REAL',
            'fiber_per_100g REAL',
            'sugar_per_100g REAL',
            'sodium_per_100g REAL',
          ]) {
            await database.execute(
              'ALTER TABLE food_entries ADD COLUMN $column',
            );
          }
        }
        if (oldVersion < 4) {
          await database.execute('''
CREATE TABLE IF NOT EXISTS nutrition_settings (
  id INTEGER PRIMARY KEY,
  goal INTEGER NOT NULL
)
''');
        }
      },
    );
    _sharedDatabase = opened;
    _database = opened;
    return _database!;
  }

  Future<String> _databasePath() async {
    if (Platform.environment['FLUTTER_TEST'] == 'true') {
      return inMemoryDatabasePath;
    }
    final directory = await getApplicationDocumentsDirectory();
    return path.join(directory.path, 'nutrition.db');
  }

  Future<List<FoodEntry>> loadForDate(DateTime date) async {
    final (start, end) = _dayBounds(date);
    if (_isFlutterTest) {
      return _testEntries
          .where(
            (entry) =>
                !entry.createdAt.isBefore(start) &&
                entry.createdAt.isBefore(end),
          )
          .toList();
    }
    final database = await _db;
    final rows = await database.query(
      'food_entries',
      where: 'created_at >= ? AND created_at < ?',
      whereArgs: [start.millisecondsSinceEpoch, end.millisecondsSinceEpoch],
      orderBy: 'created_at ASC, id ASC',
    );
    return rows.map(_fromRow).toList();
  }

  /// Loads records before [before]'s local calendar day for the history view.
  Future<List<FoodEntry>> loadHistory({DateTime? before}) async {
    final cutoff = _dayBounds(before ?? DateTime.now()).$1;
    if (_isFlutterTest) {
      final entries =
          _testEntries
              .where((entry) => entry.createdAt.isBefore(cutoff))
              .toList();
      entries.sort(_compareNewestFirst);
      return entries;
    }
    final database = await _db;
    final rows = await database.query(
      'food_entries',
      where: 'created_at < ?',
      whereArgs: [cutoff.millisecondsSinceEpoch],
      orderBy: 'created_at DESC, id DESC',
    );
    return rows.map(_fromRow).toList();
  }

  Future<int> insert(FoodEntry entry) async {
    if (_isFlutterTest) {
      final id = _testNextId++;
      _testEntries.add(entry.copyWith(id: id));
      return id;
    }
    final database = await _db;
    return database.insert('food_entries', _toRow(entry));
  }

  Future<NutritionGoal> loadGoal() async {
    if (_isFlutterTest) return _testGoal;
    final database = await _db;
    final rows = await database.query(
      'nutrition_settings',
      where: 'id = 1',
      limit: 1,
    );
    if (rows.isEmpty) return NutritionGoal.fatLoss;
    final index = (rows.first['goal'] as int? ?? 0).clamp(
      0,
      NutritionGoal.values.length - 1,
    );
    return NutritionGoal.values[index];
  }

  Future<void> saveGoal(NutritionGoal goal) async {
    if (_isFlutterTest) {
      _testGoal = goal;
      return;
    }
    final database = await _db;
    await database.insert('nutrition_settings', {
      'id': 1,
      'goal': goal.index,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> delete(int? id) async {
    if (id == null) return;
    if (_isFlutterTest) {
      _testEntries.removeWhere((entry) => entry.id == id);
      return;
    }
    final database = await _db;
    await database.delete('food_entries', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> clear() async {
    if (_isFlutterTest) {
      _testEntries.clear();
      _testNextId = 1;
      _testGoal = NutritionGoal.fatLoss;
      return;
    }
    final database = await _db;
    await database.delete('food_entries');
  }

  FoodEntry _fromRow(Map<String, Object?> row) {
    final mealIndex = row['meal'] as int? ?? 0;
    final safeMealIndex = mealIndex.clamp(0, MealType.values.length - 1);
    final name = row['name'] as String? ?? '';
    final grams = (row['grams'] as num?)?.toDouble() ?? 0;
    final calculatedExtras = FoodDatabase.find(name)?.calculate(grams);
    final sourceNutrition = _nutritionFromRow(row);
    return FoodEntry(
      id: row['id'] as int?,
      name: name,
      meal: MealType.values[safeMealIndex],
      grams: grams,
      calories: (row['calories'] as num?)?.toDouble() ?? 0,
      protein: (row['protein'] as num?)?.toDouble() ?? 0,
      carbs: (row['carbs'] as num?)?.toDouble() ?? 0,
      fat: (row['fat'] as num?)?.toDouble() ?? 0,
      fiber: _storedOrCalculated(row['fiber'], calculatedExtras?.fiber),
      sugar: _storedOrCalculated(row['sugar'], calculatedExtras?.sugar),
      sodium: _storedOrCalculated(row['sodium'], calculatedExtras?.sodium),
      nutritionPer100g: sourceNutrition,
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        (row['created_at'] as num?)?.toInt() ?? 0,
      ),
    );
  }

  double _storedOrCalculated(Object? stored, double? calculated) {
    final value = (stored as num?)?.toDouble();
    if (value != null && value > 0) return value;
    return calculated ?? 0;
  }

  Map<String, Object?> _toRow(FoodEntry entry) {
    final source = entry.nutritionPer100g;
    return {
      'name': entry.name,
      'meal': entry.meal.index,
      'grams': entry.grams,
      'calories': entry.calories,
      'protein': entry.protein,
      'carbs': entry.carbs,
      'fat': entry.fat,
      'fiber': entry.fiber,
      'sugar': entry.sugar,
      'sodium': entry.sodium,
      'calories_per_100g': source?.calories,
      'protein_per_100g': source?.protein,
      'carbs_per_100g': source?.carbs,
      'fat_per_100g': source?.fat,
      'fiber_per_100g': source?.fiber,
      'sugar_per_100g': source?.sugar,
      'sodium_per_100g': source?.sodium,
      'created_at': entry.createdAt.millisecondsSinceEpoch,
    };
  }

  Nutrition? _nutritionFromRow(Map<String, Object?> row) {
    final calories = (row['calories_per_100g'] as num?)?.toDouble();
    if (calories == null) return null;
    return Nutrition(
      calories: calories,
      protein: (row['protein_per_100g'] as num?)?.toDouble() ?? 0,
      carbs: (row['carbs_per_100g'] as num?)?.toDouble() ?? 0,
      fat: (row['fat_per_100g'] as num?)?.toDouble() ?? 0,
      fiber: (row['fiber_per_100g'] as num?)?.toDouble() ?? 0,
      sugar: (row['sugar_per_100g'] as num?)?.toDouble() ?? 0,
      sodium: (row['sodium_per_100g'] as num?)?.toDouble() ?? 0,
    );
  }

  (DateTime, DateTime) _dayBounds(DateTime date) {
    final start = DateTime(date.year, date.month, date.day);
    return (start, start.add(const Duration(days: 1)));
  }

  int _compareNewestFirst(FoodEntry a, FoodEntry b) {
    final dateComparison = b.createdAt.compareTo(a.createdAt);
    if (dateComparison != 0) return dateComparison;
    return (b.id ?? 0).compareTo(a.id ?? 0);
  }
}
