import 'dart:async';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class PlantDatabase {
  static final PlantDatabase instance = PlantDatabase._init();
  static Database? _database;

  PlantDatabase._init();

  Future<Database> get database async {
    if (_database != null) return _database!;

    _database = await _initDB('plants.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE plants (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        plant_name TEXT NOT NULL,
        common_names TEXT,
        probability REAL NOT NULL,
        image_path TEXT NOT NULL
      )
    ''');
  }

  Future<int> insertPlant(Map<String, dynamic> plantData) async {
    final db = await instance.database;
    return await db.insert('plants', plantData);
  }

  Future<List<Map<String, dynamic>>> fetchPlants() async {
    final db = await instance.database;
    return await db.query('plants');
  }

  Future<int> deletePlant(int id) async {
    final db = await instance.database;
    return await db.delete('plants', where: 'id = ?', whereArgs: [id]);
  }

  Future close() async {
    final db = await instance.database;
    db.close();
  }
}
