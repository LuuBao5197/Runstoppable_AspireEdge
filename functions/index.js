const functions = require("firebase-functions");
const cloudinary = require("cloudinary").v2;

// Cấu hình Cloudinary bằng các biến môi trường bạn đã set
cloudinary.config({
  cloud_name: functions.config().cloudinary.cloud_name,
  api_key: functions.config().cloudinary.api_key,
  api_secret: functions.config().cloudinary.api_secret,
});

/**
 * Tạo một Cloud Function có thể gọi từ client (Callable Function).
 * Function này sẽ nhận 'publicId' của ảnh và thực hiện xóa trên Cloudinary.
 */
exports.deleteCloudinaryImage = functions.https.onCall(
  async (data, context) => {
    // 1. Kiểm tra xem người dùng đã được xác thực (đăng nhập) hay chưa.
    if (!context.auth) {
      throw new functions.https.HttpsError(
        "unauthenticated",
        "Bạn phải đăng nhập để thực hiện hành động này."
      );
    }

    const publicId = data.publicId;
    if (!publicId) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "Vui lòng cung cấp publicId của file cần xóa."
      );
    }

    // 2. (Quan trọng) Kiểm tra quyền hạn
    // Trong một ứng dụng thực tế, bạn nên kiểm tra trong database (ví dụ: Firestore)
    // để đảm bảo người dùng này (context.auth.uid) có quyền xóa file này.
    // Việc này ngăn chặn người dùng A xóa file của người dùng B.

    try {
      // 3. Thực hiện gọi API của Cloudinary để xóa file
      const result = await cloudinary.uploader.destroy(publicId);

      // Ghi log kết quả (bạn có thể xem log này trong Firebase Console)
      console.log(`Xóa file thành công: ${publicId}`, result);

      // Trả về kết quả thành công cho ứng dụng Flutter
      return { success: true, result: result };
    } catch (error) {
      console.error("Lỗi khi xóa file trên Cloudinary:", error);
      // Ném một lỗi để ứng dụng Flutter có thể bắt và xử lý
      throw new functions.https.HttpsError(
        "internal",
        "Đã có lỗi xảy ra khi thực hiện xóa file trên Cloudinary."
      );
    }
  }
);