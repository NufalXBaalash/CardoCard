import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:test_1/pages/Main_page.dart';
import 'package:nfc_manager/nfc_manager.dart';
import 'package:test_1/pages/signup_page.dart';
import 'package:test_1/utils/theme_provider.dart';
import 'package:test_1/utils/app_localizations.dart';
import 'package:test_1/utils/language_provider.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:nfc_manager/nfc_manager_android.dart';
import 'package:test_1/utils/serial_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  late final FirebaseAuth _auth;
  late final FirebaseAnalytics _analytics;

  bool _isLoading = false;
  bool isNFCAvailable = false;
  bool tagProcessed = false;
  bool isSerialConnected = false;

  // Bio-Tech Colors (now used as defaults or for specific accents)
  static const Color biotechCyan = Color(0xFF00E5FF);
  static const Color biotechCyanDeep = Color(0xFF00B8D4);
  static const Color biotechBlack = Color(0xFF0F0F0F);
  static const Color frostedGlass = Color(0xFFF5F7FA);

  @override
  void initState() {
    super.initState();
    _auth = FirebaseAuth.instance;
    _analytics = FirebaseAnalytics.instance;
    _checkNFCAvailability();
    
    SerialService().init(
      onTag: (id) {
        if (!tagProcessed && !_isLoading) {
          _logHardwareEvent("SERIAL_TAG_DETECTED: $id");
          _authenticateWithNFCToken(id.trim());
        }
      },
      onDebug: (msg) {
        if (msg.contains("CONNECTED")) {
          setState(() => isSerialConnected = true);
        } else if (msg.contains("Disconnected") || msg.contains("Unplugged")) {
          setState(() => isSerialConnected = false);
        }
        _showDebugSnackBar(msg);
      },
    );
  }

  void _logHardwareEvent(String event) {
    _analytics.logEvent(name: 'hardware_auth_attempt', parameters: {'event': event});
    debugPrint("HW_AUTH: $event");
  }

  void _showDebugSnackBar(String message) {
    if (!mounted) return;
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final dynamicCyan = themeProvider.isDarkMode ? biotechCyan : biotechCyanDeep;
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message, style: GoogleFonts.orbitron(fontSize: 10, color: dynamicCyan)),
          backgroundColor: themeProvider.isDarkMode ? biotechBlack.withOpacity(0.9) : Colors.white.withOpacity(0.9),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
    });
  }

  Future<void> _checkNFCAvailability() async {
    bool isAvailable = await NfcManager.instance.isAvailable();
    setState(() {
      isNFCAvailable = isAvailable;
    });
  }

  void _startNFCSession() {
    setState(() {
      tagProcessed = false;
    });

    NfcManager.instance.startSession(
      pollingOptions: {NfcPollingOption.iso14443, NfcPollingOption.iso15693},
      onDiscovered: (NfcTag tag) async {
        if (tagProcessed) return;
        tagProcessed = true;

        try {
          String? tokenData;
          final ndef = NdefAndroid.from(tag);
          if (ndef != null && ndef.cachedNdefMessage != null) {
            final records = ndef.cachedNdefMessage!.records;
            if (records.isNotEmpty) {
              final payload = records.first.payload;
              if (payload.isNotEmpty) {
                int languageCodeLength = payload[0] & 0x3F;
                tokenData = utf8.decode(payload.sublist(1 + languageCodeLength)).trim();
              }
            }
          }

          if (tokenData == null || tokenData.isEmpty) {
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
              tokenData = id.map((e) => e.toRadixString(16).padLeft(2, '0')).join();
            }
          }

          if (tokenData != null && tokenData.isNotEmpty) {
            String finalUid = tokenData;
            if (tokenData.contains('?id=')) {
              final uri = Uri.parse(tokenData);
              finalUid = uri.queryParameters['id'] ?? tokenData;
            } else if (tokenData.contains('/')) {
              finalUid = tokenData.split('/').last;
            }
            await _authenticateWithNFCToken(finalUid.trim());
          }
        } catch (e) {
          _showErrorSnackBar("ERROR ACCESSING BIO-DATA");
        } finally {
          await Future.delayed(const Duration(milliseconds: 500));
          await NfcManager.instance.stopSession();
        }
      },
    );

    _showNfcDialog();
  }

  Future<void> _authenticateWithNFCToken(String tokenData) async {
    setState(() => _isLoading = true);
    try {
      final HttpsCallable callable = FirebaseFunctions.instance.httpsCallable('getCustomToken');
      final result = await callable.call({'uid': tokenData});
      final customToken = result.data['customToken'];
      
      if (customToken == null) throw Exception("NO TOKEN RETURNED");

      await _auth.signInWithCustomToken(customToken);

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const MainPage()),
        );
      }
    } catch (e) {
      _showErrorSnackBar("AUTHORIZATION DENIED");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showNfcDialog() {
    final isDarkMode = Provider.of<ThemeProvider>(context, listen: false).isDarkMode;
    final dynamicCyan = isDarkMode ? biotechCyan : biotechCyanDeep;
    final bgColor = isDarkMode ? biotechBlack : frostedGlass;
    final textColor = isDarkMode ? Colors.white : biotechBlack;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: bgColor.withOpacity(0.9),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
            border: Border.all(color: dynamicCyan.withOpacity(0.2)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.nfc, size: 80, color: dynamicCyan),
              const SizedBox(height: 24),
              Text(
                "SCAN BIO-ID",
                style: GoogleFonts.orbitron(fontSize: 20, fontWeight: FontWeight.bold, color: dynamicCyan, letterSpacing: 2),
              ),
              const SizedBox(height: 12),
              Text(
                "HOLD CARD TO SCANNER",
                style: GoogleFonts.orbitron(fontSize: 12, color: textColor.withOpacity(0.6), letterSpacing: 1),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.redAccent.withOpacity(0.9),
        content: Text(message, style: GoogleFonts.orbitron(fontWeight: FontWeight.bold, color: Colors.white)),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    final dynamicCyan = isDarkMode ? biotechCyan : biotechCyanDeep;
    final bgColor = isDarkMode ? biotechBlack : frostedGlass;
    final textColor = isDarkMode ? Colors.white : biotechBlack;

    return Scaffold(
      backgroundColor: bgColor,
      body: Stack(
        children: [
          // Cyberpunk Background Elements
          Positioned(
            top: -150,
            right: -150,
            child: Container(
              width: 400,
              height: 400,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: dynamicCyan.withOpacity(0.05),
              ),
            ),
          ),
          // Hardware Status Indicators
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            left: 20,
            child: Row(
              children: [
                _buildStatusDot("NFC", isNFCAvailable, dynamicCyan),
                const SizedBox(width: 15),
                _buildStatusDot("SERIAL", isSerialConnected, dynamicCyan),
              ],
            ),
          ),
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: dynamicCyan.withOpacity(0.1),
                      shape: BoxShape.circle,
                      border: Border.all(color: dynamicCyan, width: 2),
                      boxShadow: [
                        if (isDarkMode)
                          BoxShadow(color: dynamicCyan.withOpacity(0.3), blurRadius: 20)
                      ],
                    ),
                    child: Icon(Icons.shield_outlined, color: dynamicCyan, size: 50),
                  ),
                  const SizedBox(height: 40),
                  Text(
                    "CORE AUTH",
                    style: GoogleFonts.orbitron(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      color: textColor,
                      letterSpacing: 4,
                    ),
                  ),
                  Text(
                    "SECURE PROTOCOL V2.0",
                    style: GoogleFonts.orbitron(
                      fontSize: 10,
                      color: dynamicCyan,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 80),
                  
                  if (_isLoading)
                    CircularProgressIndicator(color: dynamicCyan)
                  else ...[
                    // NFC Login Button
                    GestureDetector(
                      onTap: isNFCAvailable ? _startNFCSession : null,
                      child: Container(
                        height: 60,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [dynamicCyan, dynamicCyan.withOpacity(0.7)],
                          ),
                          borderRadius: BorderRadius.circular(15),
                          boxShadow: [
                            BoxShadow(color: dynamicCyan.withOpacity(0.4), blurRadius: 15, offset: const Offset(0, 5))
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.nfc, color: isDarkMode ? biotechBlack : Colors.white),
                            const SizedBox(width: 12),
                            Text(
                              "ACCESS VIA BIO-ID",
                              style: GoogleFonts.orbitron(
                                color: isDarkMode ? biotechBlack : Colors.white,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Manual Override (Traditional Login)
                    TextButton(
                      onPressed: () {},
                      child: Text(
                        "MANUAL OVERRIDE",
                        style: GoogleFonts.orbitron(
                          color: textColor.withOpacity(0.3),
                          fontSize: 10,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusDot(String label, bool isActive, Color activeColor) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isActive ? activeColor : Colors.grey.withOpacity(0.5),
            boxShadow: [
              if (isActive)
                BoxShadow(color: activeColor.withOpacity(0.5), blurRadius: 4, spreadRadius: 1)
            ],
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: GoogleFonts.orbitron(
            fontSize: 8,
            fontWeight: FontWeight.bold,
            color: isActive ? activeColor : Colors.grey.withOpacity(0.5),
          ),
        ),
      ],
    );
  }
}
