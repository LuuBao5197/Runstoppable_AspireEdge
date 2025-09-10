import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirebaseService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // ==================== USER MODEL ====================
  static Future<void> createUser({
    required String uid,
    required String email,
    required String fullname,
    String? avatar,
    String? phone,
  }) async {
    try {
      await _firestore.collection('users').doc(uid).set({
        'email': email,
        'fullname': fullname,
        'avatar': avatar,
        'phone': phone,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Error creating user: $e');
    }
  }

  static Future<Map<String, dynamic>?> getUser(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      return doc.data();
    } catch (e) {
      throw Exception('Error getting user: $e');
    }
  }

  static Future<void> updateUser(String uid, Map<String, dynamic> data) async {
    try {
      await _firestore.collection('users').doc(uid).update({
        ...data,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Error updating user: $e');
    }
  }

  // ==================== MOOD MODEL ====================
  static Future<void> addMoodEntry({
    required String userId,
    required int moodScore,
    required String moodType,
    String? note,
    List<String>? tags,
  }) async {
    try {
      await _firestore.collection('mood_entries').add({
        'userId': userId,
        'moodScore': moodScore,
        'moodType': moodType,
        'note': note,
        'tags': tags ?? [],
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Error adding mood entry: $e');
    }
  }

  static Stream<QuerySnapshot> getMoodEntries(String userId) {
    return _firestore
        .collection('mood_entries')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  // ==================== DIARY MODEL ====================
  static Future<void> addDiaryEntry({
    required String userId,
    required String title,
    required String content,
    String? mood,
    List<String>? tags,
  }) async {
    try {
      await _firestore.collection('diary_entries').add({
        'userId': userId,
        'title': title,
        'content': content,
        'mood': mood,
        'tags': tags ?? [],
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Error adding diary entry: $e');
    }
  }

  static Stream<QuerySnapshot> getDiaryEntries(String userId) {
    return _firestore
        .collection('diary_entries')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  // ==================== QUIZ MODEL ====================
  static Future<void> addQuizResult({
    required String userId,
    required String quizId,
    required int score,
    required Map<String, dynamic> answers,
    String? result,
  }) async {
    try {
      await _firestore.collection('quiz_results').add({
        'userId': userId,
        'quizId': quizId,
        'score': score,
        'answers': answers,
        'result': result,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Error adding quiz result: $e');
    }
  }

  static Stream<QuerySnapshot> getQuizResults(String userId) {
    return _firestore
        .collection('quiz_results')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  // ==================== NOTIFICATION MODEL ====================
  static Future<void> addNotification({
    required String userId,
    required String title,
    required String message,
    String? type,
    Map<String, dynamic>? data,
  }) async {
    try {
      await _firestore.collection('notifications').add({
        'userId': userId,
        'title': title,
        'message': message,
        'type': type ?? 'general',
        'data': data ?? {},
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Error adding notification: $e');
    }
  }

  static Stream<QuerySnapshot> getNotifications(String userId) {
    return _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  static Future<void> markNotificationAsRead(String notificationId) async {
    try {
      await _firestore.collection('notifications').doc(notificationId).update({
        'isRead': true,
        'readAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Error marking notification as read: $e');
    }
  }
}
