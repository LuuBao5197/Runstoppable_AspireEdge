import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trackmentalhealth/pages/ContactUsPage.dart';
import 'package:trackmentalhealth/pages/Quizzes/QuizScreen.dart';
import 'package:trackmentalhealth/widgets/CategorySelectWidget.dart';

import '../core/constants/theme_provider.dart';
import '../pages/CareerBank/career_guidance_page.dart';
import '../pages/FeedbackPage.dart';
import '../pages/NotificationScreen.dart';
import '../pages/Quizzes/CareerQuizDashboardScreen.dart';
import '../pages/Resource/User/WishlistScreen.dart';
import '../pages/Resource/resource_main.dart';
import '../pages/login/LoginPage.dart';
import '../pages/profile/ProfileScreen.dart';
import '../services/NotificationService.dart';

class StudentScreen extends StatefulWidget {
  const StudentScreen({super.key});

  @override
  State<StudentScreen> createState() => _StudentScreenState();
}

class _StudentScreenState extends State<StudentScreen> {
  int _selectedIndex = 0;
  String? name;
  String? avatarUrl;
  bool _loadingProfile = true;
  int _unreadCount = 0;

  final NotificationService _notificationService = NotificationService();
  late StreamSubscription _notificationSub;

  final List<Widget> _screens = [
    const NotificationScreen(),
    const ResourceMain(),
    const ContactUsPage(),
    const CareerGuidancePage(),
    const CareerDashboardScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _loadProfile();

    // Listen notifications realtime
    _notificationSub =
        _notificationService.notificationsStream.listen((notifications) {
          final unread = notifications.where((n) => n['isRead'] == false).length;
          setState(() {
            _unreadCount = unread;
          });
        });
  }

  @override
  void dispose() {
    _notificationSub.cancel();
    _notificationService.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    setState(() => _loadingProfile = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        setState(() => _loadingProfile = false);
        return;
      }

      final doc =
      await FirebaseFirestore.instance.collection('account').doc(user.uid).get();

      print("📌 Doc ID: ${doc.id}");
      print("📌 Exists: ${doc.exists}");
      print("📌 Data: ${doc.data()}");
      
      if (doc.exists) {
        final data = doc.data()!;
        setState(() {
          name = data['name'] ?? "User";
          avatarUrl = data['avatarUrl'];
          _loadingProfile = false;
        });
      } else {
        setState(() => _loadingProfile = false);
      }
    } catch (e) {
      print("Load profile error: $e");
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

    Widget notificationIcon() {
      return Stack(
        children: [
          const Icon(Icons.notifications_active),
          if (_unreadCount > 0)
            Positioned(
              right: 0,
              top: 0,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                child: Text(
                  _unreadCount > 99 ? '99+' : '$_unreadCount',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      );
    }

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
                destinations: [
                  NavigationRailDestination(
                    icon: notificationIcon(),
                    label: const Text("Notice"),
                  ),
                  const NavigationRailDestination(
                    icon: Icon(Icons.book),
                    label: Text("Resource"),
                  ),
                  const NavigationRailDestination(
                    icon: Icon(Icons.contact_page),
                    label: Text("Contact"),
                  ),
                  const NavigationRailDestination(
                    icon: Icon(Icons.contact_page),
                    label: Text("CareerGuidancePage"),
                  ),
                  const NavigationRailDestination(
                    icon: Icon(Icons.quiz),
                    label: Text("View Mode"),
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
        backgroundColor: Colors.white,
        selectedItemColor: selectedColor,
        unselectedItemColor: unselectedColor,
        selectedLabelStyle:
        const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
        unselectedLabelStyle: const TextStyle(fontSize: 12),
        elevation: 10,
        items: [
          BottomNavigationBarItem(
            icon: notificationIcon(),
            label: 'Notice',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.book),
            label: 'Resource',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.contact_page),
            label: 'Contact',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.contact_page),
            label: 'CareerGuidancePage',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.quiz_rounded),
            label: "Quiz",
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
                child: const Text('Aspire Edge'),
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
                  child: StreamBuilder<DocumentSnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('account')
                        .doc(FirebaseAuth.instance.currentUser!.uid)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: CircularProgressIndicator(color: Colors.white),
                        );
                      }
                      if (!snapshot.hasData || !snapshot.data!.exists) {
                        return const Text(
                          "No profile data",
                          style: TextStyle(color: Colors.white),
                        );
                      }

                      final data =
                      snapshot.data!.data() as Map<String, dynamic>;
                      final avatarUrl = data['avatarUrl'] as String?;
                      final name = data['name'] ?? "User";

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CircleAvatar(
                            radius: 30,
                            backgroundImage:
                            (avatarUrl != null && avatarUrl.isNotEmpty)
                                ? NetworkImage(avatarUrl)
                                : null,
                            child: (avatarUrl == null || avatarUrl.isEmpty)
                                ? const Icon(
                              Icons.person,
                              size: 40,
                              color: Colors.white,
                            )
                                : null,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "Hello, $name",
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                            ),
                          ),
                        ],
                      );
                    },
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
                    Icons.feedback_outlined,
                    color: isDarkMode ? Colors.tealAccent : Colors.teal[800],
                  ),
                  title: const Text('Feedback'),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const FeedbackPage()),
                    );
                  },
                ),
                ListTile(
                  leading: Icon(
                    Icons.bookmark_border_outlined,
                    color: isDarkMode ? Colors.tealAccent : Colors.teal[800],
                  ),
                  title: const Text('Book mark'),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const WishlistScreen()),
                    );
                  },
                ),
                ListTile(
                  leading: Icon(
                    Icons.logout,
                    color: isDarkMode ? Colors.tealAccent : Colors.teal[800],
                  ),
                  title: const Text('Logout'),
                  onTap: () async {
                    final prefs = await SharedPreferences.getInstance();
                    // await prefs.clear();
                    // await FirebaseAuth.instance.signOut();
                    final googleSignIn = GoogleSignIn();
                    if (await googleSignIn.isSignedIn())
                      await googleSignIn.signOut();
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
                  _screens[_selectedIndex],
                ],
              ),
            ),
          ],
        ),
        bottomNavigationBar:
        isWideScreen ? null : _buildNavigation(context, isDarkMode),
      ),
    );
  }
}
