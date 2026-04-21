import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:test_1/utils/theme_provider.dart';
import 'package:test_1/utils/language_provider.dart';
import 'package:test_1/utils/app_localizations.dart';
import 'package:test_1/pages/doctor_home_page.dart';
import 'package:test_1/pages/doctor_patients_page.dart';
import 'package:test_1/pages/doctor_appointments_page.dart';
import 'package:test_1/pages/doctor_schedule_page.dart';
import 'package:test_1/pages/profile_page.dart';
import 'dart:ui';

class DoctorMainPage extends StatefulWidget {
  const DoctorMainPage({super.key});

  @override
  State<DoctorMainPage> createState() => DoctorMainPageState();

  static DoctorMainPageState? of(BuildContext context) =>
      context.findAncestorStateOfType<DoctorMainPageState>();
}

class DoctorMainPageState extends State<DoctorMainPage> {
  int _selectedIndex = 0;

  static final List<Widget> _pages = [
    DoctorHomePage(),
    DoctorPatientsPage(),
    DoctorAppointmentsPage(),
    DoctorSchedulePage(),
    SettingsPage(),
  ];

  static const List<String> _pageNames = [
    "Doctor Home",
    "Patients",
    "Appointments",
    "Schedule",
    "Settings",
  ];

  void _changePage(int index) {
    if (index == _selectedIndex) return;
    setState(() {
      _selectedIndex = index;
    });
  }

  void navigateToTab(int index) {
    _changePage(index);
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    final languageProvider = Provider.of<LanguageProvider>(context);
    final isRTL = languageProvider.isRTL;
    final colorScheme = Theme.of(context).colorScheme;

    final primaryColor = AppTheme.cardoBlue;
    final navBg =
        isDarkMode ? const Color(0xFF0F0F0F).withOpacity(0.8) : Colors.white.withOpacity(0.8);
    final borderColor =
        isDarkMode ? primaryColor.withOpacity(0.2) : Colors.grey.withOpacity(0.2);

    final List<IconData> _navIcons = [
      Icons.home_rounded,
      Icons.people_rounded,
      Icons.calendar_month_rounded,
      Icons.schedule_rounded,
      Icons.settings_rounded,
    ];

    return Scaffold(
      backgroundColor: isDarkMode ? const Color(0xFF0F0F0F) : Colors.white,
      extendBody: true,
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.only(left: 20, right: 20, bottom: 20),
        child: Container(
          height: 70,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(25),
            border: Border.all(color: borderColor),
            boxShadow: [
              BoxShadow(
                color: isDarkMode
                    ? Colors.black.withOpacity(0.5)
                    : Colors.grey.withOpacity(0.2),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(25),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                color: navBg,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: List.generate(_navIcons.length, (index) {
                    final isActive = _selectedIndex == index;
                    final activeColor = const Color(0xFF00E5FF);
                    final inactiveColor =
                        isDarkMode ? Colors.white38 : Colors.black38;

                    return GestureDetector(
                      onTap: () => _changePage(index),
                      behavior: HitTestBehavior.opaque,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: isActive
                              ? activeColor.withOpacity(0.1)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _navIcons[index],
                              color: isActive ? activeColor : inactiveColor,
                              size: 26,
                            ),
                            if (isActive)
                              Container(
                                margin: const EdgeInsets.only(top: 4),
                                height: 4,
                                width: 4,
                                decoration: BoxDecoration(
                                  color: activeColor,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: activeColor.withOpacity(0.8),
                                      blurRadius: 4,
                                      spreadRadius: 1,
                                    )
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
