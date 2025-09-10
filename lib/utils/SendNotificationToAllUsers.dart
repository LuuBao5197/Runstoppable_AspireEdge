import 'package:cloud_firestore/cloud_firestore.dart';
import '../DTO/SendNoticeDTO.dart';

class SendNotificationService {
  Future<void> sendNotificationToAllUsers(SendNoticeDTO notice) async {
    final firestore = FirebaseFirestore.instance;

    try {
      await firestore.collection('notifications').add({
        ...notice.toMap(),
        'createdAt': FieldValue.serverTimestamp(),
      });

      print("Notification saved to Firestore successfully!");
    } catch (e) {
      print("Error saving notification: $e");
    }
  }
}
