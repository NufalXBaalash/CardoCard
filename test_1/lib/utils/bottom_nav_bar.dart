import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        boxShadow: [
          if (!isDarkMode)
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
        ],
        border: Border(
          top: BorderSide(
            color: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade200,
            width: isDarkMode ? 0.5 : 1,
          ),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Directionality(
            // Force LTR direction to maintain same order in all languages
            textDirection: TextDirection.ltr,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _NavItem(
                  icon: Icons.home_outlined,
                  activeIcon: Icons.home,
                  isActive: currentIndex == 0,
                  label: 'Home',
                  onTap: () => onTap(0),
                  isDarkMode: isDarkMode,
                ),
                _NavItem(
                  icon: Icons.timelapse_outlined,
                  activeIcon: Icons.timelapse,
                  isActive: currentIndex == 1,
                  label: 'Reminder',
                  onTap: () => onTap(1),
                  isDarkMode: isDarkMode,
                ),
                _NavItem(
                  icon: Icons.calendar_today_outlined,
                  activeIcon: Icons.calendar_today,
                  isActive: currentIndex == 2,
                  label: 'Records',
                  onTap: () => onTap(2),
                  isDarkMode: isDarkMode,
                ),
                _NavItem(
                  icon: Icons.medical_services_outlined,
                  activeIcon: Icons.medical_services,
                  isActive: currentIndex == 3,
                  label: 'Appointments',
                  onTap: () => onTap(3),
                  isDarkMode: isDarkMode,
                ),
                _NavItem(
                  icon: Icons.person_outlined,
                  activeIcon: Icons.person,
                  isActive: currentIndex == 4,
                  label: 'Profile',
                  onTap: () => onTap(4),
                  isDarkMode: isDarkMode,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final bool isActive;
  final String label;
  final VoidCallback onTap;
  final bool isDarkMode;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.isActive,
    required this.label,
    required this.onTap,
    required this.isDarkMode,
  });

  @override
  Widget build(BuildContext context) {
    // Use CardoBlue for consistency with the rest of the app
    final Color activeColor = AppTheme.cardoBlue;
    final Color inactiveColor =
        isDarkMode ? Colors.grey[500]! : Colors.grey[600]!;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: isActive
              ? activeColor.withOpacity(isDarkMode ? 0.15 : 0.1)
              : Colors.transparent,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isActive ? activeIcon : icon,
              color: isActive ? activeColor : inactiveColor,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: isActive ? activeColor : inactiveColor,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
