import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'AdminFeedbackDetailPage.dart';

class AdminFeedbackPage extends StatefulWidget {
  const AdminFeedbackPage({super.key});

  @override
  State<AdminFeedbackPage> createState() => _AdminFeedbackPageState();
}

class _AdminFeedbackPageState extends State<AdminFeedbackPage> {
  String _filter = "All";

  @override
  Widget build(BuildContext context) {
    final query = FirebaseFirestore.instance
        .collection("feedbacks")
        .orderBy("createdAt", descending: true);

    return Scaffold(
      appBar: AppBar(
        title: const Text(""), // bỏ chữ Feedback Management
        centerTitle: true,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 12, top: 8, bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              border: Border.all(
                color: Theme.of(context).colorScheme.primary,
                width: 1.2,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: DropdownButton<String>(
              value: _filter,
              underline: const SizedBox(),
              borderRadius: BorderRadius.circular(12),
              items: const [
                DropdownMenuItem(value: "All", child: Text("All")),
                DropdownMenuItem(value: "Unresolved", child: Text("Unresolved")),
              ],
              onChanged: (val) {
                if (val != null) setState(() => _filter = val);
              },
            ),
          ),
        ],
      ),
      body: StreamBuilder(
        stream: query.snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;

          // lọc thủ công thay vì query Firestore
          final filteredDocs = _filter == "Unresolved"
              ? docs.where((d) {
            final data = d.data() as Map<String, dynamic>;
            final status = data["status"];
            return status == null || status != "resolved";
          }).toList()
              : docs;

          if (filteredDocs.isEmpty) {
            return const Center(child: Text("No feedback found"));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: filteredDocs.length,
            itemBuilder: (context, index) {
              final fb = filteredDocs[index].data() as Map<String, dynamic>;

              return Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  leading: FutureBuilder<DocumentSnapshot>(
                    future: FirebaseFirestore.instance
                        .collection("accounts")
                        .doc(fb["userId"])
                        .get(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const CircleAvatar(
                          backgroundColor: Colors.grey,
                          child: Icon(Icons.person, color: Colors.white),
                        );
                      }
                      if (!snapshot.hasData || !snapshot.data!.exists) {
                        return const CircleAvatar(
                          backgroundColor: Colors.teal,
                          child: Icon(Icons.person, color: Colors.white),
                        );
                      }

                      final acc = snapshot.data!.data() as Map<String, dynamic>;
                      final avatarUrl = acc["avatarUrl"] ?? "";

                      return CircleAvatar(
                        backgroundImage:
                        avatarUrl.isNotEmpty ? NetworkImage(avatarUrl) : null,
                        backgroundColor: Colors.teal,
                        child: avatarUrl.isEmpty
                            ? const Icon(Icons.person, color: Colors.white)
                            : null,
                      );
                    },
                  ),
                  title: Text(fb["fullName"] ?? "Unknown"),
                  subtitle: Text(
                    "${fb["message"]}\n⭐ ${fb["rating"]}/5",
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: fb["status"] == "resolved"
                      ? const Icon(Icons.check_circle, color: Colors.green)
                      : const Icon(Icons.pending_actions, color: Colors.orange),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => FeedbackDetailPage(
                          data: fb,
                          docId: filteredDocs[index].id,
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
