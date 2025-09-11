import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../tag_filter_dialog.dart';
import 'add_ebook_screen.dart';
import 'detail_ebook_screen.dart';
 // import màn hình detail

class EbookScreen extends StatefulWidget {
  const EbookScreen({super.key});

  @override
  State<EbookScreen> createState() => _EbookScreenState();
}

class _EbookScreenState extends State<EbookScreen> {
  final firestore = FirebaseFirestore.instance;
  String searchQuery = "";

  final List<String> allTags = [
    "Novel",
    "Education",
    "Career Guide",
    "Motivation",
    "Soft Skills",
    "Leadership",
    "Personal Growth",
    "Tech",
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
      setState(() => selectedTags = result);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          decoration: const InputDecoration(
            hintText: "Search ebooks...",
            border: InputBorder.none,
            prefixIcon: Icon(Icons.search, color: Colors.black),
          ),
          style: const TextStyle(color: Colors.black),
          cursorColor: Colors.black,
          onChanged: (value) {
            setState(() => searchQuery = value.toLowerCase());
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
            .collection("ebooks")
            .orderBy("createdAt", descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final docs = snapshot.data!.docs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final tags = List<String>.from(data["tags"] ?? []);

            final include = selectedTags.entries.where((e) => e.value == 1).map((e) => e.key).toList();
            final exclude = selectedTags.entries.where((e) => e.value == -1).map((e) => e.key).toList();

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
              return GestureDetector(
                onTap: () {
                  // Khi bấm mở detail
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => EbookDetailScreen(ebookId: doc.id),
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
                                data["isFavorite"] == true ? Icons.favorite : Icons.favorite_border,
                                color: Colors.red,
                              ),
                              onPressed: () => firestore.collection("ebooks").doc(doc.id).update({
                                "isFavorite": !(data["isFavorite"] ?? false),
                              }),
                            ),
                            IconButton(
                              icon: Icon(
                                data["isBookmark"] == true ? Icons.bookmark : Icons.bookmark_border,
                              ),
                              onPressed: () => firestore.collection("ebooks").doc(doc.id).update({
                                "isBookmark": !(data["isBookmark"] ?? false),
                              }),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const AddEbookScreen()));
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
