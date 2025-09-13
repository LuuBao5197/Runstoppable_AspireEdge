import 'package:cloud_firestore/cloud_firestore.dart';

// Model cho các lựa chọn của thang đo Likert
class ScaleOption {
  final String text;
  final int score;

  ScaleOption({required this.text, required this.score});

  // Factory constructor để tạo một ScaleOption từ một Map (dữ liệu từ Firestore)
  factory ScaleOption.fromMap(Map<String, dynamic> map) {
    return ScaleOption(
      text: map['text'] ?? '',
      score: map['score'] ?? 0,
    );
  }
}

// Model cho mỗi câu hỏi
class Question {
  final String id;
  final String text;
  final String mapsToGroup;

  Question({
    required this.id,
    required this.text,
    required this.mapsToGroup,
  });

  // Factory constructor để tạo một Question từ một Map
  factory Question.fromMap(Map<String, dynamic> map) {
    return Question(
      id: map['id'] ?? '',
      text: map['text'] ?? '',
      mapsToGroup: map['mapsToGroup'] ?? '',
    );
  }

  // Hàm để chuyển đổi một đối tượng Question thành Map, dùng để chèn vào SQFlite
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'text': text,
      'mapsToGroup': mapsToGroup,
    };
  }
}

// Model cho toàn bộ bài quiz
class Quiz {
  final String title;
  final int version;
  final List<ScaleOption> scale;
  final List<Question> questions;

  Quiz({
    required this.title,
    required this.version,
    required this.scale,
    required this.questions,
  });

  // Factory constructor để tạo một đối tượng Quiz hoàn chỉnh từ document của Firestore
  factory Quiz.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return Quiz(
      title: data['title'] ?? 'Quiz',
      version: data['version'] ?? 1,
      scale: (data['scale'] as List<dynamic>? ?? [])
          .map((s) => ScaleOption.fromMap(s as Map<String, dynamic>))
          .toList(),
      questions: (data['questions'] as List<dynamic>? ?? [])
          .map((q) => Question.fromMap(q as Map<String, dynamic>))
          .toList(),
    );
  }
}