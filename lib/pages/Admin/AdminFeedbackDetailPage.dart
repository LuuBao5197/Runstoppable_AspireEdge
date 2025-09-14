import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:trackmentalhealth/DTO/SendNoticeDTO.dart';
import 'package:trackmentalhealth/services/SendNoticePage.dart';

import '../../services/SendNotificationService.dart'; // 👈 thêm để format datetime

class FeedbackDetailPage extends StatefulWidget {
  final Map<String, dynamic> data;
  final String docId;

  const FeedbackDetailPage({
    super.key,
    required this.data,
    required this.docId,
  });

  @override
  State<FeedbackDetailPage> createState() => _FeedbackDetailPageState();
}

class _FeedbackDetailPageState extends State<FeedbackDetailPage> {
  final TextEditingController _replyController = TextEditingController();
  bool _isLoading = false;

  Future<void> _sendReply() async {
    if (_replyController.text.trim().isEmpty) return;

    setState(() => _isLoading = true);

    try {
      final replyText = _replyController.text.trim();

      // 1. Update feedback chính
      await FirebaseFirestore.instance
          .collection("feedbacks")
          .doc(widget.docId)
          .update({
        "adminReply": replyText,
        "status": "resolved",
        "repliedAt": FieldValue.serverTimestamp(),
      });

      // 2. Lưu thêm vào feedbackReply (log phản hồi)
      await FirebaseFirestore.instance.collection("feedbackReply").add({
        "feedbackId": widget.docId, // liên kết với feedback gốc
        "reply": replyText,
        "createdAt": FieldValue.serverTimestamp(),
        "adminId": "ADMIN", //
      });

      final not = SendNoticeDTO(
        title: "New notice!",
        message: "You have a new reply feedback!",
        userId: widget.data["userId"], // 👈 chính là user đã tạo feedback
      );

      await SendNotificationService()
          .sendNotificationToUser(widget.data["userId"], not);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("✅ Reply sent successfully")),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("❌ Failed to send reply: $e")),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// Format Firestore timestamp -> DateTime string
  String _formatDate(dynamic createdAt) {
    if (createdAt == null) return "Unknown";
    try {
      DateTime dt;
      if (createdAt is Timestamp) {
        dt = createdAt.toDate();
      } else if (createdAt is DateTime) {
        dt = createdAt;
      } else {
        return createdAt.toString(); // fallback
      }
      return DateFormat("dd MMM yyyy, hh:mm").format(dt);
    } catch (_) {
      return createdAt.toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    final fb = widget.data;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Feedback Detail"),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: SingleChildScrollView(
            child: Column(
              children: [
                // --- Header Card (User Info) ---
                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 3,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 32,
                          backgroundColor:
                          Theme.of(context).colorScheme.primary,
                          child: Text(
                            fb["fullName"]?.substring(0, 1).toUpperCase() ??
                                "?",
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.onPrimary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                fb["fullName"] ?? "Unknown User",
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                fb["email"] ?? "No email",
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                              if (fb["phone"] != null &&
                                  fb["phone"].toString().isNotEmpty)
                                Text(
                                  "📞 ${fb["phone"]}",
                                  style:
                                  Theme.of(context).textTheme.bodyMedium,
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // --- Feedback Content ---
                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.feedback, color: Colors.teal),
                            const SizedBox(width: 8),
                            Text(
                              "Feedback",
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          fb["message"] ?? "",
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                        const SizedBox(height: 12),
                        Text("⭐ Rating: ${fb["rating"]}/5"),
                        const SizedBox(height: 8),
                        Text("🕒 Date: ${_formatDate(fb["createdAt"])}"),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // --- Admin Reply (if exists) ---
                if (fb["adminReply"] != null &&
                    fb["adminReply"].toString().isNotEmpty)
                  Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    color: Theme.of(context).colorScheme.secondaryContainer,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.admin_panel_settings,
                                  color: Colors.teal),
                              const SizedBox(width: 8),
                              Text(
                                "Admin Reply",
                                style:
                                Theme.of(context).textTheme.titleMedium,
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            fb["adminReply"],
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                        ],
                      ),
                    ),
                  ),

                const SizedBox(height: 20),

                // --- Reply Box ---
                TextField(
                  controller: _replyController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: "Write your reply...",
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.reply),
                  ),
                ),

                const SizedBox(height: 16),

                // --- Send Button ---
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: _isLoading
                        ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                        : const Icon(Icons.send_rounded),
                    label: Text(_isLoading ? "Sending..." : "Send Reply"),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: _isLoading ? null : _sendReply,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
