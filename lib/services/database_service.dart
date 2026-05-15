import 'dart:convert';

import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../models/plant.dart';
import '../models/recognition_record.dart';
import '../models/recognition_result.dart';

class DatabaseService {
  static Database? _db;
  static const String _databaseName = 'plants.db';
  static const int _version = 3;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDatabase();
    return _db!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = join(await getDatabasesPath(), _databaseName);
    return openDatabase(
      dbPath,
      version: _version,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: (db, version) async {
        await _createSchema(db);
        await _seedPlants(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        await _runMigrations(db, oldVersion, newVersion);
      },
    );
  }

  Future<void> _createSchema(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS plants (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        common_name TEXT NOT NULL,
        scientific_name TEXT NOT NULL UNIQUE,
        family TEXT NOT NULL,
        description TEXT NOT NULL,
        habitat TEXT NOT NULL,
        uses_json TEXT NOT NULL,
        aliases_json TEXT NOT NULL,
        image_path TEXT NOT NULL,
        is_favorite INTEGER NOT NULL DEFAULT 0,
        is_offline_available INTEGER NOT NULL DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS recognition_records (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        plant_id INTEGER NOT NULL,
        image_path TEXT NOT NULL,
        confidence REAL NOT NULL,
        captured_at TEXT NOT NULL,
        raw_json TEXT NOT NULL,
        FOREIGN KEY (plant_id) REFERENCES plants (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_plants_common_name
      ON plants (common_name)
    ''');
    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_plants_is_favorite
      ON plants (is_favorite)
    ''');
    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_recognition_records_captured_at
      ON recognition_records (captured_at DESC)
    ''');
  }

  Future<void> _runMigrations(
    Database db,
    int oldVersion,
    int newVersion,
  ) async {
    if (oldVersion < 3) {
      await _createSchema(db);
      await _seedPlants(db);
    }

    if (newVersion > oldVersion) {
      await _createSchema(db);
    }
  }

  Future<void> _seedPlants(Database db) async {
    final seedPlants = <Plant>[
      Plant(
        commonName: 'Cây Trầu Bà',
        scientificName: 'Epipremnum aureum',
        family: 'Araceae',
        description:
            'Cây leo thân mềm, dễ sống, thường được trồng trong nhà để trang trí và lọc không khí.',
        habitat: 'Rừng nhiệt đới ẩm, khu vực bóng bán phần.',
        uses: ['Trang trí nội thất', 'Thanh lọc không khí'],
        aliases: const ['Pothos', 'Devil\'s ivy'],
        imagePath: '',
        isOfflineAvailable: true,
      ),
      Plant(
        commonName: 'Cây Monstera',
        scientificName: 'Monstera deliciosa',
        family: 'Araceae',
        description:
            'Lá xẻ đặc trưng, sinh trưởng mạnh trong điều kiện ẩm và sáng tán xạ.',
        habitat: 'Tầng dưới của rừng mưa nhiệt đới.',
        uses: ['Cây cảnh nội thất', 'Tạo mảng xanh'],
        aliases: const ['Swiss cheese plant'],
        imagePath: '',
        isOfflineAvailable: true,
      ),
      Plant(
        commonName: 'Cây Lưỡi Hổ',
        scientificName: 'Dracaena trifasciata',
        family: 'Asparagaceae',
        description:
            'Lá mọc thẳng, chịu hạn tốt, thích hợp không gian trong nhà.',
        habitat: 'Khí hậu khô nóng, vùng bán khô hạn.',
        uses: ['Trang trí', 'Chịu hạn tốt cho cảnh quan'],
        aliases: const ['Snake plant'],
        imagePath: '',
        isOfflineAvailable: true,
      ),
      Plant(
        commonName: 'Cây Bàng Singapore',
        scientificName: 'Ficus lyrata',
        family: 'Moraceae',
        description:
            'Lá lớn dạng đàn lia, được ưa chuộng làm cây nội thất cao cấp.',
        habitat: 'Rừng nhiệt đới Tây Phi.',
        uses: ['Trang trí không gian', 'Tạo điểm nhấn kiến trúc'],
        aliases: const ['Fiddle-leaf fig'],
        imagePath: '',
        isOfflineAvailable: true,
      ),
      Plant(
        commonName: 'Cây Lan Ý',
        scientificName: 'Spathiphyllum wallisii',
        family: 'Araceae',
        description:
            'Cây bụi thân thảo, hoa trắng tinh, phù hợp môi trường trong nhà.',
        habitat: 'Rừng nhiệt đới ẩm và khu vực nhiều bóng râm.',
        uses: ['Trang trí', 'Cải thiện không khí'],
        aliases: const ['Peace lily'],
        imagePath: '',
        isOfflineAvailable: true,
      ),
      Plant(
        commonName: 'Cây Kim Tiền',
        scientificName: 'Zamioculcas zamiifolia',
        family: 'Araceae',
        description: 'Lá xanh bóng, chịu thiếu sáng và thiếu nước rất tốt.',
        habitat: 'Vùng Đông Phi khô hạn.',
        uses: ['Trang trí văn phòng', 'Dễ chăm sóc'],
        aliases: const ['ZZ plant'],
        imagePath: '',
        isOfflineAvailable: true,
      ),
    ];

    final batch = db.batch();
    for (final plant in seedPlants) {
      batch.insert(
        'plants',
        plant.toMap(),
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    }
    await batch.commit(noResult: true);
  }

  Future<int> upsertPlant(Plant plant) async {
    final db = await database;
    final existing = await db.query(
      'plants',
      columns: ['id', 'is_favorite'],
      where: 'scientific_name = ?',
      whereArgs: [plant.scientificName],
      limit: 1,
    );

    if (existing.isNotEmpty) {
      final id = existing.first['id'] as int;
      final favorite = (existing.first['is_favorite'] as int? ?? 0) == 1;
      await db.update(
        'plants',
        plant.copyWith(id: id, isFavorite: favorite).toMap(),
        where: 'id = ?',
        whereArgs: [id],
      );
      return id;
    }

    return db.insert(
      'plants',
      plant.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<Plant> saveRecognition(
    RecognitionResult result, {
    required String imagePath,
  }) async {
    final db = await database;
    final plant = result.toPlant().copyWith(
          imagePath: imagePath,
          isOfflineAvailable: true,
        );
    final plantId = await upsertPlant(plant);

    await db.insert('recognition_records', {
      'plant_id': plantId,
      'image_path': imagePath,
      'confidence': result.primary.confidence,
      'captured_at': DateTime.now().toIso8601String(),
      'raw_json': jsonEncode({
        'primary': result.primary.toMap(),
        'alternatives': result.alternatives.map((item) => item.toMap()).toList(),
        'analysis_note': result.analysisNote,
      }),
    });

    return plant.copyWith(id: plantId);
  }

  Future<List<Plant>> getAllPlants({String query = ''}) async {
    final db = await database;
    final normalized = query.trim().toLowerCase();
    final maps = await db.query(
      'plants',
      where: normalized.isEmpty
          ? null
          : '''
            lower(common_name) LIKE ? OR
            lower(scientific_name) LIKE ? OR
            lower(family) LIKE ? OR
            lower(description) LIKE ?
          ''',
      whereArgs: normalized.isEmpty
          ? null
          : [
              '%$normalized%',
              '%$normalized%',
              '%$normalized%',
              '%$normalized%',
            ],
      orderBy: 'common_name COLLATE NOCASE ASC',
    );
    return maps.map(Plant.fromMap).toList(growable: false);
  }

  Future<List<Plant>> getFavoritePlants() async {
    final db = await database;
    final maps = await db.query(
      'plants',
      where: 'is_favorite = 1',
      orderBy: 'common_name COLLATE NOCASE ASC',
    );
    return maps.map(Plant.fromMap).toList(growable: false);
  }

  Future<List<RecognitionRecord>> getHistory() async {
    final db = await database;
    final maps = await db.rawQuery('''
      SELECT
        records.id AS record_id,
        records.image_path AS record_image_path,
        records.confidence AS record_confidence,
        records.captured_at AS record_captured_at,
        plants.*
      FROM recognition_records AS records
      INNER JOIN plants ON plants.id = records.plant_id
      ORDER BY records.captured_at DESC, records.id DESC
    ''');
    return maps.map(RecognitionRecord.fromMap).toList(growable: false);
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
