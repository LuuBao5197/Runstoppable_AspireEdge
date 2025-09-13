// lib/screens/survey_screen.dart

import 'package:flutter/material.dart';
import 'package:trackmentalhealth/pages/Quizzes/QuizSurveyResultScreen.dart';
import '../../services/CareerSuggestionService.dart';

class SurveyScreen extends StatefulWidget {
  const SurveyScreen({super.key});
  @override
  State<SurveyScreen> createState() => _SurveyScreenState();
}

class _SurveyScreenState extends State<SurveyScreen> {
  // Variables to store user selections
  String? _selectedEducation;
  final Set<String> _selectedGoals = {};
  final Set<String> _selectedInterests = {};

  // Define the options and their corresponding career types for the logic
  // Key: The text displayed to the user
  // Value: The career type string for the scoring logic
  final Map<String, String> _goalOptions = {
    'To lead, persuade, or manage a team': 'Enterprising',
    'To help, teach, or provide service to others': 'Social',
    'To have creative freedom and self-expression': 'Artistic',
    'To have a stable, secure job with clear procedures': 'Conventional',
    'To solve complex problems and conduct research': 'Investigative',
  };

  final Map<String, String> _interestOptions = {
    'Building, repairing things, or working outdoors': 'Realistic',
    'Analyzing data, conducting experiments, or investigating theories': 'Investigative',
    'Designing, writing, composing music, or performing': 'Artistic',
    'Volunteering, counseling, or training people': 'Social',
    'Starting a business, selling products, or public speaking': 'Enterprising',
    'Organizing data, managing budgets, or working with spreadsheets': 'Conventional',
  };

  /// Called when the user presses the "See Results" button
  void _submitSurvey() {
    final service = CareerSuggestionService();

    // Get the list of career type strings from the user's selections
    final goals = _selectedGoals.map((key) => _goalOptions[key]!).toList();
    final interests = _selectedInterests.map((key) => _interestOptions[key]!).toList();

    // Call the "brain" to get the analysis
    final suggestedTypes = service.suggestCareerTypes(
      educationLevel: _selectedEducation,
      goals: goals,
      interests: interests,
    );

    // Navigate to the results screen and pass the data
    Navigator.of(context).push(MaterialPageRoute(
      builder: (context) => QuizSurveyResultScreen(careerTypes: suggestedTypes),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Career Aptitude Survey'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- 1. EDUCATION ---
            Text(
              'Your highest level of education',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              value: _selectedEducation,
              hint: const Text('Select your education level'),
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              ),
              items: ['High School', 'Associate/Vocational', 'Bachelor\'s Degree', 'Master\'s/PhD']
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
              onChanged: (value) => setState(() => _selectedEducation = value),
            ),
            const SizedBox(height: 30),

            // --- 2. GOALS ---
            Text(
              'What are your career goals?',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            ..._goalOptions.keys.map((goal) {
              return CheckboxListTile(
                title: Text(goal),
                value: _selectedGoals.contains(goal),
                onChanged: (value) {
                  setState(() {
                    if (value!) {
                      _selectedGoals.add(goal);
                    } else {
                      _selectedGoals.remove(goal);
                    }
                  });
                },
              );
            }).toList(),
            const SizedBox(height: 30),

            // --- 3. INTERESTS ---
            Text(
              'Which activities do you enjoy?',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            ..._interestOptions.keys.map((interest) {
              return CheckboxListTile(
                title: Text(interest),
                value: _selectedInterests.contains(interest),
                onChanged: (value) {
                  setState(() {
                    if (value!) {
                      _selectedInterests.add(interest);
                    } else {
                      _selectedInterests.remove(interest);
                    }
                  });
                },
              );
            }).toList(),

            // --- SUBMIT BUTTON ---
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: _submitSurvey,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                textStyle: const TextStyle(fontSize: 18),
              ),
              child: const Text('View Career Suggestions'),
            ),
          ],
        ),
      ),
    );
  }
}