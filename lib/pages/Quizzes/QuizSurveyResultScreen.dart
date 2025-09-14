// lib/screens/result_screen.dart

import 'package:flutter/material.dart';
import 'package:trackmentalhealth/models/CareerType.dart';

class QuizSurveyResultScreen extends StatelessWidget {
  final List<CareerType> careerTypes;

  const QuizSurveyResultScreen({super.key, required this.careerTypes});

  /// Helper function to get display details (icon, color, description) for each career type.
  Map<String, dynamic> _getCareerTypeDetails(CareerType type) {
    switch (type) {
      case CareerType.Realistic:
        return {
          'title': 'Realistic (The "Doers")',
          'description': 'You likely enjoy hands-on work with tools, machinery, or animals. You are practical and grounded.\n\nSuggested Careers: Engineer, Chef, Pilot, Carpenter, Mechanic.',
          'icon': Icons.build_circle_outlined,
          'color': const Color(0xFF8D6E63) // Brown
        };
      case CareerType.Investigative:
        return {
          'title': 'Investigative (The "Thinkers")',
          'description': 'You are analytical, curious, and enjoy solving complex problems. You excel at research and intellectual challenges.\n\nSuggested Careers: Scientist, Doctor, Software Developer, Data Analyst.',
          'icon': Icons.science_outlined,
          'color': const Color(0xFF42A5F5) // Blue
        };
      case CareerType.Artistic:
        return {
          'title': 'Artistic (The "Creators")',
          'description': 'You are creative, imaginative, and value self-expression. You thrive in unstructured environments.\n\nSuggested Careers: Graphic Designer, Writer, Musician, Actor, Architect.',
          'icon': Icons.palette_outlined,
          'color': const Color(0xFFAB47BC) // Purple
        };
      case CareerType.Social:
        return {
          'title': 'Social (The "Helpers")',
          'description': 'You are empathetic, cooperative, and enjoy helping, teaching, and working with others.\n\nSuggested Careers: Teacher, Counselor, Nurse, Social Worker, HR Manager.',
          'icon': Icons.people_outline,
          'color': const Color(0xFF66BB6A) // Green
        };
      case CareerType.Enterprising:
        return {
          'title': 'Enterprising (The "Persuaders")',
          'description': 'You are ambitious, assertive, and enjoy leading, selling, and influencing people to achieve goals.\n\nSuggested Careers: Sales Manager, Entrepreneur, Lawyer, Marketing Director.',
          'icon': Icons.business_center_outlined,
          'color': const Color(0xFFEF5350) // Red
        };
      case CareerType.Conventional:
        return {
          'title': 'Conventional (The "Organizers")',
          'description': 'You are detail-oriented, organized, and efficient. You excel at working with data and following clear procedures.\n\nSuggested Careers: Accountant, Financial Analyst, Web Developer, Librarian.',
          'icon': Icons.edit_note_outlined,
          'color': const Color(0xFFFFA726) // Orange
        };
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Suggested Career Paths'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: careerTypes.isEmpty
            ? const Center(child: Text('Please go back and complete the survey to see your results!'))
            : Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Based on your answers, these career types are your best match:',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: careerTypes.length,
                itemBuilder: (context, index) {
                  final type = careerTypes[index];
                  final details = _getCareerTypeDetails(type);
                  return Card(
                    elevation: 4.0,
                    margin: const EdgeInsets.only(bottom: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(details['icon'], color: details['color'], size: 32),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  details['title'],
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: details['color'],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            details['description'],
                            style: const TextStyle(fontSize: 16, height: 1.4),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}