import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trackmentalhealth/main.dart';
import 'package:trackmentalhealth/pages/login/ForgotPasswordPage.dart';
import 'package:trackmentalhealth/pages/login/RegisterPage.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isObscure = true;
  bool _isLoading = false;
  String? _error;


  Future<void> _testFirebaseConnection() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      print('🔍 Testing Firebase connection...');
      
      // Test Firebase Auth
      final auth = FirebaseAuth.instance;
      print('✅ Firebase Auth initialized');
      
      // Test Firestore
      final firestore = FirebaseFirestore.instance;
      await firestore.collection('test').limit(1).get();
      print('✅ Firestore connection successful');
      
      setState(() => _error = "✅ Firebase connection successful!");
    } catch (e) {
      print('❌ Firebase connection test failed: $e');
      setState(() => _error = "❌ Firebase connection failed: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      print('🔍 Starting Google Sign-in with Firebase...');
      
      final googleUser = await GoogleSignIn(
        scopes: ['email', 'profile'],
        serverClientId: "1035803144115-uvl45dju0rihlspo1js34ls02lkeute8.apps.googleusercontent.com",
      ).signIn();

      if (googleUser == null) {
        setState(() {
          _isLoading = false;
          _error = "You cancelled Google sign in.";
        });
        return;
      }

      print('✅ Google Sign-in successful, getting authentication...');
      final googleAuth = await googleUser.authentication;
      final idToken = googleAuth.idToken;
      final accessToken = googleAuth.accessToken;

      if (idToken == null) {
        setState(() => _error = "Unable to get Google ID Token.");
        return;
      }

      // Tạo Firebase credential
      final credential = GoogleAuthProvider.credential(
        accessToken: accessToken,
        idToken: idToken,
      );

      print('🔐 Signing in to Firebase...');
      final userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
      final user = userCredential.user;

      if (user != null) {
        print('✅ Firebase authentication successful!');
        
        // Lưu thông tin user vào Firestore
        await _saveUserToFirestore(user);
        
        // Lưu thông tin vào SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('uid', user.uid);
        await prefs.setString('email', user.email ?? '');
        await prefs.setString('fullname', user.displayName ?? '');
        await prefs.setString('avatar', user.photoURL ?? '');
        await prefs.setString('role', 'user');

        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const MainScreen()),
        );
      } else {
        setState(() => _error = "Firebase authentication failed.");
      }
    } catch (e) {
      print("Google login error: $e");
      setState(() => _error = "Google login failed: ${e.toString()}");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveUserToFirestore(User user) async {
    try {
      final firestore = FirebaseFirestore.instance;
      final userDoc = await firestore.collection('users').doc(user.uid).get();
      
      if (!userDoc.exists) {
        await firestore.collection('users').doc(user.uid).set({
          'uid': user.uid,
          'email': user.email,
          'fullname': user.displayName ?? '',
          'avatar': user.photoURL ?? '',
          'role': 'user',
          'createdAt': FieldValue.serverTimestamp(),
          'lastLoginAt': FieldValue.serverTimestamp(),
        });
        print('✅ User data saved to Firestore');
      } else {
        // Cập nhật thời gian đăng nhập cuối
        await firestore.collection('users').doc(user.uid).update({
          'lastLoginAt': FieldValue.serverTimestamp(),
        });
        print('✅ User login time updated in Firestore');
      }
    } catch (e) {
      print('⚠️ Error saving user to Firestore: $e');
    }
  }


  Future<void> _handleLogin() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      setState(() => _error = "Please enter all required fields.");
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      print('🔍 Attempting Firebase login with email: $email');
      
      final userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      final user = userCredential.user;
      
      if (user != null) {
        print('✅ Firebase login successful! UID: ${user.uid}');
        
        // Lưu thông tin user vào Firestore
        await _saveUserToFirestore(user);
        
        // Lưu thông tin vào SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('uid', user.uid);
        await prefs.setString('email', user.email ?? '');
        await prefs.setString('fullname', user.displayName ?? '');
        await prefs.setString('avatar', user.photoURL ?? '');
        await prefs.setString('role', 'user');

        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const MainScreen()),
        );
      } else {
        setState(() => _error = "Login failed. Please try again.");
      }
    } on FirebaseAuthException catch (e) {
      print('❌ Firebase Auth error: ${e.code} - ${e.message}');
      String errorMessage = "Login failed. Please try again.";
      
      switch (e.code) {
        case 'user-not-found':
          errorMessage = "No user found with this email address.";
          break;
        case 'wrong-password':
          errorMessage = "Wrong password provided.";
          break;
        case 'invalid-email':
          errorMessage = "Invalid email address.";
          break;
        case 'user-disabled':
          errorMessage = "This user account has been disabled.";
          break;
        case 'too-many-requests':
          errorMessage = "Too many failed login attempts. Please try again later.";
          break;
        default:
          errorMessage = "Login failed: ${e.message}";
      }
      
      setState(() => _error = errorMessage);
    } catch (e) {
      print('❌ Login error: $e');
      setState(() => _error = "An unexpected error occurred. Please try again.");
    } finally {
      setState(() => _isLoading = false);
    }
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
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
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
                  const SizedBox(height: 1),
                  TextField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      prefixIcon: Icon(Icons.person),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
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
                  const SizedBox(height: 16),
                  Column(
                    children: [
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.black,
                          minimumSize: const Size(double.infinity, 50),
                          side: const BorderSide(color: Colors.grey),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed: _signInWithGoogle,
                        icon: Image.asset(
                          'assets/images/google_logo.png',
                          height: 24,
                        ),
                        label: const Text("Sign in with Google"),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                          minimumSize: const Size(double.infinity, 50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed: _testFirebaseConnection,
                        child: const Text("Test Firebase Connection"),
                      ),
                      // const SizedBox(height: 12),
                      // ElevatedButton.icon(
                      //   style: ElevatedButton.styleFrom(
                      //     backgroundColor: Colors.blue[800],
                      //     foregroundColor: Colors.white,
                      //     minimumSize: const Size(double.infinity, 50),
                      //     shape: RoundedRectangleBorder(
                      //       borderRadius: BorderRadius.circular(8),
                      //     ),
                      //   ),
                      //   onPressed: () {
                      //     // TODO: login với Facebook
                      //   },
                      //   icon: const Icon(Icons.facebook),
                      //   label: const Text("Sign in with Facebook"),
                      // ),
                    ],
                  ),
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: Text(
                        _error!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _handleLogin,
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text('Login'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ForgotPasswordPage(),
                        ),
                      );
                    },
                    child: const Text('Forgot password?'),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("Don't have an account?"),
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const RegisterPage(),
                            ),
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
