import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../DTO/SendNoticeDTO.dart';

class SendNoticePage extends StatefulWidget {
  const SendNoticePage({super.key});

  @override
  State<SendNoticePage> createState() => _SendNoticePageState();
}


class _SendNoticePageState extends State<SendNoticePage> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();
  bool _sending = false;

  List<Map<String, dynamic>> _users = [];
  String? _selectedUserId;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    final snapshot = await FirebaseFirestore.instance.collection('account').get();
    final users = snapshot.docs.map((doc) {
      final data = doc.data();
      return {
        'id': doc.id,
        'name': data['name'] ?? 'No Name',
      };
    }).toList();

    setState(() {
      _users = users;
    });
  }

  Future<void> _sendNotice() async {
    final title = _titleController.text.trim();
    final message = _messageController.text.trim();

    if (title.isEmpty || message.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in both title and message')),
      );
      return;
    }

    setState(() => _sending = true);

    try {
      if (_selectedUserId == null) {
        // Gửi cho tất cả user
        final snapshot = await FirebaseFirestore.instance.collection('account').get();
        for (var doc in snapshot.docs) {
          final notice = SendNoticeDTO(
            title: title,
            message: message,
            userId: doc.id,
          );
          await FirebaseFirestore.instance
              .collection('notifications')
              .add(notice.toMap());
        }
      } else {
        // Gửi cho user đã chọn
        final notice = SendNoticeDTO(
          title: title,
          message: message,
          userId: _selectedUserId,
        );
        await FirebaseFirestore.instance
            .collection('notifications')
            .add(notice.toMap());
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Notice sent successfully!')),
      );

      _titleController.clear();
      _messageController.clear();
      setState(() => _selectedUserId = null);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error sending notice: $e')),
      );
    } finally {
      setState(() => _sending = false);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Send Notice'),
        centerTitle: true,
        elevation: 4,
        backgroundColor: theme.appBarTheme.backgroundColor,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Card(
          color: isDark ? Colors.grey[900] : Colors.white,
          elevation: 6,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          shadowColor: theme.primaryColor.withOpacity(0.3),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Create New Notice',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 20),

                // Dropdown to select user
                DropdownButtonFormField<String>(
                  value: _selectedUserId,
                  items: [
                    const DropdownMenuItem(value: null, child: Text('All Users')),
                    ..._users.map((user) => DropdownMenuItem(
                      value: user['id'],
                      child: Text(user['name']),
                    )),
                  ],
                  onChanged: (value) => setState(() => _selectedUserId = value),
                  decoration: InputDecoration(
                    labelText: 'Select Recipient',
                    labelStyle: TextStyle(color: theme.textTheme.bodyLarge?.color),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: isDark ? Colors.grey[850] : Colors.grey[50],
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  dropdownColor: isDark ? Colors.grey[850] : Colors.white,
                ),
                const SizedBox(height: 16),

                // Title
                TextField(
                  controller: _titleController,
                  decoration: InputDecoration(
                    labelText: 'Title',
                    labelStyle: TextStyle(color: theme.textTheme.bodyLarge?.color),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: isDark ? Colors.grey[850] : Colors.grey[50],
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
                const SizedBox(height: 16),

                // Message
                TextField(
                  controller: _messageController,
                  decoration: InputDecoration(
                    labelText: 'Message',
                    labelStyle: TextStyle(color: theme.textTheme.bodyLarge?.color),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: isDark ? Colors.grey[850] : Colors.grey[50],
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  maxLines: 6,
                ),
                const SizedBox(height: 24),

                ElevatedButton(
                  onPressed: _sending ? null : _sendNotice,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _sending
                      ? SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(
                        color: theme.colorScheme.onPrimary, strokeWidth: 3),
                  )
                      : Text('Send Notice',
                      style: TextStyle(fontSize: 18, color: theme.colorScheme.onPrimary)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
