import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloudinary_public/cloudinary_public.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../utils/showToast.dart';

class EditVideoScreen extends StatefulWidget {
  final String videoId;
  const EditVideoScreen({super.key, required this.videoId});

  @override
  State<EditVideoScreen> createState() => _EditVideoScreenState();
}

class _EditVideoScreenState extends State<EditVideoScreen> {
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
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadVideo();
  }

  Future<void> _loadVideo() async {
    final doc = await firestore.collection("videos").doc(widget.videoId).get();
    if (!doc.exists) {
      showToast("Video not found", "error");
      Navigator.pop(context);
      return;
    }
    final data = doc.data()!;
    setState(() {
      _titleController.text = data['title'] ?? '';
      _descController.text = data['description'] ?? '';
      thumbnailUrl = data['thumbnail'];
      videoUrl = data['videoUrl'];
      selectedTags = List<String>.from(data['tags'] ?? []);
      isLoading = false;
    });
  }

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

  Future<void> pickVideo() async {
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
    } catch (e) {
      showToast("❌ Upload video failed", "error");
      setState(() => isUploading = false);
    }
  }

  Future<void> saveVideo() async {
    if (_titleController.text.isEmpty ||
        _descController.text.isEmpty ||
        thumbnailUrl == null ||
        videoUrl == null ||
        selectedTags.isEmpty) {
      showToast("⚠️ Fill all fields", "warning");
      return;
    }

    await firestore.collection("videos").doc(widget.videoId).update({
      "title": _titleController.text.trim(),
      "description": _descController.text.trim(),
      "thumbnail": thumbnailUrl,
      "videoUrl": videoUrl,
      "tags": selectedTags,
      "updatedAt": FieldValue.serverTimestamp(),
    });

    showToast("✅ Video updated", "success");
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    final tagsToShow = showAllTags ? allTags : allTags.take(6).toList();

    return Scaffold(
      appBar: AppBar(title: const Text("Edit Video")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
                    ? const Center(child: Icon(Icons.add_a_photo, size: 40))
                    : ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(thumbnailUrl!, fit: BoxFit.cover),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(controller: _titleController, decoration: const InputDecoration(labelText: "Title")),
            const SizedBox(height: 8),
            TextField(
              controller: _descController,
              decoration: const InputDecoration(labelText: "Description"),
              maxLines: 3,
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: pickVideo,
              icon: const Icon(Icons.video_library),
              label: Text(videoUrl != null ? "Video Selected" : "Select MP4 Video"),
            ),
            if (isUploading) const Padding(
              padding: EdgeInsets.all(8),
              child: LinearProgressIndicator(),
            ),
            const SizedBox(height: 16),
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
                      if (val) selectedTags.add(tag);
                      else selectedTags.remove(tag);
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
                onPressed: saveVideo,
                child: const Text("Save Changes"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
