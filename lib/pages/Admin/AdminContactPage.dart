import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';

class AdminContactPage extends StatefulWidget {
  const AdminContactPage({super.key});

  @override
  State<AdminContactPage> createState() => _AdminContactPageState();
}

class _AdminContactPageState extends State<AdminContactPage> {
  final CollectionReference contactsRef =
  FirebaseFirestore.instance.collection('contacts');

  final Map<String, bool> _expandedMap = {}; // theo docId xem có expand không
  String _filter = 'all'; // all / unread

  Future<void> _deleteContact(String docId) async {
    try {
      await contactsRef.doc(docId).delete();
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Deleted successfully")));
    } catch (e) {
      debugPrint("Delete contact error: $e");
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Failed to delete")));
    }
  }

  Future<void> _sendEmail(String email, String message, String docId) async {
    final Uri emailLaunchUri = Uri(
      scheme: 'mailto',
      path: email,
      query: Uri.encodeFull('subject=Reply from Admin&body=$message'),
    );

    if (!await launchUrl(emailLaunchUri)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Could not open email app")),
      );
    } else {
      // đánh dấu là đã đọc
      await contactsRef.doc(docId).update({'isRead': true});
    }
  }

  Widget _buildFilterDropdown() {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey),
          borderRadius: BorderRadius.circular(12),
        ),
        child: DropdownButton<String>(
          value: _filter,
          isExpanded: true,
          underline: const SizedBox(), // bỏ underline mặc định
          items: const [
            DropdownMenuItem(value: 'all', child: Text('All')),
            DropdownMenuItem(value: 'unread', child: Text('Unread')),
          ],
          onChanged: (value) {
            if (value != null) {
              setState(() {
                _filter = value;
              });
            }
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("User Contacts"),
        centerTitle: true,
      ),
      body: Column(
        children: [
          _buildFilterDropdown(),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream:
              contactsRef.orderBy('createdAt', descending: true).snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text("No messages found"));
                }

                // lọc theo filter
                final filteredContacts = snapshot.data!.docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final isRead = data['isRead'] ?? false;
                  return _filter == 'all' || !isRead;
                }).toList();

                if (filteredContacts.isEmpty) {
                  return const Center(child: Text("No messages found"));
                }

                return ListView.builder(
                  itemCount: filteredContacts.length,
                  itemBuilder: (context, index) {
                    final data =
                    filteredContacts[index].data() as Map<String, dynamic>;
                    final docId = filteredContacts[index].id;
                    final email = data['email'] ?? "-";
                    final message = data['message'] ?? "";
                    final timestamp = data['createdAt'] as Timestamp?;
                    final isExpanded = _expandedMap[docId] ?? false;
                    final displayMessage = !isExpanded && message.length > 100
                        ? "${message.substring(0, 100)}..."
                        : message;
                    final isRead = data['isRead'] ?? false;

                    return Card(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      child: ListTile(
                        leading: Icon(
                          Icons.email,
                          color: isRead ? Colors.green : Colors.red,
                        ),
                        title: Text(email,
                            style:
                            const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text(displayMessage),
                            if (message.length > 100)
                              GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _expandedMap[docId] = !isExpanded;
                                  });
                                },
                                child: Text(
                                  isExpanded ? "Show less" : "Show more",
                                  style: const TextStyle(
                                      color: Colors.blue, fontSize: 12),
                                ),
                              ),
                            if (timestamp != null)
                              Text(
                                timestamp.toDate().toString(),
                                style: const TextStyle(
                                    fontSize: 10, color: Colors.grey),
                              ),
                          ],
                        ),
                        onTap: () => _sendEmail(email, message, docId),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
