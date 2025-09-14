import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ContactUsPage extends StatefulWidget {
  const ContactUsPage({super.key});

  @override
  State<ContactUsPage> createState() => _ContactUsPageState();
}

class _ContactUsPageState extends State<ContactUsPage> {
  final LatLng officeLocation = const LatLng(10.807834, 106.663583);

  String? name;
  String? email;
  bool _loadingProfile = true;
  bool _sending = false;


  late TextEditingController nameController;
  late TextEditingController emailController;
  final TextEditingController messageController = TextEditingController();

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController();
    emailController = TextEditingController();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final doc = await FirebaseFirestore.instance
          .collection('account')
          .doc(user.uid)
          .get();

      setState(() {
        name = doc.data()?['name'] ?? user.displayName ?? "";
        email = doc.data()?['email'] ?? user.email ?? "";

        nameController.text = name ?? "";
        emailController.text = email ?? "";
        _loadingProfile = false;
      });
    } catch (e) {
      debugPrint("Load profile error: $e");
      setState(() => _loadingProfile = false);
    }
  }

  Future<void> _openGoogleMaps() async {
    final Uri url = Uri.parse(
        "https://www.google.com/maps/search/?api=1&query=10.807834,106.663583");
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      throw Exception("Could not open Google Maps.");
    }
  }

  Future<void> _sendMessage() async {
    final name = nameController.text.trim();
    final email = emailController.text.trim();
    final message = messageController.text.trim();

    if (name.isEmpty || email.isEmpty || message.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill all fields")),
      );
      return;
    }

    setState(() => _sending = true);

    try {
      await FirebaseFirestore.instance.collection('contacts').add({
        'email': email,
        'message': message,
        'userId': FirebaseAuth.instance.currentUser?.uid ?? 'anonymous',
        'createdAt': FieldValue.serverTimestamp(),
        'status': 'pending',
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Message sent successfully!")),
      );

      // Clear message field after sending
      messageController.clear();
    } catch (e) {
      debugPrint("Send message error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to send message.")),
      );
    } finally {
      setState(() => _sending = false);
    }
  }


  @override
  Widget build(BuildContext context) {
    if (_loadingProfile) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Contact Us"),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// Map Card
            Card(
              clipBehavior: Clip.antiAlias,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 6,
              child: SizedBox(
                height: 250,
                child: FlutterMap(
                  options: MapOptions(
                    initialCenter: officeLocation,
                    initialZoom: 16,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                      "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
                      subdomains: const ['a', 'b', 'c'],
                      userAgentPackageName: 'com.trackmentalhealth.app',
                    ),
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: officeLocation,
                          width: 60,
                          height: 60,
                          child: Icon(
                            Icons.location_on,
                            color: theme.colorScheme.error,
                            size: 40,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),

            /// Google Maps button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _openGoogleMaps,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                icon: const Icon(Icons.map),
                label: const Text(
                  "View Google Maps",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),

            const SizedBox(height: 20),

            /// Contact Info
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Phone: +84 123 456 789",
                        style: TextStyle(fontSize: 16)),
                    SizedBox(height: 8),
                    Text("Email: contact@aptech.com",
                        style: TextStyle(fontSize: 16)),
                    SizedBox(height: 8),
                    Text(
                        "Address: 21Bis Hau Giang, Tan Son Nhat Street, Ho Chi Minh City",
                        style: TextStyle(fontSize: 16)),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            /// Feedback Form
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Text(
                      "Send us a message",
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),

                    // Name auto-fill
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: "Your Name",
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Email auto-fill
                    TextField(
                      controller: emailController,
                      decoration: const InputDecoration(
                        labelText: "Email",
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Message
                    TextField(
                      controller: messageController,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        labelText: "Message",
                        alignLabelWithHint: true,
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _sending ? null : _sendMessage,
                        icon: _sending
                            ? SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                            : const Icon(Icons.send),
                        label: Text(
                          _sending ? "Sending..." : "Send",
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
