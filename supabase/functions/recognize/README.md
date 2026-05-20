# Supabase Edge Function: `recognize`

Function này nhận ảnh từ app Flutter, xác thực user bằng `Bearer access token`,
kiểm tra quota hằng ngày theo tài khoản, rồi mới gọi Gemini ở phía server.

## Secrets cần cấu hình

```bash
supabase secrets set GEMINI_API_KEY=your_gemini_key
supabase secrets set SUPABASE_URL=your_supabase_url
supabase secrets set SUPABASE_ANON_KEY=your_supabase_anon_key
supabase secrets set SUPABASE_SERVICE_ROLE_KEY=your_service_role_key
supabase secrets set DAILY_RECOGNITION_LIMIT=15
```

## Deploy

```bash
supabase functions deploy recognize
```

## URL dùng cho app Flutter

Trong file `.env` của app:

```env
RECOGNITION_API_BASE_URL=https://<project-ref>.functions.supabase.co
```

Chạy app local/dev bằng:

```bash
flutter run --dart-define-from-file=.env
```

App sẽ tự gọi:

```text
POST /recognize
```

và tự gửi `Authorization: Bearer <access_token>` nếu người dùng đã đăng nhập.

## SQL cần chạy trước

Chạy file:

```text
supabase/sync_setup.sql
```

File này đã bao gồm:
- bảng `user_recognition_daily_usage`
- hàm RPC `consume_recognition_daily_quota(...)`
- policy đọc usage của chính user
