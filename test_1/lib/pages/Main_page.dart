import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:test_1/pages/home_page.dart';
import 'package:test_1/pages/profile_page.dart';
import 'package:test_1/pages/record_page.dart';
import 'package:test_1/pages/medical_reminder_page.dart';
import 'package:test_1/pages/appointments_page.dart';
import '../utils/bottom_nav_bar.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  final FirebaseAnalytics analytics = FirebaseAnalytics.instance;
  int _selectedIndex = 0;

  static const List<Widget> _pages = [
    HomePage(),
    MedicalReminderPage(),
    RecordPage(),
    AppointmentsPage(),
    SettingsPage(),
  ];

  static const List<String> _pageNames = [
    "Home",
    "Reminders",
    "Records",
    "Appointments",
    "Profile"
  ];

  @override
  void initState() {
    super.initState();
    _initAnalytics();
  }

  Future<void> _initAnalytics() async {
    await analytics.setAnalyticsCollectionEnabled(true);
    await _logCurrentScreen();
  }

  Future<void> _logCurrentScreen() async {
    await analytics.logScreenView(
      screenName: _pageNames[_selectedIndex],
      screenClass: _pageNames[_selectedIndex],
    );
  }

  void _changePage(int index) async {
    if (index == _selectedIndex) return;

    await analytics.logEvent(
      name: "navigation_event",
      parameters: {
        'from_page': _pageNames[_selectedIndex],
        'to_page': _pageNames[index],
        'page_index': index,
      },
    );

    setState(() {
      _selectedIndex = index;
    });

    await _logCurrentScreen();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      extendBody: true,
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: _selectedIndex,
        onTap: _changePage,
      ),
    );
  }
}
