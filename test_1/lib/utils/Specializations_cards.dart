import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:test_1/utils/theme_provider.dart';
import 'package:test_1/utils/app_localizations.dart';
import 'package:test_1/utils/language_provider.dart';

class SpecializationsCards extends StatefulWidget {
  final String category;
  final IconData icon;
  final Color color;
  final String? translationKey;

  const SpecializationsCards({
    super.key,
    required this.category,
    required this.icon,
    required this.color,
    this.translationKey,
  });

  @override
  State<SpecializationsCards> createState() => _SpecializationsCardsState();
}

class _SpecializationsCardsState extends State<SpecializationsCards>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    // Initialize animation controller for hover/touch effect
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Get theme provider
    final themeProvider = Provider.of<ThemeProvider>(context);
    final languageProvider = Provider.of<LanguageProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    final isRTL = languageProvider.isRTL;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Get screen size
    final Size screenSize = MediaQuery.of(context).size;
    // Calculate responsive sizes
    final double cardWidth = screenSize.width * 0.16;
    final double iconSize = cardWidth * 0.55; // Slightly larger icon

    // Adjust font size for Arabic (larger for better readability)
    final double fontSize = isRTL
        ? screenSize.width * 0.029
        : screenSize.width * 0.025; // Responsive font size

    // Translate the category text using the AppLocalizations and use translationKey if available
    final String translatedCategory = widget.translationKey != null
        ? context.translate(widget.translationKey!)
        : context.translate(widget.category.toLowerCase());

    return LayoutBuilder(
      builder: (context, constraints) {
        // Use LayoutBuilder to get more accurate constraints
        return GestureDetector(
          onTapDown: (_) => _controller.forward(),
          onTapUp: (_) => _controller.reverse(),
          onTapCancel: () => _controller.reverse(),
          child: AnimatedBuilder(
            animation: _scaleAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _scaleAnimation.value,
                child: Container(
                  margin: EdgeInsets.symmetric(
                    horizontal: screenSize.width * 0.01,
                    vertical: screenSize.width * 0.005,
                  ),
                  padding: EdgeInsets.zero,
                  width: cardWidth,
                  // Optimize card height for Arabic text
                  height: isRTL ? cardWidth * 1.55 : cardWidth * 1.4,
                  decoration: BoxDecoration(
                    color: isDarkMode
                        ? colorScheme.surface
                        : const Color.fromARGB(255, 243, 243, 243),
                    borderRadius: BorderRadius.circular(
                        screenSize.width * 0.04), // Responsive border radius
                    boxShadow: [
                      BoxShadow(
                        color:
                            widget.color.withValues(alpha: isDarkMode ? 0.2 : 0.15),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Icon container
                      Container(
                        height: cardWidth,
                        width: cardWidth,
                        decoration: BoxDecoration(
                          color:
                              widget.color.withValues(alpha: isDarkMode ? 0.9 : 1.0),
                          borderRadius:
                              BorderRadius.circular(screenSize.width * 0.04),
                        ),
                        child: Center(
                          child: Icon(
                            widget.icon,
                            size: iconSize,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      // Optimized space between icon and text for Arabic
                      SizedBox(
                          height: isRTL
                              ? screenSize.height * 0.014
                              : screenSize.height * 0.01),
                      // Text with optimized rendering for Arabic
                      Padding(
                        padding: EdgeInsets.symmetric(
                            horizontal: isRTL
                                ? screenSize.width * 0.0045
                                : screenSize.width * 0.01),
                        child: Text(
                          translatedCategory,
                          textAlign: TextAlign.center,
                          overflow: TextOverflow.ellipsis,
                          maxLines: 2,
                          style: TextStyle(
                            fontSize: fontSize < 12 ? 12 : fontSize,
                            fontWeight: FontWeight.bold,
                            height: isRTL
                                ? 1.3
                                : 1.15, // Improved line height for Arabic
                            letterSpacing:
                                isRTL ? 0 : 0.2, // No letter spacing for Arabic
                            color: isDarkMode
                                ? colorScheme.onSurface
                                : Colors.black87,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
