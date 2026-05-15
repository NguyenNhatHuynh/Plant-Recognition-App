import 'plant.dart';

class RecognitionRecord {
  final int id;
  final Plant plant;
  final double confidence;
  final String imagePath;
  final DateTime capturedAt;

  const RecognitionRecord({
    required this.id,
    required this.plant,
    required this.confidence,
    required this.imagePath,
    required this.capturedAt,
  });

  factory RecognitionRecord.fromMap(Map<String, dynamic> map) {
    return RecognitionRecord(
      id: map['record_id'] as int? ?? 0,
      plant: Plant.fromMap(map),
      confidence: (map['record_confidence'] as num?)?.toDouble() ?? 0.0,
      imagePath: map['record_image_path'] as String? ?? '',
      capturedAt: DateTime.tryParse(
            map['record_captured_at'] as String? ?? '',
          ) ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }
}
