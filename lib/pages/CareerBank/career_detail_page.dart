import 'package:flutter/material.dart';

class CareerDetailPage extends StatelessWidget {
  final Map<String, dynamic> data;

  const CareerDetailPage({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(data["title"] ?? "Career Detail"),
        backgroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (data["imageUrl"] != null && data["imageUrl"].toString().isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  data["imageUrl"],
                  width: double.infinity,
                  height: 200,
                  fit: BoxFit.cover,
                ),
              ),
            const SizedBox(height: 16),
            Text(
              data["title"] ?? "",
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(data["description"] ?? ""),
            const SizedBox(height: 16),
            if (data["skills"] != null)
              Text("💡 Skills: ${(data["skills"] as List<dynamic>).join(", ")}"),
            const SizedBox(height: 8),
            Text("💰 Salary: ${data["salaryRange"] ?? ""}"),
            const SizedBox(height: 12),
            const Text("🎓 Education Path:", style: TextStyle(fontWeight: FontWeight.bold)),

            if (data["educationPath"] != null) ...[
              Text("   - Degree: ${data["educationPath"]["degree"] ?? ""}"),
              Text("   - Courses: ${(data["educationPath"]["courses"] as List<dynamic>?)?.join(', ') ?? ""}"),
              Text("   - Certificates: ${(data["educationPath"]["certificates"] as List<dynamic>?)?.join(', ') ?? ""}"),
              Text("   - Duration: ${data["educationPath"]["duration"] ?? ""}"),
              Text("   - Level: ${data["educationPath"]["careerLevel"] ?? ""}"),
              Text("   - Cost: ${data["educationPath"]["estimatedCost"] ?? ""}"),
            ]

          ],
        ),
      ),
    );
  }
}
