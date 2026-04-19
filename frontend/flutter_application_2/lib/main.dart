import 'package:flutter/material.dart';

import 'screens/auth/app_login_screen.dart';
import 'screens/home/feed_home_screen.dart';
import 'screens/notifications/notifications_screen.dart';
import 'screens/post/api_create_post_screen.dart';
import 'screens/profile/account_profile_screen.dart';
import 'screens/search/search_screen.dart';
import 'session/app_session.dart';
import 'session/session_scope.dart';

void main() {
  runApp(const MiniSocialApp());
}

class MiniSocialApp extends StatefulWidget {
  const MiniSocialApp({super.key});

  @override
  State<MiniSocialApp> createState() => _MiniSocialAppState();
}

class _MiniSocialAppState extends State<MiniSocialApp> {
  late final AppSession _session;

  @override
  void initState() {
    super.initState();
    _session = AppSession();
    _session.bootstrap();
  }

  @override
  void dispose() {
    _session.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SessionScope(
      session: _session,
      child: MaterialApp(
        title: 'Mini Social Network',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
          scaffoldBackgroundColor: Colors.white,
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.white,
            elevation: 0,
            iconTheme: IconThemeData(color: Colors.black),
            titleTextStyle: TextStyle(
              color: Colors.black,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        home: const AppBootstrap(),
      ),
    );
  }
}

class AppBootstrap extends StatelessWidget {
  const AppBootstrap({super.key});

  @override
  Widget build(BuildContext context) {
    final session = SessionScope.of(context);

    if (!session.isReady) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (!session.isAuthenticated) {
      return const LoginScreen();
    }

    return const MainWrapper();
  }
}

class MainWrapper extends StatefulWidget {
  const MainWrapper({super.key});

  @override
  State<MainWrapper> createState() => _MainWrapperState();
}

class _MainWrapperState extends State<MainWrapper> {
  int _selectedIndex = 0;
  int _refreshToken = 0;

  void _setTab(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Future<void> _openCreatePost() async {
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const CreatePostScreen()),
    );

    if (created == true && mounted) {
      setState(() {
        _refreshToken++;
        _selectedIndex = 0;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      HomeScreen(
        refreshToken: _refreshToken,
        onOpenSearch: () => _setTab(1),
        onOpenNotifications: () => _setTab(3),
      ),
      SearchScreen(refreshToken: _refreshToken),
      const SizedBox.shrink(),
      NotificationsScreen(refreshToken: _refreshToken),
      ProfileScreen(refreshToken: _refreshToken),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.black,
        unselectedItemColor: Colors.grey,
        showSelectedLabels: false,
        showUnselectedLabels: false,
        onTap: (index) {
          if (index == 2) {
            _openCreatePost();
            return;
          }
          _setTab(index);
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Search'),
          BottomNavigationBarItem(icon: Icon(Icons.add_box_outlined), label: 'Post'),
          BottomNavigationBarItem(icon: Icon(Icons.favorite_border), activeIcon: Icon(Icons.favorite), label: 'Alerts'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), activeIcon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}
