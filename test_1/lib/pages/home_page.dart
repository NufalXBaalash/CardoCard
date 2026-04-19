import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:test_1/database/DB.dart';
import 'package:test_1/pages/Main_page.dart';
import 'package:test_1/pages/record_page.dart';
import 'package:test_1/pages/doctor_listing_page.dart';
import 'package:test_1/pages/Edit_profile_page.dart';
import 'package:test_1/utils/Specializations_cards.dart';
import 'package:test_1/utils/health_overview_card.dart';
import 'package:test_1/utils/theme_provider.dart';
import 'package:test_1/utils/app_theme.dart';
import 'package:test_1/utils/image_utils.dart';
import 'package:test_1/utils/language_provider.dart';
import 'package:test_1/utils/app_localizations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final Specializations_DB db = Specializations_DB();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String userName = '';
  String? profileImageBase64;
  List<String> description = ["Unknown", "Unknown", "Unknown"];
  bool _isLoading = true;
  bool _isHealthDataLoading = true;
  bool _isRefreshing = false;

  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _getUserData();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _getUserData() async {
    setState(() {
      _isLoading = true;
      _isHealthDataLoading = true;
    });

    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        try {
          final userDoc = await FirebaseFirestore.instance
              .collection("users")
              .doc(currentUser.uid)
              .get();

          if (userDoc.exists) {
            final userData = userDoc.data();
            if (userData != null) {
              setState(() {
                userName = userData["fullName"] ?? "";
                profileImageBase64 = userData["profileImageBase64"];
              });
            }
          }
        } catch (e) {
          debugPrint("Error fetching user profile data: $e");
        }

        setState(() {
          _isLoading = false;
        });

        try {
          final medicalInfoDoc = await FirebaseFirestore.instance
              .collection("medical_info")
              .doc(currentUser.uid)
              .get();

          if (medicalInfoDoc.exists) {
            final medicalData = medicalInfoDoc.data();
            if (medicalData != null) {
              String bloodType =
                  medicalData["bloodType"]?.toString() ?? 'Unknown';

              String diabetesStatus = 'Unknown';
              if (medicalData["hasDiabetes"] != null) {
                diabetesStatus = medicalData["hasDiabetes"] == true
                    ? 'Affected'
                    : 'Not Affected';
              }

              String asthmaStatus = 'Unknown';
              if (medicalData["hasAsthma"] != null) {
                asthmaStatus = medicalData["hasAsthma"] == true
                    ? 'Affected'
                    : 'Not Affected';
              }

              setState(() {
                description = [
                  bloodType,
                  diabetesStatus,
                  asthmaStatus,
                ];
                _isHealthDataLoading = false;
              });
            }
          } else {
            setState(() {
              _isHealthDataLoading = false;
            });
          }
        } catch (e) {
          debugPrint("Error fetching medical info data: $e");
          setState(() {
            _isHealthDataLoading = false;
          });
        }
      } else {
        setState(() {
          _isLoading = false;
          _isHealthDataLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error in _getUserData: $e");
      setState(() {
        _isLoading = false;
        _isHealthDataLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final languageProvider = Provider.of<LanguageProvider>(context);
    final isRTL = languageProvider.isRTL;

    final screenSize = MediaQuery.of(context).size;
    final screenWidth = screenSize.width;
    final screenHeight = screenSize.height;

    final double headerHeight = screenHeight * 0.18;
    final double cardHeight = screenHeight * 0.23;
    final double cardWidth = screenWidth * 0.9;
    final double padding = screenWidth * 0.05;

    final double largeTextSize = screenWidth * 0.055;
    final double mediumTextSize = screenWidth * 0.045;
    final double smallTextSize = screenWidth * 0.035;

    final primaryCyan = const Color(0xFF00E5FF);
    final primaryCyanDeep = const Color(0xFF00B8D4);
    final dynamicCyan = isDarkMode ? primaryCyan : primaryCyanDeep;
    final bgDark = const Color(0xFF0F0F0F);
    
    final scaffoldBg = isDarkMode ? bgDark : const Color(0xFFF5F7FA);
    final cardBg = isDarkMode ? Colors.white.withOpacity(0.03) : Colors.white;
    final borderColor = isDarkMode ? Colors.white.withOpacity(0.1) : dynamicCyan.withOpacity(0.2);
    final textColor = isDarkMode ? Colors.white : const Color(0xFF0F0F0F);

    return Scaffold(
      backgroundColor: scaffoldBg,
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                color: dynamicCyan,
                strokeWidth: 2,
              ),
            )
          : RefreshIndicator(
              onRefresh: _handleRefresh,
              color: dynamicCyan,
              backgroundColor: scaffoldBg,
              child: SingleChildScrollView(
                controller: _scrollController,
                physics: const AlwaysScrollableScrollPhysics(),
                child: Directionality(
                  textDirection: isRTL ? TextDirection.rtl : TextDirection.ltr,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Bio-Tech Header
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.only(
                          top: MediaQuery.of(context).padding.top + 20,
                          left: padding,
                          right: padding,
                          bottom: 20,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.transparent,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                // Profile Image with Neon Ring
                                Container(
                                  padding: const EdgeInsets.all(2),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: dynamicCyan.withOpacity(0.5),
                                      width: 1.5,
                                    ),
                                    boxShadow: [
                                      if (isDarkMode)
                                        BoxShadow(
                                          color: dynamicCyan.withOpacity(0.2),
                                          blurRadius: 10,
                                          spreadRadius: 2,
                                        ),
                                    ],
                                  ),
                                  child: CircleAvatar(
                                    radius: 25,
                                    backgroundColor: isDarkMode ? Colors.grey[900] : Colors.grey[200],
                                    backgroundImage: profileImageBase64 != null &&
                                            profileImageBase64!.isNotEmpty
                                        ? ImageUtils.imageProviderFromBase64String(
                                                profileImageBase64!)
                                        : const AssetImage(
                                            "lib/images/06a2fecd0ffb295fe3f53cba33b95b26.jpg"),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      context.translate('welcome_back'),
                                      style: GoogleFonts.orbitron(
                                        fontSize: 10,
                                        color: dynamicCyan,
                                        letterSpacing: 2,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      userName,
                                      style: GoogleFonts.orbitron(
                                        color: textColor,
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 1,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: isDarkMode ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05),
                                shape: BoxShape.circle,
                                border: Border.all(
                                    color: isDarkMode ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.1)),
                              ),
                              child: Icon(
                                Icons.notifications_none_rounded,
                                color: dynamicCyan,
                                size: 24,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Medical Card Section (Glassmorphism)
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: padding),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  context.translate('medical_card'),
                                  style: GoogleFonts.orbitron(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: textColor.withOpacity(0.9),
                                    letterSpacing: 1.5,
                                  ),
                                ),
                                Icon(Icons.qr_code_scanner_rounded,
                                    color: dynamicCyan, size: 20),
                              ],
                            ),
                            const SizedBox(height: 16),
                            _buildGlassMedicalCard(context, cardWidth,
                                cardHeight, dynamicCyan, isRTL, isDarkMode),
                          ],
                        ),
                      ),

                      const SizedBox(height: 32),

                      // Specialties (Bento Grid Style Header)
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: padding),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              context.translate('medical_specialties'),
                              style: GoogleFonts.orbitron(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: textColor.withOpacity(0.9),
                                letterSpacing: 1.5,
                              ),
                            ),
                            GestureDetector(
                              onTap: () => _navigateToRecordPage(context),
                              child: Text(
                                context.translate('see_all'),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: dynamicCyan,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      SizedBox(
                        height: 110,
                        child: ListView.builder(
                          padding: EdgeInsets.symmetric(horizontal: padding),
                          itemCount: db.Categories.length,
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          itemBuilder: (context, index) {
                            final category = db.Categories[index];
                            return _buildSpecialtyItem(category, dynamicCyan, isDarkMode, cardBg, borderColor);
                          },
                        ),
                      ),

                      const SizedBox(height: 32),

                      // Health Overview
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: padding),
                        child: Text(
                          context.translate('health_overview'),
                          style: GoogleFonts.orbitron(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: textColor.withOpacity(0.9),
                            letterSpacing: 1.5,
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      _isHealthDataLoading
                          ? Center(child: CircularProgressIndicator(color: dynamicCyan))
                          : Padding(
                              padding: EdgeInsets.symmetric(horizontal: padding),
                              child: ListView.builder(
                                physics: const NeverScrollableScrollPhysics(),
                                shrinkWrap: true,
                                padding: EdgeInsets.zero,
                                itemCount: db.Health_overview.length,
                                itemBuilder: (context, index) {
                                  String currentDescription = '';
                                  if (index < description.length) {
                                    currentDescription = description[index];
                                  }
                                  return _buildHealthCard(
                                    db.Health_overview[index],
                                    currentDescription,
                                    dynamicCyan,
                                    isDarkMode,
                                    textColor,
                                    cardBg,
                                    borderColor,
                                  );
                                },
                              ),
                            ),

                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildGlassMedicalCard(BuildContext context, double width,
      double height, Color dynamicCyan, bool isRTL, bool isDarkMode) {
    final cardGlowColor = isDarkMode ? dynamicCyan.withOpacity(0.1) : dynamicCyan.withOpacity(0.05);
    final cardBorderColor = isDarkMode ? Colors.white.withOpacity(0.1) : dynamicCyan.withOpacity(0.2);
    final cardTextColor = isDarkMode ? Colors.white : const Color(0xFF0F0F0F);

    return Container(
      width: double.infinity,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: cardBorderColor),
        color: isDarkMode ? Colors.white.withOpacity(0.03) : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDarkMode ? 0.2 : 0.05),
            blurRadius: 15,
            offset: const Offset(0, 8),
          )
        ]
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Stack(
            children: [
              Positioned(
                top: -50,
                right: -50,
                child: Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: cardGlowColor,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: dynamicCyan.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(Icons.auto_graph_rounded,
                                  color: dynamicCyan, size: 20),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              "CARDO PREMIUM",
                              style: GoogleFonts.orbitron(
                                color: cardTextColor,
                                fontSize: 14,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 2,
                              ),
                            ),
                          ],
                        ),
                        Icon(Icons.contactless_outlined,
                            color: cardTextColor.withOpacity(0.5), size: 24),
                      ],
                    ),
                    Text(
                      "4588  2100  9845  1220",
                      style: TextStyle(
                        color: cardTextColor,
                        fontSize: 22,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 4,
                        fontFamily: 'Courier',
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "HOLDER NAME",
                              style: GoogleFonts.orbitron(
                                color: cardTextColor.withOpacity(0.4),
                                fontSize: 8,
                                letterSpacing: 1.5,
                              ),
                            ),
                            Text(
                              userName.toUpperCase(),
                              style: GoogleFonts.orbitron(
                                color: cardTextColor,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: isDarkMode ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(8),
                            border:
                                Border.all(color: cardBorderColor),
                          ),
                          child: Text(
                            "VALID 12/28",
                            style: GoogleFonts.orbitron(
                                color: cardTextColor,
                                fontSize: 8,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSpecialtyItem(Map<String, dynamic> category, Color dynamicCyan, bool isDarkMode, Color cardBg, Color borderColor) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DoctorListingPage(
              specialtyFilter: category["category"],
            ),
          ),
        );
      },
      child: Container(
        width: 85,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: borderColor),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDarkMode ? 0.2 : 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ]
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: (category["color"] as Color).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: category["icon"] is String
                  ? Image.asset(
                      category["icon"],
                      width: 24,
                      height: 24,
                      color: category["color"],
                    )
                  : Icon(
                      category["icon"],
                      color: category["color"],
                      size: 24,
                    ),
            ),
            const SizedBox(height: 8),
            Text(
              context.translate(category["translation_key"]),
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                color: isDarkMode ? Colors.white.withOpacity(0.8) : const Color(0xFF0F0F0F).withOpacity(0.8),
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHealthCard(
      Map<String, dynamic> data, String desc, Color dynamicCyan, bool isDarkMode, Color textColor, Color cardBg, Color borderColor) {
    
    // Determine status color based on description
    Color statusColor = data["color"]; // Default
    if (desc.toLowerCase().contains("affected") && !desc.toLowerCase().contains("not")) {
      statusColor = Colors.redAccent;
    } else if (desc.toLowerCase().contains("not affected")) {
      statusColor = Colors.greenAccent;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => EditProfilePage()),
          ).then((value) {
            if (value == true) {
              _getUserData(); // Refresh data if updated
            }
          });
        },
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: borderColor),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDarkMode ? 0.2 : 0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              )
            ]
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: data["icon"] is String
                    ? Image.asset(
                        data["icon"],
                        width: 24,
                        height: 24,
                        color: statusColor,
                      )
                    : Icon(data["icon"], color: statusColor, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.translate(data["translation_key"]),
                      style: GoogleFonts.poppins(
                        color: textColor.withOpacity(0.5),
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      desc,
                      style: GoogleFonts.orbitron(
                        color: statusColor == data["color"] ? textColor : statusColor,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios_rounded,
                  color: textColor.withOpacity(0.2), size: 14),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToRecordPage(BuildContext context) {
    final mainPage = MainPage.of(context);
    if (mainPage != null) {
      mainPage.navigateToTab(2); // Index of RecordPage
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const RecordPage()),
      );
    }
  }

  Future<void> _handleRefresh() async {
    if (_isRefreshing) return;
    setState(() => _isRefreshing = true);
    final currentUser = _auth.currentUser;
    if (currentUser != null) {
      await Future.wait([
        _fetchUserInfo(currentUser.uid),
        _fetchMedicalInfo(currentUser.uid)
      ]);
    }
    if (mounted) setState(() => _isRefreshing = false);
  }

  Future<void> _fetchUserInfo(String uid) async {
    try {
      final userDoc = await _firestore.collection("users").doc(uid).get();
      if (userDoc.exists && userDoc.data() != null) {
        setState(() {
          userName = userDoc.data()!["fullName"] ?? "";
          profileImageBase64 = userDoc.data()!["profileImageBase64"];
        });
      }
    } catch (e) {
      debugPrint("Error: $e");
    }
  }

  Future<void> _fetchMedicalInfo(String uid) async {
    try {
      final medicalInfoDoc =
          await _firestore.collection("medical_info").doc(uid).get();
      if (medicalInfoDoc.exists && medicalInfoDoc.data() != null) {
        final medicalData = medicalInfoDoc.data()!;
        String bloodType = medicalData["bloodType"]?.toString() ?? 'Unknown';
        String diabetesStatus = medicalData["hasDiabetes"] == true ? 'Affected' : 'Not Affected';
        String asthmaStatus = medicalData["hasAsthma"] == true ? 'Affected' : 'Not Affected';
        setState(() {
          description = [bloodType, diabetesStatus, asthmaStatus];
          _isHealthDataLoading = false;
        });
      } else {
        setState(() => _isHealthDataLoading = false);
      }
    } catch (e) {
      setState(() => _isHealthDataLoading = false);
    }
  }
}

