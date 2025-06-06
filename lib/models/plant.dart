// lib/models/plant.dart
class Plant {
  final int? id; // ID duy nhất trong cơ sở dữ liệu
  final String name; // Tên cây
  final String scientificName; // Tên khoa học
  final String description; // Mô tả chi tiết
  final String imagePath; // Đường dẫn ảnh (local hoặc URL)
  final bool isFavorite; // Trạng thái yêu thích

  Plant({
    this.id,
    required this.name,
    required this.scientificName,
    required this.description,
    required this.imagePath,
    this.isFavorite = false,
  });

  // Chuyển đổi từ Map (cho SQLite)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'scientific_name': scientificName,
      'description': description,
      'image_path': imagePath,
      'is_favorite': isFavorite ? 1 : 0,
    };
  }

  // Tạo Plant từ Map (từ SQLite)
  factory Plant.fromMap(Map<String, dynamic> map) {
    return Plant(
      id: map['id'],
      name: map['name'],
      scientificName: map['scientific_name'],
      description: map['description'],
      imagePath: map['image_path'],
      isFavorite: map['is_favorite'] == 1,
    );
  }

  // Tạo bản sao với thay đổi
  Plant copyWith({bool? isFavorite}) {
    return Plant(
      id: id,
      name: name,
      scientificName: scientificName,
      description: description,
      imagePath: imagePath,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }
}
