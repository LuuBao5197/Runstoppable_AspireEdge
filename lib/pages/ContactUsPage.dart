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
      print("Load profile error: $e");
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

  @override
  Widget build(BuildContext context) {
    if (_loadingProfile) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text("Contact Us"),
        centerTitle: true,
        backgroundColor: Colors.teal,
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
                    interactionOptions: const InteractionOptions(
                      flags: InteractiveFlag.all,
                    ),
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
                          child: const Icon(
                            Icons.location_on,
                            color: Colors.red,
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

            /// Nút đi tới Google Maps
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _openGoogleMaps,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  backgroundColor: Colors.teal,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.map, color: Colors.white),
                label: const Text(
                  "View Google Maps",
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white),
                ),
              ),
            ),

            const SizedBox(height: 20),

            /// Contact Info
            Card(
              elevation: 4,
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
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    const Text(
                      "Send us a message",
                      style:
                      TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),

                    // Name auto-fill
                    TextField(
                      controller: nameController,
                      decoration: InputDecoration(
                        labelText: "Your Name",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Email auto-fill
                    TextField(
                      controller: emailController,
                      decoration: InputDecoration(
                        labelText: "Email",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Message
                    TextField(
                      controller: messageController,
                      maxLines: 4,
                      decoration: InputDecoration(
                        labelText: "Message",
                        alignLabelWithHint: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          backgroundColor: Colors.teal,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () {
                          // TODO: Save to Firestore
                          print("📨 Name: ${nameController.text}");
                          print("📨 Email: ${emailController.text}");
                          print("📨 Msg: ${messageController.text}");
                        },
                        icon: const Icon(Icons.send, color: Colors.white),
                        label: const Text(
                          "Send",
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white),
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
