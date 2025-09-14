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
    // Handle data sync
    try {
      print("Starting data sync...");
      await DatabaseHelper.instance.syncQuizDataIfNeeded();
      print("Data sync finished.");
    } catch (e) {
      print("Error during sync: $e");
    }
    // 2. Sau khi đồng bộ, kiểm tra trạng thái đăng nhập
    await FirebaseAuth.instance.currentUser?.reload();
    final user = FirebaseAuth.instance.currentUser;
    final idTokenResult = await user!.getIdTokenResult(true);

    // 3. Điều hướng dựa trên kết quả
    if (mounted) {
      if (user != null) {

        print("Custom claims: ${idTokenResult.claims}");
        if(idTokenResult.claims?['admin'] == true){
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const AdminScreen()), // Hoặc MainScreen của bạn
          );
        } else {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const CategorySelectionScreen()), // Hoặc MainScreen của bạn
          );
        }

      } else {
        // handle when not login
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