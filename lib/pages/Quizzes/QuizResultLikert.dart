import 'package:flutter/material.dart';

import '../../helper/CareerData.dart';
import 'QuizScreenLikert.dart';


class QuizLikertResultScreen extends StatelessWidget {
  final Map<String, int> scores;

  const QuizLikertResultScreen({Key? key, required this.scores}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Xử lý logic để tìm ra 2 nhóm cao nhất và lấy dữ liệu tương ứng
    final sortedScores = scores.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final topTwoGroups = sortedScores.take(2).toList();

    // Tạo danh sách kết quả để truyền vào ListView.builder
    final List<Map<String, dynamic>> results = [
      careerProfileData[topTwoGroups[0].key]!,
      careerProfileData[topTwoGroups[1].key]!,
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text("Your Career Profile"),
        automaticallyImplyLeading: false, // Ẩn nút back
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(8.0),
        itemCount: results.length,
        itemBuilder: (context, index) {
          final resultData = results[index];
          final careers = resultData['careers'] as List<dynamic>;

          return Card(
            elevation: 4,
            margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    resultData['categoryName'],
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Theme.of(context).primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(resultData['description']),
                  const Divider(height: 24, thickness: 1),
                  Text(
                    "Suggested Careers",
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  // Liệt kê các nghề nghiệp
                  ...careers.map((career) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(Icons.work_outline, color: Theme.of(context).primaryColor),
                    title: Text(career['title'], style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text(career['description']),
                  )).toList(),
                ],
              ),
            ),
          );
        },
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            textStyle: const TextStyle(fontSize: 18),
          ),
          child: const Text("Take the Quiz Again"),
          onPressed: () {
            // Thay thế màn hình kết quả hiện tại bằng một màn hình Quiz mới
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const QuizScreenLiker()),
            );
          },
        ),
      ),
    );
  }
}