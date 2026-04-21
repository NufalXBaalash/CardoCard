import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:test_1/database/supabase_config.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:test_1/utils/theme_provider.dart';
import 'package:test_1/utils/language_provider.dart';
import 'package:test_1/utils/app_localizations.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:test_1/pages/login_screen.dart';

// Helper functions for isolate compute
Uint8List _readFileBytes(File file) => file.readAsBytesSync();
String _encodeToBase64(Uint8List data) => base64Encode(data);

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage>
    with SingleTickerProviderStateMixin {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final ImagePicker _picker = ImagePicker();

  // User data
  User? _currentUser;
  String _fullName = '';
  String _email = '';
  String _phoneNumber = '';
  String _address = '';
  String? _profileImageBase64;
  String _role = '';
  String _deleteConfirmText = '';
  String _bloodType = 'A+';
  bool _hasDiabetes = false;
  bool _hasAsthma = false;

  // Form controllers
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();

  // File for new profile image
  File? _imageFile;

  // Loading state
  bool _isLoading = false;
  bool _isSaving = false;

  // Animation controller
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  // Focus nodes
  final FocusNode _fullNameFocus = FocusNode();
  final FocusNode _phoneFocus = FocusNode();
  final FocusNode _addressFocus = FocusNode();

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

    // Load user data
    _loadCurrentUser();
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _fullNameFocus.dispose();
    _phoneFocus.dispose();
    _addressFocus.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentUser() async {
    setState(() {
      _isLoading = true;
    });

    try {
      _currentUser = _auth.currentUser;
      if (_currentUser != null) {
        final profile = await SupabaseService.fetchUserProfile(_currentUser!.uid);
        if (profile != null) {
          setState(() {
            _fullName = profile['full_name'] ?? '';
            _email = profile['email'] ?? '';
            _phoneNumber = profile['phone_number'] ?? '';
            _address = profile['address'] ?? '';
            _profileImageBase64 = profile['profile_image_base64'];
            _role = profile['role'] ?? context.translate('patient');

            _fullNameController.text = _fullName;
            _phoneController.text = _phoneNumber;
            _addressController.text = _address;
          });

          try {
            final medData = await SupabaseService.fetchMedicalInfo(_currentUser!.uid);
            if (medData != null && mounted) {
              setState(() {
                _bloodType = medData['blood_type'] ?? 'A+';
                _hasDiabetes = medData['has_diabetes'] ?? false;
                _hasAsthma = medData['has_asthma'] ?? false;
              });
            }
          } catch (e) {
            debugPrint('Error loading medical info: $e');
          }
        }
      }
    } catch (e) {
      _showErrorSnackBar(
          "${context.translate('error_loading_user_data')}: ${e.toString()}");
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveChanges() async {
    // Validate inputs
    if (_fullNameController.text.trim().isEmpty) {
      _showErrorSnackBar(context.translate('please_enter_full_name'));
      return;
    }

    if (_phoneController.text.trim().isEmpty) {
      _showErrorSnackBar(context.translate('please_enter_phone'));
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      if (_currentUser != null) {
        // Prepare data to update
        Map<String, dynamic> updateData = {
          'full_name': _fullNameController.text.trim(),
          'phone_number': _phoneController.text.trim(),
          'address': _addressController.text.trim(),
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        };

        // Process and add profile image if a new one was selected
        if (_imageFile != null) {
          final bytes = await compute(_readFileBytes, _imageFile!);

          if (bytes.isNotEmpty) {
            final base64Image = await compute(_encodeToBase64, bytes);

            if (base64Image.length > 900000) {
              throw Exception(context.translate('image_too_large'));
            }

            updateData['profile_image_base64'] = base64Image;
            updateData['profile_image_updated_at'] = DateTime.now().toUtc().toIso8601String();
          }
        }

        // Update user profile in Supabase
        await SupabaseService.updateProfile(_currentUser!.uid, updateData);

        // Update medical info
        await SupabaseService.upsertMedicalInfo(_currentUser!.uid, {
          'blood_type': _bloodType,
          'has_diabetes': _hasDiabetes,
          'has_asthma': _hasAsthma,
        });

        // Show success message
        _showSuccessSnackBar(context.translate('profile_updated_success'));

        // Navigate back after success
        if (mounted) {
          Navigator.pop(
              context, true); // Pass true to indicate successful update
        }
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar(
            "${context.translate('error_updating_profile')}: ${e.toString()}");
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Future<void> _pickImage() async {
    try {
      // Request permissions if needed
      await _requestPermissions();

      showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        builder: (BuildContext context) {
          final colorScheme = Theme.of(context).colorScheme;
          final languageProvider = Provider.of<LanguageProvider>(context);
          final isRTL = languageProvider.isRTL;

          return Directionality(
            textDirection: isRTL ? TextDirection.rtl : TextDirection.ltr,
            child: Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    context.translate('choose_option'),
                    style: GoogleFonts.lexend(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  SizedBox(height: 16),
                  ListTile(
                    leading:
                        Icon(Icons.photo_library, color: colorScheme.primary),
                    title: Text(
                      context.translate('pick_from_gallery'),
                      style: TextStyle(color: colorScheme.onSurface),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      _pickImageFromSource(ImageSource.gallery);
                    },
                  ),
                  ListTile(
                    leading: Icon(Icons.camera_alt, color: colorScheme.primary),
                    title: Text(
                      context.translate('take_photo'),
                      style: TextStyle(color: colorScheme.onSurface),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      _pickImageFromSource(ImageSource.camera);
                    },
                  ),
                ],
              ),
            ),
          );
        },
      );
    } catch (e) {
      _showErrorSnackBar(
          "${context.translate('error_accessing_camera')}: ${e.toString()}");
    }
  }

  Future<void> _requestPermissions() async {
    if (await Permission.camera.status.isDenied) {
      await Permission.camera.request();
    }

    if (await Permission.storage.status.isDenied) {
      await Permission.storage.request();
    }

    if (await Permission.photos.status.isDenied) {
      await Permission.photos.request();
    }
  }

  Future<void> _pickImageFromSource(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 800, // Limit image dimensions for better performance
        maxHeight: 800,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        // Create a copy in the app's documents directory
        final Directory appDocDir = await getApplicationDocumentsDirectory();
        final String appDocPath = appDocDir.path;
        final String fileName =
            'profile_${DateTime.now().millisecondsSinceEpoch}.jpg';
        final String filePath = '$appDocPath/$fileName';

        // Copy the picked file to our app's documents directory
        final File originalFile = File(pickedFile.path);
        final File destinationFile = await originalFile.copy(filePath);

        // Only update state once with the new image
        setState(() {
          _imageFile = destinationFile;
        });
      }
    } catch (e) {
      _showErrorSnackBar(
          "${context.translate('error_selecting_image')}: ${e.toString()}");
    }
  }

  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red.shade800,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  void _showSuccessSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.green.shade800,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  void _showDeleteAccountDialog() {
    // Local variable to hold the confirmation text inside the dialog
    String localDeleteConfirmText = '';

    showDialog(
      context: context,
      builder: (BuildContext context) {
        final colorScheme = Theme.of(context).colorScheme;
        final languageProvider = Provider.of<LanguageProvider>(context);
        final isRTL = languageProvider.isRTL;

        return StatefulBuilder(builder: (context, setDialogState) {
          return Directionality(
            textDirection: isRTL ? TextDirection.rtl : TextDirection.ltr,
            child: AlertDialog(
              title: Text(
                context.translate('delete_account_confirmation'),
                style: TextStyle(
                  color: colorScheme.error,
                  fontWeight: FontWeight.bold,
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(context.translate('delete_account_warning_detail')),
                  SizedBox(height: 16),
                  TextField(
                    decoration: InputDecoration(
                      labelText: context.translate('type_confirm'),
                      hintText: context.translate('confirm'),
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) {
                      // Update local variable AND dialog state
                      setDialogState(() {
                        localDeleteConfirmText = value;
                      });
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text(
                    context.translate('cancel'),
                    style: TextStyle(color: colorScheme.primary),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.error,
                    foregroundColor: colorScheme.onError,
                  ),
                  onPressed: localDeleteConfirmText.toLowerCase() == 'confirm'
                      ? _handleDeleteAccount
                      : null,
                  child: Text(context.translate('delete_my_account')),
                ),
              ],
            ),
          );
        });
      },
    );
  }

  void _handleDeleteAccount() {
    Navigator.of(context).pop(); // Close the dialog

    // Show a loading indicator dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text(
                context.translate('deleting_account') ?? 'Deleting account...',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      },
    );

    // Start the actual deletion process
    _deleteUserAccount();
  }

  // Delete the user account and all related data
  Future<void> _deleteUserAccount() async {
    try {
      if (_currentUser == null) {
        throw Exception('User not found');
      }

      final userId = _currentUser!.uid;

      // 1. Delete all user data from Firestore
      await _deleteUserData(userId);

      // 2. Delete the user from Firebase Auth
      await _currentUser!.delete();

      // Close the loading dialog
      if (mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }

      // Navigate to login screen
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
        );

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              context.translate('account_deleted') ??
                  'Account successfully deleted',
              style: TextStyle(color: Colors.white),
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } catch (e) {
      print('Error deleting account: $e');

      // Close the loading dialog
      if (mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }

      // Show error message
      if (mounted) {
        String errorMessage = e.toString();

        // Handle specific Firebase Auth errors
        if (e is FirebaseAuthException) {
          switch (e.code) {
            case 'requires-recent-login':
              errorMessage = context.translate('requires_recent_login') ??
                  'Please log out and log in again to delete your account';
              break;
            default:
              errorMessage = '${e.code}: ${e.message}';
          }
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${context.translate('error_deleting_account') ?? 'Error deleting account'}: $errorMessage',
              style: TextStyle(color: Colors.white),
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    }
  }

  Future<void> _deleteUserData(String userId) async {
    try {
      print('Starting deletion process for user: $userId');

      // Delete related records (tables without CASCADE)
      try { await SupabaseService.client.from('appointments').delete().eq('patient_id', userId); } catch (_) {}
      try { await SupabaseService.client.from('medical_records').delete().eq('patient_id', userId); } catch (_) {}
      try { await SupabaseService.client.from('prescriptions').delete().eq('user_id', userId); } catch (_) {}
      try { await SupabaseService.client.from('health_metrics').delete().eq('user_id', userId); } catch (_) {}

      // Delete profile (cascades to medical_info, medications)
      await SupabaseService.deleteProfile(userId);
      print('Deleted user profile and cascading data');
    } catch (e) {
      print('Error deleting user data: $e');
      throw e;
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    final colorScheme = Theme.of(context).colorScheme;
    final screenSize = MediaQuery.of(context).size;
    final screenWidth = screenSize.width;
    final screenHeight = screenSize.height;
    final languageProvider = Provider.of<LanguageProvider>(context);
    final isRTL = languageProvider.isRTL;

    return Directionality(
      textDirection: isRTL ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            context.translate('edit_profile'),
            style: GoogleFonts.lexend(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
          backgroundColor: colorScheme.surface,
          elevation: 0,
          centerTitle: true,
          leading: IconButton(
            icon: Icon(
              isRTL ? Icons.arrow_forward : Icons.arrow_back,
              color: colorScheme.onSurface,
            ),
            onPressed: () => Navigator.pop(context),
          ),
          actions: [
            if (_isSaving)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Center(
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: colorScheme.primary,
                    ),
                  ),
                ),
              )
            else
              IconButton(
                icon: Icon(
                  Icons.check,
                  color: colorScheme.primary,
                ),
                onPressed: _saveChanges,
              ),
          ],
        ),
        backgroundColor: colorScheme.background,
        body: _isLoading
            ? Center(
                child: CircularProgressIndicator(
                  color: colorScheme.primary,
                ),
              )
            : SafeArea(
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: ListView(
                    padding: EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 24,
                    ),
                    children: [
                      // Profile Image Section
                      Center(
                        child: GestureDetector(
                          onTap: _pickImage,
                          child: Stack(
                            children: [
                              // Profile image - Optimized with RepaintBoundary
                              RepaintBoundary(
                                child: Hero(
                                  tag: 'profileImage',
                                  child: AnimatedContainer(
                                    duration: Duration(milliseconds: 300),
                                    width: screenWidth * 0.28,
                                    height: screenWidth * 0.28,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: isDarkMode
                                          ? Colors.grey[800]
                                          : Colors.grey[200],
                                      border: Border.all(
                                        color: colorScheme.primary
                                            .withOpacity(0.5),
                                        width: 2,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.1),
                                          blurRadius: 10,
                                          spreadRadius: 1,
                                        ),
                                      ],
                                      image: _buildProfileImage(),
                                    ),
                                    child: (_imageFile == null &&
                                            (_profileImageBase64 == null ||
                                                _profileImageBase64!.isEmpty))
                                        ? Icon(
                                            Icons.person,
                                            size: screenWidth * 0.14,
                                            color: isDarkMode
                                                ? Colors.white54
                                                : Colors.grey,
                                          )
                                        : null,
                                  ),
                                ),
                              ),
                              // Camera icon overlay
                              Positioned(
                                right: isRTL ? null : 0,
                                left: isRTL ? 0 : null,
                                bottom: 0,
                                child: Container(
                                  padding: EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: colorScheme.primary,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: colorScheme.background,
                                      width: 2,
                                    ),
                                  ),
                                  child: Icon(
                                    Icons.camera_alt,
                                    size: 16,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      Center(
                        child: Padding(
                          padding: EdgeInsets.only(top: 8, bottom: 24),
                          child: Text(
                            context.translate('change_profile_picture'),
                            style: GoogleFonts.lexend(
                              fontSize: screenWidth * 0.035,
                              color: colorScheme.primary,
                            ),
                          ),
                        ),
                      ),

                      // Form Fields Container
                      Container(
                        decoration: BoxDecoration(
                          color: isDarkMode
                              ? colorScheme.surface.withOpacity(0.3)
                              : colorScheme.surface,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              spreadRadius: 0,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        padding: EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Full Name
                            _buildFormField(
                              label: context.translate('full_name'),
                              controller: _fullNameController,
                              focusNode: _fullNameFocus,
                              context: context,
                              prefixIcon: Icons.person_outline,
                              textInputAction: TextInputAction.next,
                              onEditingComplete: () => FocusScope.of(context)
                                  .requestFocus(_phoneFocus),
                            ),

                            // Email (Non-editable)
                            _buildNonEditableField(
                              label: context.translate('email'),
                              value: _email,
                              prefixIcon: Icons.email_outlined,
                              context: context,
                            ),

                            // Role (Non-editable)
                            _buildNonEditableField(
                              label: context.translate('role'),
                              value: _role,
                              prefixIcon: Icons.work_outline,
                              context: context,
                            ),

                            // Phone Number
                            _buildFormField(
                              label: context.translate('phone_number'),
                              controller: _phoneController,
                              focusNode: _phoneFocus,
                              context: context,
                              prefixIcon: Icons.phone_outlined,
                              keyboardType: TextInputType.phone,
                              textInputAction: TextInputAction.next,
                              onEditingComplete: () => FocusScope.of(context)
                                  .requestFocus(_addressFocus),
                            ),

                            // Address
                            _buildFormField(
                              label: context.translate('address'),
                              controller: _addressController,
                              focusNode: _addressFocus,
                              context: context,
                              prefixIcon: Icons.home_outlined,
                              textInputAction: TextInputAction.done,
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: 32),

                      // Delete Account Section
                      Container(
                        decoration: BoxDecoration(
                          color: isDarkMode
                              ? Colors.red.withOpacity(0.1)
                              : Colors.red.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.red.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        padding: EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Delete Account Header
                            Row(
                              children: [
                                Icon(Icons.warning_amber_rounded,
                                    color: Colors.red),
                                SizedBox(width: 8),
                                Text(
                                  context.translate('delete_account'),
                                  style: GoogleFonts.lexend(
                                    fontSize: screenWidth * 0.045,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.red,
                                  ),
                                ),
                              ],
                            ),

                            SizedBox(height: 12),

                            // Warning Text
                            Text(
                              context.translate('delete_account_warning'),
                              style: GoogleFonts.lexend(
                                fontSize: screenWidth * 0.035,
                                color:
                                    colorScheme.onBackground.withOpacity(0.7),
                              ),
                            ),

                            SizedBox(height: 16),

                            // Delete Account Button
                            Center(
                              child: ElevatedButton.icon(
                                onPressed: _showDeleteAccountDialog,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                  foregroundColor: Colors.white,
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 24,
                                    vertical: 12,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 0,
                                ),
                                icon: Icon(Icons.delete_forever),
                                label: Text(
                                  context.translate('delete_my_account'),
                                  style: GoogleFonts.lexend(
                                    fontSize: screenWidth * 0.04,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  DecorationImage? _buildProfileImage() {
    if (_imageFile != null) {
      return DecorationImage(
        image: FileImage(_imageFile!),
        fit: BoxFit.cover,
      );
    } else if (_profileImageBase64 != null && _profileImageBase64!.isNotEmpty) {
      try {
        return DecorationImage(
          image: MemoryImage(
            base64Decode(_profileImageBase64!),
          ),
          fit: BoxFit.cover,
        );
      } catch (e) {
        debugPrint('Error creating image from base64: $e');
        return null;
      }
    }
    return null;
  }

  Widget _buildSectionTitle(String title, BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final screenWidth = MediaQuery.of(context).size.width;

    return Padding(
      padding: EdgeInsets.only(bottom: 8, top: 16),
      child: Text(
        title,
        style: GoogleFonts.lexend(
          fontSize: screenWidth * 0.04,
          fontWeight: FontWeight.bold,
          color: colorScheme.onBackground,
        ),
      ),
    );
  }

  Widget _buildFormField({
    required String label,
    required TextEditingController controller,
    required FocusNode focusNode,
    required BuildContext context,
    required IconData prefixIcon,
    TextInputType? keyboardType,
    TextInputAction? textInputAction,
    VoidCallback? onEditingComplete,
  }) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    final colorScheme = Theme.of(context).colorScheme;
    final screenSize = MediaQuery.of(context).size;
    final screenWidth = screenSize.width;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(label, context),
        AnimatedContainer(
          duration: Duration(milliseconds: 300),
          margin: EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: isDarkMode ? const Color(0xFF2C2C2C) : Colors.grey[200],
            borderRadius: BorderRadius.circular(12),
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
              color:
                  focusNode.hasFocus ? colorScheme.primary : Colors.transparent,
              width: 1.5,
            ),
          ),
          child: TextField(
            controller: controller,
            focusNode: focusNode,
            keyboardType: keyboardType,
            textInputAction: textInputAction,
            onEditingComplete: onEditingComplete,
            style: GoogleFonts.lexend(
              fontSize: screenWidth * 0.04,
              color: colorScheme.onBackground,
            ),
            decoration: InputDecoration(
              prefixIcon: Icon(
                prefixIcon,
                color: focusNode.hasFocus
                    ? colorScheme.primary
                    : colorScheme.onBackground.withOpacity(0.6),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Colors.transparent,
              contentPadding: EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNonEditableField({
    required String label,
    required String value,
    required IconData prefixIcon,
    required BuildContext context,
  }) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    final colorScheme = Theme.of(context).colorScheme;
    final screenSize = MediaQuery.of(context).size;
    final screenWidth = screenSize.width;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(label, context),
        Container(
          margin: EdgeInsets.only(bottom: 16),
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            color: isDarkMode
                ? const Color(0xFF2C2C2C).withOpacity(0.7)
                : Colors.grey[200]!.withOpacity(0.7),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.transparent,
              width: 1.5,
            ),
          ),
          child: Row(
            children: [
              Icon(
                prefixIcon,
                color: colorScheme.onBackground.withOpacity(0.6),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Text(
                  value,
                  style: GoogleFonts.lexend(
                    fontSize: screenWidth * 0.04,
                    color: colorScheme.onBackground.withOpacity(0.8),
                  ),
                ),
              ),
              Icon(
                Icons.lock_outline,
                size: 16,
                color: colorScheme.onBackground.withOpacity(0.4),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
