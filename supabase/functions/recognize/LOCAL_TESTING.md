# Test local end-to-end cho `recognize`

## 1. Khởi tạo Supabase local nếu repo chưa có cấu hình CLI

```bash
supabase init
```

## 2. Tạo file env local cho functions

Tạo file:

```text
supabase/functions/.env.local
```

với nội dung ví dụ:

```env
SUPABASE_URL=http://127.0.0.1:54321
SUPABASE_ANON_KEY=your_local_anon_key
SUPABASE_SERVICE_ROLE_KEY=your_local_service_role_key
GEMINI_API_KEY=your_gemini_key
DAILY_RECOGNITION_LIMIT=15
```

Bạn có thể lấy key local sau khi chạy `supabase start` bằng:

```bash
supabase status
```

## 3. Chạy local stack

```bash
supabase start
```

## 4. Serve function local

```bash
supabase functions serve recognize --env-file supabase/functions/.env.local
```

Theo Supabase docs, function local thường chạy tại:

```text
http://127.0.0.1:54321/functions/v1/recognize
```

## 5. Chạy SQL setup

Mở SQL editor local hoặc project cloud và chạy file:

```text
supabase/sync_setup.sql
```

## 6. Test bằng app Flutter

Trong `.env` của app:

```env
RECOGNITION_API_BASE_URL=http://127.0.0.1:54321/functions/v1
```

Sau đó chạy app:

```bash
flutter run --dart-define-from-file=.env
```

App sẽ gọi:

```text
POST http://127.0.0.1:54321/functions/v1/recognize
```

và tự gửi `Authorization: Bearer <access_token>`.

## 7. Test bằng curl

Thay `<ACCESS_TOKEN>` bằng access token của user đã đăng nhập.

```bash
curl -i ^
  -X POST http://127.0.0.1:54321/functions/v1/recognize ^
  -H "Content-Type: application/json" ^
  -H "Authorization: Bearer <ACCESS_TOKEN>" ^
  -d "{\"mime_type\":\"image/jpeg\",\"image_base64\":\"<BASE64_IMAGE>\"}"
```

## 8. Debug khi serve lỗi

```bash
supabase functions serve recognize --env-file supabase/functions/.env.local --debug
```
