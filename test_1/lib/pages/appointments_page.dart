import 'dart:ui';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:test_1/utils/theme_provider.dart';
import 'package:test_1/utils/language_provider.dart';
import 'package:test_1/utils/app_localizations.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:test_1/pages/doctor_listing_page.dart';

class AppointmentsPage extends StatefulWidget {
  const AppointmentsPage({super.key});

  @override
  State<AppointmentsPage> createState() => _AppointmentsPageState();
}

class _AppointmentsPageState extends State<AppointmentsPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String userName = '';
  String? profileImageBase64;
  bool _isLoading = true;

  final List<Map<String, dynamic>> _specialties = [
    {'name': 'Neurologist', 'icon': Icons.psychology, 'color': Color(0xFF4FC3F7), 'key': 'neurology'},
    {'name': 'Cardiologist', 'icon': Icons.favorite, 'color': Color(0xFFFF5252), 'key': 'cardiologist'},
    {'name': 'Orthopedist', 'icon': Icons.accessibility_new, 'color': Color(0xFFFFB74D), 'key': 'orthopedics'},
    {'name': 'Pulmonologist', 'icon': Icons.air, 'color': Color(0xFF9575CD), 'key': 'pulmonology'},
    {'name': 'Dentist', 'icon': Icons.face, 'color': Color(0xFF81C784), 'key': 'dentistry'},
    {'name': 'Pediatrician', 'icon': Icons.child_care, 'color': Color(0xFFFFD54F), 'key': 'pediatrician'},
  ];

  @override
  void initState() {
    super.initState();
    _getUserData();
  }

  Future<void> _getUserData() async {
    try {
      User? currentUser = _auth.currentUser;
      if (currentUser != null) {
        final userDoc = await _firestore.collection('users').doc(currentUser.uid).get();
        if (userDoc.exists) {
          setState(() {
            userName = userDoc.data()?['fullName'] ?? 'User';
            profileImageBase64 = userDoc.data()?['profileImageBase64'];
          });
        }
      }
    } catch (e) {
      debugPrint('Error fetching user data: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    
    // Theme aware colors
    final biotechCyan = const Color(0xFF00E5FF);
    final biotechCyanDeep = const Color(0xFF00B8D4); // WCAG-compliant for Light Mode
    final dynamicCyan = isDarkMode ? biotechCyan : biotechCyanDeep;
    
    final scaffoldBg = isDarkMode ? const Color(0xFF0F0F0F) : const Color(0xFFF5F7FA);
    final cardBg = isDarkMode ? Colors.white.withOpacity(0.03) : Colors.white;
    final textColor = isDarkMode ? Colors.white : const Color(0xFF0F0F0F);
    final subTextColor = isDarkMode ? Colors.white70 : Colors.black87;
    final borderColor = isDarkMode ? Colors.white.withOpacity(0.1) : dynamicCyan.withOpacity(0.2);

    return Scaffold(
      backgroundColor: scaffoldBg,
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: dynamicCyan))
          : Stack(
              children: [
                // Background Glow (Subtle)
                Positioned(
                  top: -50,
                  left: -50,
                  child: Container(
                    width: 250,
                    height: 250,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: dynamicCyan.withOpacity(isDarkMode ? 0.05 : 0.08),
                    ),
                  ),
                ),
                SafeArea(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHeader(dynamicCyan, textColor, subTextColor, isDarkMode),
                        const SizedBox(height: 25),
                        _buildSearchBar(dynamicCyan, cardBg, borderColor, isDarkMode),
                        const SizedBox(height: 30),
                        _buildSectionTitle(context.translate('specialties').toUpperCase(), dynamicCyan, textColor),
                        const SizedBox(height: 15),
                        _buildSpecialtiesGrid(dynamicCyan, cardBg, borderColor, textColor, isDarkMode),
                        const SizedBox(height: 35),
                        _buildSectionTitle(context.translate('upcoming_appointment').toUpperCase(), dynamicCyan, textColor),
                        const SizedBox(height: 15),
                        _buildGlassAppointmentCard(dynamicCyan, isDarkMode, textColor, subTextColor),
                        const SizedBox(height: 35),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildSectionTitle(context.translate('top_specialists').toUpperCase(), dynamicCyan, textColor),
                            TextButton(
                              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const DoctorListingPage())),
                              child: Text(context.translate('see_all').toUpperCase(), 
                                style: GoogleFonts.orbitron(color: dynamicCyan, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        _buildRecentDoctorsScroll(dynamicCyan, cardBg, borderColor, textColor, subTextColor, isDarkMode),
                        const SizedBox(height: 100),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildHeader(Color primary, Color text, Color subText, bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('BIO-ID SYSTEM ACTIVE', 
              style: GoogleFonts.orbitron(
                color: primary.withOpacity(0.8), 
                fontSize: 10, 
                letterSpacing: 2,
                fontWeight: FontWeight.bold
              )
            ),
            const SizedBox(height: 4),
            Text(userName.toUpperCase(), 
              style: GoogleFonts.orbitron(
                color: text, 
                fontSize: 22, 
                fontWeight: FontWeight.bold,
                letterSpacing: 1
              )
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: primary.withOpacity(0.5), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: primary.withOpacity(0.2), 
                blurRadius: 15,
                spreadRadius: 2
              )
            ],
          ),
          child: CircleAvatar(
            radius: 28,
            backgroundColor: isDark ? Colors.grey[900] : Colors.white,
            backgroundImage: profileImageBase64 != null && profileImageBase64!.isNotEmpty
              ? MemoryImage(base64Decode(profileImageBase64!)) 
              : const AssetImage("lib/images/06a2fecd0ffb295fe3f53cba33b95b26.jpg") as ImageProvider,
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBar(Color primary, Color bg, Color border, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: TextField(
        style: GoogleFonts.poppins(color: isDark ? Colors.white : Colors.black, fontSize: 14),
        decoration: InputDecoration(
          hintText: 'SEARCH CLINIC OR DOCTOR...',
          hintStyle: GoogleFonts.orbitron(
            color: isDark ? Colors.white24 : Colors.black26, 
            fontSize: 10, 
            letterSpacing: 1.5
          ),
          prefixIcon: Icon(Icons.search_rounded, color: primary, size: 22),
          suffixIcon: Icon(Icons.tune_rounded, color: primary.withOpacity(0.6), size: 20),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, Color primary, Color text) {
    return Row(
      children: [
        Container(
          width: 4, 
          height: 18, 
          decoration: BoxDecoration(
            color: primary,
            borderRadius: BorderRadius.circular(2),
            boxShadow: [BoxShadow(color: primary.withOpacity(0.5), blurRadius: 8)]
          ),
        ),
        const SizedBox(width: 12),
        Text(title, style: GoogleFonts.orbitron(color: text, fontSize: 13, fontWeight: FontWeight.w800, letterSpacing: 1.5)),
      ],
    );
  }

  Widget _buildSpecialtiesGrid(Color primary, Color bg, Color border, Color text, bool isDark) {
    return SizedBox(
      height: 120,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: _specialties.length,
        itemBuilder: (context, index) {
          final s = _specialties[index];
          return Container(
            width: 100,
            margin: const EdgeInsets.only(right: 15, bottom: 5),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: border),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isDark ? 0.2 : 0.03),
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
                    color: (s['color'] as Color).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(s['icon'], color: s['color'], size: 26),
                ),
                const SizedBox(height: 10),
                Text(
                  context.translate(s['key']).toUpperCase(), 
                  textAlign: TextAlign.center,
                  style: GoogleFonts.orbitron(
                    fontSize: 8, 
                    color: text.withOpacity(0.8), 
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5
                  )
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildGlassAppointmentCard(Color primary, bool isDark, Color text, Color subText) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark 
            ? [primary.withOpacity(0.15), primary.withOpacity(0.05)]
            : [primary.withOpacity(0.1), Colors.white],
        ),
        border: Border.all(color: primary.withOpacity(0.3), width: 1),
        boxShadow: [
          BoxShadow(
            color: primary.withOpacity(0.1),
            blurRadius: 25,
            spreadRadius: -5,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 60, height: 60,
                      decoration: BoxDecoration(
                        color: primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: primary.withOpacity(0.2)),
                      ),
                      child: Icon(Icons.medical_information_rounded, color: primary, size: 30),
                    ),
                    const SizedBox(width: 18),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('DR. JENNIFER SMITH', 
                            style: GoogleFonts.orbitron(
                              color: text, 
                              fontWeight: FontWeight.bold, 
                              fontSize: 16,
                              letterSpacing: 0.5
                            )
                          ),
                          const SizedBox(height: 4),
                          Text('ORTHOPEDIC SPECIALIST', 
                            style: GoogleFonts.poppins(
                              color: isDark ? primary.withOpacity(0.8) : primary,
                              fontSize: 11, 
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1
                            )
                          ),
                        ],
                      ),
                    ),
                    _buildPulseIndicator(primary),
                  ],
                ),
                const SizedBox(height: 25),
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.black.withOpacity(0.2) : Colors.white.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: primary.withOpacity(0.1)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildIconInfo(Icons.calendar_today_rounded, '07 SEP', primary, text),
                      Container(width: 1, height: 24, color: primary.withOpacity(0.2)),
                      _buildIconInfo(Icons.access_time_filled_rounded, '10:30 AM', primary, text),
                      Container(width: 1, height: 24, color: primary.withOpacity(0.2)),
                      _buildIconInfo(Icons.location_on_rounded, 'UNIT-4', primary, text),
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

  Widget _buildPulseIndicator(Color primary) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: primary.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6, height: 6,
            decoration: BoxDecoration(color: primary, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text('LIVE', style: GoogleFonts.orbitron(color: primary, fontSize: 9, fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }

  Widget _buildIconInfo(IconData icon, String text, Color primary, Color textColor) {
    return Column(
      children: [
        Icon(icon, color: primary, size: 20),
        const SizedBox(height: 6),
        Text(text, style: GoogleFonts.orbitron(color: textColor, fontSize: 10, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildRecentDoctorsScroll(Color primary, Color bg, Color border, Color text, Color subText, bool isDark) {
    return SizedBox(
      height: 200,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: 4,
        itemBuilder: (context, index) {
          return Container(
            width: 280,
            margin: const EdgeInsets.only(right: 18, bottom: 10, top: 5),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: border),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: primary.withOpacity(0.3)),
                        ),
                        child: CircleAvatar(
                          radius: 24,
                          backgroundColor: primary.withOpacity(0.05),
                          child: Icon(Icons.person_rounded, color: primary, size: 28)
                        ),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('DR. ALEX WARNER', 
                              style: GoogleFonts.orbitron(
                                color: text, 
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                letterSpacing: 0.5
                              )
                            ),
                            Text('NEUROLOGY • 12Y EXP', 
                              style: GoogleFonts.poppins(
                                color: isDark ? primary.withOpacity(0.7) : primary,
                                fontSize: 10,
                                fontWeight: FontWeight.w700
                              )
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 45,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            gradient: LinearGradient(colors: [primary, primary.withOpacity(0.8)]),
                            boxShadow: [BoxShadow(color: primary.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4))]
                          ),
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                            onPressed: () {},
                            child: Text('INITIATE SCHEDULE', 
                              style: GoogleFonts.orbitron(
                                fontSize: 10, 
                                color: Colors.black,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1
                              )
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        width: 45, height: 45,
                        decoration: BoxDecoration(
                          color: primary.withOpacity(0.1),
                          border: Border.all(color: primary.withOpacity(0.2)), 
                          borderRadius: BorderRadius.circular(14)
                        ),
                        child: Icon(Icons.message_rounded, color: primary, size: 20),
                      )
                    ],
                  )
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
