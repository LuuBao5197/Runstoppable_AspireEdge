import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:trackmentalhealth/pages/Resource/User/Ebooks/detail_ebook_screen.dart';
import 'package:trackmentalhealth/pages/Resource/User/Videos/detail_video_screen.dart';
import 'Blogs/detail_blog_screen.dart';

class WishlistScreen extends StatefulWidget {
  const WishlistScreen({super.key});

  @override
  State<WishlistScreen> createState() => _WishlistScreenState();
}

class _WishlistScreenState extends State<WishlistScreen> {
  final firestore = FirebaseFirestore.instance;
  final user = FirebaseAuth.instance.currentUser;

  // trạng thái hiển thị các section
  bool showBlogs = true;
  bool showVideos = true;
  bool showEbooks = true;

  @override
  Widget build(BuildContext context) {
    final currentUserId = user?.uid;
    if (currentUserId == null) {
      return const Center(child: Text("Please login to see your wishlist."));
    }

    Widget buildSection({
      required String title,
      required bool isExpanded,
      required VoidCallback onTapHeader,
      required Stream<QuerySnapshot> stream,
      required Widget Function(DocumentSnapshot doc) itemBuilder,
    }) {
      return StreamBuilder<QuerySnapshot>(
        stream: stream,
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const CircularProgressIndicator();
          final docs = snapshot.data!.docs;
          if (docs.isEmpty) return const SizedBox();

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // header với nút expand/collapse
              ListTile(
                title: Text(title,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold)),
                trailing: Icon(isExpanded
                    ? Icons.keyboard_arrow_down
                    : Icons.keyboard_arrow_right),
                onTap: onTapHeader,
              ),
              if (isExpanded)
                ...docs.map(itemBuilder).toList(),
            ],
          );
        },
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("My Wishlist"),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Blogs
            buildSection(
              title: "Blogs",
              isExpanded: showBlogs,
              onTapHeader: () {
                setState(() {
                  showBlogs = !showBlogs;
                });
              },
              stream: firestore
                  .collection("blogs")
                  .where("bookmarks.$currentUserId", isEqualTo: true)
                  .snapshots(),
              itemBuilder: (doc) {
                final data = doc.data() as Map<String, dynamic>;
                return ListTile(
                  leading: data["thumbnail"] != null
                      ? Image.network(data["thumbnail"],
                      width: 60, fit: BoxFit.cover)
                      : null,
                  title: Text(
                    data["title"] ?? "",
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => BlogDetailScreen(blogId: doc.id)),
                    );
                  },
                );
              },
            ),
            // Videos
            buildSection(
              title: "Videos",
              isExpanded: showVideos,
              onTapHeader: () {
                setState(() {
                  showVideos = !showVideos;
                });
              },
              stream: firestore
                  .collection("videos")
                  .where("bookmarks.$currentUserId", isEqualTo: true)
                  .snapshots(),
              itemBuilder: (doc) {
                final data = doc.data() as Map<String, dynamic>;
                return ListTile(
                  leading: data["thumbnail"] != null
                      ? Image.network(data["thumbnail"],
                      width: 60, fit: BoxFit.cover)
                      : null,
                  title: Text(
                    data["title"] ?? "",
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) =>
                              VideoDetailScreen(videoId: doc.id)),
                    );
                  },
                );
              },
            ),
            // Ebooks
            buildSection(
              title: "Ebooks",
              isExpanded: showEbooks,
              onTapHeader: () {
                setState(() {
                  showEbooks = !showEbooks;
                });
              },
              stream: firestore
                  .collection("ebooks")
                  .where("bookmarks.$currentUserId", isEqualTo: true)
                  .snapshots(),
              itemBuilder: (doc) {
                final data = doc.data() as Map<String, dynamic>;
                return ListTile(
                  leading: data["thumbnail"] != null
                      ? Image.network(data["thumbnail"],
                      width: 60, fit: BoxFit.cover)
                      : null,
                  title: Text(
                    data["title"] ?? "",
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) =>
                              EbookDetailScreen(ebookId: doc.id)),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
