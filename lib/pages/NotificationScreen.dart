import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../DTO/SendNoticeDTO.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  String filter = 'All';
  List<String> oldIds = [];

  String? currentUserId = FirebaseAuth.instance.currentUser?.uid;

  Future<void> saveNotificationToFirestore(SendNoticeDTO notice) async {
    if (currentUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to save notifications')),
      );
      return;
    }

    try {
      final noticeWithUser = SendNoticeDTO(
        title: notice.title,
        message: notice.message,
        userId: currentUserId,
        isRead: notice.isRead,
        datetime: notice.datetime,
      );

      await firestore.collection("notifications").add(noticeWithUser.toMap());
      debugPrint("✅ Notification saved successfully");
    } catch (e) {
      debugPrint("❌ Error saving Firestore: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving notification: $e')),
      );
    }
  }

  Future<void> markAsRead(String id) async {
    if (currentUserId == null) return;
    try {
      final doc = await firestore.collection("notifications").doc(id).get();
      if (doc.exists && doc['userId'] == currentUserId) {
        await firestore.collection("notifications").doc(id).update({"isRead": true});
        debugPrint("✅ Notification marked as read: $id");
      }
    } catch (e) {
      debugPrint("❌ Error updating Firestore: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error marking notification as read: $e')),
      );
    }
  }

  Future<void> deleteNotification(String id) async {
    if (currentUserId == null) return;
    try {
      final doc = await firestore.collection("notifications").doc(id).get();
      if (doc.exists && doc['userId'] == currentUserId) {
        await firestore.collection("notifications").doc(id).delete();
        debugPrint("✅ Notification deleted: $id");
      }
    } catch (e) {
      debugPrint("❌ Error deleting Firestore: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting notification: $e')),
      );
    }
  }

  Stream<QuerySnapshot> notificationStream() {
    final collection = FirebaseFirestore.instance.collection("notifications");

    if (currentUserId == null) {
      // Hiển thị tất cả thông báo (public + có userId)
      return collection.orderBy("createdAt", descending: true).snapshots();
    }

    // Lọc theo userId hoặc public (userId == "ALL")
    return collection
        .where('userId', whereIn: [currentUserId, 'ALL'])
        .orderBy("createdAt", descending: true)
        .snapshots();
  }



  Future<void> showNotificationDetail(Map<String, dynamic> noti) {
    final theme = Theme.of(context);
    return showDialog(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        insetPadding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceVariant,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Row(
                children: [
                  Icon(Icons.notifications_none, color: theme.colorScheme.primary, size: 22),
                  const SizedBox(width: 8),
                  Text(
                    "Notification Details",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (noti['datetime'] != null)
                    Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        DateFormat("HH:mm - dd/MM/yyyy").format(DateTime.parse(noti['datetime'])),
                        style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 12),
                      ),
                    ),
                  const SizedBox(height: 10),
                  Text(
                    noti['title'] ?? 'No title',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 17,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceVariant,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      noti['message'] ?? 'No content',
                      style: TextStyle(fontSize: 15, height: 1.6, color: theme.colorScheme.onSurface),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 14, right: 14, left: 14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      shape: const StadiumBorder(),
                      side: BorderSide(color: theme.colorScheme.outline),
                      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
                    ),
                    child: Text("Close", style: TextStyle(color: theme.colorScheme.onSurface)),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (_) => AlertDialog(
                          title: const Text("Confirm Deletion"),
                          content: const Text("Are you sure you want to delete this notification?"),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(false),
                              child: const Text("Cancel"),
                            ),
                            ElevatedButton(
                              onPressed: () => Navigator.of(context).pop(true),
                              child: const Text("Delete"),
                            ),
                          ],
                        ),
                      );

                      if (confirm == true) {
                        await deleteNotification(noti['id']);
                        Navigator.pop(context);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.error,
                      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    ),
                    child: const Text("Delete", style: TextStyle(color: Colors.white)),
                  ),
                ],
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

    if (currentUserId == null) {
      debugPrint("❌ No user logged in");
      return Scaffold(
        appBar: AppBar(title: const Text("Notifications")),
        body: const Center(child: Text('Please log in to view notifications')),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text("Notifications"),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list),
            onSelected: (value) => setState(() => filter = value),
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'All', child: Text('All')),
              PopupMenuItem(value: 'Unread', child: Text('Unread')),
            ],
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: notificationStream(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            debugPrint("❌ StreamBuilder error: ${snapshot.error}");
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error, color: Colors.red, size: 64),
                  const SizedBox(height: 16),
                  Text('Error loading notifications: ${snapshot.error}'),
                  ElevatedButton(
                    onPressed: () => setState(() {}),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            debugPrint("🔄 Waiting for data");
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            debugPrint("ℹ️ No notifications found");
            return const Center(child: Text('No notifications', style: TextStyle(fontSize: 16)));
          }

          final docs = snapshot.data!.docs;
          List<Map<String, dynamic>> notis = docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return {
              "id": doc.id,
              "title": data["title"] ?? 'No title',
              "message": data["message"] ?? 'No content',
              "datetime": data["datetime"],
              "isRead": data["isRead"] ?? false,
            };
          }).toList();

          if (filter == 'Unread') {
            notis = notis.where((n) => n['isRead'] != true).toList();
          }

          if (notis.isEmpty) {
            debugPrint("ℹ️ No notifications after filtering");
            return const Center(child: Text('No notifications', style: TextStyle(fontSize: 16)));
          }

          debugPrint("✅ Loaded ${notis.length} notifications");
          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: notis.length,
            itemBuilder: (context, index) {
              final noti = notis[index];
              bool isRead = noti['isRead'] == true;

              return Dismissible(
                key: ValueKey(noti['id']),
                direction: DismissDirection.endToStart,
                confirmDismiss: (direction) async {
                  return await showDialog(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: const Text("Confirm Deletion"),
                      content: const Text("Are you sure you want to delete this notification?"),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(false),
                          child: const Text("Cancel"),
                        ),
                        ElevatedButton(
                          onPressed: () => Navigator.of(context).pop(true),
                          child: const Text("Delete"),
                        ),
                      ],
                    ),
                  );
                },
                onDismissed: (_) => deleteNotification(noti['id']),
                background: Container(
                  decoration: BoxDecoration(
                    color: theme.colorScheme.error,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: const Icon(Icons.delete, color: Colors.white, size: 28),
                ),
                child: Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  color: isRead ? theme.colorScheme.surfaceVariant : theme.colorScheme.surface,
                  elevation: 3,
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    leading: Icon(
                      isRead ? Icons.notifications_none : Icons.notifications_active,
                      color: isRead ? theme.colorScheme.onSurfaceVariant : theme.colorScheme.error,
                      size: 32,
                    ),
                    title: Text(
                      noti['title'],
                      style: TextStyle(
                        fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
                        fontSize: 16,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    subtitle: Text(
                      noti['message'],
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                    ),
                    trailing: isRead
                        ? null
                        : Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.error,
                        shape: BoxShape.circle,
                      ),
                    ),
                    onTap: () {
                      markAsRead(noti['id']);
                      showNotificationDetail(noti);
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
