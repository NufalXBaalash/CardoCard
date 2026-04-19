import 'dart:ui';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:test_1/pages/profile_image_page.dart';
import 'package:test_1/utils/theme_provider.dart';
import 'package:test_1/utils/app_localizations.dart';
import 'package:test_1/utils/language_provider.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage>
    with SingleTickerProviderStateMixin {
  // Bio-Tech Colors
  static const Color biotechBlack = Color(0xFF0F0F0F);
  static const Color biotechCyan = Color(0xFF00E5FF);

  // Controllers and hint texts
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  String fullNameHint = "";
  String emailHint = "";
  String passwordHint = "";
  String phoneNumberHint = "";
  String confirmPasswordHint = "";

  String _selectedRole = 'Patient'; // Default to Patient
  bool isRegistering = false; // Track registration state

  // Track which field has focus for keyboard adjustments
  final FocusNode _fullNameFocus = FocusNode();
  final FocusNode _emailFocus = FocusNode();
  final FocusNode _passwordFocus = FocusNode();
  final FocusNode _confirmPasswordFocus = FocusNode();

  // Current active focus node
  FocusNode? _activeFocusNode;

  // Animation controller for form elements
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // ScrollController to handle scrolling to focused fields
  final ScrollController _scrollController = ScrollController();

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
        curve: Interval(0.0, 0.65, curve: Curves.easeOut),
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: Offset(0, 0.1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Interval(0.0, 0.65, curve: Curves.easeOut),
      ),
    );

    // Start animations immediately
    _animationController.forward();

    // Setup focus listeners to track current field
    _fullNameFocus.addListener(() {
      if (_fullNameFocus.hasFocus) {
        setState(() => _activeFocusNode = _fullNameFocus);
        _scrollToFocusedField(70);
      }
    });

    _emailFocus.addListener(() {
      if (_emailFocus.hasFocus) {
        setState(() => _activeFocusNode = _emailFocus);
        _scrollToFocusedField(120);
      }
    });

    _passwordFocus.addListener(() {
      if (_passwordFocus.hasFocus) {
        setState(() => _activeFocusNode = _passwordFocus);
        _scrollToFocusedField(170);
      }
    });

    _confirmPasswordFocus.addListener(() {
      if (_confirmPasswordFocus.hasFocus) {
        setState(() => _activeFocusNode = _confirmPasswordFocus);
        _scrollToFocusedField(220);
      }
    });

    // Initialize hint texts
    fullNameHint = "Please enter your full name";
    emailHint = "Please enter your email";
    passwordHint = "Please enter your password";
    phoneNumberHint = "Please enter your phone number";
    confirmPasswordHint = "Please confirm your password";
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Update hints with localized values after dependencies (context) is available
    _updateDefaultHints();
  }

  void _updateDefaultHints() {
    if (mounted) {
      setState(() {
        fullNameHint = context.translate('please_enter_full_name');
        emailHint = context.translate('please_enter_email');
        passwordHint = context.translate('please_enter_password');
        phoneNumberHint = context.translate('please_enter_phone');
        confirmPasswordHint = context.translate('please_confirm_password');
      });
    }
  }

  // Scroll to the focused field when keyboard appears
  void _scrollToFocusedField(double offset) {
    Future.delayed(Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          offset,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future signUp() async {
    // Don't attempt signup if already processing
    if (isRegistering) return;

    // Basic validation
    if (_fullNameController.text.trim().isEmpty) {
      setState(() {
        fullNameHint = context.translate('name_empty_error');
      });
      return;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      setState(() {
        confirmPasswordHint = context.translate('passwords_dont_match');
      });
      return;
    }

    if (_passwordController.text.length < 6) {
      setState(() {
        _passwordController.clear();
        passwordHint = context.translate('password_too_short');
      });
      return;
    }

    // Show loading state
    setState(() {
      isRegistering = true;
    });

    try {
      // Email format validation
      final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
      if (!emailRegex.hasMatch(_emailController.text.trim())) {
        setState(() {
          emailHint = context.translate('invalid_email_format');
          isRegistering = false;
        });
        return;
      }

      // Navigate to profile image upload page with the collected data
      if (mounted) {
        Navigator.push(
          context,
          PageRouteBuilder(
            transitionDuration: Duration(milliseconds: 500),
            pageBuilder: (context, animation, secondaryAnimation) =>
                ProfileImagePage(
              fullName: _fullNameController.text.trim(),
              email: _emailController.text.trim(),
              password: _passwordController.text,
              role: _selectedRole,
            ),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
              var begin = Offset(1.0, 0.0);
              var end = Offset.zero;
              var curve = Curves.easeInOut;
              var tween =
                  Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
              var offsetAnimation = animation.drive(tween);
              return SlideTransition(position: offsetAnimation, child: child);
            },
          ),
        );
      }
    } catch (e) {
      // Handle any other errors
      print("Error during sign up: $e");
      setState(() {
        emailHint = context.translate('general_error');
        isRegistering = false;
      });
    } finally {
      // Reset loading state
      if (mounted) {
        setState(() {
          isRegistering = false;
        });
      }
    }
  }

  @override
  void dispose() {
    // Dispose controllers and focus nodes to prevent memory leaks
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();

    _fullNameFocus.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    _confirmPasswordFocus.dispose();

    _scrollController.dispose();
    _animationController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Get theme data
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    
    final backgroundColor = isDarkMode ? biotechBlack : const Color(0xFFF5F7FA);
    final cardColor = isDarkMode ? Colors.white.withOpacity(0.03) : Colors.white.withOpacity(0.7);
    final onSurfaceColor = isDarkMode ? Colors.white : biotechBlack;
    final subTextColor = isDarkMode ? Colors.white70 : Colors.black54;

    // Get language provider and direction
    final languageProvider = Provider.of<LanguageProvider>(context);
    final isRTL = languageProvider.isRTL;

    // Get screen dimensions
    final screenSize = MediaQuery.of(context).size;
    final screenHeight = screenSize.height;
    final screenWidth = screenSize.width;

    // Get keyboard height when visible
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    final isKeyboardVisible = keyboardHeight > 0;

    // Scale factor for smaller screens
    final scaleFactor = screenHeight < 700 ? 0.8 : 1.0;

    return Directionality(
      textDirection: isRTL ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        resizeToAvoidBottomInset: false, // Prevent scrolling with keyboard
        backgroundColor: backgroundColor,
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(isRTL ? Icons.arrow_forward : Icons.arrow_back,
                color: onSurfaceColor),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: GestureDetector(
          // Dismiss keyboard when tapping outside input fields
          onTap: () => FocusScope.of(context).unfocus(),
          child: SafeArea(
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
                  controller: _scrollController,
                  // Always enable scrolling for text input accessibility
                  physics: AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.only(
                      bottom: keyboardHeight > 0 ? keyboardHeight : 20),
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.05),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header section with visibility based on keyboard
                        AnimatedContainer(
                          duration: Duration(milliseconds: 300),
                          curve: Curves.easeOut,
                          height: isKeyboardVisible ? 65 : null,
                          child: Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SizedBox(
                                    height: isKeyboardVisible
                                        ? 5
                                        : screenHeight * 0.02 * scaleFactor),
                                // Animated title
                                TweenAnimationBuilder<double>(
                                  tween: Tween<double>(begin: 0.0, end: 1.0),
                                  duration: Duration(milliseconds: 800),
                                  curve: Curves.easeOutQuad,
                                  builder: (context, value, child) {
                                    return Opacity(
                                      opacity: value,
                                      child: Transform.translate(
                                        offset: Offset(0, 20 * (1 - value)),
                                        child: child,
                                      ),
                                    );
                                  },
                                  child: Text(
                                    context.translate('create_account').toUpperCase(),
                                    style: GoogleFonts.orbitron(
                                      fontSize: isKeyboardVisible
                                          ? screenWidth * 0.06
                                          : screenWidth * 0.08,
                                      fontWeight: FontWeight.bold,
                                      color: biotechCyan,
                                      letterSpacing: 2,
                                    ),
                                  ),
                                ),
                                if (!isKeyboardVisible)
                                  Column(
                                    children: [
                                      SizedBox(
                                          height:
                                              screenHeight * 0.015 * scaleFactor),
                                      // Animated subtitle
                                      TweenAnimationBuilder<double>(
                                        tween: Tween<double>(begin: 0.0, end: 1.0),
                                        duration: Duration(milliseconds: 1000),
                                        curve: Curves.easeOutCubic,
                                        builder: (context, value, child) {
                                          return Opacity(
                                            opacity: value,
                                            child: child,
                                          );
                                        },
                                        child: Text(
                                          context.translate('register_step_1'),
                                          textAlign: TextAlign.center,
                                          style: GoogleFonts.poppins(
                                            fontSize: screenWidth * 0.035,
                                            color: subTextColor,
                                          ),
                                        ),
                                      ),
                                      // Step indicator
                                      SizedBox(
                                          height:
                                              screenHeight * 0.03 * scaleFactor),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          _buildStepIndicator(1, true, isDarkMode),
                                          _buildStepDivider(false, isDarkMode),
                                          _buildStepIndicator(
                                              2, false, isDarkMode),
                                          _buildStepDivider(false, isDarkMode),
                                          _buildStepIndicator(
                                              3, false, isDarkMode),
                                        ],
                                      ),
                                      SizedBox(
                                          height:
                                              screenHeight * 0.04 * scaleFactor),
                                    ],
                                  )
                                else
                                  SizedBox(height: 5),
                              ],
                            ),
                          ),
                        ),

                        // Form section with staggered animations
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            // Full name field
                            _buildAnimatedFormField(
                              label: context.translate('full_name'),
                              controller: _fullNameController,
                              focusNode: _fullNameFocus,
                              hintText: fullNameHint,
                              errorText: fullNameHint ==
                                      context.translate('name_empty_error')
                                  ? fullNameHint
                                  : null,
                              onChanged: (value) {
                                if (fullNameHint ==
                                    context.translate('name_empty_error')) {
                                  setState(() {
                                    fullNameHint =
                                        context.translate('please_enter_full_name');
                                  });
                                }
                              },
                              textInputAction: TextInputAction.next,
                              onEditingComplete: () =>
                                  FocusScope.of(context).requestFocus(_emailFocus),
                              context: context,
                              index: 0,
                            ),

                            // Email field
                            _buildAnimatedFormField(
                              label: context.translate('email'),
                              controller: _emailController,
                              focusNode: _emailFocus,
                              hintText: emailHint,
                              errorText: emailHint ==
                                          context
                                              .translate('invalid_email_format') ||
                                      emailHint ==
                                          context.translate('email_in_use') ||
                                      emailHint ==
                                          context.translate('registration_error') ||
                                      emailHint ==
                                          context.translate('general_error')
                                  ? emailHint
                                  : null,
                              keyboardType: TextInputType.emailAddress,
                              onChanged: (value) {
                                if (emailHint ==
                                        context.translate('invalid_email_format') ||
                                    emailHint ==
                                        context.translate('email_in_use') ||
                                    emailHint ==
                                        context.translate('registration_error') ||
                                    emailHint ==
                                        context.translate('general_error')) {
                                  setState(() {
                                    emailHint =
                                        context.translate('please_enter_email');
                                  });
                                }
                              },
                              textInputAction: TextInputAction.next,
                              onEditingComplete: () => FocusScope.of(context)
                                  .requestFocus(_passwordFocus),
                              context: context,
                              index: 1,
                            ),

                            // Password field
                            _buildAnimatedFormField(
                              label: context.translate('password'),
                              controller: _passwordController,
                              focusNode: _passwordFocus,
                              hintText: passwordHint,
                              errorText: passwordHint ==
                                          context.translate('password_too_short') ||
                                      passwordHint ==
                                          context.translate('password_too_weak')
                                  ? passwordHint
                                  : null,
                              obscureText: true,
                              onChanged: (value) {
                                if (passwordHint ==
                                        context.translate('password_too_short') ||
                                    passwordHint ==
                                        context.translate('password_too_weak')) {
                                  setState(() {
                                    passwordHint =
                                        context.translate('please_enter_password');
                                  });
                                }
                              },
                              textInputAction: TextInputAction.next,
                              onEditingComplete: () => FocusScope.of(context)
                                  .requestFocus(_confirmPasswordFocus),
                              context: context,
                              index: 2,
                            ),

                            // Confirm password field
                            _buildAnimatedFormField(
                              label: context.translate('confirm_password'),
                              controller: _confirmPasswordController,
                              focusNode: _confirmPasswordFocus,
                              hintText: confirmPasswordHint,
                              errorText: confirmPasswordHint ==
                                      context.translate('passwords_dont_match')
                                  ? confirmPasswordHint
                                  : null,
                              obscureText: true,
                              onChanged: (value) {
                                if (confirmPasswordHint ==
                                    context.translate('passwords_dont_match')) {
                                  setState(() {
                                    confirmPasswordHint = context
                                        .translate('please_confirm_password');
                                  });
                                }
                              },
                              onSubmitted: (_) {
                                FocusScope.of(context).unfocus();
                              },
                              context: context,
                              index: 3,
                            ),

                            // Role selector
                            TweenAnimationBuilder<double>(
                              tween: Tween<double>(begin: 0, end: 1),
                              duration: Duration(milliseconds: 500 + 4 * 100),
                              curve: Curves.easeOut,
                              builder: (context, value, child) {
                                return Opacity(
                                  opacity: value,
                                  child: Transform.translate(
                                    offset: Offset(0, 20 * (1 - value)),
                                    child: child,
                                  ),
                                );
                              },
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    context.translate('select_role').toUpperCase(),
                                    style: GoogleFonts.orbitron(
                                      fontSize: screenWidth * 0.04,
                                      fontWeight: FontWeight.bold,
                                      color: onSurfaceColor,
                                      letterSpacing: 1.5,
                                    ),
                                  ),
                                  SizedBox(
                                      height: screenHeight * 0.01 * scaleFactor),
                                  Container(
                                    width: double.infinity,
                                    decoration: BoxDecoration(
                                      color: cardColor,
                                      borderRadius: BorderRadius.circular(15),
                                      border: Border.all(
                                        color: biotechCyan.withOpacity(isDarkMode ? 0.1 : 0.3),
                                        width: 1,
                                      ),
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(15),
                                      child: BackdropFilter(
                                        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                                        child: Row(
                                          children: [
                                            context.translate('patient'),
                                            context.translate('doctor')
                                          ].map((role) {
                                            return Expanded(
                                              child: GestureDetector(
                                                onTap: () {
                                                  setState(() {
                                                    _selectedRole = role;
                                                  });
                                                },
                                                child: AnimatedContainer(
                                                  duration: Duration(milliseconds: 300),
                                                  padding: EdgeInsets.symmetric(
                                                    vertical: screenHeight *
                                                        0.015 *
                                                        scaleFactor,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: _selectedRole == role
                                                        ? biotechCyan
                                                        : Colors.transparent,
                                                  ),
                                                  child: Text(
                                                    role.toUpperCase(),
                                                    textAlign: TextAlign.center,
                                                    style: GoogleFonts.orbitron(
                                                      color: _selectedRole == role
                                                          ? biotechBlack
                                                          : onSurfaceColor,
                                                      fontWeight: FontWeight.bold,
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            );
                                          }).toList(),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(height: screenHeight * 0.04 * scaleFactor),

                            // Register button with animation
                            TweenAnimationBuilder<double>(
                              tween: Tween<double>(begin: 0, end: 1),
                              duration: Duration(milliseconds: 500 + 5 * 100),
                              curve: Curves.easeOut,
                              builder: (context, value, child) {
                                return Opacity(
                                  opacity: value,
                                  child: Transform.translate(
                                    offset: Offset(0, 20 * (1 - value)),
                                    child: child,
                                  ),
                                );
                              },
                              child: GestureDetector(
                                onTap: isRegistering ? null : signUp,
                                child: AnimatedContainer(
                                  duration: Duration(milliseconds: 300),
                                  width: double.infinity,
                                  height: screenHeight * 0.055,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(30),
                                    color: isRegistering
                                        ? Colors.grey
                                        : biotechCyan,
                                    boxShadow: [
                                      BoxShadow(
                                        color: biotechCyan.withOpacity(0.3),
                                        blurRadius: 8,
                                        offset: Offset(0, 3),
                                      ),
                                    ],
                                  ),
                                  child: Center(
                                    child: isRegistering
                                        ? SizedBox(
                                            width: screenWidth * 0.06,
                                            height: screenWidth * 0.06,
                                            child: CircularProgressIndicator(
                                              color: biotechBlack,
                                              strokeWidth: 2.5,
                                            ),
                                          )
                                        : Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Text(
                                                context.translate('continue').toUpperCase(),
                                                style: GoogleFonts.orbitron(
                                                  color: biotechBlack,
                                                  fontSize: screenWidth * 0.045,
                                                  fontWeight: FontWeight.bold,
                                                  letterSpacing: 1.5,
                                                ),
                                              ),
                                              SizedBox(width: 8),
                                              Icon(
                                                isRTL
                                                    ? Icons.arrow_back
                                                    : Icons.arrow_forward,
                                                color: biotechBlack,
                                              ),
                                            ],
                                          ),
                                  ),
                                ),
                              ),
                            ),

                            SizedBox(height: screenHeight * 0.02 * scaleFactor),

                            // Terms and login section with animations
                            TweenAnimationBuilder<double>(
                              tween: Tween<double>(begin: 0, end: 1),
                              duration: Duration(milliseconds: 500 + 6 * 100),
                              curve: Curves.easeOut,
                              builder: (context, value, child) {
                                return Opacity(
                                  opacity: value,
                                  child: child,
                                );
                              },
                              child: Column(
                                children: [
                                  // Terms and conditions text
                                  Center(
                                    child: Padding(
                                      padding: EdgeInsets.symmetric(
                                          horizontal: screenWidth * 0.05),
                                      child: Text(
                                        context.translate('terms_agreement'),
                                        textAlign: TextAlign.center,
                                        style: GoogleFonts.poppins(
                                          color: subTextColor,
                                          fontSize: screenWidth * 0.03,
                                        ),
                                      ),
                                    ),
                                  ),

                                  SizedBox(
                                      height: screenHeight * 0.02 * scaleFactor),

                                  // Login link
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: <Widget>[
                                      Text(
                                        context.translate('already_have_account'),
                                        style: GoogleFonts.poppins(
                                            fontSize: screenWidth * 0.035,
                                            color: onSurfaceColor),
                                      ),
                                      TextButton(
                                        onPressed: () {
                                          Navigator.pop(context);
                                        },
                                        child: Text(
                                          context.translate('login'),
                                          style: GoogleFonts.poppins(
                                            color: biotechCyan,
                                            fontWeight: FontWeight.bold,
                                            fontSize: screenWidth * 0.035,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(height: screenHeight * 0.01 * scaleFactor),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Helper method for building animated form fields
  Widget _buildAnimatedFormField({
    required String label,
    required TextEditingController controller,
    required FocusNode focusNode,
    required String hintText,
    required BuildContext context,
    required int index,
    String? errorText,
    bool obscureText = false,
    TextInputType? keyboardType,
    void Function(String)? onChanged,
    void Function(String)? onSubmitted,
    TextInputAction? textInputAction,
    VoidCallback? onEditingComplete,
  }) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    
    final cardColor = isDarkMode ? Colors.white.withOpacity(0.03) : Colors.white.withOpacity(0.7);
    final onSurfaceColor = isDarkMode ? Colors.white : biotechBlack;

    final screenSize = MediaQuery.of(context).size;
    final screenHeight = screenSize.height;
    final screenWidth = screenSize.width;
    final scaleFactor = screenHeight < 700 ? 0.8 : 1.0;

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: Duration(milliseconds: 500 + index * 100),
      curve: Curves.easeOut,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - value)),
            child: child,
          ),
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: GoogleFonts.orbitron(
                fontSize: screenWidth * 0.04,
                fontWeight: FontWeight.bold,
                color: biotechCyan,
                letterSpacing: 1.5),
          ),
          SizedBox(height: screenHeight * 0.01 * scaleFactor),
          AnimatedContainer(
            duration: Duration(milliseconds: 300),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(
                color: focusNode.hasFocus
                    ? biotechCyan
                    : biotechCyan.withOpacity(isDarkMode ? 0.1 : 0.3),
                width: 1.5,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                child: TextField(
                  controller: controller,
                  focusNode: focusNode,
                  obscureText: obscureText,
                  keyboardType: keyboardType,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.transparent,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: BorderSide.none,
                    ),
                    hintText: hintText,
                    hintStyle: GoogleFonts.poppins(
                        color: errorText != null
                            ? Colors.red
                            : isDarkMode
                                ? Colors.white38
                                : Colors.black38,
                        fontSize: screenWidth * 0.035),
                    contentPadding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: screenHeight * 0.015 * scaleFactor),
                    errorText: errorText,
                    errorStyle: GoogleFonts.poppins(
                      color: Colors.red,
                      fontSize: screenWidth * 0.03,
                    ),
                  ),
                  style: GoogleFonts.poppins(color: onSurfaceColor),
                  onChanged: onChanged,
                  textInputAction: textInputAction,
                  onEditingComplete: onEditingComplete,
                  onSubmitted: onSubmitted,
                ),
              ),
            ),
          ),
          SizedBox(height: screenHeight * 0.02 * scaleFactor),
        ],
      ),
    );
  }

  // Helper method to build step indicator circles
  Widget _buildStepIndicator(int step, bool isActive, bool isDarkMode) {
    return AnimatedContainer(
      duration: Duration(milliseconds: 300),
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        color: isActive ? biotechCyan : Colors.transparent,
        shape: BoxShape.circle,
        border: Border.all(
          color: biotechCyan.withOpacity(isActive ? 1.0 : 0.3),
          width: 2,
        ),
      ),
      child: Center(
        child: Text(
          step.toString(),
          style: GoogleFonts.orbitron(
            color: isActive
                ? biotechBlack
                : biotechCyan.withOpacity(0.5),
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  // Helper method to build dividers between step indicators
  Widget _buildStepDivider(bool isActive, bool isDarkMode) {
    return AnimatedContainer(
      duration: Duration(milliseconds: 300),
      width: 40,
      height: 2,
      color: biotechCyan.withOpacity(isActive ? 1.0 : 0.2),
    );
  }
}

