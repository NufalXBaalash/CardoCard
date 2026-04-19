import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
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

  // Medical data
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
        // Fetch user data from Firestore
        final userDoc =
            await _firestore.collection('users').doc(_currentUser!.uid).get();

        if (userDoc.exists) {
          final userData = userDoc.data()!;

          setState(() {
            _fullName = userData['fullName'] ?? '';
            _email = userData['email'] ?? '';
            _phoneNumber = userData['phoneNumber'] ?? '';
            _address = userData['address'] ?? '';
            _profileImageBase64 = userData['profileImageBase64'];
            _role = userData['role'] ?? context.translate('patient');

            // Set controller values
            _fullNameController.text = _fullName;
            _phoneController.text = _phoneNumber;
            _addressController.text = _address;
          });
        }

        // Fetch medical info
        final medicalDoc = await _firestore.collection('medical_info').doc(_currentUser!.uid).get();
        if (medicalDoc.exists) {
          final medicalData = medicalDoc.data()!;
          setState(() {
            _bloodType = medicalData['bloodType'] ?? 'A+';
            _hasDiabetes = medicalData['hasDiabetes'] ?? false;
            _hasAsthma = medicalData['hasAsthma'] ?? false;
          });
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
          'fullName': _fullNameController.text.trim(),
          'phoneNumber': _phoneController.text.trim(),
          'address': _addressController.text.trim(),
          'updatedAt': FieldValue.serverTimestamp(),
        };

        // Process and add profile image if a new one was selected
        if (_imageFile != null) {
          // Move image processing to a background isolate for better performance
          final bytes = await compute(_readFileBytes, _imageFile!);

          if (bytes.isNotEmpty) {
            // Also move base64 encoding to background for performance
            final base64Image = await compute(_encodeToBase64, bytes);

            // Check if image size is reasonable (under 900KB in base64)
            if (base64Image.length > 900000) {
              throw Exception(context.translate('image_too_large'));
            }

            updateData['profileImageBase64'] = base64Image;
            updateData['profileImageUpdatedAt'] = FieldValue.serverTimestamp();
          }
        }

        // Update user document in Firestore
        await _firestore
            .collection('users')
            .doc(_currentUser!.uid)
            .update(updateData);

        // Update medical info
        await _firestore
            .collection('medical_info')
            .doc(_currentUser!.uid)
            .set({
          'bloodType': _bloodType,
          'hasDiabetes': _hasDiabetes,
          'hasAsthma': _hasAsthma,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

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

      final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
      final isDarkMode = themeProvider.isDarkMode;
      final primaryCyan = const Color(0xFF00E5FF);
      final bgDark = const Color(0xFF0F0F0F);

      showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        barrierColor: Colors.black.withOpacity(0.5),
        builder: (BuildContext context) {
          final languageProvider = Provider.of<LanguageProvider>(context);
          final isRTL = languageProvider.isRTL;

          return Directionality(
            textDirection: isRTL ? TextDirection.rtl : TextDirection.ltr,
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: isDarkMode 
                      ? bgDark.withOpacity(0.9) 
                      : Colors.white.withOpacity(0.9),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(32),
                    topRight: Radius.circular(32),
                  ),
                  border: Border.all(
                    color: primaryCyan.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: (isDarkMode ? Colors.white : Colors.black).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      context.translate('choose_option').toUpperCase(),
                      style: GoogleFonts.orbitron(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isDarkMode ? Colors.white : Colors.black,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 32),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildImageOption(
                          context,
                          icon: Icons.photo_library_rounded,
                          label: context.translate('gallery'),
                          onTap: () {
                            Navigator.pop(context);
                            _pickImageFromSource(ImageSource.gallery);
                          },
                          isDarkMode: isDarkMode,
                          primaryCyan: primaryCyan,
                        ),
                        _buildImageOption(
                          context,
                          icon: Icons.camera_alt_rounded,
                          label: context.translate('camera'),
                          onTap: () {
                            Navigator.pop(context);
                            _pickImageFromSource(ImageSource.camera);
                          },
                          isDarkMode: isDarkMode,
                          primaryCyan: primaryCyan,
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
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

  Widget _buildImageOption(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required bool isDarkMode,
    required Color primaryCyan,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: primaryCyan.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: primaryCyan.withOpacity(0.3),
              ),
            ),
            child: Icon(
              icon,
              color: primaryCyan,
              size: 30,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            label.toUpperCase(),
            style: GoogleFonts.orbitron(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.white : Colors.black,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
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
    String localDeleteConfirmText = '';
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final isDarkMode = themeProvider.isDarkMode;
    final bgDark = const Color(0xFF0F0F0F);

    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.7),
      builder: (BuildContext context) {
        final languageProvider = Provider.of<LanguageProvider>(context);
        final isRTL = languageProvider.isRTL;

        return StatefulBuilder(builder: (context, setDialogState) {
          return Directionality(
            textDirection: isRTL ? TextDirection.rtl : TextDirection.ltr,
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Dialog(
                backgroundColor: Colors.transparent,
                insetPadding: const EdgeInsets.symmetric(horizontal: 24),
                child: Container(
                  decoration: BoxDecoration(
                    color: isDarkMode 
                        ? bgDark.withOpacity(0.8) 
                        : Colors.white.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: Colors.redAccent.withOpacity(0.5),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.redAccent.withOpacity(0.1),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 28),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                context.translate('delete_account_confirmation').toUpperCase(),
                                style: GoogleFonts.orbitron(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: isDarkMode ? Colors.white : Colors.black,
                                  letterSpacing: 1.2,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Text(
                          context.translate('delete_account_warning_detail'),
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: (isDarkMode ? Colors.white : Colors.black).withOpacity(0.7),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Container(
                          decoration: BoxDecoration(
                            color: (isDarkMode ? Colors.white : Colors.black).withOpacity(0.05),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: (isDarkMode ? Colors.white : Colors.black).withOpacity(0.1),
                            ),
                          ),
                          child: TextField(
                            onChanged: (value) {
                              setDialogState(() {
                                localDeleteConfirmText = value;
                              });
                            },
                            style: GoogleFonts.poppins(
                              color: isDarkMode ? Colors.white : Colors.black,
                            ),
                            decoration: InputDecoration(
                              hintText: context.translate('confirm'),
                              hintStyle: TextStyle(
                                color: (isDarkMode ? Colors.white : Colors.black).withOpacity(0.3),
                              ),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              border: InputBorder.none,
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: Text(
                                context.translate('cancel').toUpperCase(),
                                style: GoogleFonts.orbitron(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: (isDarkMode ? Colors.white : Colors.black).withOpacity(0.5),
                                  letterSpacing: 1,
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            ElevatedButton(
                              onPressed: localDeleteConfirmText.toLowerCase() == 'confirm'
                                  ? _handleDeleteAccount
                                  : null,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.redAccent,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                disabledBackgroundColor: Colors.redAccent.withOpacity(0.3),
                              ),
                              child: Text(
                                context.translate('delete_my_account').toUpperCase(),
                                style: GoogleFonts.orbitron(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        });
      },
    );
  }

  void _handleDeleteAccount() {
    Navigator.of(context).pop(); // Close the dialog

    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final isDarkMode = themeProvider.isDarkMode;
    final primaryCyan = const Color(0xFF00E5FF);
    final bgDark = const Color(0xFF0F0F0F);

    // Show a loading indicator dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.7),
      builder: (BuildContext context) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Dialog(
            backgroundColor: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: isDarkMode 
                    ? bgDark.withOpacity(0.8) 
                    : Colors.white.withOpacity(0.8),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: primaryCyan.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(
                    color: primaryCyan,
                    strokeWidth: 2,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    context.translate('deleting_account').toUpperCase(),
                    textAlign: TextAlign.center,
                    style: GoogleFonts.orbitron(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isDarkMode ? Colors.white : Colors.black,
                      letterSpacing: 2,
                    ),
                  ),
                ],
              ),
            ),
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

  // Delete all user data from Firestore
  Future<void> _deleteUserData(String userId) async {
    try {
      print('Starting deletion process for user: $userId');

      // 1. Delete user document from users collection
      await _firestore.collection('users').doc(userId).delete();
      print('✓ Deleted user document from users collection');

      // 2. Delete user document from medical_info collection (directly using userId as document ID)
      try {
        await _firestore.collection('medical_info').doc(userId).delete();
        print('✓ Deleted user document from medical_info collection');
      } catch (e) {
        print('Error deleting from medical_info: $e');
        // Continue with deletion process even if this fails
      }

      // Optional: If you still need these other collections, but can simplify if not needed
      await _deleteCollectionData('medicalRecords', userId);
      await _deleteCollectionData('appointments', userId);
      await _deleteCollectionData('prescriptions', userId);
      await _deleteCollectionData('healthMetrics', userId);
    } catch (e) {
      print('Error deleting user data: $e');
      throw e; // Rethrow to handle in the calling function
    }
  }

  // Delete documents from a collection where userId matches
  Future<void> _deleteCollectionData(
      String collectionName, String userId) async {
    try {
      // Query for documents where userId field equals the current user's ID
      final querySnapshot = await _firestore
          .collection(collectionName)
          .where('userId', isEqualTo: userId)
          .get();

      print(
          'Found ${querySnapshot.docs.length} documents in $collectionName to delete');

      // Use batched writes for better performance
      final batch = _firestore.batch();
      int count = 0;

      for (var doc in querySnapshot.docs) {
        batch.delete(doc.reference);
        count++;

        // Firebase allows maximum 500 operations in a batch
        if (count >= 500) {
          await batch.commit();
          print('Committed batch of $count deletes');
          // Reset for next batch
          count = 0;
        }
      }

      // Commit any remaining deletes
      if (count > 0) {
        await batch.commit();
        print('Committed final batch of $count deletes');
      }

      print('Successfully deleted data from $collectionName');
    } catch (e) {
      print('Error deleting from collection $collectionName: $e');
      // Continue with other deletions even if one fails
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    final languageProvider = Provider.of<LanguageProvider>(context);
    final isRTL = languageProvider.isRTL;

    final primaryCyan = isDarkMode ? const Color(0xFF00E5FF) : const Color(0xFF00B8D4);
    final bgPage = isDarkMode ? const Color(0xFF0F0F0F) : const Color(0xFFF5F7FA);
    final cardBg = isDarkMode ? Colors.white.withOpacity(0.03) : Colors.white;
    final textColor = isDarkMode ? Colors.white : const Color(0xFF0F0F0F);
    final borderColor = isDarkMode ? Colors.white.withOpacity(0.05) : primaryCyan.withOpacity(0.2);

    return Directionality(
      textDirection: isRTL ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: bgPage,
        appBar: AppBar(
          title: Text(
            context.translate('edit_profile'),
            style: GoogleFonts.orbitron(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.white : primaryCyan,
              letterSpacing: 1.5,
            ),
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          flexibleSpace: ClipRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(color: bgPage.withOpacity(0.8)),
            ),
          ),
          leading: IconButton(
            icon: Icon(
              isRTL ? Icons.arrow_forward : Icons.arrow_back,
              color: primaryCyan,
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
                      strokeWidth: 2,
                      color: primaryCyan,
                    ),
                  ),
                ),
              )
            else
              IconButton(
                icon: Icon(
                  Icons.check_circle_outline,
                  color: primaryCyan,
                  size: 28,
                ),
                onPressed: _saveChanges,
              ),
          ],
        ),
        body: _isLoading
            ? Center(
                child: CircularProgressIndicator(
                  color: primaryCyan,
                  strokeWidth: 2,
                ),
              )
            : SafeArea(
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: ListView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 24,
                    ),
                    children: [
                      // Profile Image Section with Bio-Tech Ring
                      Center(
                        child: GestureDetector(
                          onTap: _pickImage,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              // Outer Glowing Ring
                              Container(
                                width: MediaQuery.of(context).size.width * 0.35,
                                height: MediaQuery.of(context).size.width * 0.35,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: primaryCyan.withOpacity(0.3),
                                    width: 1,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: primaryCyan.withOpacity(0.1),
                                      blurRadius: 20,
                                      spreadRadius: 5,
                                    ),
                                  ],
                                ),
                              ),
                              // Profile image
                              Hero(
                                tag: 'profileImage',
                                child: Container(
                                  width: MediaQuery.of(context).size.width * 0.3,
                                  height: MediaQuery.of(context).size.width * 0.3,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: isDarkMode ? Colors.white.withOpacity(0.05) : Colors.white,
                                    border: Border.all(
                                      color: primaryCyan.withOpacity(0.5),
                                      width: 2,
                                    ),
                                    boxShadow: isDarkMode ? [] : [
                                      BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)
                                    ],
                                    image: _buildProfileImage(),
                                  ),
                                  child: (_imageFile == null &&
                                          (_profileImageBase64 == null ||
                                              _profileImageBase64!.isEmpty))
                                      ? Icon(
                                          Icons.person_outlined,
                                          size: MediaQuery.of(context).size.width * 0.15,
                                          color: primaryCyan.withOpacity(0.5),
                                        )
                                      : null,
                                ),
                              ),
                              // Camera icon overlay
                              Positioned(
                                right: 0,
                                bottom: 0,
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: primaryCyan,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: bgPage,
                                      width: 2,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: primaryCyan.withOpacity(0.4),
                                        blurRadius: 10,
                                      ),
                                    ],
                                  ),
                                  child: Icon(
                                    Icons.add_a_photo_rounded,
                                    size: 16,
                                    color: isDarkMode ? Colors.black : Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      Center(
                        child: Text(
                          context.translate('change_profile_picture').toUpperCase(),
                          style: GoogleFonts.orbitron(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: primaryCyan,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ),

                      const SizedBox(height: 40),

                      // Protocols Header
                      Text(
                        "USER PROTOCOLS",
                        style: GoogleFonts.orbitron(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: textColor.withOpacity(0.5),
                          letterSpacing: 2,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Form Fields (Glassmorphism Bento Container)
                      Container(
                        decoration: BoxDecoration(
                          color: cardBg,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: borderColor),
                          boxShadow: isDarkMode ? [] : [
                            BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10)
                          ],
                        ),
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: [
                            _buildFormField(
                              label: context.translate('full_name'),
                              controller: _fullNameController,
                              focusNode: _fullNameFocus,
                              context: context,
                              prefixIcon: Icons.person_outline_rounded,
                              textInputAction: TextInputAction.next,
                              textColor: textColor,
                              primaryCyan: primaryCyan,
                            ),
                            const SizedBox(height: 20),
                            _buildNonEditableField(
                              label: context.translate('email'),
                              value: _email,
                              prefixIcon: Icons.alternate_email_rounded,
                              context: context,
                              textColor: textColor,
                            ),
                            const SizedBox(height: 20),
                            _buildNonEditableField(
                              label: context.translate('role'),
                              value: _role,
                              prefixIcon: Icons.admin_panel_settings_outlined,
                              context: context,
                              textColor: textColor,
                            ),
                            const SizedBox(height: 20),
                            _buildFormField(
                              label: context.translate('phone_number'),
                              controller: _phoneController,
                              focusNode: _phoneFocus,
                              context: context,
                              prefixIcon: Icons.phone_android_rounded,
                              keyboardType: TextInputType.phone,
                              textInputAction: TextInputAction.next,
                              textColor: textColor,
                              primaryCyan: primaryCyan,
                            ),
                            const SizedBox(height: 20),
                            _buildFormField(
                              label: context.translate('address'),
                              controller: _addressController,
                              focusNode: _addressFocus,
                              context: context,
                              prefixIcon: Icons.location_on_outlined,
                              textInputAction: TextInputAction.done,
                              textColor: textColor,
                              primaryCyan: primaryCyan,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 32),

                      // Medical Protocols Header
                      Text(
                        "MEDICAL PROTOCOLS",
                        style: GoogleFonts.orbitron(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: primaryCyan.withOpacity(0.5),
                          letterSpacing: 2,
                        ),
                      ),
                      const SizedBox(height: 16),

                      Container(
                        decoration: BoxDecoration(
                          color: cardBg,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: borderColor),
                          boxShadow: isDarkMode ? [] : [
                            BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10)
                          ],
                        ),
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: [
                            _buildBloodTypeDropdown(context, primaryCyan, textColor, isDarkMode),
                            const SizedBox(height: 20),
                            _buildMedicalToggle(
                              label: context.translate('diabetes'),
                              value: _hasDiabetes,
                              onChanged: (val) => setState(() => _hasDiabetes = val),
                              icon: Icons.monitor_heart_rounded,
                              primaryCyan: primaryCyan,
                              textColor: textColor,
                              isDarkMode: isDarkMode,
                            ),
                            const SizedBox(height: 16),
                            _buildMedicalToggle(
                              label: context.translate('asthma'),
                              value: _hasAsthma,
                              onChanged: (val) => setState(() => _hasAsthma = val),
                              icon: Icons.air_rounded,
                              primaryCyan: primaryCyan,
                              textColor: textColor,
                              isDarkMode: isDarkMode,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 40),

                      // Security / Danger Zone Header
                      Text(
                        "SECURITY PROTOCOLS",
                        style: GoogleFonts.orbitron(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.redAccent.withOpacity(0.5),
                          letterSpacing: 2,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Delete Account Section (High-Contrast Danger Zone)
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.redAccent.withOpacity(isDarkMode ? 0.02 : 0.05),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: Colors.redAccent.withOpacity(0.2),
                            width: 1,
                          ),
                        ),
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.gpp_maybe_rounded,
                                    color: Colors.redAccent, size: 24),
                                const SizedBox(width: 12),
                                Text(
                                  context.translate('delete_account').toUpperCase(),
                                  style: GoogleFonts.orbitron(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.redAccent,
                                    letterSpacing: 1,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              context.translate('delete_account_warning'),
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: textColor.withOpacity(0.6),
                              ),
                            ),
                            const SizedBox(height: 20),
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton(
                                onPressed: _showDeleteAccountDialog,
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.redAccent,
                                  side: const BorderSide(color: Colors.redAccent),
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                child: Text(
                                  context.translate('delete_my_account').toUpperCase(),
                                  style: GoogleFonts.orbitron(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 60),
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

  Widget _buildFormField({
    required String label,
    required TextEditingController controller,
    required FocusNode focusNode,
    required BuildContext context,
    required IconData prefixIcon,
    required Color textColor,
    required Color primaryCyan,
    TextInputType? keyboardType,
    TextInputAction? textInputAction,
    VoidCallback? onEditingComplete,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: GoogleFonts.orbitron(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: textColor.withOpacity(0.4),
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: textColor.withOpacity(0.02),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: focusNode.hasFocus ? primaryCyan : textColor.withOpacity(0.1),
              width: 1,
            ),
          ),
          child: TextField(
            controller: controller,
            focusNode: focusNode,
            keyboardType: keyboardType,
            textInputAction: textInputAction,
            onEditingComplete: onEditingComplete,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: textColor,
            ),
            decoration: InputDecoration(
              prefixIcon: Icon(
                prefixIcon,
                color: focusNode.hasFocus ? primaryCyan : textColor.withOpacity(0.3),
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
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
    required Color textColor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: GoogleFonts.orbitron(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: textColor.withOpacity(0.4),
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            color: textColor.withOpacity(0.01),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: textColor.withOpacity(0.05),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                prefixIcon,
                color: textColor.withOpacity(0.2),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  value,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: textColor.withOpacity(0.5),
                  ),
                ),
              ),
              Icon(
                Icons.lock_outline_rounded,
                size: 16,
                color: textColor.withOpacity(0.2),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBloodTypeDropdown(BuildContext context, Color primaryCyan, Color textColor, bool isDarkMode) {
    final List<String> bloodTypes = ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'];
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.translate('blood_type').toUpperCase(),
          style: GoogleFonts.orbitron(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: textColor.withOpacity(0.4),
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: textColor.withOpacity(0.02),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: textColor.withOpacity(0.1)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _bloodType,
              isExpanded: true,
              dropdownColor: isDarkMode ? const Color(0xFF0F0F0F) : Colors.white,
              icon: Icon(Icons.keyboard_arrow_down_rounded, color: primaryCyan),
              style: GoogleFonts.poppins(color: textColor, fontSize: 14),
              items: bloodTypes.map((String type) {
                return DropdownMenuItem<String>(
                  value: type,
                  child: Text(type),
                );
              }).toList(),
              onChanged: (String? newValue) {
                if (newValue != null) {
                  setState(() => _bloodType = newValue);
                }
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMedicalToggle({
    required String label,
    required bool value,
    required Function(bool) onChanged,
    required IconData icon,
    required Color primaryCyan,
    required Color textColor,
    required bool isDarkMode,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: textColor.withOpacity(0.01),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: textColor.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          Icon(icon, color: primaryCyan.withOpacity(0.7), size: 20),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.poppins(color: textColor, fontSize: 14),
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: primaryCyan,
            activeTrackColor: primaryCyan.withOpacity(0.2),
            inactiveThumbColor: isDarkMode ? Colors.white24 : Colors.grey,
            inactiveTrackColor: isDarkMode ? Colors.white10 : Colors.black12,
          ),
        ],
      ),
    );
  }
}

