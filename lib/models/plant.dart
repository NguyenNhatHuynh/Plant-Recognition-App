import 'dart:convert';

class Plant {
  final int? id;
  final String commonName;
  final List<String> aliases;
  final String englishName;
  final String scientificName;
  final String family;
  final String description;
  final String habitat;
  final String lightRequirement;
  final String wateringNeeds;
  final String careLevel;
  final String suitableTemperature;
  final String soilType;
  final String fertilizingTips;
  final String toxicityWarning;
  final List<String> uses;
  final String maximumSize;
  final String fengShuiMeaning;
  final String origin;
  final String commonIssues;
  final String imagePath;
  final bool isFavorite;
  final bool isOfflineAvailable;

  const Plant({
    this.id,
    required this.commonName,
    required this.aliases,
    required this.englishName,
    required this.scientificName,
    required this.family,
    required this.description,
    required this.habitat,
    required this.lightRequirement,
    required this.wateringNeeds,
    required this.careLevel,
    required this.suitableTemperature,
    required this.soilType,
    required this.fertilizingTips,
    required this.toxicityWarning,
    required this.uses,
    required this.maximumSize,
    required this.fengShuiMeaning,
    required this.origin,
    required this.commonIssues,
    required this.imagePath,
    this.isFavorite = false,
    this.isOfflineAvailable = false,
  });

  Plant copyWith({
    int? id,
    String? commonName,
    List<String>? aliases,
    String? englishName,
    String? scientificName,
    String? family,
    String? description,
    String? habitat,
    String? lightRequirement,
    String? wateringNeeds,
    String? careLevel,
    String? suitableTemperature,
    String? soilType,
    String? fertilizingTips,
    String? toxicityWarning,
    List<String>? uses,
    String? maximumSize,
    String? fengShuiMeaning,
    String? origin,
    String? commonIssues,
    String? imagePath,
    bool? isFavorite,
    bool? isOfflineAvailable,
  }) {
    return Plant(
      id: id ?? this.id,
      commonName: commonName ?? this.commonName,
      aliases: aliases ?? this.aliases,
      englishName: englishName ?? this.englishName,
      scientificName: scientificName ?? this.scientificName,
      family: family ?? this.family,
      description: description ?? this.description,
      habitat: habitat ?? this.habitat,
      lightRequirement: lightRequirement ?? this.lightRequirement,
      wateringNeeds: wateringNeeds ?? this.wateringNeeds,
      careLevel: careLevel ?? this.careLevel,
      suitableTemperature: suitableTemperature ?? this.suitableTemperature,
      soilType: soilType ?? this.soilType,
      fertilizingTips: fertilizingTips ?? this.fertilizingTips,
      toxicityWarning: toxicityWarning ?? this.toxicityWarning,
      uses: uses ?? this.uses,
      maximumSize: maximumSize ?? this.maximumSize,
      fengShuiMeaning: fengShuiMeaning ?? this.fengShuiMeaning,
      origin: origin ?? this.origin,
      commonIssues: commonIssues ?? this.commonIssues,
      imagePath: imagePath ?? this.imagePath,
      isFavorite: isFavorite ?? this.isFavorite,
      isOfflineAvailable: isOfflineAvailable ?? this.isOfflineAvailable,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'common_name': commonName,
      'aliases_json': jsonEncode(aliases),
      'english_name': englishName,
      'scientific_name': scientificName,
      'family': family,
      'description': description,
      'habitat': habitat,
      'light_requirement': lightRequirement,
      'watering_needs': wateringNeeds,
      'care_level': careLevel,
      'suitable_temperature': suitableTemperature,
      'soil_type': soilType,
      'fertilizing_tips': fertilizingTips,
      'toxicity_warning': toxicityWarning,
      'uses_json': jsonEncode(uses),
      'maximum_size': maximumSize,
      'feng_shui_meaning': fengShuiMeaning,
      'origin': origin,
      'common_issues': commonIssues,
      'image_path': imagePath,
      'is_favorite': isFavorite ? 1 : 0,
      'is_offline_available': isOfflineAvailable ? 1 : 0,
    };
  }

  factory Plant.fromMap(Map<String, dynamic> map) {
    return Plant(
      id: map['id'] as int?,
      commonName: _repairPotentialMojibake(
        map['common_name'] as String? ?? '',
      ),
      aliases: _parseList(map['aliases_json']),
      englishName: _repairPotentialMojibake(
        map['english_name'] as String? ?? '',
      ),
      scientificName: _repairPotentialMojibake(
        map['scientific_name'] as String? ?? '',
      ),
      family: _repairPotentialMojibake(map['family'] as String? ?? ''),
      description: _repairPotentialMojibake(
        map['description'] as String? ?? '',
      ),
      habitat: _repairPotentialMojibake(map['habitat'] as String? ?? ''),
      lightRequirement: _repairPotentialMojibake(
        map['light_requirement'] as String? ?? '',
      ),
      wateringNeeds: _repairPotentialMojibake(
        map['watering_needs'] as String? ?? '',
      ),
      careLevel: _repairPotentialMojibake(map['care_level'] as String? ?? ''),
      suitableTemperature: _repairPotentialMojibake(
        map['suitable_temperature'] as String? ?? '',
      ),
      soilType: _repairPotentialMojibake(map['soil_type'] as String? ?? ''),
      fertilizingTips: _repairPotentialMojibake(
        map['fertilizing_tips'] as String? ?? '',
      ),
      toxicityWarning: _repairPotentialMojibake(
        map['toxicity_warning'] as String? ?? '',
      ),
      uses: _parseList(map['uses_json']),
      maximumSize: _repairPotentialMojibake(
        map['maximum_size'] as String? ?? '',
      ),
      fengShuiMeaning: _repairPotentialMojibake(
        map['feng_shui_meaning'] as String? ?? '',
      ),
      origin: _repairPotentialMojibake(map['origin'] as String? ?? ''),
      commonIssues: _repairPotentialMojibake(
        map['common_issues'] as String? ?? '',
      ),
      imagePath: _repairPotentialMojibake(map['image_path'] as String? ?? ''),
      isFavorite: (map['is_favorite'] as int? ?? 0) == 1,
      isOfflineAvailable: (map['is_offline_available'] as int? ?? 0) == 1,
    );
  }

  static List<String> _parseList(dynamic value) {
    if (value == null) {
      return const [];
    }
    if (value is List) {
      return value
          .map((item) => item.toString().trim())
          .where((item) => item.isNotEmpty)
          .toList(growable: false);
    }
    if (value is String && value.isNotEmpty) {
      try {
        final decoded = jsonDecode(value);
        if (decoded is List) {
          return decoded
              .map((item) => _repairPotentialMojibake(item.toString()).trim())
              .where((item) => item.isNotEmpty)
              .toList(growable: false);
        }
      } catch (_) {
        return value
            .split(RegExp(r'[,;|]'))
            .map((item) => _repairPotentialMojibake(item).trim())
            .where((item) => item.isNotEmpty)
            .toList(growable: false);
      }
    }
    return const [];
  }

  static String _repairPotentialMojibake(String input) {
    final trimmed = input.trim();
    if (trimmed.isEmpty) {
      return input;
    }

    const mojibakeSignals = <String>[
      'Ã',
      'Ä',
      'Æ',
      'Â',
      'áº',
      'á»',
    ];
    if (!mojibakeSignals.any(trimmed.contains)) {
      return input;
    }

    try {
      return utf8.decode(latin1.encode(trimmed));
    } catch (_) {
      return input;
    }
  }
}
