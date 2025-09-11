# Hướng dẫn Debug Đăng nhập - Firebase Version

## Các vấn đề đã được sửa:

### 1. ✅ Chuyển từ API sang Firebase Authentication
- Đã loại bỏ hoàn toàn việc sử dụng API server
- Chuyển sang sử dụng Firebase Authentication
- Cập nhật tất cả logic đăng nhập để sử dụng Firebase

### 2. ✅ Sửa lỗi Navigation
- Đã thêm import `CareerBankPage` vào `main.dart`
- Đã thêm `CareerBankPage` vào danh sách `_screens`

### 3. ✅ Sửa cấu hình Google Sign-in
- Đã cập nhật `serverClientId` để khớp với `google-services.json`
- Từ: `713857311495-mvg33eppl0s6rjiju5chh0rt02ho0ltb.apps.googleusercontent.com`
- Thành: `1035803144115-uvl45dju0rihlspo1js34ls02lkeute8.apps.googleusercontent.com`

### 4. ✅ Thêm debug logging
- Đã thêm các log chi tiết để theo dõi quá trình đăng nhập Firebase
- Thêm nút "Test Firebase Connection" để kiểm tra kết nối Firebase

## Cách debug:

### Bước 1: Kiểm tra kết nối Firebase
1. Mở app và vào màn hình đăng nhập
2. Nhấn nút "Test Firebase Connection" (màu cam)
3. Xem kết quả hiển thị:
   - ✅ "Firebase connection successful!" = Firebase hoạt động bình thường
   - ❌ "Firebase connection failed" = Có vấn đề với Firebase

### Bước 2: Kiểm tra Firebase Configuration
- Đảm bảo `google-services.json` đã được cấu hình đúng
- Kiểm tra Firebase project có đang hoạt động không
- Xem console log để kiểm tra Firebase initialization

### Bước 3: Thử đăng nhập Email/Password
1. Nhập email và password
2. Nhấn "Login"
3. Xem console log để theo dõi:
   - 🔍 "Attempting Firebase login with email: ..."
   - ✅ "Firebase login successful!" hoặc ❌ "Firebase Auth error: ..."

### Bước 4: Thử đăng nhập Google
1. Nhấn "Sign in with Google"
2. Xem console log để theo dõi:
   - 🔍 "Starting Google Sign-in with Firebase..."
   - ✅ "Google Sign-in successful, getting authentication..."
   - 🔐 "Signing in to Firebase..."
   - ✅ "Firebase authentication successful!"

## Các lỗi thường gặp:

### 1. "Firebase connection failed"
**Nguyên nhân:** Firebase không được cấu hình đúng hoặc không có internet
**Giải pháp:** 
- Kiểm tra kết nối internet
- Kiểm tra `google-services.json` có đúng không
- Kiểm tra Firebase project có hoạt động không

### 2. "No user found with this email address"
**Nguyên nhân:** Email chưa được đăng ký trong Firebase
**Giải pháp:** 
- Đăng ký tài khoản mới trước
- Hoặc sử dụng Google Sign-in

### 3. "Wrong password provided"
**Nguyên nhân:** Mật khẩu không đúng
**Giải pháp:** Kiểm tra lại mật khẩu

### 4. "Google login failed"
**Nguyên nhân:** Cấu hình Google Services sai
**Giải pháp:** 
- Kiểm tra `google-services.json`
- Kiểm tra SHA-1 fingerprint
- Kiểm tra package name

### 5. "Invalid email address"
**Nguyên nhân:** Email không đúng định dạng
**Giải pháp:** Nhập email đúng định dạng (ví dụ: user@example.com)

## Console Commands để debug:

```bash
# Xem log Flutter
flutter logs

# Kiểm tra Firebase project
firebase projects:list

# Kiểm tra cấu hình Firebase
flutterfire configure
```

## Cách tạo tài khoản mới:

### 1. Đăng ký qua Google Sign-in (Khuyến nghị)
- Nhấn "Sign in with Google"
- Chọn tài khoản Google
- Tài khoản sẽ được tạo tự động

### 2. Đăng ký qua Email/Password
- Cần có trang đăng ký (RegisterPage)
- Hoặc tạo tài khoản trực tiếp trong Firebase Console

## Liên hệ hỗ trợ:

Nếu vẫn gặp vấn đề, hãy:
1. Chạy "Test Firebase Connection" và gửi kết quả
2. Gửi log từ console khi thử đăng nhập
3. Kiểm tra Firebase project có hoạt động không
4. Đảm bảo có kết nối internet
