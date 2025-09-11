import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EbookDetailScreen extends StatefulWidget {
  final String ebookId;
  const EbookDetailScreen({super.key, required this.ebookId});

  @override
  State<EbookDetailScreen> createState() => _EbookDetailScreenState();
}

class _EbookDetailScreenState extends State<EbookDetailScreen> {
  final firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;

    return Scaffold(
      appBar: AppBar(title: const Text("Ebook Detail")),
      body: StreamBuilder<DocumentSnapshot>(
        stream: firestore.collection("ebooks").doc(widget.ebookId).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final data = snapshot.data!.data() as Map<String, dynamic>?;
          if (data == null) return const Center(child: Text("Ebook not found"));

          final title = data["title"] ?? "";
          final description = data["description"] ?? "";
          final tags = List<String>.from(data["tags"] ?? []);
          final photos = List<String>.from(data["photos"] ?? []);

          if (isLandscape && photos.isNotEmpty) {
            // Landscape: scroll ngang full màn hình
            return PageView.builder(
              itemCount: photos.length,
              itemBuilder: (context, index) {
                final url = photos[index];
                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => FullscreenPhotoScreen(photoUrl: url),
                      ),
                    );
                  },
                  child: Container(
                    color: Colors.black,
                    alignment: Alignment.center,
                    child: Image.network(
                      url,
                      fit: BoxFit.contain,
                      loadingBuilder: (context, child, progress) {
                        if (progress == null) return child;
                        return const Center(child: CircularProgressIndicator());
                      },
                    ),
                  ),
                );
              },
            );
          }

          // Portrait: scroll dọc như hiện tại
          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  // Description
                  Text(description, style: const TextStyle(fontSize: 16)),
                  const SizedBox(height: 12),
                  // Tags
                  if (tags.isNotEmpty)
                    Wrap(
                      spacing: 6,
                      children: tags.map((t) => Chip(label: Text(t))).toList(),
                    ),
                  const SizedBox(height: 16),
                  // Ebook pages
                  if (photos.isNotEmpty)
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: photos.length,
                      itemBuilder: (context, index) {
                        final url = photos[index];
                        return GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => FullscreenPhotoScreen(photoUrl: url),
                              ),
                            );
                          },
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                url,
                                width: double.infinity,
                                fit: BoxFit.cover,
                                loadingBuilder: (context, child, progress) {
                                  if (progress == null) return child;
                                  return SizedBox(
                                    height: 180,
                                    child: const Center(child: CircularProgressIndicator()),
                                  );
                                },
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// Fullscreen photo view
class FullscreenPhotoScreen extends StatelessWidget {
  final String photoUrl;
  const FullscreenPhotoScreen({super.key, required this.photoUrl});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: () => Navigator.pop(context),
        child: Center(
          child: InteractiveViewer(
            child: Image.network(
              photoUrl,
              fit: BoxFit.contain,
              loadingBuilder: (context, child, progress) {
                if (progress == null) return child;
                return const Center(child: CircularProgressIndicator());
              },
            ),
          ),
        ),
      ),
    );
  }
}
