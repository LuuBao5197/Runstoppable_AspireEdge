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
import 'package:trackmentalhealth/pages/login/authentication.dart';
import 'package:trackmentalhealth/pages/login/google_auth.dart';
import 'package:trackmentalhealth/pages/utils/permissions.dart';
import 'package:trackmentalhealth/core/constants/api_constants.dart';
import 'package:trackmentalhealth/pages/login/LoginPage.dart';
import 'package:trackmentalhealth/pages/profile/ProfileScreen.dart';
import 'package:trackmentalhealth/utils/NotificationListenerWidget.dart';
import 'core/constants/theme_provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart'; // File này được tạo tự động khi bạn chạy `flutterfire configure`

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Thêm dòng này để khởi tạo Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Khởi tạo Firestore
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
  );

  print("🔥 Firebase connected successfully");
  print("🔥 Firestore initialized successfully");

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
  String? fullname;
  String? avatarUrl;
  bool _loadingProfile = true;


  bool hasNewNotification = false;

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
      return AnimatedContainer(
        duration: const Duration(milliseconds: 400),
        width: 80,
        color: backgroundColor,
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: MediaQuery.of(context).size.height,
            ),
            child: IntrinsicHeight(
              child: NavigationRail(
                backgroundColor: Colors.transparent,
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
              ),
            ),
          ),
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
        selectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 13,
        ),
        unselectedLabelStyle: const TextStyle(fontSize: 12),
        elevation: 10,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.emoji_emotions),
            label: 'Mood',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.quiz_rounded),
            label: 'Test',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.mood), label: 'Diary'),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;

    final isWideScreen = MediaQuery.of(context).size.width >= 600;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      color: isDarkMode ? Colors.black : Colors.white,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(kToolbarHeight),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 400),
            color: isDarkMode ? Colors.grey.shade900 : Colors.white,
            child: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 3,
              shadowColor: Colors.teal.withOpacity(0.3),
              title: AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 400),
                style: TextStyle(
                  color: isDarkMode ? Colors.tealAccent : Colors.teal[800],
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
                child: const Text('Track Mental Health'),
              ),
              centerTitle: true,
              iconTheme: IconThemeData(
                color: isDarkMode ? Colors.tealAccent : Colors.teal[800],
              ),
              actions: [
                Switch(
                  value: isDarkMode,
                  onChanged: (value) => themeProvider.toggleTheme(value),
                  activeColor: Colors.tealAccent,
                  inactiveThumbColor: Colors.teal[700],
                ),
              ],
            ),
          ),
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
                            ? const Icon(
                          Icons.person,
                          size: 40,
                          color: Colors.white,
                        )
                            : null,
                      ),
                      const SizedBox(height: 8),
                      AnimatedDefaultTextStyle(
                        duration: const Duration(milliseconds: 400),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                        ),
                        child: Text(
                          _loadingProfile
                              ? 'Loading...'
                              : 'Hello, ${fullname ?? "User"}',
                        ),
                      ),
                    ],
                  ),
                ),
                ListTile(
                  leading: Icon(
                    Icons.person,
                    color: isDarkMode ? Colors.tealAccent : Colors.teal[800],
                  ),
                  title: const Text('Profile'),
                  onTap: () async {
                    Navigator.pop(context);
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ProfileScreen()),
                    );
                    if (result == true) _loadProfile();
                  },
                ),
                ListTile(
                  leading: Icon(
                    Icons.settings,
                    color: isDarkMode ? Colors.tealAccent : Colors.teal[800],
                  ),
                  title: const Text('Settings'),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Settings Page chưa được tạo.'),
                      ),
                    );
                    Navigator.pop(context);
                  },
                ),
                ListTile(
                  leading: Icon(
                    Icons.logout,
                    color: isDarkMode ? Colors.tealAccent : Colors.teal[800],
                  ),
                  title: const Text('Logout'),
                  onTap: () async {
                    await AuthServices().logout();
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.clear();

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
        ),
        body: Row(
          children: [
            if (isWideScreen) _buildNavigation(context, isDarkMode),
            Expanded(
              child: Stack(
                children: [
                  // Màn hình chính
                  _screens[_selectedIndex],

                  // NotificationListenerWidget (ẩn, chỉ lắng nghe)
                  FutureBuilder<int?>(
                    future: SharedPreferences.getInstance().then(
                          (prefs) => prefs.getInt('userId'),
                    ),
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

        bottomNavigationBar: isWideScreen
            ? null
            : _buildNavigation(context, isDarkMode),
      ),
    );
  }
}
