import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

class CareerGuidancePage extends StatefulWidget {
  const CareerGuidancePage({super.key});

  @override
  State<CareerGuidancePage> createState() => _CareerGuidancePageState();
}

class _CareerGuidancePageState extends State<CareerGuidancePage> {
  // Dữ liệu đã được cập nhật để bao gồm các công việc liên quan
  final List<Map<String, dynamic>> industries = const [
    {
      "name": "Technology & Engineering",
      "icon": Icons.engineering,
      "jobs": ["Software Developer", "Data Analyst"]
    },
    {
      "name": "Economics & Management",
      "icon": Icons.business_center,
      "jobs": ["Financial Advisor", "Marketing Manager"]
    },
    {
      "name": "Healthcare",
      "icon": Icons.health_and_safety,
      "jobs": ["Doctor", "Nurse"]
    },
    {
      "name": "Education & Teaching",
      "icon": Icons.school,
      "jobs": ["Teacher", "Educational Administrator"]
    },
    {
      "name": "Agriculture, Forestry & Fishery",
      "icon": Icons.agriculture,
      "jobs": ["Agriculturist", "Veterinarian"]
    },
    {
      "name": "Culture, Arts & Tourism",
      "icon": Icons.palette,
      "jobs": ["Graphic Designer", "Tour Guide"]
    },
    {
      "name": "Law, Security & Defense",
      "icon": Icons.security,
      "jobs": ["Lawyer", "Police Officer"]
    },
    {
      "name": "General Labor & Services",
      "icon": Icons.handyman,
      "jobs": ["Electrician", "Chef"]
    },
  ];

  late YoutubePlayerController _youtubeController;

  @override
  void initState() {
    super.initState();
    _youtubeController = YoutubePlayerController(
      initialVideoId: YoutubePlayer.convertUrlToId(
          'https://www.youtube.com/watch?v=0cHIyeLFYOk')!,
      flags: const YoutubePlayerFlags(
        autoPlay: false,
        mute: false,
        enableCaption: true,
        forceHD: true, // buộc HD để tránh lỗi load
      ),
    );
  }

  @override
  void dispose() {
    _youtubeController.dispose();
    super.dispose();
  }

  void _downloadCV() async {
    final url = Uri.parse('https://www.example.com/sample_cv.docx');
    if (!await launchUrl(url)) {
      throw 'Could not launch $url';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Career Guidance & Training Tools'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 1. Career Fields Selection
          const Text(
            '1. Select a Career Field',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          ...industries.map((industry) {
            return Card(
              margin: const EdgeInsets.symmetric(vertical: 6),
              child: ExpansionTile(
                leading: Icon(industry['icon'] as IconData, color: Colors.blue),
                title: Text(industry['name'] as String),
                children: (industry['jobs'] as List<String>)
                    .map((job) => ListTile(
                  title: Text(job),
                  onTap: () {
                    // TODO: Thêm hành động khi người dùng click vào một nghề cụ thể
                    // Ví dụ: hiển thị chi tiết về nghề đó, hoặc điều hướng đến trang khác.
                    print('Bạn đã chọn nghề: $job');
                  },
                ))
                    .toList(),
              ),
            );
          }).toList(),
          const Divider(),

          // 2. CV Writing Tips
          const Text(
            '2. CV Writing Tips',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            '- Keep your CV clean, clear, and readable.\n'
                '- Include: Personal info, Career Objective, Education, Work Experience, Skills, Extracurricular Activities.\n'
                '- Keep it 1-2 pages, check spelling, and tailor it for each job.\n'
                '- Avoid unnecessary info and flashy fonts.\n'
                '- Optionally include LinkedIn or Portfolio links.',
          ),
          ElevatedButton.icon(
            onPressed: _downloadCV,
            icon: const Icon(Icons.download),
            label: const Text('Download Sample CV'),
          ),
          const Divider(),

          // 3. Interview Preparation
          const Text(
            '3. Interview Preparation',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Common Interview Questions:\n'
                '- Introduce yourself\n'
                '- Why did you choose this career?\n'
                '- Strengths and weaknesses\n'
                '- Describe a challenging situation you resolved\n'
                '- Career goals for the next 5 years\n'
                '- Why should we hire you?\n\n'
                'Body Language Tips:\n'
                '- Sit up straight, avoid crossing arms\n'
                '- Maintain eye contact\n'
                '- Smile naturally and show confidence\n'
                '- Avoid excessive hand/foot movements\n'
                '- Nod lightly when listening',
          ),
          const SizedBox(height: 10),
          const Text('Sample Interview Video:',
              style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          YoutubePlayer(
            controller: _youtubeController,
            showVideoProgressIndicator: true,
          ),
        ],
      ),
    );
  }
}