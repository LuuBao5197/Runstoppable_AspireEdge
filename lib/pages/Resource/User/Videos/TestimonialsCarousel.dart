import 'dart:async';
import 'package:flutter/material.dart';

class TestimonialsCarousel extends StatefulWidget {
  const TestimonialsCarousel({super.key});

  @override
  State<TestimonialsCarousel> createState() => _TestimonialsCarouselState();
}

class _TestimonialsCarouselState extends State<TestimonialsCarousel> {
  final PageController _controller = PageController();
  Timer? _timer;
  int _current = 0;

  final List<Map<String, String>> testimonials = [
    {
      "name": "Vanessa De Luca",
      "image": "https://themuse-renderer.vercel.app/_next/image?url=https%3A%2F%2Fcms-assets.themuse.com%2Fmedia%2Flead%2F24319.jpg&w=1920&q=75",
      "story":
      "After years in retail and home décor, I realized my career path no longer fit me. At 30, I started over as an editorial assistant at Glamour. By leveraging my past experience, embracing challenges, and building strong networks, I quickly advanced and eventually became Editor-in-Chief of a major magazine. My journey proves it’s never too late to start again"
    },
    {
      "name": "Jennifer",
      "image": "https://themuse-renderer.vercel.app/_next/image?url=https%3A%2F%2Fcms-assets.themuse.com%2Fmedia%2Flead%2F24205.jpg&w=1920&q=75",
      "story":
      "Working at a drive-thru, I never imagined a customer could change my career path. One regular noticed my positive attitude and professionalism, and recommended me for a Customer Service Representative position at her company. Though I lacked experience, I embraced the opportunity and soon grew into the role. That chance encounter opened the door to a whole new career."
    },
    {
      "name": "Amanda Corrado",
      "image": "https://themuse-renderer.vercel.app/_next/image?url=https%3A%2F%2Fcms-assets.themuse.com%2Fmedia%2Flead%2F24312.png&w=1920&q=75",
      "story":
      "I started my career in finance at JPMorgan but soon realized it wasn’t my true passion. Wanting a role with more purpose, I transitioned into HR as a Talent Acquisition Specialist at The Muse. By highlighting transferable skills and embracing challenges, I successfully shifted careers and now help others find opportunities that excite them."
    },
    {
      "name": "Krista Moroder",
      "image": "https://themuse-renderer.vercel.app/_next/image?url=https%3A%2F%2Fcms-assets.themuse.com%2Fmedia%2Fwriters%2Fkrista-moroder.jpg&w=256&q=75",
      "story":
      "I transitioned from education to software engineering in just 4 months. After learning to code through tutorials while working, I joined a 3-month bootcamp, built a strong portfolio, and landed my first SWE offer. The leap was challenging, but deeply rewarding."
    },
    {
      "name": "Jeremy",
      "image": "https://themuse-renderer.vercel.app/_next/image?url=https%3A%2F%2Fcms-assets.themuse.com%2Fmedia%2Fwriters%2Fjeremy-schifeling_190925_190348.jpg&w=256&q=75",
      "story":
      "As a kindergarten teacher, I loved helping students but realized my true passion was in technology. Encouraged by a colleague, I pursued an MBA and explored roles that combined tech with my strengths. With persistence and a tailored application, I transitioned successfully and landed a marketing position at Apple."
    },
    {
      "name": "Former Paralegal",
      "image": "https://themuse-renderer.vercel.app/_next/image?url=https%3A%2F%2Fcms-assets.themuse.com%2Fmedia%2Fwriters%2Fjenn-creighton.jpg&w=256&q=75",
      "story":
      "I began my career as a paralegal with no tech degree, but a passion for building things. Over time, I taught myself HTML, CSS, and JavaScript; leveraged web content roles; built side projects; and caught a recruiter’s eye. Now I work as a front-end engineer, proving persistence and self-learning can truly change paths."
    },
    {
      "name": "Michael",
      "image": "https://themuse-renderer.vercel.app/_next/image?url=https%3A%2F%2Fcms-assets.themuse.com%2Fmedia%2Flead%2F24160.jpg&w=1920&q=75",
      "story":
      "I didn’t have to quit my job to change my career path. By showcasing my transferable skills and working closely with HR and my managers, I was able to move into a new role within the same company. This internal transition gave me stability while still allowing me to grow in a whole new direction."
    },
    {
      "name": "Unrelated Career Switcher",
      "image": "https://www.themuse.com/_next/image?url=https%3A%2F%2Fcms-assets.themuse.com%2Fmedia%2Fwriters%2Fsarah-pike.jpg&w=256&q=75",
      "story":
      "Despite academic degrees in teaching and research, I left academia to pursue marketing. By leveraging my transferable skills—public speaking, research, writing—and tailoring resumes and cover letters, I landed a Marketing Assistant position. Proof that your background doesn’t limit what you can achieve."
    },
  ];

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 6), (timer) {
      if (_controller.hasClients) {
        _current = (_current + 1) % testimonials.length;
        _controller.animateToPage(
          _current,
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  Widget _buildTestimonial(Map<String, String> item, BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
      child: Column(
        children: [
          CircleAvatar(
            radius: 55,
            backgroundImage: NetworkImage(item["image"]!),
          ),
          const SizedBox(height: 16),
          Text(
            item["name"]!,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A237E),
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                item["story"]!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  height: 1.5,
                  color: Colors.black87,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height;

    return SizedBox(
      height: height,
      child: Column(
        children: [
          const SizedBox(height: 24),
          const Text(
            "Stories of Success",
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A237E),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          const Text(
            "Real journeys from our learners",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: Colors.black54),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: PageView.builder(
              controller: _controller,
              itemCount: testimonials.length,
              onPageChanged: (index) => setState(() => _current = index),
              itemBuilder: (context, index) {
                return _buildTestimonial(testimonials[index], context);
              },
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(testimonials.length, (index) {
              return AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.symmetric(horizontal: 5),
                width: _current == index ? 20 : 8,
                height: 8,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: _current == index
                      ? Theme.of(context).primaryColor
                      : Colors.grey[400],
                ),
              );
            }),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
