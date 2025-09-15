
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:trackmentalhealth/pages/SplashScreen.dart';
import 'package:trackmentalhealth/pages/utils/permissions.dart';
import 'core/constants/theme_provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart'; // File này được tạo tự động khi bạn chạy `flutterfire configure`
import 'package:cloud_firestore/cloud_firestore.dart';
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Init firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  // Config firebase offline persistence
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
  );
  print("🔥 Firebase connected successfully");

  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: const AspireEdgeApp(),
    ),
  );

  // Suggest Permission
  Future.microtask(() async {
    await requestAppPermissions();
  });
}

class AspireEdgeApp extends StatelessWidget {
  const AspireEdgeApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    return MaterialApp(
      title: 'Aspire Edge',
      debugShowCheckedModeBanner: false,
      themeMode: themeProvider.themeMode,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.teal,
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Colors.teal,
          elevation: 2,
        ),
      ),
      darkTheme: ThemeData.dark().copyWith(
        colorScheme: const ColorScheme.dark(
          primary: Colors.teal,
          secondary: Colors.tealAccent,
        ),
        scaffoldBackgroundColor: const Color(0xFF121212),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1E1E1E),
          foregroundColor: Colors.tealAccent,
        ),
      ),
      home: SplashScreen(),
    );
  }
}
