import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'package:trackmentalhealth/main.dart';
import 'package:trackmentalhealth/pages/login/ForgotPasswordPage.dart';
import 'package:trackmentalhealth/pages/login/RegisterPage.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool _isObscure = true;
  bool _isLoading = false;
  String? _error;

  String? _savedEmail; // 👈 email đã lưu từ lần login trước
  bool _useSavedEmail = false;

  @override
  void initState() {
    super.initState();
    _loadSavedEmail();
  }

  Future<void> _loadSavedEmail() async {
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString("last_email");
    if (email != null && email.isNotEmpty) {
      setState(() {
        _savedEmail = email;
        _emailController.text = email;
        _useSavedEmail = true;
      });
    }
  }

  // --- Face Verification
  Future<Map<String, dynamic>?> verifyFace(File image, String email) async {
    try {
      final uri = Uri.parse("http://10.0.2.2:8080/verify_face");
      var request = http.MultipartRequest('POST', uri);

      request.files.add(await http.MultipartFile.fromPath(
        'image',
        image.path,
        filename: p.basename(image.path),
      ));
      request.fields['email'] = email;

      final response = await request.send();
      final resBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        return jsonDecode(resBody);
      } else {
        print("❌ Failed: $resBody");
        return null;
      }
    } catch (e) {
      print("⚠️ Error: $e");
      return null;
    }
  }

  // --- Face Login
  Future<void> _handleFaceLogin() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.camera);
    if (picked == null) return;

    setState(() => _isLoading = true);

    final image = File(picked.path);
    final result = await verifyFace(image, _emailController.text.trim());

    if (result != null && result["success"] == true && result["customToken"] != null) {
      try {
        // 🔹 Sign in với FirebaseAuth bằng Custom Token
        await FirebaseAuth.instance.signInWithCustomToken(result["customToken"]);

        // 🔹 Lưu thông tin vào SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString("last_email", result["email"]);
        await prefs.setString("name", result["user_info"]["name"] ?? "");
        await prefs.setString("uid", result["user_info"]["uid"] ?? "");

        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const MainScreen()),
        );
      } catch (e) {
        print("❌ FirebaseAuth Custom Token login failed: $e");
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Firebase login failed")),
        );
      }
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("❌ Face verification failed")),
      );
    }

    setState(() => _isLoading = false);
  }


  // --- Email/Password Login
  Future<void> _handleEmailLogin() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      UserCredential credential = await _auth.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      final user = credential.user;

      if (user != null) {
        if (!user.emailVerified) {
          await _auth.signOut();
          setState(() => _error = "Please verify your email before logging in.");
          return;
        }

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('uid', user.uid);
        await prefs.setString('email', user.email ?? '');
        await prefs.setString('name', user.displayName ?? '');
        await prefs.setString('photoUrl', user.photoURL ?? '');
        await prefs.setString('last_email', user.email ?? ""); // 👈 lưu email

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const MainScreen()),
        );
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found' || e.code == 'wrong-password') {
        setState(() => _error = "Invalid email or password.");
      } else if (e.code == 'invalid-email') {
        setState(() => _error = "Invalid email format.");
      } else {
        setState(() => _error = "Login failed. Please try again.");
      }
    } catch (_) {
      setState(() => _error = "Login failed. Please try again.");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // --- Google Login
  Future<void> _handleGoogleLogin() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) {
        setState(() => _error = "Google sign-in cancelled.");
        return;
      }
      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      final userCredential = await _auth.signInWithCredential(credential);
      final user = userCredential.user;

      if (user != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('uid', user.uid);
        await prefs.setString('email', user.email ?? '');
        await prefs.setString('name', user.displayName ?? '');
        await prefs.setString('photoUrl', user.photoURL ?? '');
        await prefs.setString('last_email', user.email ?? ""); // 👈 lưu email

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const MainScreen()),
        );
      }
    } on FirebaseAuthException catch (_) {
      setState(() => _error = "Google login failed. Please try again.");
    } catch (_) {
      setState(() => _error = "Google login failed. Please try again.");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // --- Another account (xóa email lưu)
  Future<void> _switchAccount() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove("last_email");
    setState(() {
      _savedEmail = null;
      _useSavedEmail = false;
      _emailController.clear();
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue[50],
      appBar: AppBar(
        title: const Text('Login'),
        centerTitle: true,
        backgroundColor: Colors.red[50],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Card(
            elevation: 8,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    height: 180,
                    child: Center(
                      child: Image.network(
                        'https://res.cloudinary.com/dsj4lnlkh/image/upload/v1754325524/LogoTMH_cr3rs0.png',
                        width: 500,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // --- Email field (ẩn nếu đã có savedEmail)
                  if (!_useSavedEmail)
                    TextField(
                      controller: _emailController,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        prefixIcon: Icon(Icons.person),
                        border: OutlineInputBorder(),
                      ),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.email, color: Colors.blue),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _savedEmail ?? "",
                              style: const TextStyle(fontWeight: FontWeight.bold),
                              overflow: TextOverflow.ellipsis, // tránh email dài bị tràn
                            ),
                          ),
                          TextButton(
                            onPressed: _switchAccount,
                            child: const Text("Another account"),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 8),
                  // --- Password field
                  TextField(
                    controller: _passwordController,
                    obscureText: _isObscure,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      prefixIcon: const Icon(Icons.lock),
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _isObscure ? Icons.visibility : Icons.visibility_off,
                        ),
                        onPressed: () {
                          setState(() => _isObscure = !_isObscure);
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // --- Error Message
                  if (_error != null)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Padding(
                        padding: const EdgeInsets.only(top: 4, bottom: 8),
                        child: Text(
                          _error!,
                          style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),

                  // --- Login Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _handleEmailLogin,
                      child: _isLoading
                          ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                          : const Text('Login'),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // --- Google Login
                  if (!_useSavedEmail)
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black,
                        minimumSize: const Size(double.infinity, 50),
                        side: const BorderSide(color: Colors.grey),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: _isLoading ? null : _handleGoogleLogin,
                      icon: Image.asset('assets/images/google_logo.png', height: 24),
                      label: const Text("Sign in with Google"),
                    ),

                  const SizedBox(height: 16),

                  // --- Face Login Button
                  ElevatedButton.icon(
                    onPressed: _isLoading ? null : _handleFaceLogin,
                    icon: const Icon(Icons.face),
                    label: const Text("Login with Face"),
                  ),
                  const SizedBox(height: 12),

                  // --- Forgot Password
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const ForgotPasswordPage()),
                      );
                    },
                    child: const Text('Forgot password?'),
                  ),

                  // --- Register Link (ẩn nếu dùng savedEmail)
                  if (!_useSavedEmail)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text("Don't have an account?"),
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const RegisterPage()),
                            );
                          },
                          child: const Text('Register'),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
