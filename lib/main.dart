import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trackmentalhealth/pages/Admin/SendNoticePage.dart';
import 'package:trackmentalhealth/pages/CareerBank/CareerBankPage.dart';
import 'package:trackmentalhealth/pages/CareerBank/career_guidance_page.dart';
import 'package:trackmentalhealth/pages/NotificationScreen.dart';
import 'package:trackmentalhealth/pages/Quizzes/QuizScreen.dart';
import 'package:trackmentalhealth/pages/Resource/resource_main.dart';
import 'package:trackmentalhealth/pages/ProfilePage.dart';
import 'package:trackmentalhealth/pages/SearchPage.dart';
import 'package:trackmentalhealth/pages/CareerBankAdminPage.dart';
import 'package:trackmentalhealth/pages/login/authentication.dart';
import 'package:trackmentalhealth/pages/login/google_auth.dart';
import 'package:trackmentalhealth/pages/utils/permissions.dart';
import 'package:trackmentalhealth/pages/login/LoginPage.dart';
import 'package:trackmentalhealth/pages/profile/ProfileScreen.dart';
import 'package:trackmentalhealth/seed/importSampleCareers.dart';
import 'core/constants/theme_provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart'; // File này được tạo tự động khi bạn chạy `flutterfire configure`
import 'package:cloud_firestore/cloud_firestore.dart';



void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Thêm dòng này để khởi tạo Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  print("🔥 Firebase connected successfully");

  //khoi tao notice
  // Android init

  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: const TrackMentalHealthApp(),
    ),
  );

  // Xin quyền sau khi app đã chạy mới ko bị block UI
  Future.microtask(() async {
    await requestAppPermissions();
  });
}

class TrackMentalHealthApp extends StatelessWidget {
  const TrackMentalHealthApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    return MaterialApp(
      title: 'Track Mental Health',
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
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(), // Lắng nghe sự thay đổi
        builder: (context, snapshot) {
          // Trong khi chờ kết nối, hiển thị màn hình chờ
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(
                child: CircularProgressIndicator(),
              ),
            );
          }
          // Nếu có dữ liệu người dùng (đã đăng nhập)
          if (snapshot.hasData) {
            return const MainScreen(); // Đi thẳng vào màn hình chính
          }
          // Nếu không có dữ liệu (chưa đăng nhập)
          return const LoginPage(); // Hiển thị trang đăng nhập
        },
      ),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  String? name;
  String? avatarUrl;
  bool _loadingProfile = true;

  final List<Widget> _screens = [
    const NotificationScreen(),
    const ResourceMain(),
    const CareerGuidancePage(),
    const CareerBankPage(),
    const QuizScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  /// Trả về email hiện tại, ưu tiên FirebaseAuth, fallback sang SharedPreferences
  Future<String?> _getCurrentEmail() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && user.email != null && user.email!.isNotEmpty) {
      return user.email!;
    }

    final prefs = await SharedPreferences.getInstance();
    final savedEmail = prefs.getString("last_email");
    if (savedEmail != null && savedEmail.isNotEmpty) return savedEmail;

    return null; // Không có email
  }

  /// Load profile an toàn, không crash nếu email null
  Future<void> _loadProfile() async {
    setState(() => _loadingProfile = true);

    try {
      final email = await _getCurrentEmail();
      if (email == null) {
        print("⚠️ No email found. Cannot load profile.");
        setState(() {
          name = "User";
          avatarUrl = null;
          _loadingProfile = false;
        });
        return;
      }

      final query = await FirebaseFirestore.instance
          .collection('account')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      if (query.docs.isNotEmpty) {
        final data = query.docs.first.data();
        setState(() {
          name = data['name'] ?? "User";
          avatarUrl = data['avatarUrl'];
          _loadingProfile = false;
        });
      } else {
        setState(() {
          name = "User";
          avatarUrl = null;
          _loadingProfile = false;
        });
      }
    } catch (e) {
      print("Load profile error: $e");
      setState(() {
        name = "User";
        avatarUrl = null;
        _loadingProfile = false;
      });
    }
  }
  void _onTabTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Widget _buildNavigation(BuildContext context, bool isDarkMode) {
    final isWideScreen = MediaQuery.of(context).size.width >= 600;
    final backgroundColor = isDarkMode ? Colors.grey.shade900 : Colors.white;
    final selectedColor = Colors.tealAccent;
    final unselectedColor = isDarkMode ? Colors.white70 : Colors.grey;

    if (isWideScreen) {
      return AnimatedContainer(
        duration: const Duration(milliseconds: 400),
        width: 80,
        color: backgroundColor,
        child: NavigationRail(
          backgroundColor: Colors.transparent,
          selectedIndex: _selectedIndex,
          onDestinationSelected: _onTabTapped,
          labelType: NavigationRailLabelType.none,
          selectedIconTheme: IconThemeData(color: selectedColor),
          unselectedIconTheme: IconThemeData(color: unselectedColor),
          destinations: const [
            NavigationRailDestination(icon: Icon(Icons.notifications_active), label: Text("Notice")),
            NavigationRailDestination(icon: Icon(Icons.quiz), label: Text("Test")),
            NavigationRailDestination(icon: Icon(Icons.mood), label: Text("Diary")),
            NavigationRailDestination(icon: Icon(Icons.mood), label: Text("CareerBank")),
          ],
        ),
      );
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      color: backgroundColor,
      child: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onTabTapped,
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.transparent,
        selectedItemColor: selectedColor,
        unselectedItemColor: unselectedColor,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.notifications_active), label: 'Notice'),
          BottomNavigationBarItem(icon: Icon(Icons.quiz_rounded), label: 'Test'),
          BottomNavigationBarItem(icon: Icon(Icons.mood), label: 'Diary'),
          BottomNavigationBarItem(icon: Icon(Icons.book), label: 'Resource'),
          BottomNavigationBarItem(icon: Icon(Icons.book), label: 'CareerBank'),
          BottomNavigationBarItem(icon: Icon(Icons.quiz_rounded), label: 'Career Quizzes'),
          BottomNavigationBarItem(icon: Icon(Icons.book), label: 'Career Guidance'),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    final isWideScreen = MediaQuery.of(context).size.width >= 600;

    return Scaffold(
      backgroundColor: isDarkMode ? Colors.black : Colors.white,
      appBar: AppBar(
        title: const Text("Track Mental Health"),
        centerTitle: true,
        actions: [
          Switch(
            value: isDarkMode,
            onChanged: themeProvider.toggleTheme,
            activeColor: Colors.tealAccent,
          ),
        ],
      ),
      drawer: Drawer(
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 400),
          color: isDarkMode ? Colors.grey.shade900 : Colors.white,
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              DrawerHeader(
                decoration: const BoxDecoration(color: Colors.teal),
                child: FutureBuilder<String?>(
                  future: _getCurrentEmail(),
                  builder: (context, snapshotEmail) {
                    if (!snapshotEmail.hasData) return const Center(child: CircularProgressIndicator(color: Colors.white));

                    final email = snapshotEmail.data!;
                    return StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('account')
                          .where('email', isEqualTo: email)
                          .limit(1)
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                          return const Center(
                              child: Text("No profile data", style: TextStyle(color: Colors.white))
                          );
                        }

                        final data = snapshot.data!.docs.first.data() as Map<String, dynamic>;
                        final avatar = data['avatarUrl'] as String?;
                        final name = data['name'] ?? "User";

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CircleAvatar(
                              radius: 30,
                              backgroundImage: (avatar != null && avatar.isNotEmpty) ? NetworkImage(avatar) : null,
                              child: (avatar == null || avatar.isEmpty) ? const Icon(Icons.person, size: 40, color: Colors.white) : null,
                            ),
                            const SizedBox(height: 8),
                            Text("Hello, $name", style: const TextStyle(color: Colors.white, fontSize: 18)),
                          ],
                        );
                      },
                    );
                  },
                ),
              ),

              ListTile(
                leading: Icon(Icons.person, color: isDarkMode ? Colors.tealAccent : Colors.teal[800]),
                title: const Text('Profile'),
                onTap: () async {
                  Navigator.pop(context);
                  final result = await Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen()));
                  if (result == true) _loadProfile();
                },
              ),
              ListTile(
                leading: Icon(Icons.logout, color: isDarkMode ? Colors.tealAccent : Colors.teal[800]),
                title: const Text('Logout'),
                onTap: () async {
                  final prefs = await SharedPreferences.getInstance();
                  final lastEmail = prefs.getString("last_email");
                  await prefs.clear();
                  if (lastEmail != null) await prefs.setString("last_email", lastEmail);

                  await FirebaseAuth.instance.signOut();
                  final googleSignIn = GoogleSignIn();
                  if (await googleSignIn.isSignedIn()) await googleSignIn.signOut();

                  Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginPage()));
                },
              ),
            ],
          ),
        ),
      ),
      body: Row(
        children: [
          if (isWideScreen) _buildNavigation(context, isDarkMode),
          Expanded(child: _screens[_selectedIndex]),
        ],
      ),
      bottomNavigationBar: isWideScreen ? null : _buildNavigation(context, isDarkMode),
    );
  }
}

