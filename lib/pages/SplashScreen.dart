import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:trackmentalhealth/pages/login/LoginPage.dart';
import 'package:trackmentalhealth/widgets/AdminWidget.dart';
import 'package:trackmentalhealth/widgets/CategorySelectWidget.dart';

import '../helper/DatabaseHelper.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _initializeAppAndNavigate();
  }
  Future<void> _initializeAppAndNavigate() async {
    try {
      print("Starting data sync...");
      await DatabaseHelper.instance.syncQuizDataIfNeeded();
      print("Data sync finished.");
    } catch (e) {
      print("Error during sync: $e");
    }

    final user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      try {
        await user.reload(); // Làm mới thông tin user
        final idTokenResult = await user.getIdTokenResult(true); // Lấy token và custom claims

        print("Custom claims: ${idTokenResult.claims}");

        if (mounted) {
          if (idTokenResult.claims?['admin'] == true) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const AdminScreen()),
            );
          } else {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const CategorySelectionScreen()),
            );
          }
        }
      } catch (e) {
        print("Error fetching user token: $e");
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const LoginPage()),
          );
        }
      }
    } else {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const LoginPage()),
        );
      }
    }
  }
  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FlutterLogo(size: 80),
            SizedBox(height: 20),
            CircularProgressIndicator(),
            SizedBox(height: 10),
            Text("Initializing data ...")
          ],
        ),
      ),
    );
  }
}