import 'plant.dart';

class RecognitionCandidate {
  final String commonName;
  final String scientificName;
  final String family;
  final String description;
  final String habitat;
  final List<String> uses;
  final double confidence;

  const RecognitionCandidate({
    required this.commonName,
    required this.scientificName,
    required this.family,
    required this.description,
    required this.habitat,
    required this.uses,
    required this.confidence,
  });

  factory RecognitionCandidate.fromMap(Map<String, dynamic> map) {
    return RecognitionCandidate(
      commonName: map['common_name']?.toString() ?? '',
      scientificName: map['scientific_name']?.toString() ?? '',
      family: map['family']?.toString() ?? '',
      description: map['description']?.toString() ?? '',
      habitat: map['habitat']?.toString() ?? '',
      uses: _asStringList(map['uses']),
      confidence: (map['confidence'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'common_name': commonName,
      'scientific_name': scientificName,
      'family': family,
      'description': description,
      'habitat': habitat,
      'uses': uses,
      'confidence': confidence,
    };
  }

  Plant toPlant({String imagePath = ''}) {
    return Plant(
      commonName: commonName,
      scientificName: scientificName,
      family: family,
      description: description,
      habitat: habitat,
      uses: uses,
      aliases: const [],
      imagePath: imagePath,
      isOfflineAvailable: true,
    );
  }

  static List<String> _asStringList(dynamic value) {
    if (value is List) {
      return value.map((item) => item.toString()).toList(growable: false);
    }
    if (value is String && value.isNotEmpty) {
      return [value];
    }
    return const [];
  }
}
