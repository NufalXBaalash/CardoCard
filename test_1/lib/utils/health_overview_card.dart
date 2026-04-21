import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:test_1/utils/theme_provider.dart';
import 'package:test_1/utils/app_localizations.dart';
import 'package:test_1/utils/language_provider.dart';

class HealthOverviewCard extends StatefulWidget {
  final String title;
  final IconData icon;
  final String description;
  final Color color;
  final Color status_color;
  final String? translationKey;

  const HealthOverviewCard({
    super.key,
    required this.title,
    required this.icon,
    required this.description,
    required this.color,
    required this.status_color,
    this.translationKey,
  });

  @override
  State<HealthOverviewCard> createState() => _HealthOverviewCardState();
}

class _HealthOverviewCardState extends State<HealthOverviewCard>
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

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.01).animate(
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
    final themeProvider = Provider.of<ThemeProvider>(context);
    final languageProvider = Provider.of<LanguageProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    final isRTL = languageProvider.isRTL;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final Size screenSize = MediaQuery.of(context).size;
    final double screenWidth = screenSize.width;
    final double screenHeight = screenSize.height;

    // Calculate responsive sizes
    final double cardHeight = screenHeight * 0.08;
    final double iconSize = screenWidth * 0.075;
    final double iconContainerSize = screenWidth * 0.12;
    final double verticalPadding = screenHeight * 0.01;
    final double spacing = screenWidth * 0.04;

    // Text sizes - optimized for Arabic
    final double titleTextSize =
        isRTL ? screenWidth * 0.042 : screenWidth * 0.04;
    final double statusTextSize =
        isRTL ? screenWidth * 0.034 : screenWidth * 0.032;

    // Translate title and status texts
    final String translatedTitle = widget.translationKey != null
        ? context.translate(widget.translationKey!)
        : context.translate(widget.title.toLowerCase());
    final bool isBloodType = widget.title.toLowerCase() == "blood type";

    // Get the appropriate status label
    final String statusLabel = isBloodType
        ? context.translate('blood_type_label')
        : context.translate('status_label');

    // For the description, we may need to translate specific values depending on the context
    // This ensures values like "A+" or specific medical values are properly translated if needed
    final String translatedDescription =
        context.translate(widget.description.toLowerCase());

    return Padding(
      padding: EdgeInsets.only(
        bottom: verticalPadding,
      ),
      child: GestureDetector(
        onTapDown: (_) => _controller.forward(),
        onTapUp: (_) => _controller.reverse(),
        onTapCancel: () => _controller.reverse(),
        child: AnimatedBuilder(
          animation: _scaleAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: Container(
                width: double.infinity,
                height: cardHeight,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: isDarkMode
                      ? colorScheme.surface
                      : AppTheme.cardoLightGrey,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDarkMode ? 0.1 : 0.08),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                      horizontal:
                          isRTL ? screenWidth * 0.015 : screenWidth * 0.02),
                  child: Row(
                    children: [
                      SizedBox(width: spacing * (isRTL ? 0.3 : 0.5)),
                      Container(
                        width: iconContainerSize,
                        height: iconContainerSize,
                        decoration: BoxDecoration(
                          borderRadius:
                              BorderRadius.circular(screenWidth * 0.022),
                          color: isDarkMode
                              ? widget.color.withValues(alpha: 0.8)
                              : widget.color,
                          boxShadow: [
                            BoxShadow(
                              color: widget.color.withValues(alpha: 0.3),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Icon(
                            widget.icon,
                            size: iconSize,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      SizedBox(width: spacing),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              translatedTitle,
                              style: TextStyle(
                                fontSize: titleTextSize,
                                fontWeight: FontWeight.bold,
                                height: isRTL
                                    ? 1.2
                                    : 1.1, // Better line height for Arabic
                                color: colorScheme.onSurface,
                              ),
                            ),
                            SizedBox(height: isRTL ? 5 : 4),
                            Row(
                              children: [
                                Text(
                                  statusLabel,
                                  style: TextStyle(
                                    fontSize: statusTextSize,
                                    fontWeight: FontWeight.w400,
                                    color: isDarkMode
                                        ? Colors.grey[400]
                                        : Colors.grey[600],
                                  ),
                                ),
                                Text(
                                  translatedDescription,
                                  style: TextStyle(
                                    fontSize: statusTextSize,
                                    fontWeight: FontWeight.w600,
                                    color: isDarkMode
                                        ? widget.status_color.withValues(alpha: 0.9)
                                        : widget.status_color,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: screenWidth * 0.08,
                        child: IconButton(
                          onPressed: () {},
                          icon: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isDarkMode
                                  ? Colors.grey.withValues(alpha: 0.2)
                                  : Colors.grey.withValues(alpha: 0.1),
                            ),
                            child: Icon(
                              languageProvider.isRTL
                                  ? Icons.arrow_back_ios_rounded
                                  : Icons.arrow_forward_ios_rounded,
                              color: isDarkMode
                                  ? Colors.grey[400]
                                  : AppTheme.cardoBlue.withValues(alpha: 0.7),
                              size: screenWidth * 0.035,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: isRTL ? spacing * 0.1 : spacing * 0.2),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
