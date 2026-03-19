import 'package:flutter/material.dart';
import 'package:test_1/database/DB.dart';
import 'package:test_1/pages/chatbot_page.dart';
import 'package:test_1/pages/speciality_page.dart';
import 'package:provider/provider.dart';
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

  // Handle speciality page navigation
  void _navigateToSpecialtyPage(
      BuildContext context, Map<String, dynamic> specialty) {
    final languageProvider =
        Provider.of<LanguageProvider>(context, listen: false);
    final isRTL = languageProvider.isRTL;

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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

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
        floatingActionButton: Padding(
          padding: const EdgeInsets.only(bottom: 80.0, right: 0.0),
          child: FloatingActionButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ChatbotPage()),
              );
            },
            child: Icon(Icons.person_4),
          ),
        ),
        backgroundColor: colorScheme.background,
        appBar: AppBar(
          title: Text(
            context.translate('medical_records'),
            style: TextStyle(
              fontSize: headerFontSize * 1.2,
              fontWeight: FontWeight.w600,
              color: colorScheme.onBackground,
            ),
          ),
          centerTitle: true,
          elevation: 0,
          backgroundColor: colorScheme.background,
          foregroundColor: colorScheme.onBackground,
          surfaceTintColor: colorScheme.background,
          iconTheme: IconThemeData(
            color: colorScheme.onBackground,
          ),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
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

                // Header Card
                Container(
                  height: cardHeight,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: isDarkMode
                        ? colorScheme.surface
                        : AppTheme.cardoLightBlue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDarkMode
                          ? Colors.grey[800]!
                          : AppTheme.cardoBlue.withOpacity(0.3),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: isDarkMode
                            ? Colors.black.withOpacity(0.3)
                            : Colors.grey.withOpacity(0.1),
                        spreadRadius: 1,
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(0),
                    child: isRTL
                        ? Stack(
                            children: [
                              // Image
                              Positioned(
                                left: -screenWidth * 0.05,
                                bottom: -screenWidth * 0.05,
                                child: Opacity(
                                  opacity: 0.7,
                                  child: Image.asset(
                                    "lib/images/doctor.png",
                                    width: screenWidth * 0.4,
                                    height: screenWidth * 0.4,
                                    fit: BoxFit.contain,
                                    color: isDarkMode
                                        ? Colors.white.withOpacity(0.8)
                                        : null,
                                    colorBlendMode:
                                        isDarkMode ? BlendMode.modulate : null,
                                  ),
                                ),
                              ),

                              // Icon at top right
                              Positioned(
                                top: 10,
                                right: 10,
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: isDarkMode
                                        ? AppTheme.cardoBlue.withOpacity(0.4)
                                        : AppTheme.cardoBlue.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    Icons.medical_services_rounded,
                                    color: AppTheme.cardoBlue,
                                    size: iconSize,
                                  ),
                                ),
                              ),

                              // Text - aligned at far right
                              Align(
                                alignment: Alignment.centerRight,
                                child: Padding(
                                  padding: EdgeInsets.only(
                                    right: 10,
                                    left: screenWidth * 0.4,
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        context
                                            .translate('your_health_records'),
                                        style: TextStyle(
                                          fontSize: headerFontSize * 1.1,
                                          fontWeight: FontWeight.w700,
                                          color: colorScheme.onBackground,
                                        ),
                                        textAlign: TextAlign.right,
                                      ),
                                      SizedBox(height: screenHeight * 0.01),
                                      Text(
                                        context.translate(
                                            'select_specialty_access'),
                                        style: TextStyle(
                                          fontSize: headerFontSize * 0.6,
                                          color: isDarkMode
                                              ? Colors.grey[400]
                                              : Colors.grey[700],
                                          height: 1.4,
                                        ),
                                        textAlign: TextAlign.right,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          )
                        : Stack(
                            children: [
                              // Image on right side
                              Positioned(
                                bottom: -screenWidth * 0.05,
                                right: -screenWidth * 0.05,
                                child: Opacity(
                                  opacity: 0.7,
                                  child: Image.asset(
                                    "lib/images/doctor.png",
                                    width: screenWidth * 0.4,
                                    height: screenWidth * 0.4,
                                    fit: BoxFit.contain,
                                    color: isDarkMode
                                        ? Colors.white.withOpacity(0.8)
                                        : null,
                                    colorBlendMode:
                                        isDarkMode ? BlendMode.modulate : null,
                                  ),
                                ),
                              ),

                              // Icon at top left
                              Positioned(
                                top: gridPadding,
                                left: gridPadding,
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: isDarkMode
                                        ? AppTheme.cardoBlue.withOpacity(0.4)
                                        : AppTheme.cardoBlue.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    Icons.medical_services_rounded,
                                    color: AppTheme.cardoBlue,
                                    size: iconSize,
                                  ),
                                ),
                              ),

                              // Text content on left side
                              Positioned(
                                top: 0,
                                bottom: 0,
                                left: gridPadding * 1.5,
                                width: screenWidth * 0.6,
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      context.translate('your_health_records'),
                                      style: TextStyle(
                                        fontSize: headerFontSize * 1.1,
                                        fontWeight: FontWeight.w700,
                                        color: colorScheme.onBackground,
                                      ),
                                      textAlign: TextAlign.left,
                                    ),
                                    SizedBox(height: screenHeight * 0.01),
                                    Text(
                                      context
                                          .translate('select_specialty_access'),
                                      style: TextStyle(
                                        fontSize: headerFontSize * 0.6,
                                        color: isDarkMode
                                            ? Colors.grey[400]
                                            : Colors.grey[700],
                                        height: 1.4,
                                      ),
                                      textAlign: TextAlign.left,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
                SizedBox(height: gridPadding * 1.5),

                // Categories Title
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: gridPadding * 0.8,
                    vertical: gridPadding * 0.5,
                  ),
                  child: Row(
                    mainAxisAlignment:
                        isRTL ? MainAxisAlignment.end : MainAxisAlignment.start,
                    children: [
                      if (!isRTL)
                        Icon(
                          Icons.medical_services_outlined,
                          size: headerFontSize * 1.1,
                          color: AppTheme.cardoBlue,
                        ),
                      if (!isRTL) SizedBox(width: 8),
                      Text(
                        context.translate('specialties'),
                        style: TextStyle(
                          fontSize: headerFontSize * 1.1,
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onBackground,
                        ),
                        textAlign: isRTL ? TextAlign.right : TextAlign.left,
                      ),
                      if (isRTL) SizedBox(width: 8),
                      if (isRTL)
                        Icon(
                          Icons.medical_services_outlined,
                          size: headerFontSize * 1.1,
                          color: AppTheme.cardoBlue,
                        ),
                    ],
                  ),
                ),
                SizedBox(height: gridPadding * 0.5),

                // Grid View
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: isPortrait
                        ? (screenWidth > 600 ? 3 : 2)
                        : (screenWidth > 900 ? 4 : 3),
                    childAspectRatio: 1,
                    mainAxisSpacing: gridPadding,
                    crossAxisSpacing: gridPadding,
                  ),
                  itemCount: db.prescribingSpecialties.length,
                  itemBuilder: (context, index) {
                    final specialty = db.prescribingSpecialties[index];
                    return Material(
                      color: colorScheme.surface,
                      borderRadius: BorderRadius.circular(12),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () =>
                            _navigateToSpecialtyPage(context, specialty),
                        highlightColor: AppTheme.cardoBlue
                            .withOpacity(isDarkMode ? 0.1 : 0.3),
                        splashColor: AppTheme.cardoBlue.withOpacity(0.2),
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: isDarkMode
                                  ? Colors.grey[800]!
                                  : Colors.grey.withOpacity(0.1),
                              width: 1,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: iconSize * 1.8,
                                height: iconSize * 1.8,
                                decoration: BoxDecoration(
                                  color: isDarkMode
                                      ? colorScheme.background
                                      : AppTheme.cardoLightBlue
                                          .withOpacity(0.2),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  specialty["icon"],
                                  color: AppTheme.cardoBlue,
                                  size: iconSize,
                                ),
                              ),
                              SizedBox(height: screenHeight * 0.012),
                              Padding(
                                padding: EdgeInsets.symmetric(
                                    horizontal: gridPadding * 0.5),
                                child: Text(
                                  context.translate(
                                      specialty["translation_key"] ??
                                          specialty["name"]),
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: headerFontSize * 0.85,
                                    fontWeight: FontWeight.w500,
                                    color: colorScheme.onSurface,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
                SizedBox(height: gridPadding * 2),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
