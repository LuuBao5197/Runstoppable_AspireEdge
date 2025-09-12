import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class QuizState extends ChangeNotifier {
  // --- State Variables ---
  Map<String, dynamic>? currentQuestion;
  Map<String, int> userScores = {
    'realistic': 0,
    'investigative': 0,
    'artistic': 0,
    'social': 0,
    'enterprising': 0,
    'conventional': 0,
  };
  List<String> answeredQuestionIds = [];
  bool isLoading = true;
  bool canSkipCurrentQuestion = false;
  bool isQuizCompleted = false;
  String quizCompletionMessage = "";

  // !!! THAY THẾ URL NÀY BẰNG URL FUNCTION CỦA BẠN !!!
  final String _cloudFunctionUrl = "https://get-next-question-mn2447zabq-uc.a.run.app";

  // --- Logic Functions ---

  // Hàm này được gọi đầu tiên để bắt đầu quiz
  Future<void> startQuiz() {
    return getNextQuestion();
  }

  // Hàm chính để lấy câu hỏi từ Cloud Function
  Future<void> getNextQuestion() async {
    isLoading = true;
    notifyListeners();

    try {
      final url = Uri.parse(_cloudFunctionUrl);

      // 1. Chuẩn bị dữ liệu để gửi lên
      final body = json.encode({
        "quiz_id": "career_interest_quiz_v1",
        "current_scores": userScores,
        "answered_question_ids": answeredQuestionIds
      });

      // 2. Thực hiện yêu cầu POST đến Cloud Function
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: body,
      );

      if (response.statusCode == 200) {
        final responseJson = json.decode(response.body);
        print("response: $responseJson");

        // 3. Kiểm tra xem quiz đã kết thúc chưa
        if (responseJson['status'] == 'completed') {
          isQuizCompleted = true;
          quizCompletionMessage = responseJson['message'] ?? "Quiz Finished!";
          currentQuestion = null;
        } else {
          // 4. Cập nhật câu hỏi mới
          currentQuestion = responseJson;
          answeredQuestionIds.add(currentQuestion!['questionId']);

          // Cập nhật trạng thái nút Skip
          String questionId = currentQuestion!['questionId'];
          canSkipCurrentQuestion = questionId.startsWith('op_') || questionId.startsWith('df');
        }
      } else {
        // Xử lý lỗi từ server
        print("Server error: ${response.body}");
        // Có thể gán một thông báo lỗi để hiển thị trên UI
      }

    } catch (e) {
      // Xử lý lỗi mạng
      print("Network error: $e");
      // Có thể gán một thông báo lỗi để hiển thị trên UI
    }

    isLoading = false;
    notifyListeners();
  }

  // Hàm xử lý khi người dùng trả lời (ví dụ cho câu hỏi trắc nghiệm)
  void answerMultipleChoice(Map<String, dynamic> scores) {
    // Cộng điểm vào hồ sơ người dùng
    scores.forEach((key, value) {
      if (userScores.containsKey(key)) {
        userScores[key] = userScores[key]! + (value as int);
      }
    });
    getNextQuestion(); // Lấy câu hỏi tiếp theo
  }

  // Hàm xử lý khi người dùng trả lời câu hỏi sắp xếp
  void answerRanking(List<dynamic> rankedOptions) {
    for (int i = 0; i < rankedOptions.length; i++) {
      final option = rankedOptions[i];
      final category = option['category'];
      final score = 6 - i; // Hạng 1 được 6 điểm, hạng 2 được 5, ...
      if (userScores.containsKey(category)) {
        userScores[category] = userScores[category]! + score;
      }
    }
    getNextQuestion(); // Lấy câu hỏi tiếp theo
  }

  void skipQuestion() {
    // Không cộng điểm, chỉ cần lấy câu hỏi tiếp theo
    // ID của câu hỏi bị bỏ qua đã được thêm vào answeredQuestionIds ở lần getNextQuestion trước đó
    getNextQuestion();
  }
}