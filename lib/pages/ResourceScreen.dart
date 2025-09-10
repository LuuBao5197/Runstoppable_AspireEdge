import 'dart:io';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import '../../utils/showToast.dart';

class ResourceScreen extends StatefulWidget {
  const ResourceScreen({super.key});

  @override
  State<ResourceScreen> createState() => _ResourceScreenState();
}

class _ResourceScreenState extends State<ResourceScreen> {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();

  String? uploadedUrl;
  String selectedType = "Blog";
  bool isUploading = false;

  String searchQuery = "";

  // ✅ Upload file to backend Cloudinary
  Future<void> pickAndUploadFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles();
      if (result != null && result.files.single.path != null) {
        File file = File(result.files.single.path!);

        setState(() => isUploading = true);

        var request = http.MultipartRequest(
          'POST',
          Uri.parse('http://10.0.2.2:9999/api/upload'), // backend Cloudinary
        );
        request.files.add(await http.MultipartFile.fromPath('file', file.path));

        var response = await request.send();

        if (response.statusCode == 200) {
          final resString = await response.stream.bytesToString();
          final resJson = jsonDecode(resString);

          setState(() {
            uploadedUrl = resJson['url'];
            isUploading = false;
          });

          showToast("✅ File uploaded successfully", "success");
        } else {
          setState(() => isUploading = false);
          showToast("❌ Upload failed: ${response.statusCode}", "error");
        }
      }
    } catch (e) {
      setState(() => isUploading = false);
      showToast("❌ Upload error: $e", "error");
    }
  }

  // ✅ Save metadata to Firestore
  Future<void> saveResourceToFirestore() async {
    if (_titleController.text.trim().isEmpty ||
        _descController.text.trim().isEmpty ||
        uploadedUrl == null) {
      showToast("⚠️ Please fill all fields and upload a file", "warning");
      return;
    }

    try {
      await firestore.collection("resources").add({
        "title": _titleController.text.trim(),
        "description": _descController.text.trim(),
        "type": selectedType,
        "url": uploadedUrl ?? "",
        "tags": [],
        "isFavorite": false,
        "createdAt": FieldValue.serverTimestamp(),
      });

      showToast("✅ Resource saved successfully", "success");

      _titleController.clear();
      _descController.clear();
      setState(() {
        uploadedUrl = null;
        selectedType = "Blog";
      });
    } catch (e) {
      showToast("❌ Error saving resource: $e", "error");
    }
  }

  // ✅ Dialog thêm resource với preview ảnh
  void showAddResourceDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              title: const Text("Add Resource"),
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
                    const SizedBox(height: 10),
                    ElevatedButton.icon(
                      onPressed: isUploading
                          ? null
                          : () async {
                        await pickAndUploadFile();
                        setDialogState(() {}); // update dialog
                      },
                      icon: const Icon(Icons.attach_file),
                      label: Text(isUploading
                          ? "Uploading..."
                          : (uploadedUrl != null
                          ? "File Selected"
                          : "Select File")),
                    ),
                    const SizedBox(height: 10),
                    if (uploadedUrl != null &&
                        (uploadedUrl!.endsWith(".jpg") ||
                            uploadedUrl!.endsWith(".png") ||
                            uploadedUrl!.endsWith(".jpeg") ||
                            uploadedUrl!.contains("image")))
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Image.network(
                          uploadedUrl!,
                          height: 150,
                          fit: BoxFit.cover,
                        ),
                      ),
                    const SizedBox(height: 10),
                    DropdownButton<String>(
                      value: selectedType,
                      onChanged: (value) {
                        setDialogState(() {
                          selectedType = value!;
                        });
                      },
                      items: ["Blog", "Video", "Ebook"]
                          .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                          .toList(),
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
                    saveResourceToFirestore();
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
  }

  // ✅ Dialog xem chi tiết resource
  void showResourceDetailDialog(Map<String, dynamic> data) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: Text(data["title"] ?? "No title"),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (data["url"] != null && data["url"] != "")
                  (data["url"].endsWith(".jpg") ||
                      data["url"].endsWith(".png") ||
                      data["url"].endsWith(".jpeg") ||
                      data["url"].contains("image"))
                      ? Image.network(
                    data["url"],
                    height: 200,
                    fit: BoxFit.cover,
                  )
                      : Text("File: ${data["url"].split('/').last}"),
                const SizedBox(height: 10),
                Text("Description: ${data["description"] ?? ""}"),
                const SizedBox(height: 5),
                Text("Type: ${data["type"] ?? ""}"),
                const SizedBox(height: 5),
                Text(
                    "Created At: ${DateFormat("dd/MM/yyyy HH:mm").format((data["createdAt"] as Timestamp?)?.toDate() ?? DateTime.now())}"),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Close"),
            ),
          ],
        );
      },
    );
  }

  // ✅ Toggle favorite
  Future<void> toggleFavorite(String docId, bool current) async {
    try {
      await firestore.collection("resources").doc(docId).update({
        "isFavorite": !current,
      });
      showToast(current ? "Removed from favorites" : "Added to favorites", "success");
    } catch (e) {
      showToast("❌ Error updating favorite: $e", "error");
    }
  }

  // ✅ Build resource card với thumbnail và favorite
  Widget buildResourceCard(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
      child: ListTile(
        leading: (data["url"] != null &&
            (data["url"].endsWith(".jpg") ||
                data["url"].endsWith(".png") ||
                data["url"].endsWith(".jpeg") ||
                data["url"].contains("image")))
            ? Image.network(
          data["url"],
          width: 50,
          height: 50,
          fit: BoxFit.cover,
        )
            : const Icon(Icons.folder),
        title: Text(data["title"] ?? "No title"),
        subtitle: Text(data["description"] ?? ""),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(
                data["isFavorite"] == true ? Icons.favorite : Icons.favorite_border,
                color: Colors.red,
              ),
              onPressed: () => toggleFavorite(doc.id, data["isFavorite"] == true),
            ),
            Text(
              DateFormat("dd/MM/yyyy").format(
                (data["createdAt"] as Timestamp?)?.toDate() ?? DateTime.now(),
              ),
            ),
          ],
        ),
        onTap: () => showResourceDetailDialog(data),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Resource Center"),
      ),
      body: Column(
        children: [
          // Search field
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: "Search resources...",
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (value) {
                setState(() {
                  searchQuery = value.toLowerCase();
                });
              },
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: firestore
                  .collection("resources")
                  .orderBy("createdAt", descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Center(child: Text("Error loading resources"));
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs = snapshot.data?.docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final title = (data["title"] ?? "").toString().toLowerCase();
                  final desc =
                  (data["description"] ?? "").toString().toLowerCase();
                  return title.contains(searchQuery) ||
                      desc.contains(searchQuery);
                }).toList() ??
                    [];

                if (docs.isEmpty) {
                  return const Center(child: Text("No resources found"));
                }

                return ListView.builder(
                  itemCount: docs.length,
                  itemBuilder: (context, index) => buildResourceCard(docs[index]),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: showAddResourceDialog,
        child: const Icon(Icons.add),
      ),
    );
  }
}
