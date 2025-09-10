import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:trackmentalhealth/main.dart'; // Dùng flutterLocalNotificationsPlugin đã init
import 'package:intl/intl.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  String filter = 'All';
  List<String> oldIds = [];

  Future<void> _showSystemNotification(String title, String message) async {
    const AndroidNotificationDetails androidDetails =
    AndroidNotificationDetails(
      'app_channel_id',
      'Thông báo',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
    );

    const NotificationDetails notificationDetails =
    NotificationDetails(android: androidDetails);

    await flutterLocalNotificationsPlugin.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      message,
      notificationDetails,
    );
  }

  Future<void> saveNotificationToFirestore(Map<String, dynamic> noti) async {
    try {
      await firestore.collection("notifications").add({
        "title": noti["title"],
        "message": noti["message"],
        "datetime": noti["datetime"] ?? DateTime.now().toIso8601String(),
        "isRead": noti["isRead"] ?? false,
        "createdAt": FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint("❌ Error saving Firestore: $e");
    }
  }

  Future<void> markAsRead(String id) async {
    try {
      await firestore.collection("notifications").doc(id).update({
        "isRead": true,
      });
    } catch (e) {
      debugPrint("❌ Error update Firestore: $e");
    }
  }

  Future<void> deleteNotification(String id) async {
    try {
      await firestore.collection("notifications").doc(id).delete();
    } catch (e) {
      debugPrint("❌ Error delete Firestore: $e");
    }
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
                borderRadius:
                const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Row(
                children: [
                  Icon(Icons.notifications_none,
                      color: theme.colorScheme.primary, size: 22),
                  const SizedBox(width: 8),
                  Text("Notification Details",
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.primary)),
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
                        DateFormat("HH:mm - dd/MM/yyyy")
                            .format(DateTime.parse(noti['datetime'])),
                        style: TextStyle(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  const SizedBox(height: 10),
                  Text(noti['title'] ?? '',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 17,
                          color: theme.colorScheme.onSurface)),
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceVariant,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(noti['message'] ?? '',
                        style: TextStyle(
                            fontSize: 15,
                            height: 1.6,
                            color: theme.colorScheme.onSurface)),
                  ),
                ],
              ),
            ),
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
        stream: firestore
            .collection("notifications")
            .orderBy("createdAt", descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;
          List<Map<String, dynamic>> notis = docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return {
              "id": doc.id,
              "title": data["title"],
              "message": data["message"],
              "datetime": data["datetime"],
              "isRead": data["isRead"],
            };
          }).toList();

          // Detect new notification
          final currentIds = notis.map((n) => n['id'] as String).toList();
          if (oldIds.isNotEmpty && currentIds.length > oldIds.length) {
            final newNoti = notis.first;
            _showSystemNotification(
              newNoti['title'] ?? "New notification",
              newNoti['message'] ?? "",
            );
          }
          oldIds = currentIds;

          if (filter == 'Unread') {
            notis = notis.where((n) => n['isRead'] != true).toList();
          }

          if (notis.isEmpty) {
            return const Center(
                child: Text("No notifications", style: TextStyle(fontSize: 16)));
          }

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
                      title: const Text("Xác nhận xóa"),
                      content: const Text("Bạn có chắc chắn muốn xóa không?"),
                      actions: [
                        TextButton(
                            onPressed: () => Navigator.of(context).pop(false),
                            child: const Text("Hủy")),
                        ElevatedButton(
                            onPressed: () => Navigator.of(context).pop(true),
                            child: const Text("Xóa")),
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
                  child:
                  const Icon(Icons.delete, color: Colors.white, size: 28),
                ),
                child: Card(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  color: isRead
                      ? theme.colorScheme.surfaceVariant
                      : theme.colorScheme.surface,
                  elevation: 3,
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    leading: Icon(
                      isRead
                          ? Icons.notifications_none
                          : Icons.notifications_active,
                      color: isRead
                          ? theme.colorScheme.onSurfaceVariant
                          : theme.colorScheme.error,
                      size: 32,
                    ),
                    title: Text(
                      noti['title'] ?? '',
                      style: TextStyle(
                        fontWeight:
                        isRead ? FontWeight.normal : FontWeight.bold,
                        fontSize: 16,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    subtitle: Text(
                      noti['message'] ?? '',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style:
                      TextStyle(color: theme.colorScheme.onSurfaceVariant),
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
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          saveNotificationToFirestore({
            "title": "Thông báo test",
            "message": "Đây là thông báo test lúc ${DateTime.now()}",
            "datetime": DateTime.now().toIso8601String(),
            "isRead": false,
          });
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
