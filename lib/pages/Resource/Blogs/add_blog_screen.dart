import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloudinary_public/cloudinary_public.dart';
import 'package:image_picker/image_picker.dart';
import '../../../utils/showToast.dart';

class AddBlogScreen extends StatefulWidget {
  const AddBlogScreen({super.key});

  @override
  State<AddBlogScreen> createState() => _AddBlogScreenState();
}

class _AddBlogScreenState extends State<AddBlogScreen> {
  final firestore = FirebaseFirestore.instance;
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _contentController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  final cloudinary = CloudinaryPublic('dbghucaix', 'ml_default');

  String? thumbnailUrl;
  bool showAllTags = false;

  final List<String> allTags = [
    "Career Tips",
    "Personal Branding",
    "Soft Skills",
    "Resume & CV",
    "Interview Skills",
    "Networking",
    "Freelancing",
    "Remote Work",
    "Leadership",
    "Entrepreneurship",
  ];
  List<String> selectedTags = [];

  Future<void> pickThumbnail() async {
    final img = await _picker.pickImage(source: ImageSource.gallery);
    if (img == null) return;
    final res = await cloudinary.uploadFile(CloudinaryFile.fromFile(img.path));
    setState(() => thumbnailUrl = res.secureUrl);
  }

  Future<void> saveBlog() async {
    if (_titleController.text.isEmpty ||
        _descController.text.isEmpty ||
        _contentController.text.isEmpty ||
        thumbnailUrl == null ||
        selectedTags.isEmpty) {
      showToast("⚠️ Fill all fields", "warning");
      return;
    }

    final docRef = await firestore.collection("blogs").add({
      "title": _titleController.text.trim(),
      "description": _descController.text.trim(),
      "content": _contentController.text.trim(),
      "thumbnail": thumbnailUrl,
      "tags": selectedTags,
      "isFavorite": false,
      "isBookmark": false,
      "createdAt": FieldValue.serverTimestamp(),
    });
    await docRef.update({"id": docRef.id});

    showToast("✅ Blog saved", "success");
    Navigator.pop(context); // quay lại BlogScreen
  }

  @override
  Widget build(BuildContext context) {
    // Chỉ lấy 6 tag đầu tiên nếu showAllTags = false
    final tagsToShow = showAllTags ? allTags : allTags.take(6).toList();

    return Scaffold(
      appBar: AppBar(title: const Text("Add Blog")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Thumbnail ---
            GestureDetector(
              onTap: pickThumbnail,
              child: Container(
                height: 180,
                width: double.infinity,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade400),
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.grey.shade200,
                ),
                child: thumbnailUrl == null
                    ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_a_photo,
                          size: 40, color: Colors.grey),
                      SizedBox(height: 8),
                      Text("Tap to select thumbnail"),
                    ],
                  ),
                )
                    : ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    thumbnailUrl!,
                    fit: BoxFit.cover,
                    width: double.infinity,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // --- Title ---
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: "Title"),
            ),
            const SizedBox(height: 8),

            // --- Description ---
            TextField(
              controller: _descController,
              decoration: const InputDecoration(labelText: "Description"),
              maxLines: 3,
            ),
            const SizedBox(height: 5),

            // --- Content ---
            TextField(
              controller: _contentController,
              decoration: const InputDecoration(labelText: "Content"),
              maxLines: 3,
              keyboardType: TextInputType.multiline,
            ),

            const SizedBox(height: 5),

            // --- Tags ---
            const Text("Select Tags:",
                style: TextStyle(fontWeight: FontWeight.bold)),
            Wrap(
              spacing: 6,
              children: tagsToShow.map((tag) {
                final selected = selectedTags.contains(tag);
                return FilterChip(
                  label: Text(tag),
                  selected: selected,
                  onSelected: (val) {
                    setState(() {
                      if (val) {
                        selectedTags.add(tag);
                      } else {
                        selectedTags.remove(tag);
                      }
                    });
                  },
                );
              }).toList(),
            ),

            // --- Nút More/Less ---
            if (allTags.length > 6)
              TextButton(
                onPressed: () {
                  setState(() => showAllTags = !showAllTags);
                },
                child: Text(showAllTags ? "Less" : "More"),
              ),

            const SizedBox(height: 24),

            // --- Save button ---
            Center(
              child: ElevatedButton(
                onPressed: saveBlog,
                child: const Text("Save Blog"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
