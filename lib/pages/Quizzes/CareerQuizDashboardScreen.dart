import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:trackmentalhealth/widgets/FixedMenuWidget.dart';

class CareerDashboardScreen extends StatefulWidget {
  const CareerDashboardScreen({super.key});

  @override
  State<CareerDashboardScreen> createState() => _CareerDashboardScreenState();
}

class _CareerDashboardScreenState extends State<CareerDashboardScreen> {
  late Future<List<QueryDocumentSnapshot>> _suggestionsFuture;

  @override
  void initState() {
    super.initState();
    _suggestionsFuture = _loadSuggestions();
  }

  Future<List<QueryDocumentSnapshot>> _loadSuggestions() async {
    final snapshot = await FirebaseFirestore.instance.collection('career_suggestions').get();
    final docs = snapshot.docs;
    docs.shuffle(); // Xáo trộn để mỗi lần vào lại thấy khác
    return docs.take(6).toList(); // Chỉ lấy 3 nhóm để hiển thị
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Career Discovery Toolkit'),
      ),
      body: Stack(
        children: [
          // Display list suggestions
          FutureBuilder<List<QueryDocumentSnapshot>>(
            future: _suggestionsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Center(child: Text("No career suggestions found."));
              }

              final suggestions = snapshot.data!;
              return ListView(
                padding: const EdgeInsets.all(12.0),
                children: [
                  Text(
                    "Explore Career Paths",
                    style: Theme.of(context).textTheme.headlineMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ...suggestions.map((doc) => CareerSuggestionCard(data: doc.data() as Map<String, dynamic>)).toList(),
                  const SizedBox(height: 80),
                ],
              );
            },
          ),

          //  Widget Menu Spin
          const Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: EdgeInsets.only(bottom: 15.0),
              child: FixedMenuWidget(),
            ),
          ),
        ],
      ),
    );
  }
}

// Widget thẻ con để hiển thị thông tin nghề nghiệp, có thể tách ra file riêng
class CareerSuggestionCard extends StatelessWidget {
  final Map<String, dynamic> data;
  const CareerSuggestionCard({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final careers = data['careers'] as List<dynamic>? ?? [];
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              data['categoryName'] ?? 'N/A',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(data['description'] ?? 'No description available.'),
            if (careers.isNotEmpty) ...[
              const Divider(height: 24, thickness: 1),
              Text(
                "Examples",
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ...careers.take(2).map((career) => ListTile( // Chỉ hiển thị 2 ví dụ
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.work_outline, color: Theme.of(context).colorScheme.secondary),
                title: Text(career['title'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600)),
              )).toList(),
            ]
          ],
        ),
      ),
    );
  }
}