import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloudinary_public/cloudinary_public.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:archive/archive_io.dart';
import 'package:xml/xml.dart';
import '../../../../utils/showToast.dart';

class EditBlogScreen extends StatefulWidget {
  final String blogId;
  const EditBlogScreen({super.key, required this.blogId});

  @override
  State<EditBlogScreen> createState() => _EditBlogScreenState();
}

class _EditBlogScreenState extends State<EditBlogScreen> {
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

  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadBlogData();
  }

  Future<void> _loadBlogData() async {
    final doc = await firestore.collection("blogs").doc(widget.blogId).get();
    if (!doc.exists) {
      showToast("Blog not found", "error");
      Navigator.pop(context);
      return;
    }
    final data = doc.data()!;
    setState(() {
      _titleController.text = data['title'] ?? '';
      _descController.text = data['description'] ?? '';
      _contentController.text = data['content'] ?? '';
      thumbnailUrl = data['thumbnail'];
      selectedTags = List<String>.from(data['tags'] ?? []);
      _loading = false;
    });
  }

  // --- Pick thumbnail ---
  Future<void> pickThumbnail() async {
    final img = await _picker.pickImage(source: ImageSource.gallery);
    if (img == null) return;
    final res = await cloudinary.uploadFile(CloudinaryFile.fromFile(img.path));
    setState(() => thumbnailUrl = res.secureUrl);
  }

  // --- Import TXT or DOCX ---
  Future<void> importContentFromFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['txt', 'docx'],
    );

    if (result == null || result.files.isEmpty) return;

    final file = File(result.files.single.path!);
    final ext = file.path.split('.').last.toLowerCase();

    if (ext == 'txt') {
      final content = await file.readAsString();
      setState(() => _contentController.text = content);
    } else if (ext == 'docx') {
      try {
        final bytes = file.readAsBytesSync();
        final archive = ZipDecoder().decodeBytes(bytes);
        String text = '';
        for (final file in archive) {
          if (file.name == "word/document.xml") {
            final xmlString = String.fromCharCodes(file.content);
            final document = XmlDocument.parse(xmlString);
            document.findAllElements('w:p').forEach((pNode) {
              final paragraphText =
              pNode.findAllElements('w:t').map((t) => t.text).join();
              text += paragraphText + '\n';
            });
            break;
          }
        }
        setState(() => _contentController.text = text.trim());
      } catch (e) {
        showToast("Failed to read DOCX file: $e", "error");
      }
    }
  }

  // --- Save changes ---
  Future<void> saveBlog() async {
    if (_titleController.text.isEmpty ||
        _descController.text.isEmpty ||
        _contentController.text.isEmpty ||
        thumbnailUrl == null ||
        selectedTags.isEmpty) {
      showToast("⚠️ Fill all fields", "warning");
      return;
    }

    await firestore.collection("blogs").doc(widget.blogId).update({
      "title": _titleController.text.trim(),
      "description": _descController.text.trim(),
      "content": _contentController.text.trim(),
      "thumbnail": thumbnailUrl,
      "tags": selectedTags,
    });

    showToast("✅ Blog updated", "success");
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final tagsToShow = showAllTags ? allTags : allTags.take(6).toList();

    return Scaffold(
      appBar: AppBar(title: const Text("Edit Blog")),
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

            // --- Content + Import button ---
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TextField(
                    controller: _contentController,
                    decoration: const InputDecoration(labelText: "Content"),
                    maxLines: 8,
                    keyboardType: TextInputType.multiline,
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: importContentFromFile,
                  icon: const Icon(Icons.upload_file),
                  label: const Text("Import"),
                ),
              ],
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
            if (allTags.length > 6)
              TextButton(
                onPressed: () => setState(() => showAllTags = !showAllTags),
                child: Text(showAllTags ? "Less" : "More"),
              ),

            const SizedBox(height: 24),

            // --- Save button ---
            Center(
              child: ElevatedButton(
                onPressed: saveBlog,
                child: const Text("Save Changes"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
