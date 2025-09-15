import 'package:cloud_firestore/cloud_firestore.dart';
import '../DTO/SendNoticeDTO.dart';

class SendNotificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> sendNotificationToAllUsers(SendNoticeDTO notice) async {
    try {
      await _firestore.collection('notifications').add({
        ...notice.toMap(),
        'createdAt': FieldValue.serverTimestamp(),
        'userId': null, // null = broadcast
      });

      print("✅ Notification (broadcast) saved to Firestore!");
    } catch (e) {
      print("❌ Error saving broadcast notification: $e");
    }
  }

  Future<void> sendNotificationToUser(String userId, SendNoticeDTO notice) async {
    try {
      await _firestore.collection('notifications').add({
        ...notice.toMap(),
        'createdAt': FieldValue.serverTimestamp(),
        'userId': userId,
      });

      print("✅ Notification sent to user $userId!");
    } catch (e) {
      print("❌ Error sending notification to $userId: $e");
    }
  }
}
