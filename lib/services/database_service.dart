import 'dart:convert';

import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../models/plant.dart';
import '../models/recognition_record.dart';
import '../models/recognition_result.dart';

class DatabaseService {
  static Database? _db;
  static const String _databaseName = 'plants.db';
  static const int _version = 4;

  static const Map<String, String> _plantColumnDefinitions =
      <String, String>{
    'aliases_json': "TEXT NOT NULL DEFAULT '[]'",
    'english_name': "TEXT NOT NULL DEFAULT ''",
    'light_requirement': "TEXT NOT NULL DEFAULT ''",
    'watering_needs': "TEXT NOT NULL DEFAULT ''",
    'care_level': "TEXT NOT NULL DEFAULT ''",
    'suitable_temperature': "TEXT NOT NULL DEFAULT ''",
    'soil_type': "TEXT NOT NULL DEFAULT ''",
    'fertilizing_tips': "TEXT NOT NULL DEFAULT ''",
    'toxicity_warning': "TEXT NOT NULL DEFAULT ''",
    'maximum_size': "TEXT NOT NULL DEFAULT ''",
    'feng_shui_meaning': "TEXT NOT NULL DEFAULT ''",
    'origin': "TEXT NOT NULL DEFAULT ''",
    'common_issues': "TEXT NOT NULL DEFAULT ''",
  };

  static const List<String> _searchColumns = <String>[
    'common_name',
    'english_name',
    'scientific_name',
    'family',
    'description',
    'habitat',
    'aliases_json',
    'uses_json',
    'light_requirement',
    'watering_needs',
    'care_level',
    'suitable_temperature',
    'soil_type',
    'fertilizing_tips',
    'toxicity_warning',
    'maximum_size',
    'feng_shui_meaning',
    'origin',
    'common_issues',
  ];

  Future<Database> get database async {
    if (_db != null) {
      return _db!;
    }
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
        aliases_json TEXT NOT NULL DEFAULT '[]',
        english_name TEXT NOT NULL DEFAULT '',
        scientific_name TEXT NOT NULL UNIQUE,
        family TEXT NOT NULL,
        description TEXT NOT NULL,
        habitat TEXT NOT NULL,
        light_requirement TEXT NOT NULL DEFAULT '',
        watering_needs TEXT NOT NULL DEFAULT '',
        care_level TEXT NOT NULL DEFAULT '',
        suitable_temperature TEXT NOT NULL DEFAULT '',
        soil_type TEXT NOT NULL DEFAULT '',
        fertilizing_tips TEXT NOT NULL DEFAULT '',
        toxicity_warning TEXT NOT NULL DEFAULT '',
        uses_json TEXT NOT NULL,
        maximum_size TEXT NOT NULL DEFAULT '',
        feng_shui_meaning TEXT NOT NULL DEFAULT '',
        origin TEXT NOT NULL DEFAULT '',
        common_issues TEXT NOT NULL DEFAULT '',
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
      CREATE INDEX IF NOT EXISTS idx_plants_scientific_name
      ON plants (scientific_name)
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
    await _createSchema(db);

    if (oldVersion < 4) {
      await _ensurePlantColumns(db);
      await _seedPlants(db);
    }

    if (newVersion > oldVersion) {
      await _ensurePlantColumns(db);
    }
  }

  Future<void> _ensurePlantColumns(Database db) async {
    final columns = await db.rawQuery('PRAGMA table_info(plants)');
    final existingNames = columns
        .map((item) => item['name']?.toString() ?? '')
        .where((name) => name.isNotEmpty)
        .toSet();

    for (final entry in _plantColumnDefinitions.entries) {
      if (!existingNames.contains(entry.key)) {
        await db.execute(
          'ALTER TABLE plants ADD COLUMN ${entry.key} ${entry.value}',
        );
      }
    }
  }

  Future<void> _seedPlants(Database db) async {
    final seedPlants = <Plant>[
      const Plant(
        commonName: 'Trầu bà',
        aliases: <String>['Hoàng tâm diệp', 'Pothos', 'Devil\'s ivy'],
        englishName: 'Golden pothos',
        scientificName: 'Epipremnum aureum',
        family: 'Araceae',
        description:
            'Cây dây leo lá tim xanh pha vàng, sinh trưởng khỏe và rất phổ biến trong không gian nội thất.',
        habitat: 'Rừng mưa nhiệt đới ẩm, nơi có ánh sáng tán xạ và độ ẩm cao.',
        lightRequirement:
            'Ưa ánh sáng gián tiếp sáng; tránh nắng gắt chiếu trực tiếp vào buổi trưa.',
        wateringNeeds:
            'Tưới khi mặt đất khô khoảng 2-3 cm, giữ ẩm vừa phải và không để úng.',
        careLevel: 'Dễ',
        suitableTemperature: '18-30°C, tránh gió lạnh và nhiệt độ dưới 12°C.',
        soilType:
            'Đất tơi xốp, giàu mùn, thoát nước tốt như hỗn hợp xơ dừa, perlite và đất sạch.',
        fertilizingTips:
            'Bón phân NPK cân bằng hoặc phân hữu cơ loãng mỗi 4-6 tuần vào mùa sinh trưởng.',
        toxicityWarning:
            'Có chứa tinh thể calcium oxalate, không an toàn nếu trẻ nhỏ hoặc thú cưng nhai phải.',
        uses: <String>['Trang trí nội thất', 'Thanh lọc không khí', 'Tạo mảng xanh'],
        maximumSize: 'Dài khoảng 1-3 m trong nhà nếu có giá thể leo bám phù hợp.',
        fengShuiMeaning:
            'Thường được xem là tượng trưng cho tài lộc và sức sống, hợp đặt ở bàn làm việc hoặc cửa sổ sáng.',
        origin: 'Đảo Solomon và khu vực nhiệt đới Đông Nam Á.',
        commonIssues:
            'Lá vàng do tưới quá tay, cháy mép lá do nắng gắt, rệp sáp và nhện đỏ khi không khí quá khô.',
        imagePath: '',
        isOfflineAvailable: true,
      ),
      const Plant(
        commonName: 'Monstera',
        aliases: <String>['Trầu bà lá xẻ', 'Swiss cheese plant'],
        englishName: 'Monstera',
        scientificName: 'Monstera deliciosa',
        family: 'Araceae',
        description:
            'Cây lá lớn có vết xẻ đặc trưng, tạo cảm giác nhiệt đới và là điểm nhấn nổi bật trong không gian sống.',
        habitat: 'Tầng dưới rừng mưa nhiệt đới, khí hậu ấm và ẩm.',
        lightRequirement:
            'Ánh sáng gián tiếp mạnh là lý tưởng; thiếu sáng cây chậm lớn và lá ít xẻ hơn.',
        wateringNeeds:
            'Tưới khi lớp đất mặt bắt đầu khô, tránh để nước đọng lâu trong chậu.',
        careLevel: 'Trung bình',
        suitableTemperature: '20-30°C, phát triển tốt trong môi trường ấm và ẩm.',
        soilType:
            'Hỗn hợp đất thoáng khí, nhiều chất hữu cơ, thoát nước nhanh nhưng vẫn giữ ẩm vừa phải.',
        fertilizingTips:
            'Bón phân lá hoặc NPK loãng 2-4 tuần/lần vào mùa phát triển để hỗ trợ lá to đẹp.',
        toxicityWarning:
            'Có thể gây kích ứng miệng và tiêu hóa nếu thú cưng hoặc trẻ em ăn phải.',
        uses: <String>['Cây cảnh nội thất', 'Tạo điểm nhấn nhiệt đới', 'Trang trí phòng khách'],
        maximumSize: 'Có thể cao 2-4 m trong điều kiện chăm sóc tốt và có trụ leo.',
        fengShuiMeaning:
            'Lá xẻ lớn thường gợi cảm giác khai mở, phát triển và thu hút năng lượng tích cực.',
        origin: 'Nam Mexico đến Panama.',
        commonIssues:
            'Lá úa vàng do úng rễ, mép lá nâu do thiếu ẩm, lá non không xẻ do thiếu sáng hoặc thiếu dinh dưỡng.',
        imagePath: '',
        isOfflineAvailable: true,
      ),
      const Plant(
        commonName: 'Lưỡi hổ',
        aliases: <String>['Cây lưỡi cọp', 'Snake plant'],
        englishName: 'Snake plant',
        scientificName: 'Dracaena trifasciata',
        family: 'Asparagaceae',
        description:
            'Lá mọc thẳng, cứng cáp, chịu hạn tốt và phù hợp với người mới bắt đầu chăm cây.',
        habitat: 'Vùng bán khô hạn, khí hậu nóng và khô.',
        lightRequirement:
            'Chịu được từ ánh sáng văn phòng đến nắng nhẹ; vẫn đẹp nhất ở nơi sáng gián tiếp.',
        wateringNeeds:
            'Tưới thưa, chỉ tưới khi đất khô hẳn để tránh thối rễ.',
        careLevel: 'Dễ',
        suitableTemperature: '18-32°C, chịu nóng tốt nhưng kém chịu rét sâu.',
        soilType:
            'Đất thoát nước tốt, ưu tiên hỗn hợp dành cho sen đá hoặc xương rồng.',
        fertilizingTips:
            'Bón rất nhẹ 1-2 tháng/lần vào mùa sinh trưởng, tránh bón nhiều khiến cây mềm lá.',
        toxicityWarning:
            'Có độc tính nhẹ nếu ăn phải, nên đặt ngoài tầm với của thú cưng nhạy cảm.',
        uses: <String>['Trang trí', 'Dễ chăm sóc', 'Phù hợp phòng ngủ hoặc văn phòng'],
        maximumSize: 'Thường cao 40-120 cm tùy giống và môi trường sống.',
        fengShuiMeaning:
            'Thường được ưa chuộng để trấn giữ, hút khí xấu và tạo cảm giác mạnh mẽ, vững vàng.',
        origin: 'Tây Phi nhiệt đới.',
        commonIssues:
            'Thối gốc do dư nước, lá nhăn do thiếu nước kéo dài, đốm lá do nấm khi độ ẩm quá cao.',
        imagePath: '',
        isOfflineAvailable: true,
      ),
      const Plant(
        commonName: 'Bàng Singapore',
        aliases: <String>['Fiddle-leaf fig'],
        englishName: 'Fiddle-leaf fig',
        scientificName: 'Ficus lyrata',
        family: 'Moraceae',
        description:
            'Cây thân gỗ nhỏ với lá to bản như cây đàn, mang vẻ hiện đại và sang trọng.',
        habitat: 'Rừng mưa nhiệt đới Tây Phi.',
        lightRequirement:
            'Cần nơi rất sáng, ưu tiên gần cửa sổ có nắng nhẹ buổi sáng hoặc ánh sáng gián tiếp mạnh.',
        wateringNeeds:
            'Tưới khi đất khô khoảng 3-5 cm; cần đều đặn nhưng không để đất quá ẩm.',
        careLevel: 'Trung bình',
        suitableTemperature: '18-28°C, tránh thay đổi nhiệt độ đột ngột và gió lạnh mạnh.',
        soilType:
            'Đất tơi xốp, giàu hữu cơ, thoát nước tốt để rễ không bị bí.',
        fertilizingTips:
            'Bón phân cân bằng mỗi tháng một lần vào mùa xuân và mùa hè.',
        toxicityWarning:
            'Nhựa cây có thể gây kích ứng da và không nên để thú cưng gặm lá.',
        uses: <String>['Trang trí không gian', 'Tạo điểm nhấn nội thất', 'Phủ xanh góc phòng'],
        maximumSize: 'Có thể cao 1,5-3 m trong nhà nếu chăm sóc ổn định.',
        fengShuiMeaning:
            'Tượng trưng cho sự phát triển, thăng tiến và vẻ sang trọng của không gian sống.',
        origin: 'Tây và Trung Phi.',
        commonIssues:
            'Rụng lá do thay đổi môi trường, đốm nâu do úng hoặc lạnh, mép lá cháy do thiếu ẩm hoặc nắng gắt.',
        imagePath: '',
        isOfflineAvailable: true,
      ),
      const Plant(
        commonName: 'Lan ý',
        aliases: <String>['Bạch môn', 'Peace lily'],
        englishName: 'Peace lily',
        scientificName: 'Spathiphyllum wallisii',
        family: 'Araceae',
        description:
            'Cây bụi thân thảo với lá xanh bóng và mo hoa trắng thanh nhã, phù hợp không gian trong nhà.',
        habitat: 'Rừng nhiệt đới ẩm, nhiều bóng râm và độ ẩm cao.',
        lightRequirement:
            'Ưa bóng bán phần hoặc ánh sáng văn phòng sáng; tránh nắng trực tiếp gay gắt.',
        wateringNeeds:
            'Giữ đất hơi ẩm, tưới khi bề mặt vừa se khô; cây héo nhẹ là dấu hiệu cần nước.',
        careLevel: 'Trung bình',
        suitableTemperature: '18-30°C, thích khí hậu ấm và không khí có độ ẩm trung bình đến cao.',
        soilType:
            'Đất mùn nhẹ, thoát nước tốt nhưng giữ ẩm khá, thích hợp với than bùn và perlite.',
        fertilizingTips:
            'Bón phân loãng 4-6 tuần/lần trong mùa phát triển để hỗ trợ lá và hoa.',
        toxicityWarning:
            'Có thể gây kích ứng khi ăn phải, cần cẩn trọng với thú cưng và trẻ nhỏ.',
        uses: <String>['Trang trí', 'Làm dịu không gian', 'Phù hợp bàn làm việc và phòng khách'],
        maximumSize: 'Thường cao 40-80 cm khi trồng chậu trong nhà.',
        fengShuiMeaning:
            'Thường được xem là mang lại sự cân bằng, bình an và cảm giác hài hòa cho không gian.',
        origin: 'Trung Mỹ và khu vực nhiệt đới châu Mỹ.',
        commonIssues:
            'Lá cháy đầu do nước nhiều muối, rũ lá do thiếu nước, vàng lá do úng hoặc thiếu sáng kéo dài.',
        imagePath: '',
        isOfflineAvailable: true,
      ),
      const Plant(
        commonName: 'Kim tiền',
        aliases: <String>['ZZ plant', 'Zanzibar gem'],
        englishName: 'ZZ plant',
        scientificName: 'Zamioculcas zamiifolia',
        family: 'Araceae',
        description:
            'Cây có lá xanh bóng, thân mọng nước, chịu thiếu sáng và khô hạn rất tốt.',
        habitat: 'Vùng Đông Phi khô hạn, rừng thưa và đất thoát nước nhanh.',
        lightRequirement:
            'Phù hợp ánh sáng gián tiếp hoặc môi trường văn phòng; tránh nắng gắt chiếu trực tiếp lâu.',
        wateringNeeds:
            'Tưới ít, chỉ tưới khi đất đã khô sâu; cây rất dễ thối rễ nếu tưới dày.',
        careLevel: 'Dễ',
        suitableTemperature: '18-32°C, chịu nóng tốt và thích môi trường ổn định.',
        soilType:
            'Đất tơi thoáng, thoát nước tốt, có thể dùng đất trộn perlite hoặc hỗn hợp cho cây mọng nước.',
        fertilizingTips:
            'Bón phân nhẹ 1-2 tháng/lần trong mùa phát triển; không cần bón quá thường xuyên.',
        toxicityWarning:
            'Có độc tính nhẹ khi ăn phải, nên để xa thú cưng thích nhai lá.',
        uses: <String>['Trang trí văn phòng', 'Dễ chăm sóc', 'Phù hợp người bận rộn'],
        maximumSize: 'Có thể cao 60-120 cm trong điều kiện trong nhà.',
        fengShuiMeaning:
            'Thường gắn với ý nghĩa tài lộc, thịnh vượng và sự bền bỉ trong công việc.',
        origin: 'Đông Phi, đặc biệt là Kenya và Tanzania.',
        commonIssues:
            'Vàng lá và mềm gốc do úng, thân nhăn do quá khô lâu ngày, lá xỉn màu khi thiếu sáng kéo dài.',
        imagePath: '',
        isOfflineAvailable: true,
      ),
    ];

    for (final plant in seedPlants) {
      await _upsertPlantWithDatabase(db, plant);
    }
  }

  Future<int> _upsertPlantWithDatabase(Database db, Plant plant) async {
    final existing = await db.query(
      'plants',
      where: 'scientific_name = ?',
      whereArgs: <Object?>[plant.scientificName],
      limit: 1,
    );

    if (existing.isNotEmpty) {
      final existingPlant = Plant.fromMap(existing.first);
      final mergedPlant = _mergePlantData(
        incoming: plant,
        existing: existingPlant,
      ).copyWith(
        id: existingPlant.id,
        isFavorite: existingPlant.isFavorite,
        isOfflineAvailable:
            plant.isOfflineAvailable || existingPlant.isOfflineAvailable,
      );

      await db.update(
        'plants',
        mergedPlant.toMap(),
        where: 'id = ?',
        whereArgs: <Object?>[existingPlant.id],
      );
      return existingPlant.id!;
    }

    return db.insert(
      'plants',
      plant.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Plant _mergePlantData({
    required Plant incoming,
    required Plant existing,
  }) {
    String preferText(String next, String current) {
      return next.trim().isNotEmpty ? next : current;
    }

    List<String> preferList(List<String> next, List<String> current) {
      return next.isNotEmpty ? next : current;
    }

    return incoming.copyWith(
      id: existing.id,
      commonName: preferText(incoming.commonName, existing.commonName),
      aliases: preferList(incoming.aliases, existing.aliases),
      englishName: preferText(incoming.englishName, existing.englishName),
      scientificName: preferText(incoming.scientificName, existing.scientificName),
      family: preferText(incoming.family, existing.family),
      description: preferText(incoming.description, existing.description),
      habitat: preferText(incoming.habitat, existing.habitat),
      lightRequirement:
          preferText(incoming.lightRequirement, existing.lightRequirement),
      wateringNeeds: preferText(incoming.wateringNeeds, existing.wateringNeeds),
      careLevel: preferText(incoming.careLevel, existing.careLevel),
      suitableTemperature:
          preferText(incoming.suitableTemperature, existing.suitableTemperature),
      soilType: preferText(incoming.soilType, existing.soilType),
      fertilizingTips:
          preferText(incoming.fertilizingTips, existing.fertilizingTips),
      toxicityWarning:
          preferText(incoming.toxicityWarning, existing.toxicityWarning),
      uses: preferList(incoming.uses, existing.uses),
      maximumSize: preferText(incoming.maximumSize, existing.maximumSize),
      fengShuiMeaning:
          preferText(incoming.fengShuiMeaning, existing.fengShuiMeaning),
      origin: preferText(incoming.origin, existing.origin),
      commonIssues: preferText(incoming.commonIssues, existing.commonIssues),
      imagePath: preferText(incoming.imagePath, existing.imagePath),
      isFavorite: existing.isFavorite,
      isOfflineAvailable:
          incoming.isOfflineAvailable || existing.isOfflineAvailable,
    );
  }

  Future<int> upsertPlant(Plant plant) async {
    final db = await database;
    return _upsertPlantWithDatabase(db, plant);
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
    final plantId = await _upsertPlantWithDatabase(db, plant);

    await db.insert('recognition_records', <String, Object?>{
      'plant_id': plantId,
      'image_path': imagePath,
      'confidence': result.primary.confidence,
      'captured_at': DateTime.now().toIso8601String(),
      'raw_json': jsonEncode(<String, Object?>{
        'primary': result.primary.toMap(),
        'alternatives':
            result.alternatives.map((item) => item.toMap()).toList(),
        'analysis_note': result.analysisNote,
      }),
    });

    return plant.copyWith(id: plantId);
  }

  Future<List<Plant>> getAllPlants({String query = ''}) async {
    final db = await database;
    final normalized = query.trim().toLowerCase();
    if (normalized.isEmpty) {
      final maps = await db.query(
        'plants',
        orderBy: 'common_name COLLATE NOCASE ASC',
      );
      return maps.map(Plant.fromMap).toList(growable: false);
    }

    final terms = normalized
        .split(RegExp(r'\s+'))
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList(growable: false);

    final where = terms
        .map(
          (_) => '(${_searchColumns.map((column) => 'lower($column) LIKE ?').join(' OR ')})',
        )
        .join(' AND ');

    final args = <Object?>[];
    for (final term in terms) {
      final pattern = '%$term%';
      for (var i = 0; i < _searchColumns.length; i++) {
        args.add(pattern);
      }
    }

    final firstPrefix = '${terms.first}%';
    args
      ..add(firstPrefix)
      ..add(firstPrefix)
      ..add(firstPrefix);

    final maps = await db.rawQuery(
      '''
      SELECT *
      FROM plants
      WHERE $where
      ORDER BY
        CASE
          WHEN lower(common_name) LIKE ? THEN 0
          WHEN lower(english_name) LIKE ? THEN 1
          WHEN lower(scientific_name) LIKE ? THEN 2
          ELSE 3
        END,
        common_name COLLATE NOCASE ASC
      ''',
      args,
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
      <String, Object?>{'is_favorite': isFavorite ? 1 : 0},
      where: 'id = ?',
      whereArgs: <Object?>[plantId],
    );
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
  }
}
