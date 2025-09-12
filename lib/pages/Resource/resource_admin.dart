import 'package:flutter/material.dart';
import 'package:trackmentalhealth/pages/Resource/Admin/Ebooks/Ebook_admin_screen.dart';

import 'Admin/Blogs/add_blog_screen.dart';
import 'Admin/Blogs/blog_admin_screen.dart';
import 'Admin/Ebooks/add_ebook_screen.dart';
import 'Admin/Videos/add_video_screen.dart';
import 'Admin/Videos/Video_admin_screen.dart';

class ResourceAdminMain extends StatefulWidget {
  const ResourceAdminMain({super.key});

  @override
  State<ResourceAdminMain> createState() => _ResourceAdminMainState();
}

class _ResourceAdminMainState extends State<ResourceAdminMain>
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

  void _openAddScreen() {
    switch (_tabController.index) {
      case 0:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AddBlogScreen()),
        );
        break;
      case 1:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AddVideoScreen()),
        );
        break;
      case 2:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AddEbookScreen()),
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Admin Resource Center"),
        bottom: TabBar(
          controller: _tabController,
          tabs: myTabs,
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          AdminBlogScreen(),    // Blog tab
          AdminVideosScreen(),  // Video tab
          AdminEbookScreen()
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openAddScreen,
        child: const Icon(Icons.add),
        tooltip: 'Add new resource',
      ),
    );
  }
}
