import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:trackmentalhealth/pages/login/LoginPage.dart';
import 'package:trackmentalhealth/pages/login/authentication.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _nameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();

  String _role = "students"; // default chọn Students
  bool _isRegistering = false;

  final FirebaseAuth _auth = FirebaseAuth.instance;

  final AuthServices _authServices = AuthServices();

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isRegistering = true);

    try {
      // Tạo user mới trong Firebase Auth
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      final user = userCredential.user;
      if (user != null) {
        // Cập nhật displayName
        await user.updateDisplayName(_nameController.text.trim());

        // Thêm user vào Firestore collection "account"
        await FirebaseFirestore.instance.collection("account").doc(user.uid).set({
          "uid": user.uid,
          "name": _nameController.text.trim(),
          "email": user.email,
          "phone": _phoneController.text.trim(),
          "address": _addressController.text.trim(),
          "role": _role,
          "createdAt": FieldValue.serverTimestamp(),
          "isEmailVerified": user.emailVerified, // ban đầu = false
        });

        // Gửi email xác thực
        await user.sendEmailVerification();

        setState(() => _isRegistering = false);

        // Thông báo thành công
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text("Verify your email"),
            content: Text(
              "A verification link has been sent to ${user.email}. "
                  "If you don’t see it in your inbox, please check your Spam or Promotions folder.",
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (_) => const LoginPage()),
                  );
                },
                child: const Text("OK"),
              ),
            ],
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      setState(() => _isRegistering = false);
      String message = "Registration failed";
      if (e.code == 'email-already-in-use') {
        message = "This email is already registered.";
      } else if (e.code == 'weak-password') {
        message = "Password is too weak.";
      }
      _showDialog("Error", message);
    }
  }

  void _showDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'))
        ],
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _nameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Create Account"),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 20),
                Text(
                  "Register",
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),

                // --- Email
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: "Email",
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) return "Required";
                    final emailRegex =
                    RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                    if (!emailRegex.hasMatch(value)) return "Invalid format";
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // --- Full Name
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

                // --- Phone
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

                // --- Address
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

                // --- Role chọn radio button
                const Text("Select Role:",
                    style:
                    TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
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
                const SizedBox(height: 16),

                // --- Password
                // --- Password
                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: "Password",
                    prefixIcon: Icon(Icons.lock_outline),
                  ),
                  onChanged: (value) {
                    setState(() {}); // để cập nhật strength khi gõ
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return "Password required";
                    }
                    if (value.length < 8) {
                      return "At least 8 characters";
                    }
                    if (!RegExp(r'[A-Z]').hasMatch(value)) {
                      return "Must contain at least 1 uppercase letter";
                    }
                    if (!RegExp(r'[a-z]').hasMatch(value)) {
                      return "Must contain at least 1 lowercase letter";
                    }
                    if (!RegExp(r'[0-9]').hasMatch(value)) {
                      return "Must contain at least 1 number";
                    }
                    if (!RegExp(r'[!@#\$&*~%^.,;?]').hasMatch(value)) {
                      return "Must contain at least 1 special character";
                    }
                    return null;
                  },
                ),

// --- Strength Indicator
                Builder(
                  builder: (context) {
                    String pwd = _passwordController.text;
                    String strength = "Weak";
                    Color color = Colors.red;

                    int score = 0;
                    if (pwd.length >= 8) score++;
                    if (RegExp(r'[A-Z]').hasMatch(pwd)) score++;
                    if (RegExp(r'[a-z]').hasMatch(pwd)) score++;
                    if (RegExp(r'[0-9]').hasMatch(pwd)) score++;
                    if (RegExp(r'[!@#\$&*~%^.,;?]').hasMatch(pwd)) score++;

                    if (score >= 5) {
                      strength = "Strong";
                      color = Colors.green;
                    } else if (score >= 3) {
                      strength = "Medium";
                      color = Colors.orange;
                    }

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 8),
                        LinearProgressIndicator(
                          value: score / 5,
                          color: color,
                          backgroundColor: Colors.grey[300],
                          minHeight: 6,
                          borderRadius: BorderRadius.circular(5),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "Strength: $strength",
                          style: TextStyle(color: color, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 16),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 16),
                // --- Confirm Password
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: "Confirm Password",
                    prefixIcon: Icon(Icons.lock_reset_outlined),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return "Confirm password required";
                    }
                    if (value != _passwordController.text) {
                      return "Passwords do not match";
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                _isRegistering
                    ? const Center(child: CircularProgressIndicator())
                    : ElevatedButton.icon(
                  onPressed: _register,
                  icon: const Icon(Icons.app_registration),
                  label: const Text("Register"),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("Already have an account? "),
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(
                            builder: (_) => const LoginPage(),
                          ),
                        );
                      },
                      child: const Text("Login"),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
