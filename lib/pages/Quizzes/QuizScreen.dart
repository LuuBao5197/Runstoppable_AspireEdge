// lib/QuizScreen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'MultipleChoiceWidget.dart';
import 'QuizState.dart';
import 'RankingWidget.dart';
import 'ResultScreen.dart';

class QuizScreen extends StatelessWidget {
  const QuizScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) =>
      QuizState()..startQuiz(), // Bắt đầu lấy câu hỏi đầu tiên
      child: Scaffold(
        appBar: AppBar(title: Text("Career Interest Quiz")),
        body: Consumer<QuizState>(
          builder: (context, state, child) {
            if (state.isQuizCompleted) {
              // Dùng addPostFrameCallback để điều hướng một cách an toàn sau khi build xong
              WidgetsBinding.instance.addPostFrameCallback((_) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => ResultScreen(results: state.finalResults)),
                );
              });
              // Trong khi chờ điều hướng, hiển thị loading
              return Center(child: CircularProgressIndicator());
            }

            if (state.isLoading || state.currentQuestion == null) {
              return Center(child: CircularProgressIndicator());
            }

            if (state.currentQuestion == null) {
              return Center(child: Text("Loading question..."));
            }

            Widget questionWidget;
            String questionType = state.currentQuestion!['questionType'];

            if (questionType == 'ranking') {
              questionWidget = RankingWidget(question: state.currentQuestion!);
            } else {
              questionWidget =
                  MultipleChoiceWidget(question: state.currentQuestion!);
            }

            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    state.currentQuestion!['questionText'],
                    style: Theme.of(context).textTheme.headlineSmall,
                    textAlign: TextAlign.center,
                  ),
                ),
                Expanded(
                  child: questionWidget,
                ),
                if (state.canSkipCurrentQuestion)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: TextButton(
                      onPressed: () {
                        // === THAY ĐỔI Ở ĐÂY ===
                        // Gọi hàm skipQuestion trong QuizState
                        context.read<QuizState>().skipQuestion();
                      },
                      child: Text("Bỏ qua câu hỏi này"),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}