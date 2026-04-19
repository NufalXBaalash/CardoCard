import 'package:flutter/material.dart';
import 'package:test_1/utils/ifLogin.dart';
import 'package:test_1/utils/app_theme.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:test_1/utils/app_localizations.dart';
import 'package:test_1/utils/language_provider.dart';
import 'package:provider/provider.dart';

class SplashScreen3 extends StatefulWidget {
  const SplashScreen3({super.key});

  @override
  State<SplashScreen3> createState() => _SplashScreen3State();
}

class _SplashScreen3State extends State<SplashScreen3>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeInAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    // Initialize animation controller
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    // Create fade in animation
    _fadeInAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );

    // Create slide up animation
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));

    // Start animations
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Get screen dimensions for responsive design
    final size = MediaQuery.of(context).size;
    final screenWidth = size.width;
    final screenHeight = size.height;

    // Calculate responsive dimensions
    final double imageSize = screenWidth * 0.85;
    final double horizontalPadding = screenWidth * 0.07;
    final double verticalPadding = screenHeight * 0.03;
    final double titleSize = screenWidth * 0.06;
    final double bodyTextSize = screenWidth * 0.035;
    final double buttonHeight = screenHeight * 0.065;

    // Get language direction
    final languageProvider = Provider.of<LanguageProvider>(context);
    final isRTL = languageProvider.isRTL;

    return Directionality(
      textDirection: isRTL ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(horizontalPadding, verticalPadding,
                horizontalPadding, verticalPadding),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Title section
                FadeTransition(
                  opacity: _fadeInAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: Text(
                      context.translate('splash3_title'),
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: titleSize,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                        height: 1.3,
                      ),
                    ),
                  ),
                ),

                // Image section with animation
                FadeTransition(
                  opacity: _fadeInAnimation,
                  child: Image.asset(
                    "lib/images/8371076.jpg",
                    width: imageSize,
                    height: imageSize,
                    fit: BoxFit.contain,
                  ),
                ),

                // Bottom section with description, indicators and buttons
                Column(
                  children: [
                    // Description text
                    FadeTransition(
                      opacity: _fadeInAnimation,
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                            horizontal: horizontalPadding * 0.5),
                        child: Text(
                          context.translate('splash3_description'),
                          style: GoogleFonts.poppins(
                            fontSize: bodyTextSize,
                            color: Colors.black54,
                            height: 1.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),

                    SizedBox(height: screenHeight * 0.03),

                    // Page indicators
                    FadeTransition(
                      opacity: _fadeInAnimation,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildIndicator(false),
                          SizedBox(width: 8),
                          _buildIndicator(false),
                          SizedBox(width: 8),
                          _buildIndicator(true),
                        ],
                      ),
                    ),

                    SizedBox(height: screenHeight * 0.04),

                    // Buttons
                    FadeTransition(
                      opacity: _fadeInAnimation,
                      child: Column(
                        children: [
                          // Get Started button
                          _buildPrimaryButton(
                            text: context.translate('get_started'),
                            onTap: () => Navigator.push(
                              context,
                              PageRouteBuilder(
                                pageBuilder:
                                    (context, animation, secondaryAnimation) =>
                                        const Iflogin(),
                                transitionsBuilder: (context, animation,
                                    secondaryAnimation, child) {
                                  const begin = Offset(0.0, 0.0);
                                  const end = Offset.zero;
                                  const curve = Curves.easeInOut;

                                  var scaleAnimation =
                                      Tween(begin: 0.9, end: 1.0).animate(
                                    CurvedAnimation(
                                      parent: animation,
                                      curve: curve,
                                    ),
                                  );

                                  var fadeAnimation =
                                      Tween(begin: 0.0, end: 1.0).animate(
                                    CurvedAnimation(
                                      parent: animation,
                                      curve: curve,
                                    ),
                                  );

                                  return FadeTransition(
                                    opacity: fadeAnimation,
                                    child: ScaleTransition(
                                      scale: scaleAnimation,
                                      child: child,
                                    ),
                                  );
                                },
                                transitionDuration:
                                    const Duration(milliseconds: 500),
                              ),
                            ),
                            buttonHeight: buttonHeight,
                            isPrimary: true,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Helper method to build page indicators
  Widget _buildIndicator(bool isActive) {
    return Container(
      width: isActive ? 24 : 8,
      height: 8,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color:
            isActive ? const Color(0xff5680DC) : Colors.grey.withValues(alpha: 0.3),
        boxShadow: isActive
            ? [
                BoxShadow(
                  color: const Color(0xff5680DC).withValues(alpha: 0.3),
                  blurRadius: 4,
                  offset: Offset(0, 2),
                )
              ]
            : null,
      ),
    );
  }

  // Helper method to build primary buttons
  Widget _buildPrimaryButton({
    required String text,
    required VoidCallback onTap,
    required double buttonHeight,
    bool isPrimary = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: buttonHeight,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(buttonHeight / 2),
          color: const Color(0xff5680DC),
          boxShadow: [
            BoxShadow(
              color: const Color(0xff5680DC).withValues(alpha: 0.4),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Center(
          child: Text(
            text,
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}
