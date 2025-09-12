import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloudinary_public/cloudinary_public.dart';
import 'package:image_picker/image_picker.dart';
import '../../../utils/showToast.dart';
import '../tag_filter_dialog.dart';
import 'add_blog_screen.dart';
import 'detail_blog_screen.dart';

class BlogScreen extends StatefulWidget {
  const BlogScreen({super.key});

  @override
  State<BlogScreen> createState() => _BlogScreenState();
}

class _BlogScreenState extends State<BlogScreen> {
  final firestore = FirebaseFirestore.instance;
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  final cloudinary = CloudinaryPublic('dbghucaix', 'ml_default');

  String? thumbnailUrl;
  String searchQuery = ""; // query để search
  bool isUploading = false;

  // filter tags
  final List<String> allTags = [
    "Career Tips",
    "Personal Branding",
    "Resume & CV",
    "Interview Skills",
    "Networking",
    "Freelancing",
    "Remote Work",
    "Soft Skills",
    "Leadership",
    "Entrepreneurship",
  ];
  Map<String, int> selectedTags = {}; // tag → 0 (none), 1 (include), -1 (exclude)

  @override
  void initState() {
    super.initState();
    for (var t in allTags) {
      selectedTags[t] = 0;
    }
  }

  Future<void> pickThumbnail() async {
    final img = await _picker.pickImage(source: ImageSource.gallery);
    if (img == null) return;
    final res = await cloudinary.uploadFile(CloudinaryFile.fromFile(img.path));
    setState(() => thumbnailUrl = res.secureUrl);
  }

  Future<void> saveBlog() async {
    if (_titleController.text.isEmpty ||
        _descController.text.isEmpty ||
        thumbnailUrl == null) {
      showToast("⚠️ Fill all fields", "warning");
      return;
    }
    await firestore.collection("blogs").add({
      "title": _titleController.text.trim(),
      "description": _descController.text.trim(),
      "thumbnail": thumbnailUrl,
      "tags": ["Food", "Education"],
      "isFavorite": false,
      "isBookmark": false,
      "createdAt": FieldValue.serverTimestamp(),
    });
    showToast("✅ Blog saved", "success");
    _titleController.clear();
    _descController.clear();
    setState(() => thumbnailUrl = null);
  }

  void showAddBlogDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Add Blog"),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: "Title"),
              ),
              TextField(
                controller: _descController,
                decoration: const InputDecoration(labelText: "Description"),
              ),
              ElevatedButton.icon(
                onPressed: pickThumbnail,
                icon: const Icon(Icons.image),
                label: const Text("Select Thumbnail"),
              ),
              if (thumbnailUrl != null)
                Image.network(thumbnailUrl!, height: 100),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () {
              saveBlog();
              Navigator.pop(context);
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
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

      final include = selectedTags.entries
          .where((e) => e.value == 1)
          .map((e) => e.key)
          .toList();
      final exclude = selectedTags.entries
          .where((e) => e.value == -1)
          .map((e) => e.key)
          .toList();

      debugPrint("Include: $include");
      debugPrint("Exclude: $exclude");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          decoration: const InputDecoration(
            hintText: "Search blogs...",
            border: InputBorder.none,
            prefixIcon: Icon(Icons.search, color: Colors.black),
          ),
          style: const TextStyle(color: Colors.black),
          cursorColor: Colors.black,
          onChanged: (value) {
            setState(() {
              searchQuery = value.toLowerCase(); // cập nhật query
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
            .collection("blogs")
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

            // filter theo tag
            if (include.isNotEmpty && !include.any(tags.contains)) return false;
            if (exclude.isNotEmpty && exclude.any(tags.contains)) return false;

            // filter theo search query (LIKE - contains title)
            if (searchQuery.isNotEmpty) {
              final title = (data["title"] ?? "").toString().toLowerCase();
              if (!title.contains(searchQuery)) return false;
            }

            return true;
          }).toList();

          return ListView(
            children: docs.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              return InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => BlogDetailScreen(blogId: doc.id),
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
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
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
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddBlogScreen()),
          );
        },
        child: const Icon(Icons.add),
      ),

    );
  }
}
