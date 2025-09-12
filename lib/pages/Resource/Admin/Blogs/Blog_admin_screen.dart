import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'add_blog_screen.dart';
import 'edit_blog_screen.dart';

class AdminBlogScreen extends StatefulWidget {
  const AdminBlogScreen({super.key});

  @override
  State<AdminBlogScreen> createState() => _AdminBlogScreenState();
}

class _AdminBlogScreenState extends State<AdminBlogScreen> {
  final firestore = FirebaseFirestore.instance;
  final user = FirebaseAuth.instance.currentUser;

  // Xóa blog
  Future<void> _deleteBlog(String id) async {
    await firestore.collection("blogs").doc(id).delete();
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text("Blog deleted")));
  }

  // Rút gọn text
  String _shorten(String? text, [int maxLength = 40]) {
    if (text == null) return '';
    return text.length > maxLength ? '${text.substring(0, maxLength)}...' : text;
  }

  @override
  Widget build(BuildContext context) {
    // Kiểm tra nếu user chưa đăng nhập
    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text("Admin Blog")),
        body: const Center(child: Text("Please log in to view your blogs")),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Admin Blog"),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: firestore
            .collection("blogs")
            .where("createdBy", isEqualTo: user!.uid)
            .orderBy("createdAt", descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          // Debug log chi tiết
          print("Connection state: ${snapshot.connectionState}");
          print("Has data: ${snapshot.hasData}");
          print("Has error: ${snapshot.hasError}");
          if (snapshot.hasError) {
            print("Error details: ${snapshot.error}");
            print("Stack trace: ${snapshot.stackTrace}");
          }

          // Kiểm tra trạng thái kết nối
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // Kiểm tra lỗi
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("Error: ${snapshot.error}"),
                  const SizedBox(height: 10),
                  Text(
                    "Please ensure the index is created and deployed. Check Firebase Console.",
                  ),
                ],
              ),
            );
          }

          // Kiểm tra dữ liệu rỗng
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No blogs found"));
          }

          final docs = snapshot.data!.docs;

          // Kiểm tra chiều màn hình
          final isLandscape =
              MediaQuery.of(context).orientation == Orientation.landscape;

          if (!isLandscape) {
            // ================= Portrait / Mobile: ListView Card =================
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
                                    EditBlogScreen(blogId: docs[index].id),
                              ),
                            );
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () => _deleteBlog(docs[index].id),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          }

          // ================= Landscape / Tablet/Desktop: DataTable =================
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
                  DataColumn(label: Text('Actions')),
                ],
                rows: docs.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  return DataRow(
                    cells: [
                      DataCell(Text(_shorten(data['title']))),
                      DataCell(Text(_shorten(data['description']))),
                      DataCell(Text(
                          (data['tags'] as List<dynamic>?)?.join(', ') ?? '')),
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
                                        EditBlogScreen(blogId: doc.id),
                                  ),
                                );
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete),
                              onPressed: () => _deleteBlog(doc.id),
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
            MaterialPageRoute(builder: (_) => const AddBlogScreen()),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}