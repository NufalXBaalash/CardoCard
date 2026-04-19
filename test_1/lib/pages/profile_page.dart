import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui';
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
import 'package:nfc_manager/nfc_manager.dart';
import 'package:nfc_manager/nfc_manager_android.dart';

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

  // Bio-Tech Colors
  static const Color biotechBlack = Color(0xFF0F0F0F);
  static const Color biotechCyan = Color(0xFF00E5FF);
  static const Color biotechCyanDeep = Color(0xFF00B8D4); // WCAG-compliant for Light Mode

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
  }

  Future<void> _loadCurrentUser() async {
    setState(() => _isLoading = true);
    try {
      _currentUser = _auth.currentUser;
      if (_currentUser != null) {
        final userDoc = await _firestore.collection('users').doc(_currentUser!.uid).get();
        if (userDoc.exists) {
          final userData = userDoc.data();
          setState(() {
            _userName = userData?['fullName'] ?? "No Name";
            _profileImageBase64 = userData?['profileImageBase64'];
          });
        }
      }
    } catch (e) {
      debugPrint("Error loading user: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _signOut() async {
    await _auth.signOut();
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  void _showLinkNFCDialog() {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final isDarkMode = themeProvider.isDarkMode;
    final dynamicCyan = isDarkMode ? biotechCyan : biotechCyanDeep;
    final dialogBg = isDarkMode ? biotechBlack : Colors.white;
    final textColor = isDarkMode ? Colors.white : biotechBlack;

    bool isScanning = false;
    String statusMessage = "TAP YOUR BIO-CARD TO LINK TO ACCOUNT";

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
              child: AlertDialog(
                backgroundColor: dialogBg.withOpacity(0.8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                  side: BorderSide(color: dynamicCyan.withOpacity(0.3)),
                ),
                title: Text(
                  "LINK BIO-ID",
                  style: GoogleFonts.orbitron(
                    color: dynamicCyan,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
                ),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isScanning) ...[
                      CircularProgressIndicator(color: dynamicCyan),
                      const SizedBox(height: 20),
                    ] else ...[
                      Icon(Icons.nfc, size: 60, color: dynamicCyan),
                      const SizedBox(height: 20),
                    ],
                    Text(
                      statusMessage,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.orbitron(
                        color: textColor.withOpacity(0.7),
                        fontSize: 12,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      NfcManager.instance.stopSession();
                      Navigator.pop(context);
                    },
                    child: Text(
                      "CANCEL",
                      style: GoogleFonts.orbitron(color: Colors.redAccent, fontSize: 12),
                    ),
                  ),
                  if (!isScanning)
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: dynamicCyan,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () async {
                        setDialogState(() {
                          isScanning = true;
                          statusMessage = "WAITING FOR NFC SIGNAL...";
                        });

                        try {
                          bool isAvailable = await NfcManager.instance.isAvailable();
                          if (!isAvailable) {
                            setDialogState(() {
                              isScanning = false;
                              statusMessage = "NFC HARDWARE NOT DETECTED";
                            });
                            return;
                          }

                          NfcManager.instance.startSession(
                            pollingOptions: {NfcPollingOption.iso14443, NfcPollingOption.iso15693},
                            onDiscovered: (NfcTag tag) async {
                              try {
                                String? uid;
                                final ndef = NdefAndroid.from(tag);
                                if (ndef != null && ndef.cachedNdefMessage != null) {
                                  final records = ndef.cachedNdefMessage!.records;
                                  if (records.isNotEmpty) {
                                    final payload = records.first.payload;
                                    if (payload.isNotEmpty) {
                                      int languageCodeLength = payload[0] & 0x3F;
                                      uid = utf8.decode(payload.sublist(1 + languageCodeLength)).trim();
                                    }
                                  }
                                }

                                if (uid == null || uid.isEmpty) {
                                  final dynamic data = tag.data;
                                  List<int>? id;
                                  try {
                                    id = data.identifier as List<int>?;
                                  } catch (e) {
                                    try {
                                      id = (data['identifier'] ?? data['id'] ?? data['mifare']?['identifier']) as List<int>?;
                                    } catch (_) {}
                                  }
                                  if (id != null) {
                                    uid = id.map((e) => e.toRadixString(16).padLeft(2, '0')).join();
                                  }
                                }

                                if (uid != null && uid.isNotEmpty) {
                                  await _firestore.collection('users').doc(_currentUser!.uid).update({'nfcUid': uid});
                                  await _firestore.collection('users').doc(uid).set({
                                    'linkedUser': _currentUser!.uid,
                                    'type': 'nfc_mapping'
                                  }, SetOptions(merge: true));

                                  if (mounted) {
                                    Navigator.pop(context);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        backgroundColor: dynamicCyan,
                                        content: Text(
                                          "BIO-ID LINKED SUCCESSFULLY",
                                          style: GoogleFonts.orbitron(color: isDarkMode ? biotechBlack : Colors.white, fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                    );
                                  }
                                } else {
                                  setDialogState(() {
                                    isScanning = false;
                                    statusMessage = "INVALID SCAN: RETRY";
                                  });
                                }
                              } catch (e) {
                                setDialogState(() {
                                  isScanning = false;
                                  statusMessage = "SYSTEM ERROR: $e";
                                });
                              } finally {
                                await Future.delayed(const Duration(milliseconds: 500));
                                await NfcManager.instance.stopSession();
                              }
                            },
                          );
                        } catch (e) {
                          setDialogState(() {
                            isScanning = false;
                            statusMessage = "SCAN FAILURE: $e";
                          });
                        }
                      },
                      child: Text(
                        "START SCAN",
                        style: GoogleFonts.orbitron(color: isDarkMode ? biotechBlack : Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final languageProvider = Provider.of<LanguageProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;

    final dynamicCyan = isDarkMode ? biotechCyan : biotechCyanDeep;
    final scaffoldBg = isDarkMode ? biotechBlack : const Color(0xFFF5F7FA);
    final textColor = isDarkMode ? Colors.white : biotechBlack;
    final cardBg = isDarkMode ? Colors.white.withOpacity(0.03) : Colors.white;
    final borderColor = isDarkMode ? Colors.white.withOpacity(0.1) : dynamicCyan.withOpacity(0.2);

    return Scaffold(
      backgroundColor: scaffoldBg,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(color: scaffoldBg.withOpacity(0.5)),
          ),
        ),
        title: Text(
          context.translate('profile').toUpperCase(),
          style: GoogleFonts.orbitron(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: dynamicCyan,
            letterSpacing: 2,
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoading 
          ? Center(child: CircularProgressIndicator(color: dynamicCyan))
          : Stack(
              children: [
                // Background Glows
                Positioned(
                  bottom: -100,
                  right: -100,
                  child: Container(
                    width: 300,
                    height: 300,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: dynamicCyan.withOpacity(isDarkMode ? 0.05 : 0.08),
                    ),
                  ),
                ),
                SafeArea(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    children: [
                      _buildProfileHeader(dynamicCyan, textColor, cardBg, isDarkMode),
                      const SizedBox(height: 30),
                      _buildSectionLabel("CORE SETTINGS", dynamicCyan),
                      _buildSettingsCard(
                        cardBg: cardBg,
                        borderColor: borderColor,
                        children: [
                          _buildSettingRow(
                            icon: Icons.dark_mode_outlined,
                            title: context.translate('dark_mode'),
                            textColor: textColor,
                            dynamicCyan: dynamicCyan,
                            trailing: Switch(
                              value: themeProvider.isDarkMode,
                              onChanged: (_) => themeProvider.toggleTheme(),
                              activeColor: biotechCyan,
                              activeTrackColor: biotechCyan.withOpacity(0.3),
                              inactiveThumbColor: isDarkMode ? Colors.white38 : Colors.grey,
                              inactiveTrackColor: isDarkMode ? Colors.white10 : Colors.black12,
                            ),
                          ),
                          _buildDivider(isDarkMode),
                          _buildSettingRow(
                            icon: Icons.language_outlined,
                            title: "LANGUAGE",
                            textColor: textColor,
                            dynamicCyan: dynamicCyan,
                            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const LanguageSettingsPage())),
                            trailing: Icon(Icons.chevron_right, color: dynamicCyan),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      _buildSectionLabel("BIO-AUTHENTICATION", dynamicCyan),
                      _buildSettingsCard(
                        cardBg: cardBg,
                        borderColor: borderColor,
                        children: [
                          _buildSettingRow(
                            icon: Icons.nfc,
                            title: "LINK BIO-ID CARD",
                            subtitle: "Enable NFC Quick-Auth",
                            textColor: textColor,
                            dynamicCyan: dynamicCyan,
                            onTap: _showLinkNFCDialog,
                            trailing: Icon(Icons.add_link, color: dynamicCyan),
                          ),
                        ],
                      ),
                      const SizedBox(height: 40),
                      _buildLogoutButton(),
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildProfileHeader(Color dynamicCyan, Color textColor, Color cardBg, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: dynamicCyan.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ]
      ),
      child: Row(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: dynamicCyan, width: 2),
              boxShadow: [
                BoxShadow(color: dynamicCyan.withOpacity(0.2), blurRadius: 10)
              ],
            ),
            child: CircleAvatar(
              backgroundColor: isDark ? biotechBlack : Colors.white,
              backgroundImage: _profileImageBase64 != null 
                  ? MemoryImage(base64Decode(_profileImageBase64!))
                  : null,
              child: _profileImageBase64 == null 
                  ? Icon(Icons.person, size: 40, color: dynamicCyan)
                  : null,
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _userName.toUpperCase(),
                  style: GoogleFonts.orbitron(
                    color: textColor,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _currentUser?.email ?? "",
                  style: GoogleFonts.poppins(
                    color: dynamicCyan,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => EditProfilePage())),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: dynamicCyan.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: dynamicCyan.withOpacity(0.3)),
                    ),
                    child: Text(
                      "EDIT PROTOCOL",
                      style: GoogleFonts.orbitron(color: dynamicCyan, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(String label, Color dynamicCyan) {
    return Padding(
      padding: const EdgeInsets.only(left: 10, bottom: 10),
      child: Text(
        label,
        style: GoogleFonts.orbitron(
          color: dynamicCyan.withOpacity(0.6),
          fontSize: 10,
          letterSpacing: 2,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildSettingsCard({required List<Widget> children, required Color cardBg, required Color borderColor}) {
    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: Column(children: children),
        ),
      ),
    );
  }

  Widget _buildSettingRow({
    required IconData icon,
    required String title,
    required Color textColor,
    required Color dynamicCyan,
    String? subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return ListTile(
      onTap: onTap,
      leading: Icon(icon, color: dynamicCyan, size: 24),
      title: Text(
        title.toUpperCase(),
        style: GoogleFonts.orbitron(color: textColor, fontSize: 14, fontWeight: FontWeight.w600),
      ),
      subtitle: subtitle != null 
          ? Text(subtitle, style: GoogleFonts.poppins(color: textColor.withOpacity(0.4), fontSize: 11)) 
          : null,
      trailing: trailing,
    );
  }

  Widget _buildDivider(bool isDark) {
    return Divider(height: 1, color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05), indent: 20, endIndent: 20);
  }

  Widget _buildLogoutButton() {
    return Container(
      width: double.infinity,
      height: 55,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.redAccent.withOpacity(0.3)),
      ),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.redAccent.withOpacity(0.1),
          foregroundColor: Colors.redAccent,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        ),
        onPressed: _signOut,
        child: Text(
          "TERMINATE SESSION",
          style: GoogleFonts.orbitron(fontWeight: FontWeight.bold, letterSpacing: 2),
        ),
      ),
    );
  }
}
