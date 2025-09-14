import 'package:firebase_auth/firebase_auth.dart';

class UserSession {
  /// Lấy UID của user hiện tại từ FirebaseAuth
  static String? getCurrentUserId() {
    final user = FirebaseAuth.instance.currentUser;
    return user?.uid;
  }

  /// Lấy thông tin user khác nếu cần
  static String? getCurrentUserEmail() {
    return FirebaseAuth.instance.currentUser?.email;
  }

  static String? getCurrentUserDisplayName() {
    return FirebaseAuth.instance.currentUser?.displayName;
  }

  static String? getCurrentUserPhotoURL() {
    return FirebaseAuth.instance.currentUser?.photoURL;
  }

  /// Logout user
  static Future<void> logout() async {
    try {
      await FirebaseAuth.instance.signOut();
    } catch (e) {
      print("Logout error: $e");
    }
  }
}
