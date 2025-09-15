import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';

import '../SplashScreen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  File? _imageFile;
  String? _avatarUrl;
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _emailController = TextEditingController();

  String _role = "students";
  bool _isLoading = true;
  bool _isRegisteringFace = false;

  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  // ⚡ Cloudinary config
  final String cloudName = "dbghucaix";
  final String uploadPreset = "ml_default";

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _registerFace() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.camera, imageQuality: 80);

    if (picked == null) return;

    setState(() => _isRegisteringFace = true);

    try {
      final file = File(picked.path);
      final email = _emailController.text.trim();

      final formData = FormData.fromMap({
        "image": await MultipartFile.fromFile(file.path),
        "email": email,
      });

      final response = await Dio().post(
        "http://10.0.2.2:8080/generate_embedding", // Docker backend
        data: formData,
        options: Options(
          headers: {"Content-Type": "multipart/form-data"},
        ),
      );

      if (response.statusCode == 200) {
        // Lưu kết quả nếu muốn
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Face registered successfully ✅")),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: ${response.data["error"]}")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to register face: $e")),
      );
    } finally {
      setState(() => _isRegisteringFace = false);
    }
  }

  Future<void> _loadProfile() async {
    setState(() => _isLoading = true);
    try {
      final email = _auth.currentUser?.email ?? await SharedPreferences.getInstance().then((p) => p.getString("last_email"));
      if (email == null) {
        debugPrint("No email found");
        setState(() => _isLoading = false);
        return;
      }

      final query = await _firestore
          .collection("account")
          .where("email", isEqualTo: email)
          .limit(1)
          .get();

      if (query.docs.isNotEmpty) {
        final data = query.docs.first.data();
        setState(() {
          _avatarUrl = data["avatarUrl"];
          _nameController.text = data["name"] ?? "";
          _phoneController.text = data["phone"] ?? "";
          _addressController.text = data["address"] ?? "";
          _emailController.text = data["email"] ?? "";
          _role = data["role"] ?? "students";
        });
      }
    } catch (e) {
      debugPrint("Error loading profile: $e");
    }

    setState(() => _isLoading = false);
  }


  Future<String?> _uploadToCloudinary(File file) async {
    final url = "https://api.cloudinary.com/v1_1/$cloudName/image/upload";
    try {
      FormData formData = FormData.fromMap({
        "file": await MultipartFile.fromFile(file.path),
        "upload_preset": uploadPreset,
      });

      final response = await Dio().post(url, data: formData);

      if (response.statusCode == 200) {
        return response.data["secure_url"];
      } else {
        debugPrint("Cloudinary upload failed: ${response.data}");
        return null;
      }
    } catch (e) {
      debugPrint("Cloudinary upload error: $e");
      return null;
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: source, imageQuality: 75);

    if (picked != null) {
      setState(() {
        _imageFile = File(picked.path);
      });

      final url = await _uploadToCloudinary(_imageFile!);
      if (url != null) {
        final uid = _auth.currentUser?.uid;
        if (uid != null) {
          await _firestore.collection("account").doc(uid).update({"avatarUrl": url});
        }
        setState(() {
          _avatarUrl = url;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Upload failded")),
        );
      }
    }
  }

  void _showImagePickerOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text("Take a photo"),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text("Choice from gallery"),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      final uid = _auth.currentUser?.uid;
      if (uid == null) return;

      await _firestore.collection("account").doc(uid).update({
        "name": _nameController.text.trim(),
        "phone": _phoneController.text.trim(),
        "address": _addressController.text.trim(),
        "role": _role,
      });

      if (mounted) {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Text("Success 🎉",
                style: TextStyle(fontWeight: FontWeight.bold)),
            content: const Text("Your profile has been updated successfully."),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pushReplacement(
                    PageRouteBuilder(
                      pageBuilder: (context, animation, secondaryAnimation) =>
                      const SplashScreen(),
                      transitionsBuilder:
                          (context, animation, secondaryAnimation, child) {
                        const begin = Offset(0.0, 0.2);
                        const end = Offset.zero;
                        const curve = Curves.easeOutCubic;

                        var tween = Tween(begin: begin, end: end)
                            .chain(CurveTween(curve: curve));
                        var fadeTween = Tween<double>(begin: 0, end: 1);

                        return SlideTransition(
                          position: animation.drive(tween),
                          child: FadeTransition(
                            opacity: animation.drive(fadeTween),
                            child: child,
                          ),
                        );
                      },
                      transitionDuration: const Duration(milliseconds: 500),
                    ),
                  );
                },
                child: const Text("OK"),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      debugPrint("Error saving profile: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e")),
        );
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("My Profile"),
        centerTitle: true,
        elevation: 2,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Avatar
            Stack(
              children: [
                CircleAvatar(
                  radius: 48,
                  backgroundColor: Colors.blue.shade100,
                  backgroundImage:
                  _avatarUrl != null ? NetworkImage(_avatarUrl!) : null,
                  child: _avatarUrl == null
                      ? const Icon(Icons.person, size: 50, color: Colors.white)
                      : null,
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: InkWell(
                    onTap: _showImagePickerOptions,
                    child: CircleAvatar(
                      radius: 16,
                      backgroundColor: Colors.blue,
                      child: const Icon(Icons.camera_alt,
                          size: 18, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Email (readonly)
                      TextFormField(
                        controller: _emailController,
                        enabled: false,
                        decoration: const InputDecoration(
                          labelText: "Email",
                          prefixIcon: Icon(Icons.email_outlined),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Name
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: "Full Name",
                          prefixIcon: Icon(Icons.person_outline),
                        ),
                        validator: (value) =>
                        value == null || value.isEmpty ? "Required" : null,
                      ),
                      const SizedBox(height: 16),

                      // Phone
                      TextFormField(
                        controller: _phoneController,
                        decoration: const InputDecoration(
                          labelText: "Phone",
                          prefixIcon: Icon(Icons.phone_outlined),
                        ),
                        validator: (value) =>
                        value == null || value.isEmpty ? "Required" : null,
                      ),
                      const SizedBox(height: 16),

                      // Address
                      TextFormField(
                        controller: _addressController,
                        decoration: const InputDecoration(
                          labelText: "Address",
                          prefixIcon: Icon(Icons.home_outlined),
                        ),
                        validator: (value) =>
                        value == null || value.isEmpty ? "Required" : null,
                      ),
                      const SizedBox(height: 16),

                      // Role radio buttons
                      const Text(
                        "Select Role:",
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      RadioListTile(
                        title: const Text("Students"),
                        value: "students",
                        groupValue: _role,
                        onChanged: (val) =>
                            setState(() => _role = val.toString()),
                      ),
                      RadioListTile(
                        title: const Text("Graduates"),
                        value: "graduates",
                        groupValue: _role,
                        onChanged: (val) =>
                            setState(() => _role = val.toString()),
                      ),
                      RadioListTile(
                        title: const Text("Professionals"),
                        value: "professionals",
                        groupValue: _role,
                        onChanged: (val) =>
                            setState(() => _role = val.toString()),
                      ),
                      const SizedBox(height: 24),
                      TextButton.icon(
                        onPressed: _isRegisteringFace ? null : _registerFace,
                        icon: const Icon(Icons.face),
                        label: Text(_isRegisteringFace ? "Registering..." : "Register Face"),
                      ),

                      ElevatedButton.icon(
                        onPressed: _saveProfile,
                        icon: const Icon(Icons.save),
                        label: const Text("Save"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
