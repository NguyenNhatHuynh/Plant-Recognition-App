import 'plant.dart';
import 'recognition_candidate.dart';

class RecognitionResult {
  final RecognitionCandidate primary;
  final List<RecognitionCandidate> alternatives;
  final String analysisNote;
  final String imagePath;

  const RecognitionResult({
    required this.primary,
    required this.alternatives,
    required this.analysisNote,
    required this.imagePath,
  });

  factory RecognitionResult.fromGeminiJson(
    Map<String, dynamic> json, {
    required String imagePath,
  }) {
    final primaryMap = _asStringMap(json['primary']);
    if (primaryMap == null) {
      throw const FormatException('Missing or invalid "primary" object.');
    }

    final primary = RecognitionCandidate.fromMap(primaryMap);
    final alternatives = <RecognitionCandidate>[
      for (final item in (json['alternatives'] as List? ?? const []))
        if (_asStringMap(item) case final map?) RecognitionCandidate.fromMap(map),
    ];
    return RecognitionResult(
      primary: primary,
      alternatives: alternatives,
      analysisNote: json['analysis_note']?.toString() ?? '',
      imagePath: imagePath,
    );
  }

  Plant toPlant() {
    return primary.toPlant(imagePath: imagePath);
  }

  static Map<String, dynamic>? _asStringMap(dynamic value) {
    if (value is Map<String, dynamic>) {
      return value;
    }
    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }
    return null;
  }
}
