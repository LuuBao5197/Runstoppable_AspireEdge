// lib/MultipleChoiceWidget.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'QuizState.dart'; // Import QuizState

class MultipleChoiceWidget extends StatefulWidget {
  final Map<String, dynamic> question;
  const MultipleChoiceWidget({super.key, required this.question});

  @override
  State<MultipleChoiceWidget> createState() => _MultipleChoiceWidgetState();
}

class _MultipleChoiceWidgetState extends State<MultipleChoiceWidget> {
  Map<String, dynamic>? _selectedAnswer;

  @override
  Widget build(BuildContext context) {
    final List<dynamic> answers = widget.question['answers'];

    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            itemCount: answers.length,
            itemBuilder: (context, index) {
              final answer = answers[index];
              return Padding(
                padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                child: RadioListTile<Map<String, dynamic>>(
                  title: Text(answer['answerText']),
                  value: answer,
                  groupValue: _selectedAnswer,
                  onChanged: (value) {
                    setState(() {
                      _selectedAnswer = value;
                    });
                  },
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.0),
                      side: BorderSide(
                        color: _selectedAnswer == answer
                            ? Theme.of(context).primaryColor
                            : Colors.grey.shade300,
                      )),
                  tileColor: Colors.white,
                ),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              minimumSize: Size(double.infinity, 50),
            ),
            onPressed: _selectedAnswer == null
                ? null
                : () {
              // === THAY ĐỔI Ở ĐÂY ===
              final scores = _selectedAnswer!['scores'] as Map<String, dynamic>;

              // Gọi hàm trong QuizState để xử lý
              context.read<QuizState>().answerMultipleChoice(scores);
            },
            child: Text("Submit Answer"),
          ),
        ),
      ],
    );
  }
}