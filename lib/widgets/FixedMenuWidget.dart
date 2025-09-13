import 'package:flutter/material.dart';

import '../pages/Quizzes/QuizScreen.dart';
import '../pages/Quizzes/QuizScreenLikert.dart';
import '../pages/Quizzes/SurveyScreen.dart';

class FixedMenuWidget extends StatelessWidget {
  const FixedMenuWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white, // nền cho menu
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildMenuItem(
            context,
            icon: Icons.psychology,
            color: Colors.orange,
            label: "AI powered quiz",
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const QuizScreen()),
            ),
          ),
          _buildMenuItem(
            context,
            icon: Icons.rule,
            color: Colors.blue,
            label: "Normal Quiz",
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const QuizScreenLiker()),
            ),
          ),
          _buildMenuItem(
            context,
            icon: Icons.checklist,
            color: Colors.green,
            label: "Survey",
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SurveyScreen()),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(
      BuildContext context, {
        required IconData icon,
        required Color color,
        required String label,
        required VoidCallback onPressed,
      }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        FloatingActionButton(
          mini: true,
          heroTag: null,
          onPressed: onPressed,
          backgroundColor: color,
          child: Icon(icon, size: 20),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}
