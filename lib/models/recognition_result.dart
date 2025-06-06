import 'plant.dart';

// lib/models/recognition_result.dart
class RecognitionResult {
  final String name; // Tên cây được nhận dạng
  final String scientificName; // Tên khoa học
  final String description; // Mô tả chi tiết
  final double confidence; // Độ tin cậy của nhận dạng (0-1)
  final String imagePath; // Đường dẫn ảnh đã nhận dạng

  RecognitionResult({
    required this.name,
    required this.scientificName,
    required this.description,
    required this.confidence,
    required this.imagePath,
  });

  // Tạo từ JSON (từ API như Plant.id)
  factory RecognitionResult.fromJson(Map<String, dynamic> json) {
    return RecognitionResult(
      name: json['suggestions'][0]['plant_name'] ?? 'Unknown',
      scientificName: json['suggestions'][0]['plant_details']
              ['scientific_name'] ??
          'Unknown',
      description: json['suggestions'][0]['plant_details']['wiki_description']
              ['value'] ??
          'No description available',
      confidence:
          (json['suggestions'][0]['probability'] as num?)?.toDouble() ?? 0.0,
      imagePath: json['images'][0]['url'] ?? '',
    );
  }

  // Chuyển đổi thành Plant để lưu vào cơ sở dữ liệu
  Plant toPlant() {
    return Plant(
      name: name,
      scientificName: scientificName,
      description: description,
      imagePath: imagePath,
    );
  }
}
