import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../tag_filter_dialog.dart';
import '../../Admin/Videos/add_video_screen.dart';
import 'detail_video_screen.dart';

class VideoScreen extends StatefulWidget {
  const VideoScreen({super.key});

  @override
  State<VideoScreen> createState() => _VideoScreenState();
}

class _VideoScreenState extends State<VideoScreen> {
  final firestore = FirebaseFirestore.instance;
  final userId = FirebaseAuth.instance.currentUser!.uid; // 👈 id user
  String searchQuery = "";

  // filter tags
  final List<String> allTags = [
    "Tutorial",
    "Interview",
    "Education",
    "Motivation",
    "Lifestyle",
    "Entertainment",
  ];
  Map<String, int> selectedTags = {};

  @override
  void initState() {
    super.initState();
    for (var t in allTags) {
      selectedTags[t] = 0;
    }
  }

  void openFilterDialog() async {
    final result = await showDialog<Map<String, int>>(
      context: context,
      builder: (_) => TagFilterDialog(
        allTags: allTags,
        currentSelection: selectedTags,
      ),
    );

    if (result != null) {
      setState(() {
        selectedTags = result;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          decoration: const InputDecoration(
            hintText: "Search videos...",
            border: InputBorder.none,
            prefixIcon: Icon(Icons.search, color: Colors.black),
          ),
          style: const TextStyle(color: Colors.black),
          cursorColor: Colors.black,
          onChanged: (value) {
            setState(() {
              searchQuery = value.toLowerCase();
            });
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: openFilterDialog,
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: firestore
            .collection("videos")
            .orderBy("createdAt", descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final tags = List<String>.from(data["tags"] ?? []);

            final include = selectedTags.entries
                .where((e) => e.value == 1)
                .map((e) => e.key)
                .toList();
            final exclude = selectedTags.entries
                .where((e) => e.value == -1)
                .map((e) => e.key)
                .toList();

            if (include.isNotEmpty && !include.any(tags.contains)) return false;
            if (exclude.isNotEmpty && exclude.any(tags.contains)) return false;

            if (searchQuery.isNotEmpty) {
              final title = (data["title"] ?? "").toString().toLowerCase();
              if (!title.contains(searchQuery)) return false;
            }

            return true;
          }).toList();

          return ListView(
            children: docs.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              final videoId = doc.id;

              return StreamBuilder<DocumentSnapshot>(
                stream: firestore
                    .collection("videos")
                    .doc(videoId)
                    .collection("favorites")
                    .doc(userId)
                    .snapshots(),
                builder: (context, favSnap) {
                  final isFav = favSnap.data?.exists ?? false;

                  return StreamBuilder<DocumentSnapshot>(
                    stream: firestore
                        .collection("videos")
                        .doc(videoId)
                        .collection("bookmarks")
                        .doc(userId)
                        .snapshots(),
                    builder: (context, markSnap) {
                      final isMark = markSnap.data?.exists ?? false;

                      return InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => VideoDetailScreen(videoId: videoId),
                            ),
                          );
                        },
                        child: Card(
                          margin: const EdgeInsets.all(8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (data["thumbnail"] != null)
                                ClipRRect(
                                  borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                                  child: Image.network(
                                    data["thumbnail"],
                                    height: 180,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            data["title"] ?? "",
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            data["description"] ?? "",
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),
                                    IconButton(
                                      icon: Icon(
                                        isFav ? Icons.favorite : Icons.favorite_border,
                                        color: Colors.red,
                                      ),
                                      onPressed: () async {
                                        final favRef = firestore
                                            .collection("videos")
                                            .doc(videoId)
                                            .collection("favorites")
                                            .doc(userId);
                                        if (isFav) {
                                          await favRef.delete();
                                        } else {
                                          await favRef.set({"createdAt": FieldValue.serverTimestamp()});
                                        }
                                      },
                                    ),
                                    IconButton(
                                      icon: Icon(
                                        isMark ? Icons.bookmark : Icons.bookmark_border,
                                      ),
                                      onPressed: () async {
                                        final markRef = firestore
                                            .collection("videos")
                                            .doc(videoId)
                                            .collection("bookmarks")
                                            .doc(userId);
                                        if (isMark) {
                                          await markRef.delete();
                                        } else {
                                          await markRef.set({"createdAt": FieldValue.serverTimestamp()});
                                        }
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              );
            }).toList(),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddVideoScreen()),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
