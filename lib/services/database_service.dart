// lib/services/database_service.dart
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/plant.dart';

class DatabaseService {
  static Database? _db;
  static const String _databaseName = 'plants.db';
  static const int _version = 1;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDatabase();
    return _db!;
  }

  Future<Database> _initDatabase() async {
    final path = join(await getDatabasesPath(), _databaseName);
    return await openDatabase(
      path,
      version: _version,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE plants (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT,
            scientific_name TEXT,
            description TEXT,
            image_path TEXT,
            is_favorite INTEGER
          )
        ''');
        await db.execute('''
          CREATE TABLE history (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            plant_id INTEGER,
            timestamp TEXT,
            FOREIGN KEY (plant_id) REFERENCES plants (id)
          )
        ''');
      },
    );
  }

  Future<void> savePlant(Plant plant) async {
    final db = await database;
    final plantId = await db.insert('plants', plant.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);

    // Lưu vào lịch sử
    await db.insert('history', {
      'plant_id': plantId,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  Future<List<Plant>> getFavorites() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'plants',
      where: 'is_favorite = ?',
      whereArgs: [1],
    );
    return List.generate(maps.length, (i) => Plant.fromMap(maps[i]));
  }

  Future<List<Plant>> getHistory() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT plants.* FROM plants
      JOIN history ON plants.id = history.plant_id
      ORDER BY history.timestamp DESC
    ''');
    return List.generate(maps.length, (i) => Plant.fromMap(maps[i]));
  }

  Future<void> toggleFavorite(int plantId, bool isFavorite) async {
    final db = await database;
    await db.update(
      'plants',
      {'is_favorite': isFavorite ? 1 : 0},
      where: 'id = ?',
      whereArgs: [plantId],
    );
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
  }
}
