import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloudinary_public/cloudinary_public.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../../utils/showToast.dart';

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
  String? pdfUrl;
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

  /// Pick thumbnail and upload to Cloudinary
  Future<void> pickThumbnail() async {
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

  /// Pick PDF and upload to Firebase Storage
  Future<void> pickAndUploadPdf() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );
      if (result == null || result.files.isEmpty) return;

      setState(() => isUploading = true);
      final file = File(result.files.single.path!);

      final ref = FirebaseStorage.instance
          .ref()
          .child("ebooks/${DateTime.now().millisecondsSinceEpoch}_${result.files.single.name}");
      await ref.putFile(file);

      final downloadUrl = await ref.getDownloadURL();

      setState(() {
        pdfUrl = downloadUrl;
        isUploading = false;
      });

      showToast("✅ PDF uploaded successfully", "success");
    } catch (e) {
      setState(() => isUploading = false);
      showToast("❌ Upload PDF failed: $e", "error");
    }
  }

  /// Save ebook info to Firestore
  Future<void> saveEbook() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      showToast("⚠️ You must be logged in to create an ebook", "warning");
      return;
    }

    if (_titleController.text.isEmpty ||
        _descController.text.isEmpty ||
        thumbnailUrl == null ||
        pdfUrl == null ||
        selectedTags.isEmpty) {
      showToast("⚠️ Fill all fields", "warning");
      return;
    }

    final docRef = await firestore.collection("ebooks").add({
      "title": _titleController.text.trim(),
      "description": _descController.text.trim(),
      "thumbnail": thumbnailUrl,
      "pdfUrl": pdfUrl,
      "tags": selectedTags,
      "isFavorite": false,
      "isBookmark": false,
      "createdAt": FieldValue.serverTimestamp(),
      "createdBy": user.uid, // thêm trường createdBy
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
                  child: Image.network(
                    thumbnailUrl!,
                    fit: BoxFit.cover,
                  ),
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

            // PDF Upload
            ElevatedButton.icon(
              onPressed: pickAndUploadPdf,
              icon: const Icon(Icons.picture_as_pdf),
              label: const Text("Select Ebook PDF"),
            ),
            if (isUploading) const LinearProgressIndicator(),
            if (pdfUrl != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    const Icon(Icons.picture_as_pdf, color: Colors.red),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        "PDF Selected",
                        style: const TextStyle(fontWeight: FontWeight.w500),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          pdfUrl = null;
                        });
                      },
                      child: const Icon(Icons.close, color: Colors.black54),
                    ),
                  ],
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

            // Save button
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
