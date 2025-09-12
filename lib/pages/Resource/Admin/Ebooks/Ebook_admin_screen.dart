import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'add_ebook_screen.dart';
import 'edit_ebook_screen.dart'; // bạn sẽ tạo màn hình edit tương tự Add

class AdminEbookScreen extends StatefulWidget {
  const AdminEbookScreen({super.key});

  @override
  State<AdminEbookScreen> createState() => _AdminEbookScreenState();
}

class _AdminEbookScreenState extends State<AdminEbookScreen> {
  final firestore = FirebaseFirestore.instance;
  final user = FirebaseAuth.instance.currentUser;

  // Xóa ebook
  Future<void> _deleteEbook(String id) async {
    await firestore.collection("ebooks").doc(id).delete();
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text("Ebook deleted")));
  }

  // Rút gọn text
  String _shorten(String? text, [int maxLength = 40]) {
    if (text == null) return '';
    return text.length > maxLength ? '${text.substring(0, maxLength)}...' : text;
  }

  @override
  Widget build(BuildContext context) {
    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text("Admin Ebook")),
        body: const Center(child: Text("Please log in to view your ebooks")),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Admin Ebook")),
      body: StreamBuilder<QuerySnapshot>(
        stream: firestore
            .collection("ebooks")
            .where("createdBy", isEqualTo: user!.uid) // chỉ lấy ebook của user này
            .orderBy("createdAt", descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No ebooks found"));
          }

          final docs = snapshot.data!.docs;
          final isLandscape =
              MediaQuery.of(context).orientation == Orientation.landscape;

          if (!isLandscape) {
            // Mobile / Portrait
            return ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: docs.length,
              itemBuilder: (context, index) {
                final data = docs[index].data() as Map<String, dynamic>;
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  child: ListTile(
                    leading: data['thumbnail'] != null
                        ? Image.network(
                      data['thumbnail'],
                      width: 50,
                      height: 50,
                      fit: BoxFit.cover,
                    )
                        : null,
                    title: Text(_shorten(data['title'], 50)),
                    subtitle: Text(_shorten(data['description'], 100)),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    EditEbookScreen(ebookId: docs[index].id),
                              ),
                            );
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () => _deleteEbook(docs[index].id),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          }

          // Tablet / Landscape
          return SingleChildScrollView(
            scrollDirection: Axis.vertical,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: const [
                  DataColumn(label: Text('Title')),
                  DataColumn(label: Text('Description')),
                  DataColumn(label: Text('Tags')),
                  DataColumn(label: Text('Thumbnail')),
                  DataColumn(label: Text('PDF URL')),
                  DataColumn(label: Text('Favorite')),
                  DataColumn(label: Text('Bookmark')),
                  DataColumn(label: Text('Actions')),
                ],
                rows: docs.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  return DataRow(
                    cells: [
                      DataCell(Text(_shorten(data['title']))),
                      DataCell(Text(_shorten(data['description']))),
                      DataCell(
                        Text(
                          (data['tags'] as List<dynamic>?)?.join(', ') ?? '',
                        ),
                      ),
                      DataCell(
                        data['thumbnail'] != null
                            ? Image.network(
                          data['thumbnail'],
                          width: 50,
                          height: 50,
                          fit: BoxFit.cover,
                        )
                            : const SizedBox.shrink(),
                      ),
                      DataCell(Text(data['pdfUrl'] ?? '')),
                      DataCell(
                        Icon(
                          data['isFavorite'] == true
                              ? Icons.favorite
                              : Icons.favorite_border,
                          color: Colors.red,
                        ),
                      ),
                      DataCell(
                        Icon(
                          data['isBookmark'] == true
                              ? Icons.bookmark
                              : Icons.bookmark_border,
                        ),
                      ),
                      DataCell(
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        EditEbookScreen(ebookId: doc.id),
                                  ),
                                );
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete),
                              onPressed: () => _deleteEbook(doc.id),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddEbookScreen()),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
