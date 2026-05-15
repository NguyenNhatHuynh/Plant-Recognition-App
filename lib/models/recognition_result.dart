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
    final primary = RecognitionCandidate.fromMap(
      Map<String, dynamic>.from(json['primary'] as Map),
    );
    final alternatives = <RecognitionCandidate>[
      for (final item in (json['alternatives'] as List? ?? const []))
        RecognitionCandidate.fromMap(Map<String, dynamic>.from(item as Map)),
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
}
