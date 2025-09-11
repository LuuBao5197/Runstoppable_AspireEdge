import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:cloud_firestore/cloud_firestore.dart';

Future<void> importCareerData() async {
  try {
    // Load JSON từ assets
    final String response =
    await rootBundle.loadString('assets/career_bank_data.json');
    final Map<String, dynamic> data = json.decode(response);

    final firestore = FirebaseFirestore.instance;

    for (final entry in data.entries) {
      final industry = entry.key; // ví dụ: "Technology – Engineering"
      final careers = entry.value as List;

      final industryRef = firestore.collection("CareerBank").doc(industry);

      for (final career in careers) {
        await industryRef.collection("careers").add(career);
        print("✅ Imported career: ${career['title']} into $industry");
      }
    }

    print("🎉 Import completed!");
  } catch (e) {
    print("❌ Import failed: $e");
  }
}
