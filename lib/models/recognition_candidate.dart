import 'plant.dart';

class RecognitionCandidate {
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
  final double confidence;

  const RecognitionCandidate({
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
    required this.confidence,
  });

  factory RecognitionCandidate.fromMap(Map<String, dynamic> map) {
    return RecognitionCandidate(
      commonName: map['common_name']?.toString() ?? '',
      aliases: _asStringList(map['aliases']),
      englishName: map['english_name']?.toString() ?? '',
      scientificName: map['scientific_name']?.toString() ?? '',
      family: map['family']?.toString() ?? '',
      description: map['description']?.toString() ?? '',
      habitat: map['habitat']?.toString() ?? '',
      lightRequirement: map['light_requirement']?.toString() ?? '',
      wateringNeeds: map['watering_needs']?.toString() ?? '',
      careLevel: map['care_level']?.toString() ?? '',
      suitableTemperature: map['suitable_temperature']?.toString() ?? '',
      soilType: map['soil_type']?.toString() ?? '',
      fertilizingTips: map['fertilizing_tips']?.toString() ?? '',
      toxicityWarning: map['toxicity_warning']?.toString() ?? '',
      uses: _asStringList(map['uses']),
      maximumSize: map['maximum_size']?.toString() ?? '',
      fengShuiMeaning: map['feng_shui_meaning']?.toString() ?? '',
      origin: map['origin']?.toString() ?? '',
      commonIssues: map['common_issues']?.toString() ?? '',
      confidence: (map['confidence'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'common_name': commonName,
      'aliases': aliases,
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
      'uses': uses,
      'maximum_size': maximumSize,
      'feng_shui_meaning': fengShuiMeaning,
      'origin': origin,
      'common_issues': commonIssues,
      'confidence': confidence,
    };
  }

  Plant toPlant({String imagePath = ''}) {
    return Plant(
      commonName: commonName,
      aliases: aliases,
      englishName: englishName,
      scientificName: scientificName,
      family: family,
      description: description,
      habitat: habitat,
      lightRequirement: lightRequirement,
      wateringNeeds: wateringNeeds,
      careLevel: careLevel,
      suitableTemperature: suitableTemperature,
      soilType: soilType,
      fertilizingTips: fertilizingTips,
      toxicityWarning: toxicityWarning,
      uses: uses,
      maximumSize: maximumSize,
      fengShuiMeaning: fengShuiMeaning,
      origin: origin,
      commonIssues: commonIssues,
      imagePath: imagePath,
      isOfflineAvailable: true,
    );
  }

  static List<String> _asStringList(dynamic value) {
    if (value is List) {
      return value
          .map((item) => item.toString().trim())
          .where((item) => item.isNotEmpty)
          .toList(growable: false);
    }
    if (value is String && value.isNotEmpty) {
      return value
          .split(RegExp(r'[,;|]'))
          .map((item) => item.trim())
          .where((item) => item.isNotEmpty)
          .toList(growable: false);
    }
    return const [];
  }
}
