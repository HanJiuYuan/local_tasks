import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'nutrition_models.dart';

class NutritionStore {
  static Database? _sharedDatabase;
  static final _testEntries = <FoodEntry>[];
  static var _testNextId = 1;
  Database? _database;

  static bool get _isFlutterTest =>
      Platform.environment['FLUTTER_TEST'] == 'true';

  Future<Database> get _db async {
    final existing = _database ?? _sharedDatabase;
    if (existing != null) return existing;

    final databasePath = await _databasePath();
    final opened = await openDatabase(
      databasePath,
      version: 1,
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
  created_at INTEGER NOT NULL
)
''');
        await database.execute(
          'CREATE INDEX idx_food_entries_created_at '
          'ON food_entries(created_at)',
        );
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
    if (_isFlutterTest) {
      final start = DateTime(date.year, date.month, date.day);
      final end = start.add(const Duration(days: 1));
      return _testEntries
          .where(
            (entry) =>
                !entry.createdAt.isBefore(start) &&
                entry.createdAt.isBefore(end),
          )
          .toList();
    }
    final database = await _db;
    final start = DateTime(date.year, date.month, date.day);
    final end = start.add(const Duration(days: 1));
    final rows = await database.query(
      'food_entries',
      where: 'created_at >= ? AND created_at < ?',
      whereArgs: [start.millisecondsSinceEpoch, end.millisecondsSinceEpoch],
      orderBy: 'created_at ASC, id ASC',
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
      return;
    }
    final database = await _db;
    await database.delete('food_entries');
  }

  FoodEntry _fromRow(Map<String, Object?> row) {
    final mealIndex = row['meal'] as int? ?? 0;
    final safeMealIndex = mealIndex.clamp(0, MealType.values.length - 1);
    return FoodEntry(
      id: row['id'] as int?,
      name: row['name'] as String? ?? '',
      meal: MealType.values[safeMealIndex],
      grams: (row['grams'] as num?)?.toDouble() ?? 0,
      calories: (row['calories'] as num?)?.toDouble() ?? 0,
      protein: (row['protein'] as num?)?.toDouble() ?? 0,
      carbs: (row['carbs'] as num?)?.toDouble() ?? 0,
      fat: (row['fat'] as num?)?.toDouble() ?? 0,
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        (row['created_at'] as num?)?.toInt() ?? 0,
      ),
    );
  }

  Map<String, Object?> _toRow(FoodEntry entry) {
    return {
      'name': entry.name,
      'meal': entry.meal.index,
      'grams': entry.grams,
      'calories': entry.calories,
      'protein': entry.protein,
      'carbs': entry.carbs,
      'fat': entry.fat,
      'created_at': entry.createdAt.millisecondsSinceEpoch,
    };
  }
}
