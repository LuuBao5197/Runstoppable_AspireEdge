import 'package:flutter/material.dart';
import 'package:trackmentalhealth/widgets/ProfessionalWidget.dart';
import 'package:trackmentalhealth/widgets/StudentWidget.dart';
import 'GraduateScreenWidget.dart';
// Enum để quản lý các lựa chọn một cách an toàn
enum UserCategory { student, graduate, professional }

class CategorySelectionScreen extends StatelessWidget {
  const CategorySelectionScreen({super.key});

  // Hàm xử lý khi một category được chọn
  void _onCategorySelected(BuildContext context, UserCategory category) {
    // In ra để kiểm tra
    print('Selected category: ${category.name}');
    if(category == UserCategory.student){
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => StudentScreen()),
      );
    } else if (category == UserCategory.graduate) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => GraduateScreen()),
      );
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => ProfessionalScreen()),
      );
    }

    // Hiển thị một thông báo tạm thời
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('You selected: ${category.name}')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Choose Your Path'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                "Who are you?",
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Text(
                "Select your current status to get personalized content",
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.grey[600]),
              ),
              const SizedBox(height: 40),

              // Widget thẻ cho Student
              _CategoryCard(
                icon: Icons.school_outlined,
                title: "Student",
                subtitle: "Grades 8-12, planning your future.",
                color: Colors.blue,
                onTap: () => _onCategorySelected(context, UserCategory.student),
              ),
              const SizedBox(height: 20),

              // Widget thẻ cho Graduate
              _CategoryCard(
                icon: Icons.auto_stories_outlined,
                title: "Graduate",
                subtitle: "University level, entering the workforce.",
                color: Colors.orange,
                onTap: () => _onCategorySelected(context, UserCategory.graduate),
              ),
              const SizedBox(height: 20),

              // Widget thẻ cho Professional
              _CategoryCard(
                icon: Icons.work_outline_rounded,
                title: "Professional",
                subtitle: "Experienced, looking to grow or change careers.",
                color: Colors.green,
                onTap: () => _onCategorySelected(context, UserCategory.professional),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Widget thẻ có thể tái sử dụng
class _CategoryCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _CategoryCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shadowColor: color.withOpacity(0.3),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Row(
            children: [
              Icon(icon, size: 40, color: color),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[700]),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios_rounded, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}