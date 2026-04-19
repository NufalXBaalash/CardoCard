import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:test_1/database/DB.dart';
import 'package:test_1/pages/chatbot_page.dart';
import 'package:test_1/pages/speciality_page.dart';
import 'package:test_1/utils/theme_provider.dart';
import 'package:test_1/utils/language_provider.dart';
import 'package:test_1/utils/app_localizations.dart';

class RecordPage extends StatefulWidget {
  const RecordPage({super.key});

  @override
  State<RecordPage> createState() => _RecordPageState();
}

class _RecordPageState extends State<RecordPage> {
  Specializations_DB db = Specializations_DB();

  // Bio-Tech Colors
  static const Color biotechBlack = Color(0xFF0F0F0F);
  static const Color biotechCyan = Color(0xFF00E5FF);
  static const Color biotechCyanDeep = Color(0xFF00B8D4);

  // Handle speciality page navigation
  void _navigateToSpecialtyPage(
      BuildContext context, Map<String, dynamic> specialty) {
    // Get the translated specialty name using the translation key
    final translatedSpecialtyName =
        context.translate(specialty["translation_key"] ?? specialty["name"]);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SpecialityPage(
          specialtyName: translatedSpecialtyName,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;

    final primaryCyan = isDarkMode ? biotechCyan : biotechCyanDeep;
    final backgroundColor = isDarkMode ? biotechBlack : const Color(0xFFF5F7FA);
    final cardColor = isDarkMode ? Colors.white.withOpacity(0.03) : Colors.white.withOpacity(0.7);
    final headerTextColor = isDarkMode ? Colors.white : biotechBlack;
    final subTextColor = isDarkMode ? Colors.white70 : Colors.black54;
    final appBarColor = isDarkMode ? biotechBlack.withOpacity(0.5) : Colors.white.withOpacity(0.5);
    
    // Get RTL information
    final languageProvider = Provider.of<LanguageProvider>(context);
    final isRTL = languageProvider.isRTL;

    final mediaQuery = MediaQuery.of(context);
    final screenWidth = mediaQuery.size.width;
    final screenHeight = mediaQuery.size.height;
    final isPortrait = mediaQuery.orientation == Orientation.portrait;

    final headerFontSize = screenWidth * 0.045;
    final cardHeight = isPortrait ? screenHeight * 0.22 : screenHeight * 0.28;
    final gridPadding = screenWidth * 0.03;
    final iconSize = screenWidth * 0.07;

    return Directionality(
      textDirection: isRTL ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: backgroundColor,
        extendBodyBehindAppBar: true,
        floatingActionButton: Padding(
          padding: const EdgeInsets.only(bottom: 80.0),
          child: FloatingActionButton(
            backgroundColor: primaryCyan,
            elevation: 10,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ChatbotPage()),
              );
            },
            child: Icon(Icons.psychology_outlined, color: isDarkMode ? biotechBlack : Colors.white, size: 30),
          ),
        ),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          flexibleSpace: ClipRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(color: appBarColor),
            ),
          ),
          title: Text(
            context.translate('medical_records').toUpperCase(),
            style: GoogleFonts.orbitron(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: primaryCyan,
              letterSpacing: 2,
            ),
          ),
          centerTitle: true,
        ),
        body: SafeArea(
          child: Stack(
            children: [
              // Background Glows
              Positioned(
                top: -50,
                left: -50,
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: biotechCyan.withOpacity(isDarkMode ? 0.05 : 0.1),
                  ),
                ),
              ),
              SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.symmetric(
                  horizontal: gridPadding * 1.5,
                  vertical: gridPadding * 0.5,
                ),
                child: Column(
                  crossAxisAlignment:
                      isRTL ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: gridPadding * 0.5),

                    // Bio-ID / Health Record Header Card
                    _buildGlassHeader(screenWidth, cardHeight, isRTL, iconSize, headerFontSize, isDarkMode, cardColor, headerTextColor, subTextColor, primaryCyan),

                    SizedBox(height: gridPadding * 2),

                    // Categories Title
                    _buildSectionTitle(context, headerFontSize, isRTL, headerTextColor, primaryCyan),

                    SizedBox(height: gridPadding),

                    // Bento Grid View
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: isPortrait
                            ? (screenWidth > 600 ? 3 : 2)
                            : (screenWidth > 900 ? 4 : 3),
                        childAspectRatio: 0.9,
                        mainAxisSpacing: gridPadding,
                        crossAxisSpacing: gridPadding,
                      ),
                      itemCount: db.prescribingSpecialties.length,
                      itemBuilder: (context, index) {
                        final specialty = db.prescribingSpecialties[index];
                        return _buildSpecialtyCard(context, specialty, iconSize, headerFontSize, isDarkMode, cardColor, headerTextColor, primaryCyan);
                      },
                    ),
                    SizedBox(height: gridPadding * 5),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGlassHeader(double screenWidth, double cardHeight, bool isRTL, double iconSize, double headerFontSize, bool isDarkMode, Color cardColor, Color headerTextColor, Color subTextColor, Color primaryCyan) {
    return Container(
      height: cardHeight,
      width: double.infinity,
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: primaryCyan.withOpacity(isDarkMode ? 0.2 : 0.4),
          width: 1.5,
        ),
        boxShadow: isDarkMode ? [] : [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 8),
          )
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Stack(
            children: [
              // Tech Pattern Overlay
              Positioned.fill(
                child: Opacity(
                  opacity: isDarkMode ? 0.05 : 0.02,
                  child: Image.network(
                    'https://www.transparenttextures.com/patterns/carbon-fibre.png',
                    repeat: ImageRepeat.repeat,
                    color: isDarkMode ? null : Colors.black,
                  ),
                ),
              ),
              
              // Decorative Icon
              Positioned(
                top: 20,
                right: isRTL ? null : 20,
                left: isRTL ? 20 : null,
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: primaryCyan.withOpacity(0.1),
                    shape: BoxShape.circle,
                    border: Border.all(color: primaryCyan.withOpacity(0.3)),
                  ),
                  child: Icon(
                    Icons.fingerprint,
                    color: primaryCyan,
                    size: iconSize * 1.2,
                  ),
                ),
              ),

              // Content
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: isRTL ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                  children: [
                    Text(
                      'BIO-DATA ACCESS',
                      style: GoogleFonts.orbitron(
                        fontSize: 12,
                        color: primaryCyan,
                        letterSpacing: 2,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      context.translate('your_health_records').toUpperCase(),
                      style: GoogleFonts.orbitron(
                        fontSize: headerFontSize * 1.1,
                        fontWeight: FontWeight.w800,
                        color: headerTextColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      context.translate('select_specialty_access'),
                      style: GoogleFonts.poppins(
                        fontSize: headerFontSize * 0.65,
                        color: subTextColor,
                      ),
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

  Widget _buildSectionTitle(BuildContext context, double headerFontSize, bool isRTL, Color headerTextColor, Color primaryCyan) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 20,
          decoration: BoxDecoration(
            color: primaryCyan,
            borderRadius: BorderRadius.circular(2),
            boxShadow: [
              BoxShadow(color: primaryCyan.withOpacity(0.5), blurRadius: 8)
            ],
          ),
        ),
        const SizedBox(width: 12),
        Text(
          context.translate('specialties').toUpperCase(),
          style: GoogleFonts.orbitron(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: headerTextColor,
            letterSpacing: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildSpecialtyCard(BuildContext context, Map<String, dynamic> specialty, double iconSize, double headerFontSize, bool isDarkMode, Color cardColor, Color headerTextColor, Color primaryCyan) {
    return GestureDetector(
      onTap: () => _navigateToSpecialtyPage(context, specialty),
      child: Container(
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: primaryCyan.withOpacity(isDarkMode ? 0.1 : 0.3),
            width: 1,
          ),
          boxShadow: isDarkMode ? [] : [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: iconSize * 2,
                  height: iconSize * 2,
                  decoration: BoxDecoration(
                    color: primaryCyan.withOpacity(0.05),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: primaryCyan.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: Icon(
                    specialty["icon"],
                    color: primaryCyan,
                    size: iconSize,
                  ),
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Text(
                    context.translate(specialty["translation_key"] ?? specialty["name"]).toUpperCase(),
                    textAlign: TextAlign.center,
                    style: GoogleFonts.orbitron(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: headerTextColor,
                      letterSpacing: 0.5,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
