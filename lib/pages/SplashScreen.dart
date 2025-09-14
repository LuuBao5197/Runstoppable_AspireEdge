import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:trackmentalhealth/main.dart';
import 'package:trackmentalhealth/pages/login/LoginPage.dart';
import 'package:trackmentalhealth/widgets/AdminWidget.dart';
import 'package:trackmentalhealth/widgets/CategorySelectWidget.dart';
import 'package:trackmentalhealth/widgets/StudentWidget.dart';

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
    // Đồng bộ dữ liệu (an toàn vì đã có try-catch)
    try {
      print("Starting data sync...");
      await DatabaseHelper.instance.syncQuizDataIfNeeded();
      print("Data sync finished.");
    } catch (e) {
      print("Error during sync: $e");
    }

    // Lấy người dùng hiện tại
    final user = FirebaseAuth.instance.currentUser;

    // SỬA LỖI: Kiểm tra user có null hay không TRƯỚC TIÊN
    if (user != null) {
      // Nếu người dùng tồn tại (đã đăng nhập)
      // Di chuyển toàn bộ logic cần user vào trong khối if này
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
        // Xử lý lỗi có thể xảy ra khi reload hoặc lấy token (ví dụ: mất mạng)
        print("Error fetching user token: $e");
        // Nếu lỗi, coi như chưa đăng nhập và đưa về trang Login
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const LoginPage()),
          );
        }
      }
    } else {
      // Nếu người dùng không tồn tại (chưa đăng nhập)
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