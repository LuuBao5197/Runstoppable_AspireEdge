import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trackmentalhealth/widgets/CategorySelectWidget.dart';
import '../core/constants/theme_provider.dart';
import '../pages/CareerBank/CareerBankPage.dart';
import '../pages/NotificationScreen.dart';
import '../pages/Quizzes/CareerQuizDashboardScreen.dart';
import '../pages/Quizzes/QuestionListScreen.dart';
import '../pages/Resource/resource_main.dart';
import '../pages/login/LoginPage.dart';
import '../pages/profile/ProfileScreen.dart';

class ProfessionalScreen extends StatefulWidget {
  const ProfessionalScreen({super.key});

  @override
  State<ProfessionalScreen> createState() => _ProfessionalScreenState();
}

class _ProfessionalScreenState extends State<ProfessionalScreen> {
  int _selectedIndex = 0;
  String? name;
  String? avatarUrl;
  bool _loadingProfile = true;
  bool hasNewNotification = false;
  final List<Widget> _screens = [
    const NotificationScreen(),
    const ResourceMain(),
    const CareerBankPage(),
    const CareerDashboardScreen(),
    const CategorySelectionScreen()
    // const QuestionListScreen()
  ];

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }
  Future<void> _loadProfile() async {
    setState(() => _loadingProfile = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        setState(() => _loadingProfile = false);
        return;
      }

      final doc = await FirebaseFirestore.instance
          .collection('account')
          .doc(user.uid)
          .get();

      print("📌 Doc ID: ${doc.id}");
      print("📌 Exists: ${doc.exists}");
      print("📌 Data: ${doc.data()}");

      if (doc.exists) {
        final data = doc.data()!;
        setState(() {
          name = data['name'] ?? "User";
          avatarUrl = data['avatarUrl'];
          _loadingProfile = false;
          print("✅ Avatar URL: $avatarUrl");
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
                    icon: Icon(Icons.notifications_active),
                    label: Text("Notice"),

                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.quiz),
                    label: Text("Resource"),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.mood),
                    label: Text("CareerBank"),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.quiz),
                    label: Text("Career Quizzes"),
                  ),

                  NavigationRailDestination(
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
            icon: Icon(Icons.notifications_active),
            label: 'Notice',
          ),
          BottomNavigationBarItem( // ✅ thêm Resource tab
            icon: Icon(Icons.book),
            label: 'Resource',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.book),
            label: 'CareerBank',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.quiz_rounded),
            label: 'Career Quizzes',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.quiz_rounded),
            label: 'View Mode',
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

                      final data = snapshot.data!.data() as Map<String, dynamic>;
                      final avatarUrl = data['avatarUrl'] as String?;
                      final name = data['name'] ?? "User";

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CircleAvatar(
                            radius: 30,
                            backgroundImage: (avatarUrl != null && avatarUrl.isNotEmpty)
                                ? NetworkImage(avatarUrl)
                                : null,
                            child: (avatarUrl == null || avatarUrl.isEmpty)
                                ? const Icon(Icons.person, size: 40, color: Colors.white)
                                : null,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "Hello, $name",
                            style: const TextStyle(color: Colors.white, fontSize: 18),
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
                    Icons.logout,
                    color: isDarkMode ? Colors.tealAccent : Colors.teal[800],
                  ),
                  title: const Text('Logout'),
                  onTap: () async {
                    final prefs = await SharedPreferences.getInstance();
                    // await prefs.clear();
                    await FirebaseAuth.instance.signOut();
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
                  // Màn hình chính
                  _screens[_selectedIndex],
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