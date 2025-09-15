import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
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
  List<Map<String, dynamic>> finalResults = [];

  final String _cloudFunctionUrl = "https://get-next-question-mn2447zabq-uc.a.run.app";

  Future<void> startQuiz() {
    return getNextQuestion();
  }

  Future<void> getNextQuestion() async {
    isLoading = true;
    notifyListeners();

    try {
      final url = Uri.parse(_cloudFunctionUrl);

      final body = json.encode({
        "quiz_id": "career_interest_quiz_v1",
        "current_scores": userScores,
        "answered_question_ids": answeredQuestionIds
      });

      //POST to Firebase Function
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: body,
      );

      if (response.statusCode == 200) {
        final responseJson = json.decode(response.body);
        print("response: $responseJson");

        // Check end quizz?
        if (responseJson['status'] == 'completed') {
          await processFinalScores(responseJson['final_scores']);
          // isQuizCompleted = true;
          // quizCompletionMessage = responseJson['message'] ?? "Quiz Finished!";
          // currentQuestion = null;
        } else {
          // 4. Update new quesation
          currentQuestion = responseJson;
          answeredQuestionIds.add(currentQuestion!['questionId']);

          // Update status of Skip Button
          String questionId = currentQuestion!['questionId'];
          canSkipCurrentQuestion = questionId.startsWith('op_') || questionId.startsWith('df');
        }
      } else {
        // Handle error from server
        print("Server error: ${response.body}");
      }
    } catch (e) {
      print("Network error: $e");
    }

    isLoading = false;
    notifyListeners();
  }

  //Handle end mark
  Future<void> processFinalScores(Map<String, dynamic> finalScores) async {
    final sortedScores = finalScores.entries.toList()
      ..sort((a, b) => (b.value as int).compareTo(a.value as int));

    final topTwoCategories = sortedScores.take(2).toList();

    final db = FirebaseFirestore.instance;
    for (var categoryEntry in topTwoCategories) {
      final docId = categoryEntry.key;
      final docSnapshot = await db.collection('career_suggestions').doc(docId).get();
      if (docSnapshot.exists) {
        finalResults.add(docSnapshot.data()!);
      }
    }
    isQuizCompleted = true;
    isLoading = false;
    notifyListeners();
  }

  void answerMultipleChoice(Map<String, dynamic> scores) {
    scores.forEach((key, value) {
      if (userScores.containsKey(key)) {
        userScores[key] = userScores[key]! + (value as int);
      }
    });
    getNextQuestion();
  }

  void answerRanking(List<dynamic> rankedOptions) {
    for (int i = 0; i < rankedOptions.length; i++) {
      final option = rankedOptions[i];
      final category = option['category'];
      final score = 6 - i;
      if (userScores.containsKey(category)) {
        userScores[category] = userScores[category]! + score;
      }
    }
    getNextQuestion();
  }

  void skipQuestion() {
    getNextQuestion();
  }
}