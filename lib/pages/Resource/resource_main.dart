import 'package:flutter/material.dart';

import 'Blogs/blog_screen.dart';
import 'Videos/video_screen.dart';
import 'Ebooks/ebook_screen.dart';

class ResourceMain extends StatefulWidget {
  const ResourceMain({super.key});

  @override
  State<ResourceMain> createState() => _ResourceMainState();
}

class _ResourceMainState extends State<ResourceMain>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final List<Tab> myTabs = const [
    Tab(icon: Icon(Icons.article), text: "Blog"),
    Tab(icon: Icon(Icons.video_library), text: "Video"),
    Tab(icon: Icon(Icons.book), text: "Ebook"),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: myTabs.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Resource Center"),
        bottom: TabBar(
          controller: _tabController,
          tabs: myTabs,
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          BlogScreen(),
          VideoScreen(),
          EbookScreen(),
        ],
      ),
    );
  }
}
