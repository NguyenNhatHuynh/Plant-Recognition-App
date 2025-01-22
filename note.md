lib/
├── main.dart               # Điểm khởi đầu của ứng dụng
├── core/                   # Logic và dịch vụ cốt lõi
│   ├── api/                # API Services
│   │   ├── plant_api.dart  # Giao tiếp với Plant.id API
│   │   ├── database.dart   # Kết nối SQLite hoặc Hive
│   │   └── tflite_service.dart # Tích hợp TensorFlow Lite
│   ├── utils/              # Các hàm tiện ích
│   │   ├── constants.dart  # Hằng số dùng chung (URL API, token, v.v.)
│   │   ├── theme.dart      # Cấu hình giao diện
│   │   └── helpers.dart    # Hàm tiện ích
├── features/               # Tính năng chính
│   ├── identification/     # Nhận diện cây cối
│   │   ├── view/           # UI màn hình nhận diện
│   │   │   └── identify_screen.dart
│   │   ├── model/          # Model dữ liệu cho cây
│   │   │   └── plant.dart
│   │   └── controller/     # Logic xử lý nghiệp vụ
│   │       └── identify_controller.dart
│   ├── history/            # Lịch sử nhận diện
│   │   ├── view/           # UI màn hình lịch sử
│   │   ├── model/          # Model dữ liệu lịch sử
│   │   └── controller/     # Logic xử lý lịch sử
├── shared/                 # Thành phần tái sử dụng
│   ├── widgets/            # Widget dùng chung
│   │   ├── loading.dart    # Hiển thị loading
│   │   ├── button.dart     # Nút tái sử dụng
│   │   └── plant_card.dart # Hiển thị thông tin cây
│   └── styles/             # Phong cách chung
└── assets/                 # Tài nguyên ứng dụng
    ├── images/             # Hình ảnh
    ├── fonts/              # Font chữ
    └── models/             # Mô hình ML (nếu dùng TensorFlow Lite)