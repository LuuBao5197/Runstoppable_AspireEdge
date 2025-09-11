import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloudinary_public/cloudinary_public.dart';
import 'package:image_picker/image_picker.dart';

import '../../../utils/showToast.dart';

class AddEbookScreen extends StatefulWidget {
  const AddEbookScreen({super.key});

  @override
  State<AddEbookScreen> createState() => _AddEbookScreenState();
}

class _AddEbookScreenState extends State<AddEbookScreen> {
  final firestore = FirebaseFirestore.instance;
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  final cloudinary = CloudinaryPublic('dbghucaix', 'ml_default');

  String? thumbnailUrl;
  List<String> photos = [];
  bool isUploading = false;
  bool showAllTags = false;

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
  List<String> selectedTags = [];

  // Pick thumbnail
  Future<void> pickThumbnail() async {
    final img = await _picker.pickImage(source: ImageSource.gallery);
    if (img == null) return;
    try {
      final res = await cloudinary.uploadFile(CloudinaryFile.fromFile(img.path));
      setState(() => thumbnailUrl = res.secureUrl);
    } catch (e) {
      showToast("❌ Upload thumbnail failed", "error");
    }
  }

  // Pick multiple photos
  Future<void> pickPhotos() async {
    final imgs = await _picker.pickMultiImage();
    if (imgs.isEmpty) return;
    setState(() => isUploading = true);
    try {
      for (var img in imgs) {
        final res = await cloudinary.uploadFile(CloudinaryFile.fromFile(img.path));
        photos.add(res.secureUrl);
      }
      setState(() => isUploading = false);
    } catch (e) {
      showToast("❌ Upload photos failed", "error");
      setState(() => isUploading = false);
    }
  }

  // Save ebook
  Future<void> saveEbook() async {
    if (_titleController.text.isEmpty ||
        _descController.text.isEmpty ||
        thumbnailUrl == null ||
        photos.isEmpty ||
        selectedTags.isEmpty) {
      showToast("⚠️ Fill all fields", "warning");
      return;
    }

    final docRef = await firestore.collection("ebooks").add({
      "title": _titleController.text.trim(),
      "description": _descController.text.trim(),
      "thumbnail": thumbnailUrl,
      "photos": photos,
      "tags": selectedTags,
      "isFavorite": false,
      "isBookmark": false,
      "createdAt": FieldValue.serverTimestamp(),
    });
    await docRef.update({"id": docRef.id});

    showToast("✅ Ebook saved", "success");
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final tagsToShow = showAllTags ? allTags : allTags.take(6).toList();

    return Scaffold(
      appBar: AppBar(title: const Text("Add Ebook")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail
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
                      Icon(Icons.add_a_photo, size: 40, color: Colors.grey),
                      SizedBox(height: 8),
                      Text("Tap to select thumbnail"),
                    ],
                  ),
                )
                    : ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(thumbnailUrl!, fit: BoxFit.cover),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Title
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: "Title"),
            ),
            const SizedBox(height: 8),

            // Description
            TextField(
              controller: _descController,
              decoration: const InputDecoration(labelText: "Description"),
              maxLines: 3,
            ),
            const SizedBox(height: 8),

            // Photos
            ElevatedButton.icon(
              onPressed: pickPhotos,
              icon: const Icon(Icons.collections),
              label: const Text("Select Ebook Pages"),
            ),
            if (isUploading) const LinearProgressIndicator(),
            if (photos.isNotEmpty)
              SizedBox(
                height: 120,
                child: ReorderableListView(
                  scrollDirection: Axis.horizontal,
                  onReorder: (oldIndex, newIndex) {
                    setState(() {
                      if (newIndex > oldIndex) newIndex--;
                      final item = photos.removeAt(oldIndex);
                      photos.insert(newIndex, item);
                    });
                  },
                  children: photos.asMap().entries.map((entry) {
                    final index = entry.key;
                    final url = entry.value;
                    return Stack(
                      key: ValueKey(url),
                      children: [
                        Container(
                          margin: const EdgeInsets.all(4),
                          child: Image.network(url, width: 100, height: 100, fit: BoxFit.cover),
                        ),
                        Positioned(
                          top: 0,
                          right: 0,
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                photos.removeAt(index);
                              });
                            },
                            child: Container(
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.black54,
                              ),
                              child: const Icon(Icons.close, color: Colors.white, size: 18),
                            ),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),

            const SizedBox(height: 16),

            // Tags
            const Text("Select Tags:", style: TextStyle(fontWeight: FontWeight.bold)),
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
            if (allTags.length > 6)
              TextButton(
                onPressed: () => setState(() => showAllTags = !showAllTags),
                child: Text(showAllTags ? "Less" : "More"),
              ),

            const SizedBox(height: 24),

            Center(
              child: ElevatedButton(
                onPressed: saveEbook,
                child: const Text("Save Ebook"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
