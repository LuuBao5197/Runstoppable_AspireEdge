import 'package:cloud_firestore/cloud_firestore.dart';

// ==================== USER MODEL ====================
class FirebaseUser {
  final String uid;
  final String email;
  final String fullname;
  final String? avatar;
  final String? phone;
  final DateTime createdAt;
  final DateTime updatedAt;

  FirebaseUser({
    required this.uid,
    required this.email,
    required this.fullname,
    this.avatar,
    this.phone,
    required this.createdAt,
    required this.updatedAt,
  });

  factory FirebaseUser.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return FirebaseUser(
      uid: doc.id,
      email: data['email'] ?? '',
      fullname: data['fullname'] ?? '',
      avatar: data['avatar'],
      phone: data['phone'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'fullname': fullname,
      'avatar': avatar,
      'phone': phone,
    };
  }
}

// ==================== MOOD ENTRY MODEL ====================
class MoodEntry {
  final String id;
  final String userId;
  final int moodScore;
  final String moodType;
  final String? note;
  final List<String> tags;
  final DateTime createdAt;

  MoodEntry({
    required this.id,
    required this.userId,
    required this.moodScore,
    required this.moodType,
    this.note,
    required this.tags,
    required this.createdAt,
  });

  factory MoodEntry.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return MoodEntry(
      id: doc.id,
      userId: data['userId'] ?? '',
      moodScore: data['moodScore'] ?? 0,
      moodType: data['moodType'] ?? '',
      note: data['note'],
      tags: List<String>.from(data['tags'] ?? []),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'moodScore': moodScore,
      'moodType': moodType,
      'note': note,
      'tags': tags,
    };
  }
}

// ==================== DIARY ENTRY MODEL ====================
class DiaryEntry {
  final String id;
  final String userId;
  final String title;
  final String content;
  final String? mood;
  final List<String> tags;
  final DateTime createdAt;
  final DateTime updatedAt;

  DiaryEntry({
    required this.id,
    required this.userId,
    required this.title,
    required this.content,
    this.mood,
    required this.tags,
    required this.createdAt,
    required this.updatedAt,
  });

  factory DiaryEntry.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return DiaryEntry(
      id: doc.id,
      userId: data['userId'] ?? '',
      title: data['title'] ?? '',
      content: data['content'] ?? '',
      mood: data['mood'],
      tags: List<String>.from(data['tags'] ?? []),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'title': title,
      'content': content,
      'mood': mood,
      'tags': tags,
    };
  }
}

// ==================== QUIZ RESULT MODEL ====================
class QuizResult {
  final String id;
  final String userId;
  final String quizId;
  final int score;
  final Map<String, dynamic> answers;
  final String? result;
  final DateTime createdAt;

  QuizResult({
    required this.id,
    required this.userId,
    required this.quizId,
    required this.score,
    required this.answers,
    this.result,
    required this.createdAt,
  });

  factory QuizResult.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return QuizResult(
      id: doc.id,
      userId: data['userId'] ?? '',
      quizId: data['quizId'] ?? '',
      score: data['score'] ?? 0,
      answers: Map<String, dynamic>.from(data['answers'] ?? {}),
      result: data['result'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'quizId': quizId,
      'score': score,
      'answers': answers,
      'result': result,
    };
  }
}

// ==================== NOTIFICATION MODEL ====================
class FirebaseNotification {
  final String id;
  final String userId;
  final String title;
  final String message;
  final String type;
  final Map<String, dynamic> data;
  final bool isRead;
  final DateTime createdAt;
  final DateTime? readAt;

  FirebaseNotification({
    required this.id,
    required this.userId,
    required this.title,
    required this.message,
    required this.type,
    required this.data,
    required this.isRead,
    required this.createdAt,
    this.readAt,
  });

  factory FirebaseNotification.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return FirebaseNotification(
      id: doc.id,
      userId: data['userId'] ?? '',
      title: data['title'] ?? '',
      message: data['message'] ?? '',
      type: data['type'] ?? 'general',
      data: Map<String, dynamic>.from(data['data'] ?? {}),
      isRead: data['isRead'] ?? false,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      readAt: data['readAt'] != null 
          ? (data['readAt'] as Timestamp).toDate() 
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'title': title,
      'message': message,
      'type': type,
      'data': data,
      'isRead': isRead,
    };
  }
}
