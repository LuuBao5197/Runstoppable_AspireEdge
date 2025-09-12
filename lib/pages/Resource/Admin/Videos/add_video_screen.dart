import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloudinary_public/cloudinary_public.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../utils/showToast.dart';

class AddVideoScreen extends StatefulWidget {
  const AddVideoScreen({super.key});

  @override
  State<AddVideoScreen> createState() => _AddVideoScreenState();
}

class _AddVideoScreenState extends State<AddVideoScreen> {
  final firestore = FirebaseFirestore.instance;
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  final cloudinary = CloudinaryPublic('dbghucaix', 'ml_default');

  String? thumbnailUrl;
  String? videoUrl;
  bool isUploading = false;
  bool showAllTags = false;

  final List<String> allTags = [
    "Tutorial",
    "Career Guide",
    "Interview Tips",
    "Motivation",
    "Soft Skills",
    "Leadership",
    "Personal Growth",
    "Remote Work",
    "Freelancing",
    "Tech Trends",
  ];
  List<String> selectedTags = [];

  // --- Pick Thumbnail ---
  Future<void> pickThumbnail() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      showToast("⚠️ You must be logged in to upload thumbnail", "warning");
      return;
    }

    final img = await _picker.pickImage(source: ImageSource.gallery);
    if (img == null) return;

    try {
      final res = await cloudinary.uploadFile(
        CloudinaryFile.fromFile(img.path, resourceType: CloudinaryResourceType.Image),
      );
      setState(() => thumbnailUrl = res.secureUrl);
      showToast("✅ Thumbnail uploaded", "success");
    } catch (e) {
      showToast("❌ Upload thumbnail failed: $e", "error");
    }
  }

  // --- Pick Video ---
  Future<void> pickVideo() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      showToast("⚠️ You must be logged in to upload video", "warning");
      return;
    }

    final video = await _picker.pickVideo(source: ImageSource.gallery);
    if (video == null) return;

    setState(() => isUploading = true);
    try {
      final res = await cloudinary.uploadFile(
        CloudinaryFile.fromFile(video.path, resourceType: CloudinaryResourceType.Video),
      );
      setState(() {
        videoUrl = res.secureUrl;
        isUploading = false;
      });
      showToast("✅ Video uploaded", "success");
    } catch (e) {
      showToast("❌ Upload video failed: $e", "error");
      setState(() => isUploading = false);
    }
  }

  // --- Save Video ---
  Future<void> saveVideo() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      showToast("⚠️ You must be logged in to create a video", "warning");
      return;
    }

    if (_titleController.text.isEmpty ||
        _descController.text.isEmpty ||
        thumbnailUrl == null ||
        videoUrl == null ||
        selectedTags.isEmpty) {
      showToast("⚠️ Fill all fields", "warning");
      return;
    }

    final docRef = await firestore.collection("videos").add({
      "title": _titleController.text.trim(),
      "description": _descController.text.trim(),
      "thumbnail": thumbnailUrl,
      "videoUrl": videoUrl,
      "tags": selectedTags,
      "isFavorite": false,
      "isWishlist": false,
      "createdAt": FieldValue.serverTimestamp(),
      "createdBy": user.uid, // thêm createdBy
    });

    await docRef.update({"id": docRef.id});

    showToast("✅ Video saved", "success");
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final tagsToShow = showAllTags ? allTags : allTags.take(6).toList();

    return Scaffold(
      appBar: AppBar(title: const Text("Add Video")),
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
                      Icon(Icons.add_a_photo, size: 40, color: Colors.grey),
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
            const SizedBox(height: 8),

            // --- Upload Video ---
            ElevatedButton.icon(
              onPressed: pickVideo,
              icon: const Icon(Icons.video_library),
              label: Text(videoUrl != null ? "Video Selected" : "Select MP4 Video"),
            ),
            if (isUploading)
              const Padding(
                padding: EdgeInsets.all(8),
                child: LinearProgressIndicator(),
              ),
            const SizedBox(height: 16),

            // --- Tags ---
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

            // --- Save Button ---
            Center(
              child: ElevatedButton(
                onPressed: saveVideo,
                child: const Text("Save Video"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
