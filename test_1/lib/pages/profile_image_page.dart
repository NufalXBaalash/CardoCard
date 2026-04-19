import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:test_1/pages/medical_info_page.dart';
import 'package:test_1/utils/theme_provider.dart';
import 'package:test_1/utils/app_localizations.dart';
import 'package:test_1/utils/language_provider.dart';

class ProfileImagePage extends StatefulWidget {
  final String fullName;
  final String email;
  final String password;
  final String role;

  const ProfileImagePage({
    super.key,
    required this.fullName,
    required this.email,
    required this.password,
    required this.role,
  });

  @override
  State<ProfileImagePage> createState() => _ProfileImagePageState();
}

class _ProfileImagePageState extends State<ProfileImagePage>
    with SingleTickerProviderStateMixin {
  // Bio-Tech Colors
  static const Color biotechBlack = Color(0xFF0F0F0F);
  static const Color biotechCyan = Color(0xFF00E5FF);

  File? _imageFile;
  bool _isLoading = false;
  final ImagePicker _picker = ImagePicker();
  String? _base64Image;

  // Firebase storage reference
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Animation controller for image and buttons
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

    // Request permissions when the page loads
    _requestPermissions();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  // Request necessary permissions
  Future<void> _requestPermissions() async {
    print("Checking camera and storage permissions...");

    // For Android 13+ (SDK 33+), we need READ_MEDIA_IMAGES
    // For older Android, we need READ_EXTERNAL_STORAGE
    if (await Permission.camera.status.isDenied) {
      print("Requesting camera permission");
      await Permission.camera.request();
    }

    // Check for storage permissions based on Android version
    if (await Permission.storage.status.isDenied) {
      print("Requesting storage permission");
      await Permission.storage.request();
    }

    if (await Permission.photos.status.isDenied) {
      print("Requesting photos permission");
      await Permission.photos.request();
    }
  }

  // Check permissions before opening image picker
  Future<bool> _checkPermissions(ImageSource source) async {
    print(
        "Checking permissions for ${source == ImageSource.camera ? 'camera' : 'gallery'}");

    if (source == ImageSource.camera) {
      if (await Permission.camera.isDenied) {
        final status = await Permission.camera.request();
        if (status.isDenied) {
          _showPermissionDeniedMessage("Camera");
          return false;
        }
      }
    } else {
      // For gallery, check appropriate permissions
      bool hasPermission = false;

      // First try photos permission (for newer devices)
      if (await Permission.photos.isDenied) {
        final photosStatus = await Permission.photos.request();
        hasPermission = photosStatus.isGranted;
      } else {
        hasPermission = true;
      }

      // If that didn't work, try storage permission
      if (!hasPermission && await Permission.storage.isDenied) {
        final storageStatus = await Permission.storage.request();
        hasPermission = storageStatus.isGranted;
      }

      if (!hasPermission) {
        _showPermissionDeniedMessage("Gallery");
        return false;
      }
    }

    return true;
  }

  // Show permission denied message with instructions
  void _showPermissionDeniedMessage(String permissionType) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(context
            .translate('permission_required')
            .replaceAll('{type}', permissionType)),
        backgroundColor: Colors.red,
        duration: Duration(seconds: 5),
        action: SnackBarAction(
          label: context.translate('settings'),
          onPressed: () {
            openAppSettings();
          },
          textColor: Colors.white,
        ),
      ),
    );
  }

  // Pick image from gallery
  Future<void> _pickImage() async {
    try {
      // Check permissions first
      if (!await _checkPermissions(ImageSource.gallery)) {
        return;
      }

      print("Opening image picker for gallery selection");
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      print(
          "Image picker result: ${pickedFile != null ? 'Image selected' : 'No image selected'}");

      if (pickedFile != null) {
        try {
          // Create a temporary file in the app's documents directory
          final Directory appDocDir = await getApplicationDocumentsDirectory();
          final String appDocPath = appDocDir.path;
          final String fileName =
              'temp_${DateTime.now().millisecondsSinceEpoch}.jpg';
          final String filePath = '$appDocPath/$fileName';

          // Copy the picked file to our app's documents directory
          final File originalFile = File(pickedFile.path);
          final File destinationFile = await originalFile.copy(filePath);

          print("Copied image to app directory: $filePath");

          if (await destinationFile.exists()) {
            final int fileSize = await destinationFile.length();
            print("Selected image file size: $fileSize bytes");

            if (fileSize > 0) {
              setState(() {
                _imageFile = destinationFile;
              });
            } else {
              print("Selected image has zero bytes");
              _showErrorMessage(context.translate('empty_image_error'));
            }
          } else {
            print("Destination file doesn't exist after copy");
            _showErrorMessage(context.translate('image_access_error'));
          }
        } catch (e) {
          print("Error processing selected image: $e");
          _showErrorMessage(context.translate('image_processing_error'));
        }
      }
    } catch (e) {
      print("Error picking image from gallery: $e");
      _showErrorMessage(context.translate('image_selection_error'));
    }
  }

  // Take photo with camera
  Future<void> _takePhoto() async {
    try {
      // Check permissions first
      if (!await _checkPermissions(ImageSource.camera)) {
        return;
      }

      print("Opening camera for photo capture");
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      print(
          "Camera result: ${pickedFile != null ? 'Photo taken' : 'No photo taken'}");

      if (pickedFile != null) {
        try {
          // Create a temporary file in the app's documents directory
          final Directory appDocDir = await getApplicationDocumentsDirectory();
          final String appDocPath = appDocDir.path;
          final String fileName =
              'temp_${DateTime.now().millisecondsSinceEpoch}.jpg';
          final String filePath = '$appDocPath/$fileName';

          // Copy the picked file to our app's documents directory
          final File originalFile = File(pickedFile.path);
          final File destinationFile = await originalFile.copy(filePath);

          print("Copied camera image to app directory: $filePath");

          if (await destinationFile.exists()) {
            final int fileSize = await destinationFile.length();
            print("Captured photo file size: $fileSize bytes");

            if (fileSize > 0) {
              setState(() {
                _imageFile = destinationFile;
              });
            } else {
              print("Captured photo has zero bytes");
              _showErrorMessage(context.translate('empty_photo_error'));
            }
          } else {
            print("Destination file doesn't exist after copy");
            _showErrorMessage(context.translate('photo_access_error'));
          }
        } catch (e) {
          print("Error processing captured photo: $e");
          _showErrorMessage(context.translate('photo_processing_error'));
        }
      }
    } catch (e) {
      print("Error taking photo with camera: $e");
      _showErrorMessage(context.translate('photo_capture_error'));
    }
  }

  // Upload image to Firebase storage and update user document
  Future<void> _uploadImageAndContinue() async {
    if (_imageFile == null) {
      _showErrorMessage(context.translate('select_profile_image_first'));
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Process the image for the next step
      await _processImageForNextStep();
    } catch (e) {
      print("ERROR DURING PROFILE IMAGE UPLOAD: $e");
      _showErrorMessage(context
          .translate('image_upload_failed')
          .replaceAll('{error}', e.toString().split(":")[0]));
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Process image and move to next step
  Future<void> _processImageForNextStep() async {
    if (_imageFile == null) {
      throw Exception(context.translate('no_image_selected'));
    }

    print("Processing image for next step");

    try {
      // 1. Read the image file
      final bytes = await _imageFile!.readAsBytes();
      if (bytes.isEmpty) {
        throw Exception(context.translate('image_empty'));
      }

      // 2. Convert the bytes to base64 string
      print("Converting image to base64...");
      final base64Image = base64Encode(bytes);
      print("Base64 image length: ${base64Image.length}");

      // If image is too large, you may need to resize or compress it further
      if (base64Image.length > 900000) {
        throw Exception(context.translate('image_too_large'));
      }

      // Store base64 image for passing to next screen
      _base64Image = base64Image;

      print("Image processed successfully!");
      _showSuccessMessage(context.translate('profile_image_processed'));

      // Wait a moment for the success message to be seen
      await Future.delayed(Duration(seconds: 1));

      // Navigate to next page
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MedicalInfoPage(
              fullName: widget.fullName,
              email: widget.email,
              password: widget.password,
              role: widget.role,
              profileImageBase64: _base64Image,
            ),
          ),
        );
      }
    } catch (e) {
      print("IMAGE PROCESSING FAILED: $e");
      throw e; // Rethrow to be handled by the calling method
    }
  }

  // Skip image upload and continue to medical info
  void _skipAndContinue() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MedicalInfoPage(
          fullName: widget.fullName,
          email: widget.email,
          password: widget.password,
          role: widget.role,
          profileImageBase64: null,
        ),
      ),
    );
  }

  // Show error message with retry option
  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.white),
            SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: context.translate('retry'),
          textColor: Colors.white,
          onPressed: () {
            _showImageSourceOptions();
          },
        ),
        duration: Duration(seconds: 5),
      ),
    );
  }

  // Show success message
  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 2),
      ),
    );
  }

  // Show image picker options
  void _showImageSourceOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
        final isDarkMode = themeProvider.isDarkMode;
        final cardColor = isDarkMode ? biotechBlack : Colors.white;
        final onSurfaceColor = isDarkMode ? Colors.white : biotechBlack;

        return Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
            border: Border.all(
              color: biotechCyan.withOpacity(isDarkMode ? 0.2 : 0.4),
              width: 1.5,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                context.translate('choose_option').toUpperCase(),
                style: GoogleFonts.orbitron(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: biotechCyan,
                  letterSpacing: 1.5,
                ),
              ),
              SizedBox(height: 16),
              ListTile(
                leading: Icon(Icons.photo_library, color: biotechCyan),
                title: Text(
                  context.translate('pick_gallery'),
                  style: GoogleFonts.poppins(color: onSurfaceColor),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage();
                },
              ),
              ListTile(
                leading: Icon(Icons.camera_alt, color: biotechCyan),
                title: Text(
                  context.translate('take_photo'),
                  style: GoogleFonts.poppins(color: onSurfaceColor),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _takePhoto();
                },
              ),
            ],
          ),
        );
      },
    );
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
    final screenWidth = screenSize.width;
    final screenHeight = screenSize.height;

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
      },
      child: Directionality(
        textDirection: isRTL ? TextDirection.rtl : TextDirection.ltr,
        child: Scaffold(
          backgroundColor: backgroundColor,
          extendBodyBehindAppBar: true,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: Icon(isRTL ? Icons.arrow_forward : Icons.arrow_back,
                  color: onSurfaceColor),
              onPressed: () {
                // Simply navigate back without dialog
                Navigator.of(context).pop();
              },
            ),
            title: Text(
              context.translate('profile_picture').toUpperCase(),
              style: GoogleFonts.orbitron(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: biotechCyan,
                letterSpacing: 1.5,
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
                  right: -50,
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
                  physics: BouncingScrollPhysics(),
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.05),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        SizedBox(height: screenHeight * 0.02),

                        // Step indicator with improved UI
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
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _buildStepIndicator(1, true, isDarkMode),
                              _buildStepDivider(true, isDarkMode),
                              _buildStepIndicator(2, true, isDarkMode),
                              _buildStepDivider(false, isDarkMode),
                              _buildStepIndicator(3, false, isDarkMode),
                            ],
                          ),
                        ),

                        SizedBox(height: screenHeight * 0.03),

                        // Title with animation
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
                            context.translate('add_profile_picture').toUpperCase(),
                            textAlign: TextAlign.center,
                            style: GoogleFonts.orbitron(
                              fontSize: screenWidth * 0.06,
                              fontWeight: FontWeight.bold,
                              color: onSurfaceColor,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ),

                        SizedBox(height: screenHeight * 0.015),

                        // Description with animation
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
                          child: Container(
                            width: screenWidth * 0.8,
                            child: Text(
                              context.translate('profile_picture_description'),
                              textAlign: TextAlign.center,
                              style: GoogleFonts.poppins(
                                fontSize: screenWidth * 0.035,
                                color: subTextColor,
                                height: 1.3,
                              ),
                            ),
                          ),
                        ),

                        SizedBox(height: screenHeight * 0.05),

                        // Profile image container with enhanced animations
                        GestureDetector(
                          onTap: _showImageSourceOptions,
                          child: TweenAnimationBuilder<double>(
                            tween: Tween<double>(begin: 0, end: 1),
                            duration: Duration(milliseconds: 1000),
                            curve: Curves.easeOutCubic,
                            builder: (context, value, child) {
                              return Opacity(
                                opacity: value,
                                child: Transform.scale(
                                  scale: 0.8 + (0.2 * value),
                                  child: child,
                                ),
                              );
                            },
                            child: AnimatedContainer(
                              duration: Duration(milliseconds: 300),
                              width: screenWidth * 0.55,
                              height: screenWidth * 0.55,
                              decoration: BoxDecoration(
                                color: cardColor,
                                shape: BoxShape.circle,
                                boxShadow: isDarkMode ? [] : [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 15,
                                    spreadRadius: 2,
                                    offset: Offset(0, 5),
                                  ),
                                ],
                                border: Border.all(
                                  color: _imageFile != null
                                      ? biotechCyan
                                      : biotechCyan.withOpacity(isDarkMode ? 0.2 : 0.4),
                                  width: 4,
                                ),
                                image: _imageFile != null
                                    ? DecorationImage(
                                        image: FileImage(_imageFile!),
                                        fit: BoxFit.cover,
                                      )
                                    : null,
                              ),
                              child: ClipOval(
                                child: BackdropFilter(
                                  filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                                  child: _imageFile == null
                                      ? Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            AnimatedContainer(
                                              duration: Duration(milliseconds: 300),
                                              padding: EdgeInsets.all(12),
                                              decoration: BoxDecoration(
                                                color: biotechCyan.withOpacity(0.1),
                                                shape: BoxShape.circle,
                                              ),
                                              child: Icon(
                                                Icons.add_a_photo,
                                                size: screenWidth * 0.08,
                                                color: biotechCyan,
                                              ),
                                            ),
                                            SizedBox(height: 16),
                                            Text(
                                              context.translate('tap_add_photo').toUpperCase(),
                                              style: GoogleFonts.orbitron(
                                                fontSize: 10,
                                                fontWeight: FontWeight.w500,
                                                color: biotechCyan,
                                                letterSpacing: 1,
                                              ),
                                            ),
                                          ],
                                        )
                                      : null,
                                ),
                              ),
                            ),
                          ),
                        ),

                        SizedBox(height: screenHeight * 0.07),

                        // Continue button with enhanced design
                        TweenAnimationBuilder<double>(
                          tween: Tween<double>(begin: 0, end: 1),
                          duration: Duration(milliseconds: 1400),
                          curve: Curves.easeOutCubic,
                          builder: (context, value, child) {
                            return Opacity(
                              opacity: value,
                              child: Transform.translate(
                                offset: Offset(0, 30 * (1 - value)),
                                child: child,
                              ),
                            );
                          },
                          child: GestureDetector(
                            onTap: _isLoading ? null : _uploadImageAndContinue,
                            child: AnimatedContainer(
                              duration: Duration(milliseconds: 300),
                              width: double.infinity,
                              height: screenHeight * 0.06,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(30),
                                color: _isLoading
                                    ? Colors.grey
                                    : biotechCyan,
                                boxShadow: [
                                  BoxShadow(
                                    color: biotechCyan.withOpacity(0.3),
                                    blurRadius: 8,
                                    spreadRadius: 1,
                                    offset: Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: Center(
                                child: _isLoading
                                    ? SizedBox(
                                        width: screenWidth * 0.06,
                                        height: screenWidth * 0.06,
                                        child: CircularProgressIndicator(
                                          color: biotechBlack,
                                          strokeWidth: 2.5,
                                        ),
                                      )
                                    : Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
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
                                            size: screenWidth * 0.045,
                                          ),
                                        ],
                                      ),
                              ),
                            ),
                          ),
                        ),

                        SizedBox(height: screenHeight * 0.02),

                        // Skip button with animation
                        TweenAnimationBuilder<double>(
                          tween: Tween<double>(begin: 0, end: 1),
                          duration: Duration(milliseconds: 1600),
                          curve: Curves.easeOutCubic,
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
                            onTap: _isLoading ? null : _skipAndContinue,
                            child: AnimatedContainer(
                              duration: Duration(milliseconds: 300),
                              width: double.infinity,
                              height: screenHeight * 0.06,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(30),
                                color: Colors.transparent,
                                border: Border.all(
                                  color: biotechCyan,
                                  width: 1.5,
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  context.translate('skip_for_now').toUpperCase(),
                                  style: GoogleFonts.orbitron(
                                    color: biotechCyan,
                                    fontSize: screenWidth * 0.04,
                                    fontWeight: FontWeight.w500,
                                    letterSpacing: 1.5,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),

                        SizedBox(height: screenHeight * 0.04),
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

