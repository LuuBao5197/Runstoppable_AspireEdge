// lib/services/career_suggestion_service.dart
import '../models/CareerType.dart';


class CareerSuggestionService {
  /// Main analysis function that returns the most suitable career type(s).
  List<CareerType> suggestCareerTypes({
    String? educationLevel,
    required List<String> goals,
    required List<String> interests,
  }) {
    // 1. Initialize scores for the six career types
    final Map<CareerType, int> scores = {
      for (var type in CareerType.values) type: 0,
    };

    // 2. Add points based on INTERESTS and GOALS
    // These are the most important factors, so they get a higher weight (e.g., +3 points)
    for (var interestTypeStr in interests) {
      final type = _stringToCareerType(interestTypeStr);
      scores[type] = scores[type]! + 3;
    }
    for (var goalTypeStr in goals) {
      final type = _stringToCareerType(goalTypeStr);
      scores[type] = scores[type]! + 3;
    }

    // 3. Add bonus points based on EDUCATION
    // This is a secondary factor, so it gets a lower weight (e.g., +1, +2 points)
    if (educationLevel != null) {
      switch (educationLevel) {
        case 'Master\'s/PhD':
          scores[CareerType.Investigative] = scores[CareerType.Investigative]! + 2;
          break;
        case 'Associate/Vocational':
          scores[CareerType.Realistic] = scores[CareerType.Realistic]! + 1;
          break;
      }
    }

    // 4. Find the highest score
    if (scores.values.every((score) => score == 0)) return []; // Return empty if nothing was selected

    int maxScore = 0;
    scores.values.forEach((score) {
      if (score > maxScore) {
        maxScore = score;
      }
    });

    // 5. Filter and return all career types that match the highest score
    final List<CareerType> result = [];
    scores.forEach((type, score) {
      if (score == maxScore) {
        result.add(type);
      }
    });

    return result;
  }

  /// Helper function to convert a string (from the option maps) to a CareerType enum.
  CareerType _stringToCareerType(String typeStr) {
    switch (typeStr) {
      case 'Realistic':
        return CareerType.Realistic;
      case 'Investigative':
        return CareerType.Investigative;
      case 'Artistic':
        return CareerType.Artistic;
      case 'Social':
        return CareerType.Social;
      case 'Enterprising':
        return CareerType.Enterprising;
      default: // Conventional
        return CareerType.Conventional;
    }
  }
}