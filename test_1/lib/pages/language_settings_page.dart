import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:test_1/utils/language_provider.dart';
import 'package:test_1/utils/app_localizations.dart';
import 'package:test_1/utils/theme_provider.dart';

class LanguageSettingsPage extends StatefulWidget {
  const LanguageSettingsPage({Key? key}) : super(key: key);

  @override
  State<LanguageSettingsPage> createState() => _LanguageSettingsPageState();
}

class _LanguageSettingsPageState extends State<LanguageSettingsPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    // Initialize animation controller
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 600),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOut,
      ),
    );

    // Start animation
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    final colorScheme = Theme.of(context).colorScheme;

    // Get screen dimensions
    final screenSize = MediaQuery.of(context).size;
    final screenWidth = screenSize.width;

    return Directionality(
      // Use the appropriate text direction
      textDirection: languageProvider.textDirection,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            context.translate('choose_language'),
            style: GoogleFonts.lexend(
              fontSize: screenWidth * 0.045,
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
          backgroundColor: colorScheme.surface,
          surfaceTintColor: Colors.transparent,
          elevation: 2,
          shadowColor: Colors.black12,
          centerTitle: true,
          leading: IconButton(
            icon: Icon(
                languageProvider.isRTL ? Icons.arrow_forward : Icons.arrow_back,
                color: colorScheme.onSurface),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        backgroundColor: colorScheme.surface,
        body: FadeTransition(
          opacity: _fadeAnimation,
          child: SingleChildScrollView(
            padding: EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Auto-detect option
                _buildSectionTitle(context.translate('language'), context),
                SizedBox(height: 16),

                _buildSettingCard(
                  child: SwitchListTile(
                    title: Text(
                      context.translate('auto_detect'),
                      style: GoogleFonts.lexend(
                        fontSize: screenWidth * 0.04,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    subtitle: Text(
                      languageProvider.isAutoDetect
                          ? languageProvider.isArabic
                              ? context.translate('arabic')
                              : context.translate('english')
                          : context.translate('auto_detect'),
                      style: GoogleFonts.lexend(
                        fontSize: screenWidth * 0.035,
                        color: colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                    value: languageProvider.isAutoDetect,
                    activeColor: colorScheme.primary,
                    onChanged: (value) async {
                      await languageProvider.setAutoDetect(value);
                    },
                    secondary: Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: colorScheme.primaryContainer.withValues(alpha: 0.3),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.language,
                        color: colorScheme.primary,
                      ),
                    ),
                  ),
                ),

                SizedBox(height: 32),

                // Manual language selection
                Text(
                  context.translate('choose_language'),
                  style: GoogleFonts.lexend(
                    fontSize: screenWidth * 0.04,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),

                SizedBox(height: 16),

                // English option
                _buildLanguageOption(
                  title: context.translate('english'),
                  languageCode: LanguageProvider.ENGLISH,
                  icon: Icons.language,
                  selected: !languageProvider.isAutoDetect &&
                      languageProvider.currentLanguage ==
                          LanguageProvider.ENGLISH,
                  onTap: () async {
                    await languageProvider
                        .setLanguage(LanguageProvider.ENGLISH);
                  },
                ),

                SizedBox(height: 12),

                // Arabic option
                _buildLanguageOption(
                  title: context.translate('arabic'),
                  languageCode: LanguageProvider.ARABIC,
                  icon: Icons.language,
                  selected: !languageProvider.isAutoDetect &&
                      languageProvider.currentLanguage ==
                          LanguageProvider.ARABIC,
                  onTap: () async {
                    await languageProvider.setLanguage(LanguageProvider.ARABIC);
                  },
                ),

                SizedBox(height: 40),

                // Information text
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: colorScheme.primary.withValues(alpha: 0.2),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: colorScheme.primary,
                            size: 20,
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              context.translate('auto_detect_description') ??
                                  "When auto-detect is enabled, the app will determine your language based on your device settings and location:",
                              style: GoogleFonts.lexend(
                                fontSize: screenWidth * 0.035,
                                fontWeight: FontWeight.w500,
                                color:
                                    colorScheme.onSurface.withValues(alpha: 0.9),
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 12),
                      Padding(
                        padding: EdgeInsets.only(left: 32),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildBulletPoint(
                              "Arabic will be used in Arabic-speaking countries (Saudi Arabia, UAE, Egypt, etc.)",
                              screenWidth,
                              colorScheme,
                            ),
                            SizedBox(height: 6),
                            _buildBulletPoint(
                              "English will be used in all other countries",
                              screenWidth,
                              colorScheme,
                            ),
                            SizedBox(height: 6),
                            _buildBulletPoint(
                              "Your device language settings will be considered",
                              screenWidth,
                              colorScheme,
                            ),
                            SizedBox(height: 6),
                            _buildBulletPoint(
                              "Location access allows for accurate language selection",
                              screenWidth,
                              colorScheme,
                            ),
                          ],
                        ),
                      ),
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

  Widget _buildSectionTitle(String title, BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final screenWidth = MediaQuery.of(context).size.width;

    return Text(
      title,
      style: GoogleFonts.lexend(
        fontSize: screenWidth * 0.04,
        fontWeight: FontWeight.bold,
        color: colorScheme.onSurface,
      ),
    );
  }

  Widget _buildSettingCard({required Widget child}) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            spreadRadius: 0,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildLanguageOption({
    required String title,
    required String languageCode,
    required IconData icon,
    required bool selected,
    required VoidCallback onTap,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final screenWidth = MediaQuery.of(context).size.width;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        decoration: BoxDecoration(
          color: selected
              ? colorScheme.primary.withValues(alpha: 0.1)
              : colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected
                ? colorScheme.primary
                : colorScheme.outline.withValues(alpha: 0.3),
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            // Flag icon
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 4,
                    spreadRadius: 0,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: Icon(
                  icon,
                  color: colorScheme.primary,
                  size: 20,
                ),
              ),
            ),
            SizedBox(width: 16),

            // Language text
            Text(
              title,
              style: GoogleFonts.lexend(
                fontSize: screenWidth * 0.04,
                fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                color: colorScheme.onSurface,
              ),
            ),

            Spacer(),

            // Selected indicator
            if (selected)
              Container(
                padding: EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: colorScheme.primary,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check,
                  color: Colors.white,
                  size: 16,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBulletPoint(
      String text, double screenWidth, ColorScheme colorScheme) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: EdgeInsets.only(top: 8),
          width: 4,
          height: 4,
          decoration: BoxDecoration(
            color: colorScheme.onSurface.withValues(alpha: 0.7),
            shape: BoxShape.circle,
          ),
        ),
        SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.lexend(
              fontSize: screenWidth * 0.033,
              color: colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
        ),
      ],
    );
  }
}

