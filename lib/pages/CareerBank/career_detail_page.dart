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
            if (data["education_path"] != null) ...[
              Text("   - Degree: ${data["education_path"]["degree"] ?? ""}"),
              Text("   - Courses: ${(data["education_path"]["courses"] as List<dynamic>?)?.join(', ') ?? ""}"),
              Text("   - Certificates: ${(data["education_path"]["certificates"] as List<dynamic>?)?.join(', ') ?? ""}"),
              Text("   - Duration: ${data["education_path"]["duration"] ?? ""}"),
              Text("   - Level: ${data["education_path"]["career_level"] ?? ""}"),
              Text("   - Cost: ${data["education_path"]["estimated_cost"] ?? ""}"),
            ]


          ],
        ),
      ),
    );
  }
}
