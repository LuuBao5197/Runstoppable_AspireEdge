import 'package:flutter/material.dart';
import 'package:trackmentalhealth/pages/Quizzes/QuizScreen.dart';



class ResultScreen extends StatelessWidget {
  final List<Map<String, dynamic>> results;

  const ResultScreen({Key? key, required this.results}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Your Career Profile"),
        automaticallyImplyLeading: false, // Ẩn nút back
      ),
      body: ListView.builder(
        padding: EdgeInsets.all(8.0),
        itemCount: results.length,
        itemBuilder: (context, index) {
          final resultData = results[index];
          final careers = resultData['careers'] as List<dynamic>;

          return Card(
            margin: EdgeInsets.all(8.0),
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
                  SizedBox(height: 8),
                  Text(resultData['description']),
                  Divider(height: 24, thickness: 1),
                  Text(
                    "Suggested Careers",
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  // Liệt kê các nghề nghiệp
                  ...careers.map((career) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(Icons.work_outline, color: Theme.of(context).primaryColor),
                    title: Text(career['title'], style: TextStyle(fontWeight: FontWeight.w600)),
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
          child: Text("Take the Quiz Again"),
          onPressed: () {
            // Quay về màn hình chính hoặc màn hình quiz để làm lại
            // Thay thế màn hình kết quả hiện tại bằng một màn hình Quiz mới
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const QuizScreen()),
            );
          },
        ),
      ),
    );
  }
}