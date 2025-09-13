import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:trackmentalhealth/main.dart';
import 'package:trackmentalhealth/pages/login/LoginPage.dart';

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
      // 1. Luôn chạy đồng bộ dữ liệu nền trước
      print("Starting data sync...");
      await DatabaseHelper.instance.syncQuizDataIfNeeded();
      print("Data sync finished.");
    } catch (e) {
      print("Error during sync: $e");
    }

    // 2. Sau khi đồng bộ, kiểm tra trạng thái đăng nhập
    final user = FirebaseAuth.instance.currentUser;

    // 3. Điều hướng dựa trên kết quả
    if (mounted) {
      if (user != null) {
        // Nếu đã đăng nhập, đi đến màn hình chính
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const MainScreen()), // Hoặc MainScreen của bạn
        );
      } else {
        // Nếu chưa đăng nhập, đi đến màn hình đăng nhập
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
            Text("Đang khởi tạo...")
          ],
        ),
      ),
    );
  }
}