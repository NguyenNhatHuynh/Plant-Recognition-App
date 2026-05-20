# Ứng Dụng Nhận Diện Cây Cối

Ứng dụng Flutter giúp người dùng nhận diện cây từ ảnh chụp hoặc ảnh tải lên, lưu lịch sử tra cứu, đánh dấu cây yêu thích và xem thông tin chi tiết về từng loài cây.

## Mục tiêu

- Nhận diện cây bằng ảnh từ camera hoặc thư viện ảnh
- Hiển thị thông tin chi tiết về cây sau khi nhận diện
- Lưu lịch sử nhận diện để xem lại
- Hỗ trợ thư viện cây và danh sách yêu thích
- Hoạt động mượt theo hướng `local-first` với `SQLite`
- Đồng bộ dữ liệu người dùng qua `Supabase`

## Tính năng chính

- Chụp ảnh cây bằng camera
- Chọn ảnh từ thư viện
- Nhận diện cây bằng AI
- Trang chi tiết cây với thông tin chăm sóc và ảnh tham khảo
- Thư viện cây có tìm kiếm và lọc
- Lịch sử nhận diện
- Yêu thích
- Hồ sơ người dùng
- Đồng bộ nền giữa `SQLite` và `Supabase`
- Giới hạn số lượt nhận diện mỗi ngày

## Kiến trúc hiện tại

Ứng dụng đang chạy theo mô hình:

- `Flutter UI` cho giao diện và điều hướng
- `SQLite` là nguồn dữ liệu hiển thị chính để app mượt và dùng được khi mạng yếu
- `Supabase Auth` cho đăng ký, đăng nhập, đổi mật khẩu
- `Supabase Database` để đồng bộ metadata người dùng và lịch sử
- `Supabase Edge Function` làm backend nhận diện trong môi trường release
- `Gemini` được gọi từ backend để tránh lộ API key trong bản phát hành

Luồng chính:

1. Người dùng đăng nhập
2. Chụp ảnh hoặc chọn ảnh
3. App gọi backend nhận diện
4. Backend gọi Gemini và trả kết quả về app
5. App lưu dữ liệu vào `SQLite`
6. `SyncService` đồng bộ dữ liệu lên `Supabase`

## Cấu trúc thư mục

```text
lib/
  bootstrap/          Khởi tạo cấu hình và services
  config/             Đọc biến môi trường
  models/             Model dữ liệu
  services/           Auth, database, recognition, sync
  state/              AppState dùng chung
  theme/              Light mode / Dark mode
  ui/
    screens/          Các màn hình chính
    widgets/          Widget tái sử dụng

supabase/
  functions/
    recognize/        Edge Function nhận diện cây
  sync_setup.sql      SQL tạo bảng và quota server-side
```

## Công nghệ sử dụng

- Flutter
- Dart
- Provider
- SQLite (`sqflite`)
- Supabase
- Gemini
- HTTP

## Yêu cầu môi trường

- Flutter SDK
- Dart SDK
- Android Studio hoặc VS Code
- Tài khoản Supabase
- API key Gemini
- Supabase CLI nếu muốn chạy Edge Function local hoặc deploy function

## Biến môi trường

Tạo file `.env` ở root project:

```env
SUPABASE_URL=
SUPABASE_PUBLISHABLE_KEY=
GEMINI_API_KEY=
RECOGNITION_API_BASE_URL=
```

### Ý nghĩa từng biến

- `SUPABASE_URL`: URL project Supabase
- `SUPABASE_PUBLISHABLE_KEY`: Publishable key của Supabase
- `GEMINI_API_KEY`: Chỉ dùng cho dev direct hoặc backend secrets
- `RECOGNITION_API_BASE_URL`: Base URL của backend nhận diện

## Lấy value cho từng biến

### 1. `SUPABASE_URL`

Vào:

- `Supabase Dashboard`
- `Project Settings`
- `API`

Lấy giá trị ở mục:

- `Project URL`

Ví dụ:

```env
SUPABASE_URL=https://your-project-ref.supabase.co
```

### 2. `SUPABASE_PUBLISHABLE_KEY`

Vào:

- `Supabase Dashboard`
- `Project Settings`
- `API`

Lấy giá trị ở mục:

- `Publishable key`

Ví dụ:

```env
SUPABASE_PUBLISHABLE_KEY=sb_publishable_xxxxxxxxx
```

### 3. `GEMINI_API_KEY`

Lấy từ Google AI Studio hoặc Google AI API project của bạn.

Lưu ý:

- Trong môi trường `release`, không nên để key này trong app
- Key này nên được đưa vào `Supabase secrets` để backend dùng

### 4. `RECOGNITION_API_BASE_URL`

Biến này là nơi app gọi backend nhận diện.

Bạn sẽ điền khác nhau theo từng mode:

#### Dev direct Gemini

Nếu đang chạy dev và chưa deploy backend:

```env
RECOGNITION_API_BASE_URL=
```

Lúc này app dev có thể gọi Gemini trực tiếp.

#### Dev local backend

Nếu đang chạy local Edge Function:

```env
RECOGNITION_API_BASE_URL=http://127.0.0.1:54321/functions/v1
```

App sẽ gọi endpoint:

```text
http://127.0.0.1:54321/functions/v1/recognize
```

#### Backend production

Nếu đã deploy Edge Function lên Supabase:

```env
RECOGNITION_API_BASE_URL=https://your-project-ref.functions.supabase.co
```

App sẽ gọi:

```text
https://your-project-ref.functions.supabase.co/recognize
```

### Làm sao để lấy đúng value `RECOGNITION_API_BASE_URL`?

Sau khi deploy function bằng:

```bash
supabase functions deploy recognize
```

Base URL sẽ theo format:

```text
https://<project-ref>.functions.supabase.co
```

Trong đó:

- `<project-ref>` là mã project Supabase của bạn

Ví dụ project URL là:

```text
https://qtretjocwhoywgrolkvo.supabase.co
```

thì:

```env
RECOGNITION_API_BASE_URL=https://qtretjocwhoywgrolkvo.functions.supabase.co
```

## Cài đặt project

```bash
git clone <repo-url>
cd Plant-Recognition-App
flutter pub get
```

## Chạy app ở môi trường dev

### Cách 1: Dev direct Gemini

Phù hợp để test nhanh khi chưa dựng backend.

`.env`:

```env
SUPABASE_URL=...
SUPABASE_PUBLISHABLE_KEY=...
GEMINI_API_KEY=your_gemini_key
RECOGNITION_API_BASE_URL=
```

Chạy:

```bash
flutter run --dart-define-from-file=.env -d <deviceId>
```

### Cách 2: Dev với backend local

Phù hợp để test gần production hơn.

`.env`:

```env
SUPABASE_URL=...
SUPABASE_PUBLISHABLE_KEY=...
GEMINI_API_KEY=
RECOGNITION_API_BASE_URL=http://127.0.0.1:54321/functions/v1
```

Chạy local Supabase function:

```bash
supabase start
supabase functions serve recognize --env-file supabase/functions/.env.local
```

Sau đó chạy app:

```bash
flutter run --dart-define-from-file=.env -d <deviceId>
```

## Thiết lập backend nhận diện

### 1. Chạy SQL trên Supabase

Mở `SQL Editor` và chạy file:

```text
supabase/sync_setup.sql
```

File này tạo:

- `user_plants`
- `user_recognition_records`
- `user_recognition_daily_usage`
- RPC quota `consume_recognition_daily_quota(...)`

### 2. Cài Supabase CLI

```bash
npm install -g supabase
```

### 3. Đăng nhập và link project

```bash
supabase login
supabase link --project-ref <project-ref>
```

### 4. Set secrets cho Edge Function

```bash
supabase secrets set GEMINI_API_KEY=your_gemini_key
supabase secrets set SUPABASE_URL=your_supabase_url
supabase secrets set SUPABASE_ANON_KEY=your_supabase_publishable_key
supabase secrets set SUPABASE_SERVICE_ROLE_KEY=your_service_role_key
supabase secrets set DAILY_RECOGNITION_LIMIT=15
```

### 5. Deploy function

```bash
supabase functions deploy recognize
```

## Lưu ý rất quan trọng về release

Ở bản phát hành, app đã chặn gọi Gemini trực tiếp từ client.

Nghĩa là:

- Nếu chưa deploy backend
- Hoặc chưa cấu hình `RECOGNITION_API_BASE_URL`

thì tính năng nhận diện **sẽ không hoạt động trong release**.

Vì vậy hiện tại chỉ nên hiểu là:

- App đã đi đúng kiến trúc cho production
- Nhưng chỉ thật sự sẵn sàng vận hành khi backend đã được deploy và cấu hình hoàn chỉnh

## Chạy test

```bash
flutter analyze
flutter test
```

## Trạng thái hiện tại

Ứng dụng hiện đã có:

- giao diện chính khá đầy đủ
- đăng nhập, đăng ký, đổi mật khẩu
- thư viện, lịch sử, yêu thích, profile
- local database
- đồng bộ nền với Supabase
- skeleton backend nhận diện

Các phần vẫn cần hoàn thiện thêm trước khi lên Play Store chính thức:

- đổi `applicationId` khỏi `com.example...`
- cấu hình release signing thật
- deploy backend nhận diện
- bỏ hoàn toàn Gemini key khỏi client release
- cập nhật app icon, app name, store listing
- hoàn thiện README, privacy policy và ảnh chụp màn hình

## Gợi ý môi trường sử dụng

- `Demo / nội bộ`: đã dùng được
- `Beta nhỏ`: có thể dùng sau khi backend chạy ổn
- `Play Store chính thức`: nên hoàn thiện thêm phần release config và backend production

## Tác giả

Xoan Dev
