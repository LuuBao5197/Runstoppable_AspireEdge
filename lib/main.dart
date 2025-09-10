import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trackmentalhealth/pages/NotificationPage.dart';
import 'package:trackmentalhealth/pages/ProfilePage.dart';
import 'package:trackmentalhealth/pages/SearchPage.dart';
import 'package:trackmentalhealth/pages/CareerBank/CareerBankPage.dart';
import 'package:trackmentalhealth/pages/utils/permissions.dart';
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
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Đang kết nối Firebase...'),
                  ],
                ),
              ),
            );
          }
          
          // Nếu có lỗi
          if (snapshot.hasError) {
            print('❌ Auth state error: ${snapshot.error}');
            return const LoginPage();
          }
          
          // Nếu có dữ liệu người dùng (đã đăng nhập)
          if (snapshot.hasData && snapshot.data != null) {
            print('✅ User authenticated: ${snapshot.data!.uid}');
            return const MainScreen(); // Đi thẳng vào màn hình chính
          }
          
          // Nếu không có dữ liệu (chưa đăng nhập)
          print('ℹ️ No user authenticated, showing login page');
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
  StreamSubscription<DocumentSnapshot>? _firestoreSubscription;

  bool hasNewNotification = false;

  final List<Widget> _screens = [
    const NotificationsPage(),
    const SearchPage(),
    const ProfilePage(),
    const CareerBankPage(),
  ];

  @override
  void initState() {
    super.initState();
    _loadProfile();
    _setupFirestoreListener();
  }

  void _setupFirestoreListener() {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      // Lắng nghe thay đổi trong Firestore user document
      _firestoreSubscription = FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .snapshots()
          .listen((snapshot) {
        if (snapshot.exists && mounted) {
          final data = snapshot.data()!;
          setState(() {
            fullname = data['fullname'] ?? currentUser.displayName ?? "User";
            avatarUrl = data['avatar'] ?? currentUser.photoURL;
          });
          print('🔄 Profile updated from Firestore listener');
        }
      });
    }
  }

  @override
  void dispose() {
    _firestoreSubscription?.cancel();
    super.dispose();
  }


  Future<void> _loadProfile() async {
    setState(() => _loadingProfile = true);
    try {
      // Lấy user hiện tại từ Firebase Auth
      final currentUser = FirebaseAuth.instance.currentUser;
      
      if (currentUser == null) {
        print('⚠️ No current user found');
        setState(() => _loadingProfile = false);
        return;
      }

      print('🔍 Loading profile for user: ${currentUser.uid}');

      // Lấy thông tin từ Firestore
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .get();

      if (userDoc.exists) {
        final data = userDoc.data()!;
        setState(() {
          fullname = data['fullname'] ?? currentUser.displayName ?? "User";
          avatarUrl = data['avatar'] ?? currentUser.photoURL;
          _loadingProfile = false;
        });

        // Cập nhật SharedPreferences để đồng bộ
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('uid', currentUser.uid);
        await prefs.setString('email', currentUser.email ?? '');
        await prefs.setString('fullname', fullname ?? '');
        if (avatarUrl != null && avatarUrl!.isNotEmpty) {
          await prefs.setString('avatar', avatarUrl!);
        }
        
        print('✅ Profile loaded from Firestore');
      } else {
        // Nếu không có trong Firestore, tạo document mới
        print('📝 Creating new user document in Firestore');
        await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser.uid)
            .set({
          'uid': currentUser.uid,
          'email': currentUser.email,
          'fullname': currentUser.displayName ?? 'User',
          'avatar': currentUser.photoURL ?? '',
          'role': 'user',
          'createdAt': FieldValue.serverTimestamp(),
          'lastLoginAt': FieldValue.serverTimestamp(),
        });

        setState(() {
          fullname = currentUser.displayName ?? "User";
          avatarUrl = currentUser.photoURL;
          _loadingProfile = false;
        });

        // Cập nhật SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('uid', currentUser.uid);
        await prefs.setString('email', currentUser.email ?? '');
        await prefs.setString('fullname', fullname ?? '');
        if (avatarUrl != null && avatarUrl!.isNotEmpty) {
          await prefs.setString('avatar', avatarUrl!);
        }
        
        print('✅ New user document created');
      }
    } catch (e) {
      print('❌ Error loading profile: $e');
      // Fallback: lấy từ SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        fullname = prefs.getString('fullname') ?? "User";
        avatarUrl = prefs.getString('avatar');
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
                  NavigationRailDestination(
                    icon: Icon(Icons.mood),
                    label: Text("CareerBank"),
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
          BottomNavigationBarItem(
            icon: Icon(Icons.account_balance),
            label: 'CareerBank',
          ),
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
                    try {
                      // Đăng xuất Firebase
                      await FirebaseAuth.instance.signOut();
                      
                      // Đăng xuất Google nếu có
                      final googleSignIn = GoogleSignIn();
                      if (await googleSignIn.isSignedIn()) {
                        await googleSignIn.signOut();
                      }
                      
                      // Xóa dữ liệu local
                      final prefs = await SharedPreferences.getInstance();
                      await prefs.clear();

                      if (!mounted) return;
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => const LoginPage()),
                      );
                    } catch (e) {
                      print('Logout error: $e');
                      // Vẫn xóa dữ liệu local và chuyển về login
                      final prefs = await SharedPreferences.getInstance();
                      await prefs.clear();
                      
                      if (!mounted) return;
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => const LoginPage()),
                      );
                    }
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
                  Builder(
                    builder: (context) {
                      final currentUser = FirebaseAuth.instance.currentUser;
                      if (currentUser == null) return const SizedBox.shrink();
                      return NotificationListenerWidget(userId: currentUser.uid);
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
