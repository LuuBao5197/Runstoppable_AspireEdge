import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:intl/intl.dart';
import '../DTO/FeedbackDTO.dart';

class FeedbackPage extends StatefulWidget {
  const FeedbackPage({super.key});

  @override
  State<FeedbackPage> createState() => _FeedbackPageState();
}

class _FeedbackPageState extends State<FeedbackPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();

  double _rating = 3;

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  void _loadUserInfo() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _emailController.text = user.email ?? "";
      _nameController.text = user.displayName ?? "";
      _phoneController.text = user.phoneNumber ?? "";
    }
  }

  void _submitFeedback() async {
    if (_formKey.currentState!.validate()) {
      final user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("⚠️ You must login to send feedback")),
        );
        return;
      }

      final feedback = FeedbackDTO(
        userId: user.uid,
        fullName: _nameController.text,
        email: _emailController.text,
        phone: _phoneController.text,
        message: _messageController.text,
        createdAt: DateTime.now(),
        rating: _rating.toInt(),
        status: "pending",
      );

      try {
        await FirebaseFirestore.instance
            .collection("feedbacks")
            .add(feedback.toJson());

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("✅ Thank you for your feedback!")),
        );

        _messageController.clear();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("❌ Failed to send feedback: $e")),
        );
      }
    }
  }

  String _formatDate(dynamic ts) {
    if (ts == null) return "";
    DateTime dateTime;

    if (ts is Timestamp) {
      dateTime = ts.toDate();
    } else if (ts is Map && ts['_seconds'] != null) {
      dateTime = DateTime.fromMillisecondsSinceEpoch(ts['_seconds'] * 1000);
    } else if (ts is String) {
      dateTime = DateTime.tryParse(ts) ?? DateTime.now();
    } else {
      dateTime = DateTime.now();
    }

    return DateFormat("dd/MM/yyyy HH:mm").format(dateTime);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Feedback",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: isDark ? Colors.grey[900] : Colors.teal,
        elevation: 2,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // --- Form Feedback ---
              Card(
                color: Theme.of(context).cardColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                elevation: 6,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        Text(
                          "We always listen to improve our service.\nPlease share your feedback with us",
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                fontSize: 16,
                                color: isDark
                                    ? Colors.grey[300]
                                    : Colors.black54,
                              ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        // Full name
                        TextFormField(
                          controller: _nameController,
                          readOnly: true,
                          decoration: InputDecoration(
                            labelText: "Full name",
                            prefixIcon: const Icon(Icons.person),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Email
                        TextFormField(
                          controller: _emailController,
                          readOnly: true,
                          decoration: InputDecoration(
                            labelText: "Email",
                            prefixIcon: const Icon(Icons.email),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Phone number
                        TextFormField(
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          decoration: InputDecoration(
                            labelText: "Phone number",
                            prefixIcon: const Icon(Icons.phone),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          validator: (value) =>
                              value == null || value.length < 9
                              ? "Invalid phone number"
                              : null,
                        ),
                        const SizedBox(height: 16),
                        // Feedback message
                        TextFormField(
                          controller: _messageController,
                          maxLines: 4,
                          decoration: InputDecoration(
                            labelText: "Your feedback",
                            alignLabelWithHint: true,
                            prefixIcon: const Icon(Icons.feedback),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          validator: (value) => value == null || value.isEmpty
                              ? "Please enter your feedback"
                              : null,
                        ),
                        const SizedBox(height: 24),
                        // Rating bar
                        Column(
                          children: [
                            Text(
                              "Rate our service:",
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: Colors.teal,
                                  ),
                            ),
                            const SizedBox(height: 8),
                            RatingBar.builder(
                              initialRating: _rating,
                              minRating: 1,
                              direction: Axis.horizontal,
                              allowHalfRating: false,
                              itemCount: 5,
                              itemSize: 40,
                              itemPadding: const EdgeInsets.symmetric(
                                horizontal: 4.0,
                              ),
                              itemBuilder: (context, _) =>
                                  const Icon(Icons.star, color: Colors.amber),
                              onRatingUpdate: (rating) {
                                setState(() {
                                  _rating = rating;
                                });
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 28),
                        // Submit button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            icon: Icon(
                              Icons.send_rounded,
                              color: Theme.of(context).colorScheme.onPrimary,
                            ),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              backgroundColor: Theme.of(
                                context,
                              ).colorScheme.primary,
                            ),
                            onPressed: _submitFeedback,
                            label: Text(
                              "Send Feedback",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.onPrimary,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 30),
              // --- List Feedback ---
              if (user != null)
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection("feedbacks")
                      .where("userId", isEqualTo: user.uid)
                      .orderBy("createdAt", descending: true)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final feedbacks = snapshot.data!.docs;

                    if (feedbacks.isEmpty) {
                      return const Text("You haven't sent any feedback yet.");
                    }

                    return ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: feedbacks.length,
                      itemBuilder: (context, index) {
                        final fb =
                            feedbacks[index].data() as Map<String, dynamic>;
                        final fbId = feedbacks[index].id;

                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 3,
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Feedback gốc
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const CircleAvatar(
                                      radius: 18,
                                      backgroundColor: Colors.teal,
                                      child: Icon(
                                        Icons.person,
                                        color: Colors.white,
                                        size: 20,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            fb["fullName"] ?? "Anonymous",
                                            style: Theme.of(context)
                                                .textTheme
                                                .titleMedium
                                                ?.copyWith(
                                                  fontWeight: FontWeight.bold,
                                                ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            fb["message"] ?? "",
                                            style: Theme.of(
                                              context,
                                            ).textTheme.bodyLarge,
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            "⭐ ${fb["rating"]}/5   ·   ${_formatDate(fb["createdAt"])}",
                                            style: const TextStyle(
                                              color: Colors.grey,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                // --- reply từ admin ---
                                StreamBuilder<QuerySnapshot>(
                                  stream: FirebaseFirestore.instance
                                      .collection("feedbackReply")
                                      .where("feedbackId", isEqualTo: fbId)
                                      .orderBy("createdAt", descending: false)
                                      .snapshots(),
                                  builder: (context, snapReply) {
                                    if (snapReply.connectionState == ConnectionState.waiting) {
                                      return const Padding(
                                        padding: EdgeInsets.symmetric(vertical: 8.0),
                                        child: CircularProgressIndicator(),
                                      );
                                    }

                                    if (!snapReply.hasData || snapReply.data!.docs.isEmpty) {
                                      return const SizedBox();
                                    }

                                    final replies = snapReply.data!.docs;
                                    final isDark = Theme.of(context).brightness == Brightness.dark;

                                    return Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: replies.map((r) {
                                        final reply = r.data() as Map<String, dynamic>;
                                        final dynamic createdAtField = reply["createdAt"];

                                        return Container(
                                          margin: const EdgeInsets.only(top: 6, left: 40),
                                          child: Card(
                                            color: isDark ? Colors.grey[800] : Colors.grey[100],
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            elevation: 1,
                                            child: Padding(
                                              padding: const EdgeInsets.all(12),
                                              child: Row(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  CircleAvatar(
                                                    radius: 16,
                                                    backgroundColor: Colors.teal,
                                                    child: const Icon(
                                                      Icons.admin_panel_settings,
                                                      color: Colors.white,
                                                      size: 18,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 10),
                                                  Expanded(
                                                    child: Column(
                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                      children: [
                                                        Text(
                                                          "Aspire Edge",
                                                          style: Theme.of(context)
                                                              .textTheme
                                                              .bodyMedium
                                                              ?.copyWith(
                                                            fontWeight: FontWeight.bold,
                                                            color: isDark ? Colors.teal[200] : Colors.teal,
                                                          ),
                                                        ),
                                                        const SizedBox(height: 4),
                                                        Text(
                                                          reply["reply"] ?? "",
                                                          style: TextStyle(
                                                            color: isDark ? Colors.grey[300] : Colors.black87,
                                                          ),
                                                        ),
                                                        const SizedBox(height: 4),
                                                        Text(
                                                          _formatDate(createdAtField),
                                                          style: TextStyle(
                                                            fontSize: 12,
                                                            color: isDark ? Colors.grey[400] : Colors.grey,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        );
                                      }).toList(),
                                    );
                                  },
                                )
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}
