import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:test_1/utils/theme_provider.dart';

class BottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const BottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    
    final primaryCyan = const Color(0xFF00E5FF);
    final bgDark = const Color(0xFF0F0F0F);
    
    // In "Bio-Tech" style, we might want a dark nav bar even in light mode, 
    // but the user complained about inconsistency. 
    // Let's make it theme-aware but styled.
    final Color navBg = isDarkMode ? bgDark.withOpacity(0.8) : Colors.white.withOpacity(0.8);
    final Color borderColor = isDarkMode ? primaryCyan.withOpacity(0.2) : Colors.grey.withOpacity(0.2);

    return Padding(
      padding: const EdgeInsets.only(left: 20, right: 20, bottom: 20),
      child: Container(
        height: 70,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(25),
          border: Border.all(color: borderColor),
          boxShadow: [
            BoxShadow(
              color: isDarkMode ? Colors.black.withOpacity(0.5) : Colors.grey.withOpacity(0.2),
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
                children: [
                  _NavItem(
                    icon: Icons.grid_view_rounded,
                    isActive: currentIndex == 0,
                    onTap: () => onTap(0),
                    primaryCyan: primaryCyan,
                    isDarkMode: isDarkMode,
                  ),
                  _NavItem(
                    icon: Icons.alarm_rounded,
                    isActive: currentIndex == 1,
                    onTap: () => onTap(1),
                    primaryCyan: primaryCyan,
                    isDarkMode: isDarkMode,
                  ),
                  _NavItem(
                    icon: Icons.folder_copy_rounded,
                    isActive: currentIndex == 2,
                    onTap: () => onTap(2),
                    primaryCyan: primaryCyan,
                    isDarkMode: isDarkMode,
                  ),
                  _NavItem(
                    icon: Icons.calendar_month_rounded,
                    isActive: currentIndex == 3,
                    onTap: () => onTap(3),
                    primaryCyan: primaryCyan,
                    isDarkMode: isDarkMode,
                  ),
                  _NavItem(
                    icon: Icons.person_rounded,
                    isActive: currentIndex == 4,
                    onTap: () => onTap(4),
                    primaryCyan: primaryCyan,
                    isDarkMode: isDarkMode,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final bool isActive;
  final VoidCallback onTap;
  final Color primaryCyan;
  final bool isDarkMode;

  const _NavItem({
    required this.icon,
    required this.isActive,
    required this.onTap,
    required this.primaryCyan,
    required this.isDarkMode,
  });

  @override
  Widget build(BuildContext context) {
    final activeColor = primaryCyan;
    final inactiveColor = isDarkMode ? Colors.white38 : Colors.black38;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? activeColor.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
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
  }
}

