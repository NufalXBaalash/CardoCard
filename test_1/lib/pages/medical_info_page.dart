import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:test_1/pages/Main_page.dart';
import 'package:test_1/utils/theme_provider.dart';
import 'package:test_1/utils/app_localizations.dart';
import 'package:test_1/utils/language_provider.dart';

class MedicalInfoPage extends StatefulWidget {
  final String fullName;
  final String email;
  final String password;
  final String role;
  final String? profileImageBase64;

  const MedicalInfoPage({
    super.key,
    required this.fullName,
    required this.email,
    required this.password,
    required this.role,
    this.profileImageBase64,
  });

  @override
  State<MedicalInfoPage> createState() => _MedicalInfoPageState();
}

class _MedicalInfoPageState extends State<MedicalInfoPage>
    with SingleTickerProviderStateMixin {
  // Controllers
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _nationalIDController = TextEditingController();

  // Focus nodes for keyboard handling
  final FocusNode _phoneFocus = FocusNode();
  final FocusNode _addressFocus = FocusNode();
  final FocusNode _nationalIDFocus = FocusNode();

  // Current active focus node
  FocusNode? _activeFocusNode;

  // ScrollController to handle scrolling to focused fields
  final ScrollController _scrollController = ScrollController();

  // State variables
  String _gender = 'Male'; // Default gender selection
  bool _hasAsthma = false;
  bool _hasDiabetes = false;
  String _bloodType = 'A+'; // Default blood type
  bool _isSubmitting = false;

  // List of blood types for dropdown
  final List<String> _bloodTypes = [
    'A+',
    'A-',
    'B+',
    'B-',
    'AB+',
    'AB-',
    'O+',
    'O-'
  ];

  // Form validation error messages
  String _phoneError = '';
  String _nationalIDError = '';
  String _addressError = '';
  String _authError = '';

  // Animation controller for form elements
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

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

    _slideAnimation = Tween<Offset>(
      begin: Offset(0, 0.1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOut,
      ),
    );

    // Start animations
    _animationController.forward();

    // Setup focus listeners to track current field
    _phoneFocus.addListener(() {
      if (_phoneFocus.hasFocus) {
        setState(() => _activeFocusNode = _phoneFocus);
        _scrollToFocusedField(70);
      }
    });

    _addressFocus.addListener(() {
      if (_addressFocus.hasFocus) {
        setState(() => _activeFocusNode = _addressFocus);
        _scrollToFocusedField(130);
      }
    });

    _nationalIDFocus.addListener(() {
      if (_nationalIDFocus.hasFocus) {
        setState(() => _activeFocusNode = _nationalIDFocus);
        _scrollToFocusedField(190);
      }
    });
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _addressController.dispose();
    _nationalIDController.dispose();

    _phoneFocus.dispose();
    _addressFocus.dispose();
    _nationalIDFocus.dispose();

    _scrollController.dispose();
    _animationController.dispose();

    super.dispose();
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

  Future<void> _submitMedicalInfo() async {
    // Reset any error message
    setState(() {
      _authError = '';
    });

    // Basic validation
    bool isValid = true;

    if (_phoneController.text.trim().isEmpty) {
      setState(() {
        _phoneError = context.translate('phone_required');
      });
      isValid = false;
    }

    if (_addressController.text.trim().isEmpty) {
      setState(() {
        _addressError = context.translate('address_required');
      });
      isValid = false;
    }

    if (!isValid) return;

    // Show loading state
    setState(() {
      _isSubmitting = true;
    });

    try {
      // 1. Create Firebase Auth account
      final UserCredential userCredential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: widget.email,
        password: widget.password,
      );

      final String userId = userCredential.user!.uid;

      // 2. Store user data in Firestore
      await FirebaseFirestore.instance.collection('users').doc(userId).set({
        'fullName': widget.fullName,
        'email': widget.email,
        'role': widget.role,
        'phoneNumber': _phoneController.text.trim(),
        'address': _addressController.text.trim(),
        'gender': _gender,
        'nationalID': _nationalIDController.text.trim(),
        'createdAt': FieldValue.serverTimestamp(),
        'registrationComplete': true, // Registration is now complete
        'medicalInfoAddedAt': FieldValue.serverTimestamp(),
      });

      // 3. Save profile image if provided
      if (widget.profileImageBase64 != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .update({
          'profileImageBase64': widget.profileImageBase64,
          'profileImageUpdatedAt': FieldValue.serverTimestamp(),
        });
      }

      // 4. Save medical information
      await FirebaseFirestore.instance
          .collection('medical_info')
          .doc(userId)
          .set({
        'hasAsthma': _hasAsthma,
        'hasDiabetes': _hasDiabetes,
        'bloodType': _bloodType,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Navigate to main page after successful registration
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => MainPage()),
          (route) => false,
        );
      }
    } on FirebaseAuthException catch (e) {
      // Handle specific authentication errors
      String errorMessage = context.translate('registration_failed');

      if (e.code == 'email-already-in-use') {
        errorMessage = context.translate('email_in_use');
      } else if (e.code == 'invalid-email') {
        errorMessage = context.translate('invalid_email_format');
      } else if (e.code == 'weak-password') {
        errorMessage = context.translate('password_too_weak');
      } else if (e.code == 'operation-not-allowed') {
        errorMessage = context.translate('email_password_not_enabled');
      }

      setState(() {
        _authError = errorMessage;
        _isSubmitting = false;
      });

      // Display the error to the user
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_authError),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 5),
        ),
      );
    } catch (e) {
      // Handle any other errors
      print("Error submitting medical info: $e");
      setState(() {
        _authError = context.translate('account_creation_error');
        _isSubmitting = false;
      });

      if (mounted) {
        // Check if widget is still mounted before showing SnackBar
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_authError),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 5),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Get theme data
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Get language direction
    final languageProvider = Provider.of<LanguageProvider>(context);
    final isRTL = languageProvider.isRTL;

    // Get screen dimensions with MediaQuery
    final screenSize = MediaQuery.of(context).size;
    final screenWidth = screenSize.width;
    final screenHeight = screenSize.height;

    // Scale factor for smaller screens
    final scaleFactor = screenHeight < 700 ? 0.8 : 1.0;

    // Get keyboard height when visible
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    final isKeyboardVisible = keyboardHeight > 0;

    return WillPopScope(
      onWillPop: () async {
        // Simply allow back navigation without dialog
        return true;
      },
      child: Directionality(
        textDirection: isRTL ? TextDirection.rtl : TextDirection.ltr,
        child: Scaffold(
          backgroundColor: colorScheme.background,
          appBar: PreferredSize(
            preferredSize: Size.fromHeight(40), // Smaller app bar
            child: AppBar(
              backgroundColor: colorScheme.background,
              surfaceTintColor: Colors.transparent,
              elevation: 0,
              leading: IconButton(
                icon: Icon(isRTL ? Icons.arrow_forward : Icons.arrow_back,
                    color: colorScheme.onBackground),
                onPressed: () {
                  // Simply navigate back without dialog
                  Navigator.of(context).pop();
                },
              ),
              title: Text(
                context.translate('medical_information'),
                style: GoogleFonts.lexend(
                  fontSize: screenWidth * 0.045,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onBackground,
                ),
              ),
              centerTitle: true,
            ),
          ),
          body: GestureDetector(
            // Dismiss keyboard when tapping outside input fields
            onTap: () => FocusScope.of(context).unfocus(),
            child: SafeArea(
              child: SingleChildScrollView(
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
                      // Step indicator
                      if (!isKeyboardVisible)
                        TweenAnimationBuilder<double>(
                          tween: Tween<double>(begin: 0, end: 1),
                          duration: Duration(milliseconds: 800),
                          curve: Curves.easeOutCubic,
                          builder: (context, value, child) {
                            return Opacity(
                              opacity: value,
                              child: Transform.translate(
                                offset: Offset(0, 10 * (1 - value)),
                                child: child,
                              ),
                            );
                          },
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 16),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _buildStepIndicator(1, true, colorScheme),
                                _buildStepDivider(true, colorScheme),
                                _buildStepIndicator(2, true, colorScheme),
                                _buildStepDivider(true, colorScheme),
                                _buildStepIndicator(3, true, colorScheme),
                              ],
                            ),
                          ),
                        ),

                      // Header - stays visible with keyboard (just smaller)
                      Container(
                        height: isKeyboardVisible ? 55 : null,
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(
                                  height: isKeyboardVisible
                                      ? 5
                                      : screenHeight * 0.01 * scaleFactor),
                              if (!isKeyboardVisible)
                                TweenAnimationBuilder<double>(
                                  tween: Tween<double>(begin: 0, end: 1),
                                  duration: Duration(milliseconds: 1000),
                                  curve: Curves.easeOutQuad,
                                  builder: (context, value, child) {
                                    return Opacity(
                                      opacity: value,
                                      child: Transform.translate(
                                        offset: Offset(0, 15 * (1 - value)),
                                        child: child,
                                      ),
                                    );
                                  },
                                  child: Text(
                                    context.translate('complete_your_profile'),
                                    style: GoogleFonts.lexend(
                                      fontSize: screenWidth * 0.06,
                                      fontWeight: FontWeight.bold,
                                      color: colorScheme.onBackground,
                                    ),
                                  ),
                                )
                              else
                                Text(
                                  context.translate('complete_profile'),
                                  style: GoogleFonts.lexend(
                                    fontSize: screenWidth * 0.045,
                                    fontWeight: FontWeight.bold,
                                    color: colorScheme.onBackground,
                                  ),
                                ),
                              if (!isKeyboardVisible)
                                Column(
                                  children: [
                                    SizedBox(
                                        height:
                                            screenHeight * 0.01 * scaleFactor),
                                    TweenAnimationBuilder<double>(
                                      tween: Tween<double>(begin: 0, end: 1),
                                      duration: Duration(milliseconds: 1200),
                                      curve: Curves.easeOutCubic,
                                      builder: (context, value, child) {
                                        return Opacity(
                                          opacity: value,
                                          child: Transform.translate(
                                            offset: Offset(0, 15 * (1 - value)),
                                            child: child,
                                          ),
                                        );
                                      },
                                      child: Text(
                                        context
                                            .translate('step3_provide_medical'),
                                        textAlign: TextAlign.center,
                                        style: GoogleFonts.lexend(
                                          fontSize: screenWidth * 0.035,
                                          color: colorScheme.onBackground
                                              .withOpacity(0.7),
                                        ),
                                      ),
                                    ),
                                    SizedBox(
                                        height:
                                            screenHeight * 0.01 * scaleFactor),
                                    TweenAnimationBuilder<double>(
                                      tween: Tween<double>(begin: 0, end: 1),
                                      duration: Duration(milliseconds: 1400),
                                      curve: Curves.easeOutCubic,
                                      builder: (context, value, child) {
                                        return Opacity(
                                          opacity: value,
                                          child: Transform.translate(
                                            offset: Offset(0, 15 * (1 - value)),
                                            child: child,
                                          ),
                                        );
                                      },
                                      child: Text(
                                        context
                                            .translate('welcome_user')
                                            .replaceAll(
                                                '{name}', widget.fullName),
                                        textAlign: TextAlign.center,
                                        style: GoogleFonts.lexend(
                                          fontSize: screenWidth * 0.04,
                                          fontWeight: FontWeight.w500,
                                          color: colorScheme.primary,
                                        ),
                                      ),
                                    ),
                                    if (_authError.isNotEmpty)
                                      TweenAnimationBuilder<double>(
                                        tween: Tween<double>(begin: 0, end: 1),
                                        duration: Duration(milliseconds: 300),
                                        curve: Curves.easeOut,
                                        builder: (context, value, child) {
                                          return Opacity(
                                            opacity: value,
                                            child: child,
                                          );
                                        },
                                        child: Container(
                                          margin: EdgeInsets.only(top: 10),
                                          padding: EdgeInsets.symmetric(
                                            vertical: 8,
                                            horizontal: 12,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.red.withOpacity(0.1),
                                            borderRadius:
                                                BorderRadius.circular(8),
                                            border: Border.all(
                                                color: Colors.red
                                                    .withOpacity(0.5)),
                                          ),
                                          child: Text(
                                            _authError,
                                            textAlign: TextAlign.center,
                                            style: GoogleFonts.lexend(
                                              fontSize: screenWidth * 0.035,
                                              color: Colors.red,
                                            ),
                                          ),
                                        ),
                                      ),
                                    SizedBox(
                                        height:
                                            screenHeight * 0.02 * scaleFactor),
                                  ],
                                )
                              else
                                SizedBox(height: 5),
                            ],
                          ),
                        ),
                      ),

                      // Form section
                      // Phone Number Field with animation
                      _buildAnimatedFormField(
                        label: context.translate('phone_number'),
                        controller: _phoneController,
                        focusNode: _phoneFocus,
                        hintText: context.translate('enter_phone'),
                        errorText: _phoneError.isNotEmpty ? _phoneError : null,
                        keyboardType: TextInputType.phone,
                        onChanged: (value) {
                          if (_phoneError.isNotEmpty) {
                            setState(() {
                              _phoneError = '';
                            });
                          }
                        },
                        textInputAction: TextInputAction.next,
                        onEditingComplete: () =>
                            FocusScope.of(context).requestFocus(_addressFocus),
                        context: context,
                        index: 0,
                      ),

                      // Address Field with animation
                      _buildAnimatedFormField(
                        label: context.translate('address'),
                        controller: _addressController,
                        focusNode: _addressFocus,
                        hintText: context.translate('enter_address'),
                        errorText:
                            _addressError.isNotEmpty ? _addressError : null,
                        onChanged: (value) {
                          if (_addressError.isNotEmpty) {
                            setState(() {
                              _addressError = '';
                            });
                          }
                        },
                        textInputAction: TextInputAction.next,
                        onEditingComplete: () => FocusScope.of(context)
                            .requestFocus(_nationalIDFocus),
                        context: context,
                        index: 1,
                      ),

                      // National ID with animation
                      _buildAnimatedFormField(
                        label: context.translate('national_id'),
                        controller: _nationalIDController,
                        focusNode: _nationalIDFocus,
                        hintText: context.translate('enter_national_id'),
                        errorText: _nationalIDError.isNotEmpty
                            ? _nationalIDError
                            : null,
                        keyboardType: TextInputType.text,
                        onChanged: (value) {
                          if (_nationalIDError.isNotEmpty) {
                            setState(() {
                              _nationalIDError = '';
                            });
                          }
                        },
                        textInputAction: TextInputAction.done,
                        onEditingComplete: () =>
                            FocusScope.of(context).unfocus(),
                        context: context,
                        index: 2,
                      ),

                      // Gender Selection with animation
                      _buildAnimatedSection(
                        title: context.translate('gender'),
                        index: 3,
                        context: context,
                        child: Row(
                          children: [
                            _buildAnimatedRadioOption(
                              value: context.translate('male'),
                              groupValue: _gender,
                              onChanged: (value) {
                                setState(() {
                                  _gender = value!;
                                });
                              },
                              context: context,
                            ),
                            SizedBox(width: screenWidth * 0.1),
                            _buildAnimatedRadioOption(
                              value: context.translate('female'),
                              groupValue: _gender,
                              onChanged: (value) {
                                setState(() {
                                  _gender = value!;
                                });
                              },
                              context: context,
                            ),
                          ],
                        ),
                      ),

                      // Medical Conditions with animation
                      _buildAnimatedSection(
                        title: context.translate('medical_conditions'),
                        index: 4,
                        context: context,
                        child: Column(
                          children: [
                            // Asthma Selection
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  context.translate('have_asthma'),
                                  style: TextStyle(
                                    fontSize: screenWidth * 0.04,
                                    color: colorScheme.onBackground,
                                  ),
                                ),
                                Row(
                                  children: [
                                    _buildAnimatedButton(
                                      text: context.translate('yes'),
                                      isActive: _hasAsthma,
                                      onPressed: () {
                                        setState(() {
                                          _hasAsthma = true;
                                        });
                                      },
                                      context: context,
                                    ),
                                    SizedBox(width: screenWidth * 0.02),
                                    _buildAnimatedButton(
                                      text: context.translate('no'),
                                      isActive: !_hasAsthma,
                                      onPressed: () {
                                        setState(() {
                                          _hasAsthma = false;
                                        });
                                      },
                                      context: context,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            SizedBox(
                                height: screenHeight * 0.015 * scaleFactor),

                            // Diabetes Selection
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  context.translate('have_diabetes'),
                                  style: TextStyle(
                                    fontSize: screenWidth * 0.04,
                                    color: colorScheme.onBackground,
                                  ),
                                ),
                                Row(
                                  children: [
                                    _buildAnimatedButton(
                                      text: context.translate('yes'),
                                      isActive: _hasDiabetes,
                                      onPressed: () {
                                        setState(() {
                                          _hasDiabetes = true;
                                        });
                                      },
                                      context: context,
                                    ),
                                    SizedBox(width: screenWidth * 0.02),
                                    _buildAnimatedButton(
                                      text: context.translate('no'),
                                      isActive: !_hasDiabetes,
                                      onPressed: () {
                                        setState(() {
                                          _hasDiabetes = false;
                                        });
                                      },
                                      context: context,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // Blood Type Dropdown with animation
                      _buildAnimatedSection(
                        title: context.translate('blood_type'),
                        index: 5,
                        context: context,
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color: isDarkMode
                                ? const Color(0xFF2C2C2C)
                                : Colors.grey[200],
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 4,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: DropdownButton<String>(
                            value: _bloodType,
                            icon: Icon(
                              Icons.arrow_drop_down,
                              color: colorScheme.onBackground.withOpacity(0.7),
                            ),
                            isExpanded: true,
                            underline: SizedBox(),
                            dropdownColor: colorScheme.surface,
                            style: TextStyle(color: colorScheme.onBackground),
                            onChanged: (String? newValue) {
                              setState(() {
                                _bloodType = newValue!;
                              });
                            },
                            items: _bloodTypes
                                .map<DropdownMenuItem<String>>((String value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Text(
                                    context.translate(value.toLowerCase())),
                              );
                            }).toList(),
                          ),
                        ),
                      ),

                      SizedBox(height: screenHeight * 0.025 * scaleFactor),

                      // Submit Button with animation
                      TweenAnimationBuilder<double>(
                        tween: Tween<double>(begin: 0, end: 1),
                        duration: Duration(milliseconds: 500 + 6 * 100),
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
                          onTap: _isSubmitting ? null : _submitMedicalInfo,
                          child: AnimatedContainer(
                            duration: Duration(milliseconds: 300),
                            width: double.infinity,
                            height: screenHeight * 0.055,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(30),
                              color: _isSubmitting
                                  ? Colors.grey
                                  : colorScheme.primary,
                              boxShadow: [
                                BoxShadow(
                                  color: colorScheme.primary.withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Center(
                              child: _isSubmitting
                                  ? SizedBox(
                                      width: screenWidth * 0.06,
                                      height: screenWidth * 0.06,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2.5,
                                      ),
                                    )
                                  : Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          context.translate('create_account'),
                                          style: GoogleFonts.lexend(
                                            color: Colors.white,
                                            fontSize: screenWidth * 0.045,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        SizedBox(width: 8),
                                        Icon(
                                          Icons.check_circle_outline,
                                          color: Colors.white,
                                          size: screenWidth * 0.05,
                                        ),
                                      ],
                                    ),
                            ),
                          ),
                        ),
                      ),

                      SizedBox(height: screenHeight * 0.025 * scaleFactor),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Helper method to build animated form fields
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
    final colorScheme = Theme.of(context).colorScheme;
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
            label,
            style: GoogleFonts.inter(
              fontSize: screenWidth * 0.04,
              fontWeight: FontWeight.bold,
              color: colorScheme.onBackground,
            ),
          ),
          SizedBox(height: screenHeight * 0.008 * scaleFactor),
          AnimatedContainer(
            duration: Duration(milliseconds: 300),
            decoration: BoxDecoration(
              color: isDarkMode ? const Color(0xFF2C2C2C) : Colors.grey[200],
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: focusNode.hasFocus
                      ? colorScheme.primary.withOpacity(0.3)
                      : Colors.transparent,
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
              border: Border.all(
                color: focusNode.hasFocus
                    ? colorScheme.primary
                    : Colors.transparent,
                width: 1.5,
              ),
            ),
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              obscureText: obscureText,
              keyboardType: keyboardType,
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.transparent,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                hintText: hintText,
                hintStyle: TextStyle(
                  color: isDarkMode ? const Color(0xFFAAAAAA) : Colors.grey,
                ),
                errorText: errorText,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: screenHeight * 0.012 * scaleFactor,
                ),
              ),
              style: TextStyle(color: colorScheme.onBackground),
              onChanged: onChanged,
              textInputAction: textInputAction,
              onEditingComplete: onEditingComplete,
              onSubmitted: onSubmitted,
            ),
          ),
          SizedBox(height: screenHeight * 0.015 * scaleFactor),
        ],
      ),
    );
  }

  // Helper method to build animated sections
  Widget _buildAnimatedSection({
    required String title,
    required Widget child,
    required BuildContext context,
    required int index,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
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
            title,
            style: GoogleFonts.inter(
              fontSize: screenWidth * 0.04,
              fontWeight: FontWeight.bold,
              color: colorScheme.onBackground,
            ),
          ),
          SizedBox(height: screenHeight * 0.01 * scaleFactor),
          child,
          SizedBox(height: screenHeight * 0.02 * scaleFactor),
        ],
      ),
    );
  }

  // Helper method to build animated radio options
  Widget _buildAnimatedRadioOption({
    required String value,
    required String groupValue,
    required void Function(String?)? onChanged,
    required BuildContext context,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final screenWidth = MediaQuery.of(context).size.width;

    return Row(
      children: [
        Radio<String>(
          value: value,
          groupValue: groupValue,
          activeColor: colorScheme.primary,
          onChanged: onChanged,
        ),
        Text(
          value,
          style: GoogleFonts.lexend(
            fontSize: screenWidth * 0.04,
            color: colorScheme.onBackground,
          ),
        ),
      ],
    );
  }

  // Helper method to build animated buttons
  Widget _buildAnimatedButton({
    required String text,
    required bool isActive,
    required VoidCallback onPressed,
    required BuildContext context,
  }) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    final colorScheme = Theme.of(context).colorScheme;
    final screenSize = MediaQuery.of(context).size;
    final screenHeight = screenSize.height;
    final screenWidth = screenSize.width;
    final scaleFactor = screenHeight < 700 ? 0.8 : 1.0;

    return ElevatedButton(
      onPressed: onPressed,
      style: ButtonStyle(
        backgroundColor: MaterialStateProperty.all(
          isActive
              ? colorScheme.primary
              : isDarkMode
                  ? Colors.grey[800]
                  : Colors.grey[300],
        ),
        foregroundColor: MaterialStateProperty.all(
          isActive ? Colors.white : colorScheme.onBackground,
        ),
        minimumSize: MaterialStateProperty.all(
          Size(screenWidth * 0.15, screenHeight * 0.04 * scaleFactor),
        ),
        shape: MaterialStateProperty.all(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        elevation: MaterialStateProperty.all(isActive ? 2 : 0),
        animationDuration: Duration(milliseconds: 200),
      ),
      child: Text(
        text,
        style: GoogleFonts.lexend(
          fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }

  // Helper method to build step indicator circles
  Widget _buildStepIndicator(int step, bool isActive, ColorScheme colorScheme) {
    return AnimatedContainer(
      duration: Duration(milliseconds: 300),
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        color: isActive ? colorScheme.primary : Colors.transparent,
        shape: BoxShape.circle,
        border: Border.all(
          color: isActive
              ? colorScheme.primary
              : colorScheme.onBackground.withOpacity(0.3),
          width: 2,
        ),
      ),
      child: Center(
        child: Text(
          step.toString(),
          style: TextStyle(
            color: isActive
                ? Colors.white
                : colorScheme.onBackground.withOpacity(0.5),
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  // Helper method to build dividers between step indicators
  Widget _buildStepDivider(bool isActive, ColorScheme colorScheme) {
    return AnimatedContainer(
      duration: Duration(milliseconds: 300),
      width: 40,
      height: 2,
      color: isActive
          ? colorScheme.primary
          : colorScheme.onBackground.withOpacity(0.2),
    );
  }
}
