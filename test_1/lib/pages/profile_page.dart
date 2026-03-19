import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:test_1/pages/login_screen.dart';
import 'package:test_1/utils/theme_provider.dart';
import 'package:test_1/utils/image_utils.dart';
import 'package:test_1/pages/Edit_profile_page.dart';
import 'package:test_1/pages/language_settings_page.dart';
import 'package:test_1/utils/language_provider.dart';
import 'package:test_1/utils/app_localizations.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  User? _currentUser;
  String _userName = '';
  String? _profileImageBase64;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
  }

  Future<void> _loadCurrentUser() async {
    setState(() {
      _isLoading = true;
    });
    try {
      _currentUser = _auth.currentUser;
      if (_currentUser != null) {
        // Fetch user data from Firestore
        final userDoc =
            await _firestore.collection('users').doc(_currentUser!.uid).get();
        if (userDoc.exists) {
          final userData = userDoc.data();
          setState(() {
            _userName = userData?['fullName'] ?? context.translate('no_name');
            _profileImageBase64 = userData?['profileImageBase64'];
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                '${context.translate('error_loading_user')}: ${e.toString()}'),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _signOut() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await _auth.signOut();
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                '${context.translate('error_signing_out')}: ${e.toString()}'),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Navigate to edit profile page
  void _navigateToEditProfile() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const EditProfilePage()),
    );

    // If returning with success result, reload user data
    if (result == true) {
      _loadCurrentUser();
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    final colorScheme = Theme.of(context).colorScheme;

    // Get language direction
    final languageProvider = Provider.of<LanguageProvider>(context);
    final isRTL = languageProvider.isRTL;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          context.translate('profile'),
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
          ),
        ),
        centerTitle: true,
        backgroundColor: colorScheme.surface,
        elevation: 0,
      ),
      backgroundColor: colorScheme.background,
      body: Directionality(
        textDirection: isRTL ? TextDirection.rtl : TextDirection.ltr,
        child: _isLoading
            ? Center(
                child: CircularProgressIndicator(color: colorScheme.primary))
            : SingleChildScrollView(
                physics: AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Profile Section
                    Card(
                      margin: EdgeInsets.only(bottom: 24),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 30,
                              backgroundColor: isDarkMode
                                  ? Colors.grey[800]
                                  : Colors.grey[300],
                              child: _profileImageBase64 != null &&
                                      _profileImageBase64!.isNotEmpty
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(30),
                                      child: ImageUtils.imageFromBase64String(
                                        _profileImageBase64!,
                                        width: 60,
                                        height: 60,
                                        fit: BoxFit.cover,
                                      ),
                                    )
                                  : Icon(
                                      Icons.person,
                                      size: 30,
                                      color: isDarkMode
                                          ? Colors.grey[300]
                                          : Colors.grey[700],
                                    ),
                            ),
                            SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _userName.isNotEmpty
                                        ? _userName
                                        : context.translate('no_name'),
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: colorScheme.onSurface,
                                    ),
                                  ),
                                  if (_currentUser?.email != null)
                                    Text(
                                      _currentUser!.email!,
                                      style: TextStyle(
                                        color: colorScheme.onSurface
                                            .withOpacity(0.7),
                                      ),
                                    ),
                                  SizedBox(height: 4),
                                  Text(
                                    context.translate('edit_personal_details'),
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: colorScheme.primary,
                                    ),
                                  )
                                ],
                              ),
                            ),
                            IconButton(
                              icon: Icon(
                                Icons.edit,
                                color: colorScheme.primary,
                              ),
                              onPressed: _navigateToEditProfile,
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Theme Toggle Section
                    Card(
                      margin: EdgeInsets.only(bottom: 24),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              context.translate('appearance'),
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: colorScheme.onSurface,
                              ),
                            ),
                            SizedBox(height: 16),
                            InkWell(
                              onTap: () {
                                themeProvider.toggleTheme();
                              },
                              borderRadius: BorderRadius.circular(8),
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 8.0),
                                child: Row(
                                  children: [
                                    Icon(
                                      isDarkMode
                                          ? Icons.dark_mode
                                          : Icons.light_mode,
                                      color: colorScheme.primary,
                                    ),
                                    SizedBox(width: 16),
                                    Expanded(
                                      child: Text(
                                        context.translate('dark_mode'),
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: colorScheme.onSurface,
                                        ),
                                      ),
                                    ),
                                    Switch(
                                      value: isDarkMode,
                                      onChanged: (value) {
                                        themeProvider.toggleTheme();
                                      },
                                      activeColor: colorScheme.primary,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Profile Settings
                    _buildSectionCard(
                      context.translate('personal_information'),
                      [
                        _buildSettingTile(
                          icon: Icons.person_outline,
                          title: context.translate('edit_profile'),
                          onTap: _navigateToEditProfile,
                        ),
                        Divider(height: 1),
                        _buildSettingTile(
                          icon: Icons.lock_outline,
                          title: context.translate('change_password'),
                          onTap: () {},
                        ),
                        Divider(height: 1),
                        _buildSettingTile(
                          icon: Icons.medical_services_outlined,
                          title: context.translate('doctors'),
                          onTap: () {},
                        ),
                        Divider(height: 1),
                        _buildSettingTile(
                          icon: Icons.people_outline,
                          title: context.translate('community'),
                          onTap: () {},
                        ),
                      ],
                    ),

                    SizedBox(height: 16),

                    // App Settings
                    _buildSectionCard(
                      context.translate('app_settings'),
                      [
                        _buildSettingTile(
                          icon: Icons.notifications_none,
                          title: context.translate('notifications'),
                          onTap: () {},
                        ),
                        Divider(height: 1),
                        _buildSettingTile(
                          icon: Icons.language,
                          title: context.translate('language'),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) =>
                                      const LanguageSettingsPage()),
                            );
                          },
                        ),
                        Divider(height: 1),
                        _buildSettingTile(
                          icon: Icons.public,
                          title: context.translate('regional'),
                          onTap: () {},
                        ),
                        Divider(height: 1),
                        _buildSettingTile(
                          icon: Icons.info_outline,
                          title: context.translate('about_us'),
                          onTap: () {},
                        ),
                      ],
                    ),

                    SizedBox(height: 24),

                    // Logout Button
                    Center(
                      child: ElevatedButton(
                        onPressed: _signOut,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          minimumSize: Size(150, 45),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                        ),
                        child: Text(
                          context.translate('logout'),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),

                    // App Version
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 24, bottom: 40),
                        child: Text(
                          context.translate('app_version'),
                          style: TextStyle(
                            color: colorScheme.onBackground.withOpacity(0.6),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildSectionCard(String title, List<Widget> children) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      margin: EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            SizedBox(height: 8),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildSettingTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final languageProvider = Provider.of<LanguageProvider>(context);
    final isRTL = languageProvider.isRTL;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12.0),
        child: Row(
          children: [
            Icon(
              icon,
              color: colorScheme.primary,
            ),
            SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  color: colorScheme.onSurface,
                ),
              ),
            ),
            Icon(
              isRTL ? Icons.arrow_forward_ios : Icons.arrow_forward_ios,
              color: colorScheme.onSurface.withOpacity(0.6),
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}
