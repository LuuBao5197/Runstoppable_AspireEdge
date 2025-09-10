import 'package:cloud_firestore/cloud_firestore.dart';

class SendNoticeDTO {
  final String title;
  final String message;
  final String datetime; // ISO string
  final bool isRead;
  final String? userId; // optional, null = all users

  SendNoticeDTO({
    required this.title,
    required this.message,
    String? datetime,
    this.isRead = false,
    this.userId,
  }) : datetime = datetime ?? DateTime.now().toIso8601String();

  // Chuyển sang Map để lưu Firestore
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'message': message,
      'datetime': datetime,
      'isRead': isRead,
      if (userId != null) 'userId': userId,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}
