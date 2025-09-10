import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../utils/showToast.dart';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';

class ResourceScreen extends StatefulWidget {
  const ResourceScreen({super.key});

  @override
  State<ResourceScreen> createState() => _ResourceScreenState();
}

class _ResourceScreenState extends State<ResourceScreen> {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  String filter = 'All'; // All, Blog, Ebook, Video, Image

  /// 🔹 Lưu resource vào Firestore
  Future<void> saveResourceToFirestore(Map<String, dynamic> resource) async {
    try {
      await firestore.collection("resources").add({
        "title": resource["title"],
        "description": resource["description"],
        "type": resource["type"],
        "url": resource["url"] ?? "",
        "tags": resource["tags"] ?? [],
        "isFavorite": resource["isFavorite"] ?? false,
        "createdAt": FieldValue.serverTimestamp(),
      });
      showToast("✅ Resource saved to Firestore", "success");
    } catch (e) {
      showToast("❌ Lỗi khi lưu Firestore: $e", "error");
    }
  }

  /// 🔹 Toggle favorite
  Future<void> toggleFavorite(String id, bool current) async {
    try {
      await firestore.collection("resources").doc(id).update({
        "isFavorite": !current,
      });
    } catch (e) {
      showToast("❌ Lỗi khi cập nhật Firestore: $e", "error");
    }
  }

  /// 🔹 Xóa resource
  Future<void> deleteResource(String id) async {
    try {
      await firestore.collection("resources").doc(id).delete();
      showToast("✅ Resource deleted", "success");
    } catch (e) {
      showToast("❌ Lỗi khi xóa Firestore: $e", "error");
    }
  }

  /// 🔹 Hiển thị chi tiết resource
  Future<void> showResourceDetail(Map<String, dynamic> res, String id) {
    final theme = Theme.of(context);
    return showDialog(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceVariant,
                borderRadius:
                const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Row(
                children: [
                  Icon(Icons.library_books,
                      color: theme.colorScheme.primary, size: 22),
                  const SizedBox(width: 8),
                  Text("Resource Details",
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.primary)),
                ],
              ),
            ),

            // Body
            Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (res['createdAt'] != null)
                    Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        DateFormat("HH:mm - dd/MM/yyyy").format(
                            (res['createdAt'] as Timestamp?)?.toDate() ??
                                DateTime.now()),
                        style: TextStyle(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  const SizedBox(height: 10),
                  Text(res['title'] ?? '',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 17,
                          color: theme.colorScheme.onSurface)),
                  const SizedBox(height: 10),
                  Text("Type: ${res['type'] ?? ''}",
                      style: TextStyle(
                          fontSize: 14,
                          color: theme.colorScheme.onSurfaceVariant)),
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceVariant,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(res['description'] ?? '',
                        style: TextStyle(
                            fontSize: 15,
                            height: 1.6,
                            color: theme.colorScheme.onSurface)),
                  ),
                ],
              ),
            ),

            // Footer
            Padding(
              padding: const EdgeInsets.only(bottom: 14, right: 14),
              child: Align(
                alignment: Alignment.centerRight,
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    shape: const StadiumBorder(),
                    side: BorderSide(color: theme.colorScheme.outline),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 22, vertical: 10),
                  ),
                  child: Text("Close",
                      style: TextStyle(color: theme.colorScheme.onSurface)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Resource Center"),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list),
            onSelected: (value) => setState(() => filter = value),
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'All', child: Text('All')),
              PopupMenuItem(value: 'Blog', child: Text('Blog')),
              PopupMenuItem(value: 'Ebook', child: Text('Ebook')),
              PopupMenuItem(value: 'Video', child: Text('Video')),
              PopupMenuItem(value: 'Image', child: Text('Image')),
            ],
          ),
        ],
      ),

      /// 🔹 StreamBuilder realtime
      body: StreamBuilder<QuerySnapshot>(
        stream: firestore
            .collection("resources")
            .orderBy("createdAt", descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;

          List<Map<String, dynamic>> resources = docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return {
              "id": doc.id,
              "title": data["title"],
              "description": data["description"],
              "type": data["type"],
              "url": data["url"],
              "tags": data["tags"],
              "isFavorite": data["isFavorite"] ?? false,
              "createdAt": data["createdAt"],
            };
          }).toList();

          // lọc
          if (filter != 'All') {
            resources =
                resources.where((r) => r['type'] == filter).toList();
          }

          if (resources.isEmpty) {
            return const Center(
                child: Text("No resources found",
                    style: TextStyle(fontSize: 16)));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: resources.length,
            itemBuilder: (context, index) {
              final res = resources[index];
              final bool isFav = res['isFavorite'] == true;

              return Dismissible(
                key: ValueKey(res['id']),
                direction: DismissDirection.endToStart,
                confirmDismiss: (direction) async {
                  return await showDialog(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: const Text("Confirm delete"),
                      content: const Text(
                          "Are you sure you want to delete this resource?"),
                      actions: [
                        TextButton(
                            onPressed: () =>
                                Navigator.of(context).pop(false),
                            child: const Text("Cancel")),
                        ElevatedButton(
                            onPressed: () =>
                                Navigator.of(context).pop(true),
                            child: const Text("Delete")),
                      ],
                    ),
                  );
                },
                onDismissed: (_) => deleteResource(res['id']),
                background: Container(
                  decoration: BoxDecoration(
                    color: theme.colorScheme.error,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: const Icon(Icons.delete,
                      color: Colors.white, size: 28),
                ),
                child: Card(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  elevation: 3,
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    leading: Icon(
                      res['type'] == "Blog"
                          ? Icons.article
                          : res['type'] == "Ebook"
                          ? Icons.book
                          : res['type'] == "Video"
                          ? Icons.video_library
                          : Icons.image,
                      color: theme.colorScheme.primary,
                      size: 32,
                    ),
                    title: Text(
                      res['title'] ?? '',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    subtitle: Text(
                      res['description'] ?? '',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          color: theme.colorScheme.onSurfaceVariant),
                    ),
                    trailing: IconButton(
                      icon: Icon(
                          isFav ? Icons.favorite : Icons.favorite_border,
                          color: isFav
                              ? theme.colorScheme.error
                              : theme.colorScheme.onSurfaceVariant),
                      onPressed: () =>
                          toggleFavorite(res['id'], isFav),
                    ),
                    onTap: () => showResourceDetail(res, res['id']),
                  ),
                ),
              );
            },
          );
        },
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showDialog(
            context: context,
            builder: (_) {
              final _titleController = TextEditingController();
              final _descController = TextEditingController();
              String selectedType = 'Blog';
              String? uploadedUrl;
              bool isUploading = false;

              return StatefulBuilder(
                builder: (context, setState) {
                  Future<void> pickAndUploadFile() async {
                    try {
                      FilePickerResult? result = await FilePicker.platform.pickFiles();
                      if (result != null && result.files.single.path != null) {
                        File file = File(result.files.single.path!);

                        setState(() => isUploading = true);

                        final storageRef = FirebaseStorage.instance
                            .ref()
                            .child("resources/${DateTime.now().millisecondsSinceEpoch}_${result.files.single.name}");

                        await storageRef.putFile(file);
                        final url = await storageRef.getDownloadURL();

                        setState(() {
                          uploadedUrl = url;
                          isUploading = false;
                        });

                        showToast("✅ File uploaded successfully", "success");
                      }
                    } catch (e) {
                      setState(() => isUploading = false);
                      showToast("❌ Upload error: $e", "error");
                    }
                  }

                  return AlertDialog(
                    title: const Text("Add Resource"),
                    content: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          TextField(
                            controller: _titleController,
                            decoration: const InputDecoration(labelText: "Title"),
                          ),
                          TextField(
                            controller: _descController,
                            decoration: const InputDecoration(labelText: "Description"),
                            maxLines: 3,
                          ),
                          const SizedBox(height: 10),

                          // Button chọn file
                          Row(
                            children: [
                              ElevatedButton.icon(
                                onPressed: pickAndUploadFile,
                                icon: const Icon(Icons.attach_file),
                                label: const Text("Select File"),
                              ),
                              const SizedBox(width: 10),
                              if (isUploading)
                                const CircularProgressIndicator()
                              else if (uploadedUrl != null)
                                const Icon(Icons.check_circle, color: Colors.green),
                            ],
                          ),

                          const SizedBox(height: 10),
                          DropdownButtonFormField<String>(
                            value: selectedType,
                            items: const [
                              DropdownMenuItem(value: "Blog", child: Text("Blog")),
                              DropdownMenuItem(value: "Ebook", child: Text("Ebook")),
                              DropdownMenuItem(value: "Video", child: Text("Video")),
                              DropdownMenuItem(value: "Image", child: Text("Image")),
                            ],
                            onChanged: (val) => selectedType = val!,
                            decoration: const InputDecoration(labelText: "Type"),
                          ),
                        ],
                      ),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text("Cancel"),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          if (_titleController.text.isEmpty ||
                              _descController.text.isEmpty ||
                              uploadedUrl == null) {
                            showToast("❌ Please fill in all required fields", "error");
                            return;
                          }

                          saveResourceToFirestore({
                            "title": _titleController.text.trim(),
                            "description": _descController.text.trim(),
                            "type": selectedType,
                            "url": uploadedUrl, // link file trên Firebase Storage
                            "tags": [],
                            "isFavorite": false,
                          });

                          Navigator.pop(context);
                        },
                        child: const Text("Save"),
                      ),
                    ],
                  );
                },
              );
            },
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
