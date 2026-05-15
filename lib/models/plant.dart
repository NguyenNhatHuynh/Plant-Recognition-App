import 'dart:convert';

class Plant {
  final int? id;
  final String commonName;
  final String scientificName;
  final String family;
  final String description;
  final String habitat;
  final List<String> uses;
  final List<String> aliases;
  final String imagePath;
  final bool isFavorite;
  final bool isOfflineAvailable;

  const Plant({
    this.id,
    required this.commonName,
    required this.scientificName,
    required this.family,
    required this.description,
    required this.habitat,
    required this.uses,
    required this.aliases,
    required this.imagePath,
    this.isFavorite = false,
    this.isOfflineAvailable = false,
  });

  Plant copyWith({
    int? id,
    String? commonName,
    String? scientificName,
    String? family,
    String? description,
    String? habitat,
    List<String>? uses,
    List<String>? aliases,
    String? imagePath,
    bool? isFavorite,
    bool? isOfflineAvailable,
  }) {
    return Plant(
      id: id ?? this.id,
      commonName: commonName ?? this.commonName,
      scientificName: scientificName ?? this.scientificName,
      family: family ?? this.family,
      description: description ?? this.description,
      habitat: habitat ?? this.habitat,
      uses: uses ?? this.uses,
      aliases: aliases ?? this.aliases,
      imagePath: imagePath ?? this.imagePath,
      isFavorite: isFavorite ?? this.isFavorite,
      isOfflineAvailable: isOfflineAvailable ?? this.isOfflineAvailable,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'common_name': commonName,
      'scientific_name': scientificName,
      'family': family,
      'description': description,
      'habitat': habitat,
      'uses_json': jsonEncode(uses),
      'aliases_json': jsonEncode(aliases),
      'image_path': imagePath,
      'is_favorite': isFavorite ? 1 : 0,
      'is_offline_available': isOfflineAvailable ? 1 : 0,
    };
  }

  factory Plant.fromMap(Map<String, dynamic> map) {
    return Plant(
      id: map['id'] as int?,
      commonName: map['common_name'] as String? ?? '',
      scientificName: map['scientific_name'] as String? ?? '',
      family: map['family'] as String? ?? '',
      description: map['description'] as String? ?? '',
      habitat: map['habitat'] as String? ?? '',
      uses: _parseList(map['uses_json']),
      aliases: _parseList(map['aliases_json']),
      imagePath: map['image_path'] as String? ?? '',
      isFavorite: (map['is_favorite'] as int? ?? 0) == 1,
      isOfflineAvailable: (map['is_offline_available'] as int? ?? 0) == 1,
    );
  }

  static List<String> _parseList(dynamic value) {
    if (value == null) {
      return const [];
    }
    if (value is List) {
      return value.map((item) => item.toString()).toList(growable: false);
    }
    if (value is String && value.isNotEmpty) {
      final decoded = jsonDecode(value);
      if (decoded is List) {
        return decoded.map((item) => item.toString()).toList(growable: false);
      }
    }
    return const [];
  }
}
