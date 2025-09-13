import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/career_models.dart';
import 'career_seed_data.dart';


Future<void> importSampleCareers() async {
  final firestore = FirebaseFirestore.instance;

  for (final career in sampleCareers) {
    await firestore.collection("careers").add({
      "title": career.title,
      "industry": career.industry,
      "description": career.description,
      "skills": career.skills,
      "salaryRange": career.salaryRange,
      "imageUrl": career.imageUrl,
      "createdAt": career.createdAt,
      "updatedAt": career.updatedAt,
      "educationPath": {
        "degree": career.educationPath?.degree,
        "courses": career.educationPath?.courses,
        "certificates": career.educationPath?.certificates,
        "duration": career.educationPath?.duration,
        "careerLevel": career.educationPath?.careerLevel,
        "estimatedCost": career.educationPath?.estimatedCost,
      },
    });
  }

  print("✅ Sample careers imported successfully!");
}
