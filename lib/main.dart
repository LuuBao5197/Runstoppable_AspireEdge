import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trackmentalhealth/pages/NotificationPage.dart';
import 'package:trackmentalhealth/pages/ProfilePage.dart';
import 'package:trackmentalhealth/pages/SearchPage.dart';
import 'package:trackmentalhealth/pages/utils/permissions.dart';
import 'package:trackmentalhealth/core/constants/api_constants.dart';
import 'package:trackmentalhealth/pages/login/LoginPage.dart';
import 'package:trackmentalhealth/pages/profile/ProfileScreen.dart';
import 'package:trackmentalhealth/utils/NotificationListenerWidget.dart';
import 'core/constants/theme_provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart'; // Tạo bằng `flutterfire configure`
import 'package:cloud_firestore/cloud_firestore.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  print("🔥 Firebase connected successfully");

  /// 👉 Chỉ gọi khi muốn seed data
  await seedSampleData();

  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: const TrackMentalHealthApp(),
    ),
  );

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
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          if (snapshot.hasData) {
            return const MainScreen();
          }
          return const LoginPage();
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
  String? fullname;
  String? avatarUrl;
  bool _loadingProfile = true;

  final List<Widget> _screens = [
    const NotificationsPage(),
    const SearchPage(),
    const ProfilePage(),
  ];

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() => _loadingProfile = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      final userId = prefs.getInt('userId');

      if (userId == null || token == null) {
        setState(() => _loadingProfile = false);
        return;
      }

      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/users/profile/$userId'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        String? avatar = data['avatar'];
        if (avatar != null && !avatar.startsWith('http')) {
          avatar = '${ApiConstants.baseUrl}/uploads/$avatar';
        }

        setState(() {
          fullname = data['fullname'] ?? "User";
          avatarUrl = avatar;
          _loadingProfile = false;
        });

        if (avatarUrl != null) await prefs.setString('avatarUrl', avatarUrl!);
      } else {
        setState(() => _loadingProfile = false);
      }
    } catch (_) {
      setState(() => _loadingProfile = false);
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
      return NavigationRail(
        backgroundColor: backgroundColor,
        selectedIndex: _selectedIndex,
        onDestinationSelected: _onTabTapped,
        labelType: NavigationRailLabelType.none,
        selectedIconTheme: IconThemeData(color: selectedColor),
        unselectedIconTheme: IconThemeData(color: unselectedColor),
        destinations: const [
          NavigationRailDestination(
            icon: Icon(Icons.emoji_emotions),
            label: Text("Mood"),
          ),
          NavigationRailDestination(
            icon: Icon(Icons.quiz),
            label: Text("Test"),
          ),
          NavigationRailDestination(
            icon: Icon(Icons.mood),
            label: Text("Diary"),
          ),
        ],
      );
    }

    return BottomNavigationBar(
      currentIndex: _selectedIndex,
      onTap: _onTabTapped,
      type: BottomNavigationBarType.fixed,
      backgroundColor: backgroundColor,
      selectedItemColor: selectedColor,
      unselectedItemColor: unselectedColor,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.emoji_emotions), label: 'Mood'),
        BottomNavigationBarItem(icon: Icon(Icons.quiz_rounded), label: 'Test'),
        BottomNavigationBarItem(icon: Icon(Icons.mood), label: 'Diary'),
      ],
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
        title: const Text('Track Mental Health'),
        backgroundColor: isDarkMode ? Colors.grey.shade900 : Colors.white,
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(color: Colors.teal),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundImage:
                    (avatarUrl != null && avatarUrl!.isNotEmpty)
                        ? NetworkImage(avatarUrl!)
                        : null,
                    child: (avatarUrl == null || avatarUrl!.isEmpty)
                        ? const Icon(Icons.person, size: 40, color: Colors.white)
                        : null,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _loadingProfile
                        ? 'Loading...'
                        : 'Hello, ${fullname ?? "User"}',
                    style: const TextStyle(color: Colors.white, fontSize: 18),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text('Profile'),
              onTap: () {
                Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const ProfileScreen()));
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Logout'),
              onTap: () async {
                final prefs = await SharedPreferences.getInstance();
                await prefs.clear();
                final googleSignIn = GoogleSignIn();
                if (await googleSignIn.isSignedIn()) await googleSignIn.signOut();
                if (!mounted) return;
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginPage()),
                );
              },
            ),
          ],
        ),
      ),
      body: Row(
        children: [
          if (isWideScreen) _buildNavigation(context, isDarkMode),
          Expanded(
            child: Stack(
              children: [
                _screens[_selectedIndex],
                FutureBuilder<int?>(
                  future: SharedPreferences.getInstance()
                      .then((prefs) => prefs.getInt('userId')),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) return const SizedBox.shrink();
                    final userId = snapshot.data;
                    if (userId == null) return const SizedBox.shrink();
                    return NotificationListenerWidget(userId: userId);
                  },
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar:
      isWideScreen ? null : _buildNavigation(context, isDarkMode),
    );
  }
}

/// Hàm seed data Firestore
Future<void> seedSampleData() async {
  final db = FirebaseFirestore.instance;
  print("⏳ Đang thêm seed data...");

  await db.collection("users").doc("user1").set({
    "name": "Nguyen Van A",
    "email": "a@example.com",
    "tier": "student",
    "created_at": FieldValue.serverTimestamp(),
  });

  await db.collection("careers").doc("career1").set({
    "title": "Software Engineer",
    "industry": "IT",
    "description": "Phát triển và duy trì phần mềm",
    "salary_range": "1000-3000 USD",
    "education_path": "Cử nhân CNTT",
    "skills": ["Java", "Flutter", "SQL"],
  });

  await db.collection("resources").doc("res1").set({
    "title": "Hướng dẫn viết CV",
    "type": "blog",
    "description": "Cách viết CV thu hút nhà tuyển dụng",
    "url": "https://example.com/cv",
    "created_at": FieldValue.serverTimestamp(),
  });

  await db.collection("quizzes").doc("quiz1").set({
    "question_text": "Bạn thích làm việc nhóm hay làm việc độc lập?",
    "options": {"A": "Làm việc nhóm", "B": "Làm việc độc lập"},
    "score_map": {"A": 10, "B": 20}
  });

  await db.collection("notifications").doc("n1").set({
    "title": "Có blog mới!",
    "message": "Xem ngay bài viết về viết CV.",
    "created_at": FieldValue.serverTimestamp(),
  });

  print("✅ Seed data đã thêm thành công!");
}
