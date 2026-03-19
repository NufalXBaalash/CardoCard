import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:test_1/database/DB.dart';
import 'package:test_1/pages/record_page.dart';
import 'package:test_1/utils/Specializations_cards.dart';
import 'package:test_1/utils/health_overview_card.dart';
import 'package:test_1/utils/theme_provider.dart';
import 'package:test_1/utils/app_theme.dart';
import 'package:test_1/utils/image_utils.dart';
// import 'package:liquid_pull_to_refresh/liquid_pull_to_refresh.dart';
import 'package:test_1/utils/language_provider.dart';
import 'package:test_1/utils/app_localizations.dart';
import 'dart:math' as math;

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
        // Fetch user basic info
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
          } else {
            print("User document does not exist for ID: ${currentUser.uid}");
          }
        } catch (e) {
          print("Error fetching user profile data: $e");
        }

        // Main page content can now be shown
        setState(() {
          _isLoading = false;
        });

        // Fetch medical info from medical_info table
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

              // Format diabetes status properly
              String diabetesStatus = 'Unknown';
              if (medicalData["hasDiabetes"] != null) {
                diabetesStatus = medicalData["hasDiabetes"] == true
                    ? 'Affected'
                    : 'Not Affected';
              }

              // Format asthma status properly
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
            print(
                "Medical info document does not exist for ID: ${currentUser.uid}");
            setState(() {
              _isHealthDataLoading = false;
            });
          }
        } catch (e) {
          print("Error fetching medical info data: $e");
          setState(() {
            _isHealthDataLoading = false;
          });
        }
      } else {
        print("No user is currently signed in");
        setState(() {
          _isLoading = false;
          _isHealthDataLoading = false;
        });
      }
    } catch (e) {
      print("Error in _getUserData: $e");
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

    // Get language direction
    final languageProvider = Provider.of<LanguageProvider>(context);
    final isRTL = languageProvider.isRTL;

    final screenSize = MediaQuery.of(context).size;
    final screenWidth = screenSize.width;
    final screenHeight = screenSize.height;

    // Responsive sizing factors
    final double headerHeight = screenHeight * 0.20;
    final double cardHeight = screenHeight * 0.22;
    final double cardWidth = screenWidth * 0.9;
    final double padding = screenWidth * 0.05;
    final double smallPadding = screenWidth * 0.02;

    // Text sizes
    final double largeTextSize = screenWidth * 0.055;
    final double mediumTextSize = screenWidth * 0.045;
    final double smallTextSize = screenWidth * 0.035;

    // Updated colors for better visual appeal
    final primaryColor = AppTheme.cardoBlue;
    final refreshBgColor = isDarkMode
        ? Color.fromARGB(255, 25, 55, 95)
        : Color.fromARGB(255, 231, 242, 255);

    return Scaffold(
      backgroundColor: colorScheme.background,
      extendBodyBehindAppBar: true,
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    color: primaryColor,
                    strokeWidth: 3,
                  ),
                  SizedBox(height: 16),
                  Text(
                    "Loading your data...",
                    style: TextStyle(
                      color: colorScheme.onBackground.withOpacity(0.7),
                      fontSize: smallTextSize,
                    ),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: _handleRefresh,
              color: primaryColor,
              backgroundColor: refreshBgColor,
              strokeWidth: 2.5,
              displacement: 40,
              child: SingleChildScrollView(
                controller: _scrollController,
                physics: const AlwaysScrollableScrollPhysics(),
                child: Directionality(
                  textDirection: isRTL ? TextDirection.rtl : TextDirection.ltr,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Container that extends under status bar
                      Container(
                        width: double.infinity,
                        height:
                            headerHeight + MediaQuery.of(context).padding.top,
                        padding: EdgeInsets.only(
                            top: MediaQuery.of(context).padding.top),
                        decoration: BoxDecoration(
                          color: AppTheme.cardoBlue,
                          borderRadius: const BorderRadius.only(
                            bottomLeft: Radius.circular(25),
                            bottomRight: Radius.circular(25),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black
                                  .withOpacity(isDarkMode ? 0.4 : 0.2),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: padding,
                            vertical: smallPadding,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(height: screenHeight * 0.015),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  // Profile and User info
                                  Row(
                                    children: [
                                      // Profile Image with border - Optimized
                                      Container(
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: Colors.white,
                                            width: 2,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color:
                                                  Colors.black.withOpacity(0.2),
                                              blurRadius: 6,
                                              offset: const Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                              screenWidth * 0.1),
                                          child: profileImageBase64 != null &&
                                                  profileImageBase64!.isNotEmpty
                                              ? ImageUtils
                                                  .imageFromBase64String(
                                                  profileImageBase64!,
                                                  width: screenWidth * 0.12,
                                                  height: screenWidth * 0.12,
                                                  fit: BoxFit.cover,
                                                  errorWidget: Image.asset(
                                                    "lib/images/06a2fecd0ffb295fe3f53cba33b95b26.jpg",
                                                    width: screenWidth * 0.12,
                                                    height: screenWidth * 0.12,
                                                    fit: BoxFit.cover,
                                                  ),
                                                )
                                              : Image.asset(
                                                  "lib/images/06a2fecd0ffb295fe3f53cba33b95b26.jpg",
                                                  width: screenWidth * 0.12,
                                                  height: screenWidth * 0.12,
                                                  fit: BoxFit.cover,
                                                ),
                                        ),
                                      ),
                                      SizedBox(width: screenWidth * 0.03),
                                      // User info with improved typography
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            context.translate('welcome_back'),
                                            style: TextStyle(
                                              fontSize: smallTextSize,
                                              color:
                                                  Colors.white.withOpacity(0.9),
                                              fontWeight: FontWeight.w400,
                                            ),
                                          ),
                                          SizedBox(height: 2),
                                          Text(
                                            userName,
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: mediumTextSize,
                                              fontWeight: FontWeight.bold,
                                              letterSpacing: 0.3,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  // Notification Icon with badge
                                  Stack(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.2),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          Icons.notifications_none_rounded,
                                          size: screenWidth * 0.07,
                                          color: Colors.white,
                                        ),
                                      ),
                                      Positioned(
                                        right: 8,
                                        top: 8,
                                        child: Container(
                                          width: 10,
                                          height: 10,
                                          decoration: BoxDecoration(
                                            color: Colors.redAccent,
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: AppTheme.cardoBlue,
                                              width: 1.5,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),

                              SizedBox(height: screenHeight * 0.02),

                              // Search Box with improved styling
                              Container(
                                margin: EdgeInsets.only(
                                    bottom: screenHeight * 0.01),
                                padding: EdgeInsets.symmetric(
                                  horizontal: screenWidth * 0.02,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: isDarkMode
                                      ? Colors.black.withOpacity(0.2)
                                      : Colors.white,
                                  borderRadius: BorderRadius.circular(15),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      blurRadius: 8,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                                alignment: Alignment.center,
                                child: TextField(
                                  style: TextStyle(
                                    fontSize: smallTextSize,
                                    color: isDarkMode
                                        ? Colors.white
                                        : Colors.black87,
                                  ),
                                  decoration: InputDecoration(
                                    fillColor: Colors.transparent,
                                    hoverColor: Colors.transparent,
                                    hintText: "Search for doctors, records...",
                                    hintStyle: TextStyle(
                                      color: isDarkMode
                                          ? Colors.white70
                                          : Colors.grey[500],
                                      fontSize: smallTextSize * 0.9,
                                    ),
                                    border: InputBorder.none,
                                    prefixIcon: Icon(
                                      Icons.search_rounded,
                                      size: screenWidth * 0.05,
                                      color: isDarkMode
                                          ? Colors.white70
                                          : AppTheme.cardoBlue.withOpacity(0.7),
                                    ),
                                    suffixIcon: IconButton(
                                      onPressed: () {},
                                      icon: Icon(
                                        Icons.mic_rounded,
                                        size: screenWidth * 0.05,
                                        color: isDarkMode
                                            ? Colors.white70
                                            : AppTheme.cardoBlue
                                                .withOpacity(0.7),
                                      ),
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(
                                        vertical: 12),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      SizedBox(height: screenHeight * 0.025),

                      // Medical Card Section - Enhanced with better styling
                      Padding(
                        padding:
                            EdgeInsets.symmetric(horizontal: padding * 0.8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              context.translate('medical_card'),
                              style: TextStyle(
                                fontSize: mediumTextSize,
                                fontWeight: FontWeight.bold,
                                color: colorScheme.onBackground,
                              ),
                            ),

                            SizedBox(height: screenHeight * 0.015),

                            // Enhanced Card with better performance
                            RepaintBoundary(
                              child: _buildMedicalCard(context, cardWidth,
                                  cardHeight, isDarkMode, colorScheme),
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: screenHeight * 0.025),

                      // Specializations Section with improved UI
                      Padding(
                        padding:
                            EdgeInsets.symmetric(horizontal: padding * 0.8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  context.translate('medical_specialties'),
                                  style: TextStyle(
                                    fontSize: mediumTextSize,
                                    fontWeight: FontWeight.bold,
                                    color: colorScheme.onBackground,
                                  ),
                                ),
                                TextButton(
                                  onPressed: () =>
                                      _navigateToRecordPage(context),
                                  style: TextButton.styleFrom(
                                    foregroundColor: AppTheme.cardoBlue,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 4),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        context.translate('see_all'),
                                        style: TextStyle(
                                          fontSize: smallTextSize,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      const Icon(
                                          Icons.arrow_forward_ios_rounded,
                                          size: 12),
                                    ],
                                  ),
                                ),
                              ],
                            ),

                            SizedBox(height: screenHeight * 0.015),

                            // Use RepaintBoundary around the ListView for performance
                            RepaintBoundary(
                              child: SizedBox(
                                height: screenHeight * 0.13,
                                child: ListView.builder(
                                  padding: EdgeInsets.only(
                                    right: isRTL ? padding * 0.5 : padding,
                                    left: isRTL ? padding * 0.5 : 0,
                                  ),
                                  itemCount: db.Categories.length,
                                  scrollDirection: Axis.horizontal,
                                  physics: const BouncingScrollPhysics(),
                                  itemBuilder: (context, index) {
                                    final category = db.Categories[index];
                                    return SpecializationsCards(
                                      category: category["category"],
                                      icon: category["icon"],
                                      color: category["color"],
                                      translationKey:
                                          category["translation_key"],
                                    );
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: screenHeight * 0.025),

                      // Health Overview Section - Optimized
                      Padding(
                        padding: EdgeInsets.symmetric(
                            horizontal: isRTL ? padding * 0.7 : padding * 0.8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  context.translate('health_overview'),
                                  style: TextStyle(
                                    fontSize: mediumTextSize,
                                    fontWeight: FontWeight.bold,
                                    color: colorScheme.onBackground,
                                  ),
                                ),
                                IconButton(
                                  onPressed: () =>
                                      _navigateToRecordPage(context),
                                  icon: Icon(
                                    Icons.more_horiz_rounded,
                                    color: AppTheme.cardoBlue,
                                    size: 24,
                                  ),
                                  style: IconButton.styleFrom(
                                    padding: EdgeInsets.zero,
                                    minimumSize: const Size(40, 40),
                                  ),
                                ),
                              ],
                            ),

                            SizedBox(height: screenHeight * 0.001),

                            // Health cards - Optimized
                            _isHealthDataLoading
                                ? Center(
                                    child: Padding(
                                      padding:
                                          EdgeInsets.symmetric(vertical: 20),
                                      child: CircularProgressIndicator(
                                        color: AppTheme.cardoBlue,
                                        strokeWidth: 3,
                                      ),
                                    ),
                                  )
                                : description.every((item) => item == 'Unknown')
                                    ? _buildNoMedicalDataView(
                                        context, colorScheme)
                                    : RepaintBoundary(
                                        child: ListView.builder(
                                          physics:
                                              const NeverScrollableScrollPhysics(),
                                          shrinkWrap: true,
                                          itemCount: db.Health_overview.length,
                                          itemBuilder: (context, index) {
                                            // Ensure we don't go out of bounds with the description array
                                            String currentDescription = '';
                                            if (index < description.length) {
                                              currentDescription =
                                                  description[index];
                                            }

                                            return HealthOverviewCard(
                                              title: db.Health_overview[index]
                                                  ["title"],
                                              description: currentDescription,
                                              icon: db.Health_overview[index]
                                                  ["icon"],
                                              status_color:
                                                  db.Health_overview[index]
                                                      ["status_color"],
                                              color: db.Health_overview[index]
                                                  ["color"],
                                              translationKey:
                                                  db.Health_overview[index]
                                                      ["translation_key"],
                                            );
                                          },
                                        ),
                                      ),

                            // Bottom padding for scroll comfort
                            SizedBox(height: screenHeight * 0.03),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  void _navigateToRecordPage(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const RecordPage()),
    );
  }

  // Simplified refresh method
  Future<void> _handleRefresh() async {
    if (_isRefreshing) return;

    setState(() {
      _isRefreshing = true;
    });

    try {
      // Fetch data
      final currentUser = _auth.currentUser;
      if (currentUser != null) {
        // Fetch user basic info and medical info in parallel
        await Future.wait([
          _fetchUserInfo(currentUser.uid),
          _fetchMedicalInfo(currentUser.uid)
        ]);
      }
    } catch (e) {
      print("Error in refresh: $e");
    } finally {
      // Always make sure to reset the refreshing state
      if (mounted) {
        setState(() {
          _isRefreshing = false;
        });
      }
    }
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
      print("Error fetching user profile: $e");
    }
  }

  Future<void> _fetchMedicalInfo(String uid) async {
    try {
      final medicalInfoDoc =
          await _firestore.collection("medical_info").doc(uid).get();
      if (medicalInfoDoc.exists && medicalInfoDoc.data() != null) {
        final medicalData = medicalInfoDoc.data()!;

        String bloodType = medicalData["bloodType"]?.toString() ?? 'Unknown';

        String diabetesStatus = 'Unknown';
        if (medicalData["hasDiabetes"] != null) {
          diabetesStatus =
              medicalData["hasDiabetes"] == true ? 'Affected' : 'Not Affected';
        }

        String asthmaStatus = 'Unknown';
        if (medicalData["hasAsthma"] != null) {
          asthmaStatus =
              medicalData["hasAsthma"] == true ? 'Affected' : 'Not Affected';
        }

        setState(() {
          description = [bloodType, diabetesStatus, asthmaStatus];
          _isHealthDataLoading = false;
        });
      } else {
        setState(() {
          _isHealthDataLoading = false;
        });
      }
    } catch (e) {
      print("Error fetching medical data: $e");
      setState(() {
        _isHealthDataLoading = false;
      });
    }
  }

  Widget _buildMedicalCard(BuildContext context, double cardWidth,
      double cardHeight, bool isDarkMode, ColorScheme colorScheme) {
    final mediumTextSize = MediaQuery.of(context).size.width * 0.04;
    final smallTextSize = MediaQuery.of(context).size.width * 0.035;

    // Get language direction
    final languageProvider = Provider.of<LanguageProvider>(context);
    final isRTL = languageProvider.isRTL;

    // Use the imported AppTheme from theme_provider.dart for card colors
    final cardColors = [
      AppTheme.cardoBlue,
      AppTheme.cardoCardBlue,
      AppTheme.cardoLightBlue,
    ];

    return Container(
      width: double.infinity,
      height: cardHeight,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: isRTL ? Alignment.topRight : Alignment.topLeft,
          end: isRTL ? Alignment.bottomLeft : Alignment.bottomRight,
          colors: cardColors,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.cardoBlue.withOpacity(isDarkMode ? 0.4 : 0.3),
            spreadRadius: 0,
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Decorative circles with glass effect - adjusted for RTL
          Positioned(
            left: isRTL ? -cardWidth * 0.1 : cardWidth * 0.7,
            right: isRTL ? cardWidth * 0.7 : null,
            top: -cardHeight * 0.1,
            child: Container(
              width: cardWidth * 0.3,
              height: cardWidth * 0.3,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(cardWidth * 0.3),
                color: Colors.white.withOpacity(0.15),
              ),
            ),
          ),
          Positioned(
            left: isRTL ? cardWidth * 0.7 : -cardWidth * 0.1,
            right: isRTL ? -cardWidth * 0.1 : null,
            bottom: -cardHeight * 0.15,
            child: Container(
              width: cardWidth * 0.35,
              height: cardWidth * 0.35,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(cardWidth * 0.35),
                color: Colors.white.withOpacity(0.1),
              ),
            ),
          ),

          // Content container with better spacing and RTL support
          Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment:
                  isRTL ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Image.asset(
                          "lib/images/icons8-heartbeat-90.png",
                          width: 24,
                          height: 24,
                          color: Colors.white,
                        ),
                        SizedBox(width: 8),
                        Text(
                          "CardoCard",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: mediumTextSize * 0.9,
                            fontWeight: FontWeight.bold,
                            letterSpacing: isRTL ? 0 : 0.5,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Icon(
                          Icons.nfc_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                        SizedBox(width: 4),
                        Text(
                          "NFC",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: smallTextSize,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Divider(
                    color: Colors.white.withOpacity(0.3),
                    thickness: 1,
                  ),
                ),
                const Spacer(),

                // Card number with improved spacing and RTL support
                Text(
                  "1234 5678 9012 3456",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: mediumTextSize,
                    fontWeight: FontWeight.w600,
                    letterSpacing: isRTL ? 0 : 1.2,
                  ),
                  textDirection:
                      TextDirection.ltr, // Always LTR for card numbers
                ),
                SizedBox(height: 8),

                // Patient name row with RTL support
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      userName.isNotEmpty
                          ? userName
                          : context.translate('no_name'),
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: isRTL ? smallTextSize * 1.1 : smallTextSize,
                        fontWeight: FontWeight.w500,
                        height: isRTL ? 1.2 : 1.0,
                      ),
                    ),
                    Text(
                      context.translate('member'),
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: smallTextSize * 0.8,
                        fontWeight: FontWeight.w500,
                        letterSpacing: isRTL ? 0 : 1,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoMedicalDataView(
      BuildContext context, ColorScheme colorScheme) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 15),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.cardoBlue.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.medical_information_outlined,
              size: 48,
              color: AppTheme.cardoBlue,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            context.translate('no_medical_data'),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            context.translate('no_medical_data_message'),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.arrow_upward,
                size: 18,
                color: AppTheme.cardoBlue,
              ),
              SizedBox(width: 8),
              Text(
                context.translate('pull_to_refresh'),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.cardoBlue,
                ),
              ),
              SizedBox(width: 8),
              Icon(
                Icons.arrow_downward,
                size: 18,
                color: AppTheme.cardoBlue,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
