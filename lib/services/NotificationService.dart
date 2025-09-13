import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal() {
    _listenNotifications();
  }

  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final StreamController<List<Map<String, dynamic>>> _controller = StreamController.broadcast();

  Stream<List<Map<String, dynamic>>> get notificationsStream => _controller.stream;

  String? get currentUserId => FirebaseAuth.instance.currentUser?.uid;

  List<String> oldIds = [];

  void _listenNotifications() {
    firestore.collection("notifications")
        .orderBy("createdAt", descending: true)
        .snapshots()
        .listen((snapshot) {
      final notis = snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          "id": doc.id,
          "title": data["title"] ?? 'No title',
          "message": data["message"] ?? 'No content',
          "datetime": data["datetime"],
          "isRead": data["isRead"] ?? false,
          "userId": data["userId"],
        };
      }).where((n) => n['userId'] == currentUserId || n['userId'] == 'ALL').toList();

      _controller.add(notis);
    });

  }

  void dispose() {
    _controller.close();
  }
}
