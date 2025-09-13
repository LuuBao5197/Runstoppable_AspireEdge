import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:path/path.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';

import '../models/QuizLikert.dart';

// Import các lớp Model Quiz, Question... bạn đã tạo

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;
  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('app_database.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);
    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future _createDB(Database db, int version) async {
    // Để đơn giản, chúng ta lưu cả câu hỏi vào một bảng duy nhất
    await db.execute('''
      CREATE TABLE quiz_questions (
        id TEXT PRIMARY KEY,
        text TEXT NOT NULL,
        mapsToGroup TEXT NOT NULL
      )
    ''');
    // Bạn cũng có thể tạo bảng cho scale, title... nếu muốn
  }

  // HÀM ĐỒNG BỘ HÓA CHÍNH
  Future<void> syncQuizDataIfNeeded() async {
    // 1. Kiểm tra mạng
    final connectivityResult = await Connectivity().checkConnectivity();
    if (!connectivityResult.contains(ConnectivityResult.mobile) &&
        !connectivityResult.contains(ConnectivityResult.wifi)) {
      print("Không có mạng, dùng dữ liệu offline.");
      return;
    }

    // 2. Lấy phiên bản remote và local
    final prefs = await SharedPreferences.getInstance();
    final localVersion = prefs.getInt('localQuizVersion') ?? 0;

    final remoteVersionDoc = await FirebaseFirestore.instance.collection('metadata').doc('quizVersion').get();
    final remoteVersion = remoteVersionDoc.data()?['version'] ?? 1;

    // 3. So sánh và quyết định đồng bộ
    if (remoteVersion > localVersion) {
      print("Phát hiện phiên bản mới! Bắt đầu đồng bộ...");

      // 4. Tải dữ liệu từ Firestore
      final quizDoc = await FirebaseFirestore.instance.collection('quizzes').doc('generalInterestQuiz_v1').get();
      final quiz = Quiz.fromFirestore(quizDoc);

      // 5. Cập nhật vào SQFlite
      await _updateLocalDatabase(quiz);

      // 6. Lưu lại phiên bản mới
      await prefs.setInt('localQuizVersion', remoteVersion);
      print("Đồng bộ thành công phiên bản $remoteVersion.");
    } else {
      print("Dữ liệu đã là phiên bản mới nhất.");
    }
  }

  Future<void> _updateLocalDatabase(Quiz quiz) async {
    final db = await instance.database;
    await db.transaction((txn) async {
      // Xóa tất cả dữ liệu cũ
      await txn.delete('quiz_questions');

      // Chèn dữ liệu mới
      for (final question in quiz.questions) {
        await txn.insert('quiz_questions', {
          'id': question.id,
          'text': question.text,
          'mapsToGroup': question.mapsToGroup
        });
      }
    });
  }

  // Hàm để đọc quiz từ SQFlite để hiển thị
  Future<List<Question>> getQuizQuestionsFromLocalDB() async {
    final db = await instance.database;
    final maps = await db.query('quiz_questions');
    if (maps.isNotEmpty) {
      return maps.map((map) => Question.fromMap(map)).toList();
    } else {
      return [];
    }
  }
}