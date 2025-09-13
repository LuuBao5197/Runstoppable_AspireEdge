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
        const SnackBar(content: Text('Vui lòng đăng nhập để lưu thông báo')),
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
        SnackBar(content: Text('Lỗi khi lưu thông báo: $e')),
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
        SnackBar(content: Text('Lỗi khi đánh dấu đã đọc: $e')),
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
        SnackBar(content: Text('Lỗi khi xóa thông báo: $e')),
      );
    }
  }

  Stream<QuerySnapshot> notificationStream() {
    if (currentUserId == null) {
      debugPrint("❌ currentUserId is null, returning empty stream");
      return const Stream<QuerySnapshot>.empty();
    }
    debugPrint("🔄 Fetching notifications for user: $currentUserId");
    return firestore
        .collection("notifications")
        .where('userId', isEqualTo: currentUserId)
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
                    "Chi tiết thông báo",
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
                    noti['title'] ?? 'Không có tiêu đề',
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
                      noti['message'] ?? 'Không có nội dung',
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
                    child: Text("Đóng", style: TextStyle(color: theme.colorScheme.onSurface)),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (_) => AlertDialog(
                          title: const Text("Xác nhận xóa"),
                          content: const Text("Bạn có chắc muốn xóa thông báo này?"),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(false),
                              child: const Text("Hủy"),
                            ),
                            ElevatedButton(
                              onPressed: () => Navigator.of(context).pop(true),
                              child: const Text("Xóa"),
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
                    child: const Text("Xóa", style: TextStyle(color: Colors.white)),
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

    // Kiểm tra nếu chưa đăng nhập
    if (currentUserId == null) {
      debugPrint("❌ No user logged in");
      return Scaffold(
        appBar: AppBar(title: const Text("Thông báo")),
        body: const Center(child: Text('Vui lòng đăng nhập để xem thông báo')),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text("Thông báo"),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list),
            onSelected: (value) => setState(() => filter = value),
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'All', child: Text('Tất cả')),
              PopupMenuItem(value: 'Unread', child: Text('Chưa đọc')),
            ],
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: notificationStream(),
        builder: (context, snapshot) {
          // Xử lý lỗi (ví dụ: quyền Firestore sai, mất mạng)
          if (snapshot.hasError) {
            debugPrint("❌ StreamBuilder error: ${snapshot.error}");
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error, color: Colors.red, size: 64),
                  const SizedBox(height: 16),
                  Text('Lỗi khi tải thông báo: ${snapshot.error}'),
                  ElevatedButton(
                    onPressed: () => setState(() {}), // Thử lại
                    child: const Text('Thử lại'),
                  ),
                ],
              ),
            );
          }

          // Hiển thị loading khi đang chờ dữ liệu
          if (snapshot.connectionState == ConnectionState.waiting) {
            debugPrint("🔄 Waiting for data");
            return const Center(child: CircularProgressIndicator());
          }

          // Nếu không có dữ liệu hoặc collection rỗng
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            debugPrint("ℹ️ No notifications found");
            return const Center(child: Text('Không có thông báo nào', style: TextStyle(fontSize: 16)));
          }

          final docs = snapshot.data!.docs;
          List<Map<String, dynamic>> notis = docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return {
              "id": doc.id,
              "title": data["title"] ?? 'Không có tiêu đề',
              "message": data["message"] ?? 'Không có nội dung',
              "datetime": data["datetime"],
              "isRead": data["isRead"] ?? false,
            };
          }).toList();

          if (filter == 'Unread') {
            notis = notis.where((n) => n['isRead'] != true).toList();
          }

          if (notis.isEmpty) {
            debugPrint("ℹ️ No notifications after filtering");
            return const Center(child: Text('Không có thông báo', style: TextStyle(fontSize: 16)));
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
                      title: const Text("Xác nhận xóa"),
                      content: const Text("Bạn có chắc muốn xóa thông báo này?"),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(false),
                          child: const Text("Hủy"),
                        ),
                        ElevatedButton(
                          onPressed: () => Navigator.of(context).pop(true),
                          child: const Text("Xóa"),
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