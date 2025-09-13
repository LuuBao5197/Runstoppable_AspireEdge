import 'package:flutter/material.dart';
import 'package:trackmentalhealth/pages/Quizzes/QuizResultLikert.dart';

import '../../helper/DatabaseHelper.dart';
import '../../models/QuizLikert.dart';


class QuizScreenLiker extends StatefulWidget {
  const QuizScreenLiker({super.key});

  @override
  State<QuizScreenLiker> createState() => _QuizScreenLikerState();
}

class _QuizScreenLikerState extends State<QuizScreenLiker> {
  late Future<List<Question>> _quizQuestionsFuture;
  final PageController _pageController = PageController();

  final Map<String, int> scores = {
    'Realistic': 0, 'Investigative': 0, 'Artistic': 0,
    'Social': 0, 'Enterprising': 0, 'Conventional': 0,
  };

  final List<ScaleOption> scaleOptions = [
    ScaleOption(text: "Strongly Dislike", score: 0),
    ScaleOption(text: "Dislike", score: 1),
    ScaleOption(text: "Neutral", score: 2),
    ScaleOption(text: "Like", score: 3),
    ScaleOption(text: "Strongly Like", score: 4),
  ];

  @override
  void initState() {
    super.initState();
    _quizQuestionsFuture = _loadAndShuffleQuestions();
  }

  Future<List<Question>> _loadAndShuffleQuestions() async {
    final allQuestions = await DatabaseHelper.instance.getQuizQuestionsFromLocalDB();
    if (allQuestions.isEmpty) return [];

    final Map<String, List<Question>> groupedQuestions = {};
    for (var q in allQuestions) {
      (groupedQuestions[q.mapsToGroup] ??= []).add(q);
    }

    final List<Question> finalQuizList = [];
    groupedQuestions.forEach((group, questionsInGroup) {
      questionsInGroup.shuffle();
      // Đảm bảo không lấy quá số câu hỏi hiện có trong nhóm
      final questionsToTake = questionsInGroup.length < 4 ? questionsInGroup.length : 4;
      finalQuizList.addAll(questionsInGroup.take(questionsToTake));
    });

    finalQuizList.shuffle();
    return finalQuizList;
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  // THAY THẾ HÀM CŨ BẰNG HÀM NÀY
  void _onAnswerSelected(Question question, ScaleOption option, int currentIndex, int totalQuestions) {
    setState(() {
      scores[question.mapsToGroup] = (scores[question.mapsToGroup] ?? 0) + option.score;
    });

    // LOGIC ĐÚNG: So sánh số nguyên đơn giản
    if (currentIndex < totalQuestions) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeIn,
      );
    } else {
      // Nếu là câu hỏi cuối cùng, gọi kết quả
      _showResults();
    }
  }
  // =================================================================
  // HÀM _showResults() ĐÃ ĐƯỢC NÂNG CẤP HOÀN CHỈNH
  // =================================================================
  void _showResults() {
    // 1. Chuyển Map điểm số thành một List để sắp xếp
    final sortedScores = scores.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // 2. Lấy ra 2 nhóm có điểm số cao nhất
    final topTwoGroups = sortedScores.take(2).toList();
    final resultText =
        "1. ${topTwoGroups[0].key}: ${topTwoGroups[0].value} điểm\n"
        "2. ${topTwoGroups[1].key}: ${topTwoGroups[1].value} điểm";

    // 3. Hiển thị kết quả trong một Dialog
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
      builder: (_) => QuizLikertResultScreen(scores: scores),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Bài Trắc nghiệm Sở thích"),
      ),
      body: FutureBuilder<List<Question>>(
        future: _quizQuestionsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text("Lỗi tải dữ liệu: ${snapshot.error}"));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text(
                "Không có dữ liệu quiz.\nVui lòng đảm bảo bạn đã kết nối mạng trong lần đầu sử dụng.",
                textAlign: TextAlign.center,
              ),
            );
          } else {
            final questions = snapshot.data!;
            return buildQuizView(questions);
          }
        },
      ),
    );
  }

  Widget buildQuizView(List<Question> questions) {
    return PageView.builder(
      controller: _pageController,
      itemCount: questions.length,
      physics: const NeverScrollableScrollPhysics(),
      itemBuilder: (context, index) {
        final question = questions[index];
        return buildQuestionPage(question, index + 1, questions.length);
      },
    );
  }

  Widget buildQuestionPage(Question question, int currentIndex, int totalQuestions) {
    // Code phần này không thay đổi
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Câu $currentIndex / $totalQuestions',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 20),
          Text(
            question.text,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 40),
          ...scaleOptions.map((option) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 6.0),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: const TextStyle(fontSize: 16),
                ),
                  onPressed: () => _onAnswerSelected(question, option, currentIndex, totalQuestions),
                child: Text(option.text),
              ),
            );
          }).toList(),
        ],
      ),
    );
  }
}