import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:test_1/pages/Main_page.dart';
import 'package:nfc_manager/nfc_manager.dart';
import 'package:test_1/pages/signup_page.dart';
import 'package:crypto/crypto.dart';
import 'package:test_1/utils/theme_provider.dart';
import 'package:test_1/utils/app_localizations.dart';
import 'package:test_1/utils/language_provider.dart';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  // Firebase instances
  late final FirebaseAuth _auth;
  late final FirebaseAnalytics _analytics;

  // Controllers
  final TextEditingController _cardIdController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  // State variables
  String cardIDHint = "";
  String passwordHint = "";
  bool isAuthenticating = false;
  bool _passwordVisible = false;

  // Analytics events
  static const _loginAttemptEvent = 'login_attempt';
  static const _loginSuccessEvent = 'login_success';
  static const _loginFailureEvent = 'login_failure';
  static const _loginErrorEvent = 'login_error';
  static const _validationErrorEvent = 'login_validation_error';
  static const _passwordResetAttemptEvent = 'password_reset_attempt';
  static const _passwordResetSuccessEvent = 'password_reset_success';
  static const _passwordResetFailureEvent = 'password_reset_failure';
  static const _nfcLoginAttemptEvent = 'nfc_login_attempt';
  static const _nfcLoginSuccessEvent = 'nfc_login_success';
  static const _nfcLoginFailureEvent = 'nfc_login_failure';

  @override
  void initState() {
    super.initState();
    _auth = FirebaseAuth.instance;
    _analytics = FirebaseAnalytics.instance;
    _analytics.setAnalyticsCollectionEnabled(true);
    cardIDHint = "Please enter your card id";
    passwordHint = "Please enter your password";
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _updateDefaultHints();
  }

  void _updateDefaultHints() {
    if (mounted) {
      setState(() {
        cardIDHint = context.translate('please_enter_email');
        passwordHint = context.translate('please_enter_password');
      });
    }
  }

  @override
  void dispose() {
    _cardIdController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _reloadAuthState() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser != null) {
        await currentUser.reload();
      }
    } catch (e) {
      print("Error reloading auth state: $e");
    }
  }

  Future<void> signIn() async {
    if (isAuthenticating) return;

    if (_cardIdController.text.trim().isEmpty) {
      _updateStateWithError(cardError: context.translate('email_empty_error'));
      await _logValidationError('empty_email');
      return;
    }

    if (_passwordController.text.isEmpty) {
      _updateStateWithError(
          passwordError: context.translate('password_empty_error'));
      await _logValidationError('empty_password');
      return;
    }

    _updateState(authenticating: true);

    try {
      final email = _cardIdController.text.trim();
      await _logEvent(_loginAttemptEvent, {'method': 'email', 'email': email});

      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: _passwordController.text,
      );

      if (userCredential.user != null) {
        await _reloadAuthState();
        await Future.wait([
          _analytics.logLogin(loginMethod: 'email'),
          _analytics.setUserId(id: userCredential.user!.uid),
          _analytics.setUserProperty(
            name: 'email',
            value: userCredential.user!.email,
          ),
        ]);

        if (mounted) {
          _showSnackBar(
              context.translate('authentication_successful'), Colors.green);
          Future.delayed(const Duration(seconds: 1), () {
            if (mounted && _auth.currentUser != null) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const MainPage()),
              );
            }
          });
        }
      }
    } on FirebaseAuthException catch (e) {
      await _logEvent(_loginFailureEvent, {
        'method': 'email',
        'error_code': e.code,
        'email': _cardIdController.text.trim(),
      });
      _handleFirebaseAuthError(e);
    } catch (e) {
      await _logEvent(_loginErrorEvent, {
        'method': 'email',
        'error': e.toString(),
      });
      _updateState(cardError: context.translate('general_error'));
    } finally {
      if (mounted) _updateState(authenticating: false);
    }
  }

  void _updateState({
    bool authenticating = false,
    String? cardError,
    String? passwordError,
  }) {
    if (mounted) {
      setState(() {
        isAuthenticating = authenticating;
        if (cardError != null) cardIDHint = cardError;
        if (passwordError != null) passwordHint = passwordError;
      });
    }
  }

  void _updateStateWithError({String? cardError, String? passwordError}) {
    _updateState(
      cardError: cardError,
      passwordError: passwordError,
    );
  }

  Future<void> _logEvent(String name,
      [Map<String, dynamic>? parameters]) async {
    try {
      await _analytics.logEvent(name: name, parameters: parameters);
    } catch (e) {
      debugPrint('Analytics error: $e');
    }
  }

  Future<void> _logValidationError(String errorType) async {
    await _logEvent(_validationErrorEvent, {'error_type': errorType});
  }

  Future<void> _startNFCSession(BuildContext context) async {
    try {
      setState(() => isAuthenticating = true);

      bool tagProcessed = false;

      await NfcManager.instance.startSession(
        onDiscovered: (NfcTag tag) async {
          if (tagProcessed) return;
          tagProcessed = true;

          try {
            // Read NFC tag data
            String? tokenData;

            // Try to read NDEF message from the tag
            if (tag.data.containsKey('ndef')) {
              var ndef = tag.data['ndef'];
              if (ndef != null && ndef['cachedMessage'] != null) {
                var cachedMessage = ndef['cachedMessage'];
                var records = cachedMessage['records'];
                if (records != null && records.isNotEmpty) {
                  // Get the first record's payload
                  var payload = records[0]['payload'];
                  if (payload != null) {
                    // Convert payload bytes to string
                    tokenData = String.fromCharCodes(
                        payload.skip(3)); // Skip NDEF header bytes
                    print("NFC Tag data read: $tokenData");
                    await _logEvent(
                        _nfcLoginAttemptEvent, {'token_found': 'true'});
                  }
                }
              }
            }

            await NfcManager.instance.stopSession();
            if (mounted) Navigator.pop(context);

            if (tokenData != null) {
              // Check if the token contains a URL with ID parameter or AUTH token
              if (tokenData.contains('osamakemekem.github.io/cardo/?id=') ||
                  tokenData.contains('AUTH:')) {
                await _authenticateWithNFCToken(tokenData);
              } else {
                print("Invalid token format: $tokenData");
                await _logEvent(
                    _nfcLoginFailureEvent, {'error': 'invalid_token_format'});
                if (mounted) {
                  _showSnackBar(
                      'Invalid card format or missing authentication data',
                      Colors.red);
                }
              }
            } else {
              print("No data read from NFC card");
              await _logEvent(_nfcLoginFailureEvent, {'error': 'no_data_read'});
              if (mounted) {
                _showSnackBar('No data read from card', Colors.red);
              }
            }
          } catch (e) {
            print("Error during NFC processing: $e");
            if (mounted) {
              _showSnackBar(context.translate('error_processing_nfc') + ': $e',
                  Colors.red);
            }
          } finally {
            setState(() => isAuthenticating = false);
          }
        },
        onError: (error) async {
          await NfcManager.instance.stopSession();
          if (mounted) {
            Navigator.pop(context);
            _showSnackBar(
                context.translate('nfc_error') + ': $error', Colors.red);
          }
          setState(() => isAuthenticating = false);
        },
      );
    } catch (e) {
      print("Error starting NFC session: $e");
      if (mounted) {
        _showSnackBar(
            context.translate('error_starting_nfc') + ': $e', Colors.red);
        Navigator.pop(context);
      }
      setState(() => isAuthenticating = false);
    }
  }

  Future<void> _authenticateWithNFCToken(String tokenData) async {
    setState(() => isAuthenticating = true);

    try {
      await _logEvent(_nfcLoginAttemptEvent, {'method': 'nfc_token'});
      
      // Use predefined credentials for NFC login
      final String email = "Nufalbaalash@gmail.com";
      final String password = "14102005";
      
      print("Using predefined credentials for NFC login");
      
      try {
        // Sign in with predefined email and password
        final userCredential = await _auth.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
        
        if (userCredential.user != null) {
          print("Successfully authenticated with predefined credentials");
          await _logEvent(_nfcLoginSuccessEvent, {
            'user_id': userCredential.user!.uid,
            'method': 'nfc_predefined',
          });
          
          await _onSuccessfulAuthentication(
              userCredential.user!, 'nfc_predefined');
        } else {
          await _logEvent(_nfcLoginFailureEvent, {'error': 'auth_failed'});
          throw Exception('Failed to authenticate with predefined credentials');
        }
      } catch (e) {
        print("Error authenticating with predefined credentials: $e");
        await _logEvent(_nfcLoginFailureEvent,
            {'error': 'auth_error', 'message': e.toString()});
        rethrow;
      }
      
      // The original token processing code is no longer needed since we're using
      // predefined credentials, but keeping it commented for reference
      /*
      // Check if the token contains a URL with an ID parameter
      if (tokenData.contains('osamakemekem.github.io/cardo/?id=')) {
        // Extract the user ID from the URL
        final Uri uri = Uri.parse(tokenData.trim());
        final String? userId = uri.queryParameters['id'];

        if (userId != null && userId.isNotEmpty) {
          print("Extracted user ID from NFC tag: $userId");

          try {
            // Check if the user ID exists in Firestore
            final userDoc = await FirebaseFirestore.instance
                .collection('users')
                .doc(userId)
                .get();

            if (userDoc.exists) {
              // Sign in with the extracted user ID
              await _signInWithUserId(userId);
            } else {
              await _logEvent(
                  _nfcLoginFailureEvent, {'error': 'user_not_found'});
              throw Exception('User not found in database');
            }
          } catch (e) {
            print("Error authenticating with user ID: $e");
            await _logEvent(_nfcLoginFailureEvent,
                {'error': 'auth_error', 'message': e.toString()});
            rethrow;
          }
        } else {
          await _logEvent(
              _nfcLoginFailureEvent, {'error': 'invalid_id_format'});
          throw Exception('Invalid or missing user ID in URL');
        }
      }
      // Fallback to the old AUTH token format if URL format is not found
      else if (tokenData.contains("AUTH:")) {
        // Parse the AUTH token format: AUTH:userId:timestamp:signature
        // Make sure we're only working with the AUTH part
        if (!tokenData.startsWith("AUTH:")) {
          print(
              "Warning: Token doesn't start with AUTH: prefix, but contains it elsewhere");
          // Try to extract the AUTH part from the token data
          int authIndex = tokenData.indexOf("AUTH:");
          if (authIndex >= 0) {
            tokenData = tokenData.substring(authIndex);
            print("Extracted AUTH token: $tokenData");
          } else {
            await _logEvent(
                _nfcLoginFailureEvent, {'error': 'invalid_token_format'});
            throw Exception('Invalid token format - AUTH prefix not found');
          }
        }

        final parts = tokenData.split(':');
        // We need at least 4 parts: AUTH, userId, timestamp, signature
        if (parts.length < 4 || parts[0] != 'AUTH') {
          await _logEvent(
              _nfcLoginFailureEvent, {'error': 'invalid_token_format'});
          throw Exception('Invalid token format - incorrect number of parts');
        }

        final userId = parts[1];
        final timestamp = parts[2];
        final receivedSignature = parts[3];

        // Verify the signature
        final signatureBase = userId + ":" + timestamp;
        final expectedSignature = sha256
            .convert(utf8.encode(signatureBase))
            .toString()
            .substring(0, 16);

        if (receivedSignature != expectedSignature) {
          await _logEvent(
              _nfcLoginFailureEvent, {'error': 'invalid_signature'});
          throw Exception('Invalid token signature');
        }

        // Check if token is expired (optional, can be implemented based on requirements)
        final tokenTimestamp = int.tryParse(timestamp) ?? 0;
        final currentTime = DateTime.now().millisecondsSinceEpoch;
        final tokenAge = currentTime - tokenTimestamp;

        // Token expires after 24 hours (86400000 milliseconds)
        if (tokenAge > 86400000) {
          await _logEvent(_nfcLoginFailureEvent, {'error': 'token_expired'});
          throw Exception('Token has expired');
        }

        // Sign in with custom token or get user by ID
        try {
          // In a real implementation, you would need to have a server that can generate
          // a custom token for this userId, or use another authentication method
          // For this example, we'll use signInAnonymously and then link it to the userId
          final userCredential = await _auth.signInAnonymously();

          if (userCredential.user != null) {
            // Store the userId in the user's metadata or Firestore
            await FirebaseFirestore.instance
                .collection('users')
                .doc(userCredential.user!.uid)
                .set({
              'linkedUserId': userId,
              'authMethod': 'nfc_token',
              'lastLogin': FieldValue.serverTimestamp(),
              'tokenTimestamp': timestamp,
            }, SetOptions(merge: true));

            print("Successfully authenticated user with NFC token");
            await _logEvent(_nfcLoginSuccessEvent, {
              'user_id': userCredential.user!.uid,
              'linked_user_id': userId,
            });

            await _onSuccessfulAuthentication(
                userCredential.user!, 'nfc_token');
          } else {
            await _logEvent(_nfcLoginFailureEvent, {'error': 'auth_failed'});
            throw Exception('Failed to authenticate with token');
          }
        } catch (e) {
          print("Error authenticating with token: $e");
          await _logEvent(_nfcLoginFailureEvent,
              {'error': 'auth_error', 'message': e.toString()});
          rethrow;
        }
      } else {
        await _logEvent(
            _nfcLoginFailureEvent, {'error': 'invalid_token_format'});
        throw Exception('Invalid token format - URL or AUTH prefix not found');
      }
      */
    } catch (e) {
      print("Error processing NFC token: $e");
      await _logEvent(_nfcLoginFailureEvent,
          {'error': 'processing_error', 'message': e.toString()});
      if (mounted) {
        _showSnackBar(
            context.translate('authentication_error') + ': $e', Colors.red);
      }
    } finally {
      setState(() => isAuthenticating = false);
    }
  }

  // New method to sign in with user ID
  Future<void> _signInWithUserId(String userId) async {
    try {
      // For security, we should verify this on a server, but for this example:
      // We'll use signInAnonymously and then link it to the userId in Firestore
      final userCredential = await _auth.signInAnonymously();

      if (userCredential.user != null) {
        // Store the userId in the user's metadata or Firestore
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userCredential.user!.uid)
            .set({
          'linkedUserId': userId,
          'authMethod': 'nfc_url',
          'lastLogin': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        print("Successfully authenticated user with NFC URL");
        await _logEvent(_nfcLoginSuccessEvent, {
          'user_id': userCredential.user!.uid,
          'linked_user_id': userId,
        });

        await _onSuccessfulAuthentication(userCredential.user!, 'nfc_url');
      } else {
        await _logEvent(_nfcLoginFailureEvent, {'error': 'auth_failed'});
        throw Exception('Failed to authenticate with user ID');
      }
    } catch (e) {
      print("Error signing in with user ID: $e");
      await _logEvent(_nfcLoginFailureEvent,
          {'error': 'sign_in_error', 'message': e.toString()});
      rethrow;
    }
  }

  Future<void> _onSuccessfulAuthentication(User user, String method) async {
    if (!mounted) return;

    print("Authentication successful! User ID: ${user.uid}");

    try {
      await user.reload();
    } catch (e) {
      print("Error reloading user data: $e");
    }

    await _logEvent(_loginSuccessEvent, {'method': method});

    await Future.wait([
      _analytics.logLogin(loginMethod: method),
      _analytics.setUserId(id: user.uid),
      _analytics.setUserProperty(
        name: 'login_method',
        value: method,
      ),
    ]);

    if (mounted) {
      _showSnackBar(
          context.translate('authentication_successful'), Colors.green);
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const MainPage()),
      );
    }
  }

  void _showSnackBar(String message, Color backgroundColor) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
      ),
    );
  }

  void _handleFirebaseAuthError(FirebaseAuthException e) {
    if (e.code == 'user-not-found') {
      _updateStateWithError(
        cardError: context.translate('user_not_found'),
      );
      _cardIdController.clear();
    } else if (e.code == 'invalid-email') {
      _updateStateWithError(
        cardError: context.translate('invalid_email'),
      );
      _cardIdController.clear();
    } else if (e.code == 'wrong-password') {
      _updateStateWithError(
        passwordError: context.translate('wrong_password'),
      );
      _passwordController.clear();
    } else {
      _updateStateWithError(
        cardError: context.translate('auth_error') + ": ${e.code}",
      );
    }
  }

  Future<void> resetPassword(String email) async {
    try {
      await _logEvent(_passwordResetAttemptEvent, {'email': email});
      await _auth.sendPasswordResetEmail(email: email);
      await _logEvent(_passwordResetSuccessEvent, {'email': email});
      _showSnackBar(
        context.translate('password_reset_email_sent'),
        Colors.green,
      );
    } on FirebaseAuthException catch (e) {
      await _logEvent(_passwordResetFailureEvent, {
        'email': email,
        'error_code': e.code,
      });
      _showSnackBar(
        e.message ?? context.translate('general_error'),
        Colors.red,
      );
    }
  }

  void _showNFCScanDialog(BuildContext context, double screenWidth) async {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    bool isNFCAvailable = false;
    String statusMessage = context.translate('checking_nfc');

    try {
      isNFCAvailable = await NfcManager.instance.isAvailable();
      statusMessage = isNFCAvailable
          ? context.translate('tap_card')
          : context.translate('nfc_unavailable');
    } catch (e) {
      statusMessage = context.translate('error_checking_nfc');
    }

    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          backgroundColor: colorScheme.surface,
          title: Column(
            children: [
              Image.asset(
                "lib/images/contactless.png",
                width: screenWidth * 0.2,
                height: screenWidth * 0.2,
              ),
              Text(
                context.translate('card_authentication'),
                style: TextStyle(
                  fontSize: screenWidth * 0.05,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                statusMessage,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: screenWidth * 0.04,
                  color: colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
              if (isNFCAvailable) ...[
                SizedBox(height: 16),
                Icon(
                  Icons.nfc,
                  size: screenWidth * 0.1,
                  color: colorScheme.primary,
                ),
                SizedBox(height: 16),
                Text(
                  context.translate('waiting_for_card'),
                  style: TextStyle(
                    fontSize: screenWidth * 0.035,
                    color: colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
                SizedBox(height: 8),
                CircularProgressIndicator(
                  color: colorScheme.primary,
                  strokeWidth: 3,
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                if (isNFCAvailable) NfcManager.instance.stopSession();
                Navigator.pop(context);
                setState(() => isAuthenticating = false);
              },
              child: Text(
                context.translate('cancel'),
                style: TextStyle(
                  color: colorScheme.primary,
                  fontSize: screenWidth * 0.035,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (isNFCAvailable) _startNFCSession(context);
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final languageProvider = Provider.of<LanguageProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final screenSize = MediaQuery.of(context).size;
    final screenHeight = screenSize.height;
    final screenWidth = screenSize.width;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: colorScheme.background,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.05),
          child: Column(
            children: [
              SizedBox(height: screenHeight * 0.04),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Column(
                      children: [
                        Image.asset(
                          "lib/images/app_logo2.png",
                          width: screenWidth * 0.3,
                          height: screenWidth * 0.3,
                        ),
                        Text(
                          context.translate('app_name'),
                          style: GoogleFonts.lexend(
                            fontSize: screenWidth * 0.08,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onBackground,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: screenHeight * 0.005),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          context.translate('card_id'),
                          style: GoogleFonts.inter(
                            fontSize: screenWidth * 0.04,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onBackground,
                          ),
                        ),
                        SizedBox(height: screenHeight * 0.008),
                        TextField(
                          controller: _cardIdController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: isDarkMode
                                ? const Color(0xFF2C2C2C)
                                : Colors.grey[200],
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide.none,
                            ),
                            hintText: cardIDHint,
                            hintStyle: TextStyle(
                              color: const [
                                "Invalid email address",
                                "Authentication error",
                                "An error occurred",
                                "User not found",
                                "Email cannot be empty",
                              ].contains(cardIDHint)
                                  ? Colors.red
                                  : isDarkMode
                                      ? const Color(0xFFAAAAAA)
                                      : Colors.grey,
                              fontSize: screenWidth * 0.035,
                            ),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: screenHeight * 0.015,
                            ),
                          ),
                          style: TextStyle(color: colorScheme.onBackground),
                          onChanged: (value) {
                            if (cardIDHint !=
                                context.translate('please_enter_email')) {
                              setState(() {
                                cardIDHint =
                                    context.translate('please_enter_email');
                              });
                            }
                          },
                          textInputAction: TextInputAction.next,
                        ),
                        SizedBox(height: screenHeight * 0.015),
                        Text(
                          context.translate('password'),
                          style: GoogleFonts.inter(
                            fontSize: screenWidth * 0.04,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onBackground,
                          ),
                        ),
                        SizedBox(height: screenHeight * 0.008),
                        TextField(
                          controller: _passwordController,
                          obscureText: !_passwordVisible,
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: isDarkMode
                                ? const Color(0xFF2C2C2C)
                                : Colors.grey[200],
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide.none,
                            ),
                            hintText: passwordHint,
                            hintStyle: TextStyle(
                              color: const [
                                "Incorrect password",
                                "Password cannot be empty",
                              ].contains(passwordHint)
                                  ? Colors.red
                                  : isDarkMode
                                      ? const Color(0xFFAAAAAA)
                                      : Colors.grey,
                              fontSize: screenWidth * 0.035,
                            ),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: screenHeight * 0.015,
                            ),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _passwordVisible
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                                color:
                                    isDarkMode ? Colors.grey : Colors.grey[600],
                              ),
                              onPressed: () {
                                setState(() {
                                  _passwordVisible = !_passwordVisible;
                                });
                              },
                            ),
                          ),
                          style: TextStyle(color: colorScheme.onBackground),
                          onChanged: (value) {
                            if (passwordHint !=
                                context.translate('please_enter_password')) {
                              setState(() {
                                passwordHint =
                                    context.translate('please_enter_password');
                              });
                            }
                          },
                          onSubmitted: (_) => signIn(),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: () {
                                _showForgotPasswordDialog(context, screenWidth);
                              },
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.symmetric(
                                  vertical: screenHeight * 0.005,
                                  horizontal: screenWidth * 0.02,
                                ),
                                foregroundColor:
                                    colorScheme.onBackground.withOpacity(0.7),
                              ),
                              child: Text(
                                context.translate('forgot_password'),
                                style: TextStyle(
                                  fontSize: screenWidth * 0.035,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    GestureDetector(
                      onTap: signIn,
                      child: Container(
                        width: double.infinity,
                        height: screenHeight * 0.055,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(30),
                          color: colorScheme.primary,
                        ),
                        child: Center(
                          child: isAuthenticating
                              ? SizedBox(
                                  width: screenWidth * 0.06,
                                  height: screenWidth * 0.06,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2.5,
                                  ),
                                )
                              : Text(
                                  context.translate('login'),
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: screenWidth * 0.045,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ),
                    ),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: Container(
                            height: 1,
                            color: colorScheme.onBackground.withOpacity(0.3),
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 10),
                          child: Text(
                            context.translate('or_continue_with'),
                            style: TextStyle(
                              color: colorScheme.onBackground.withOpacity(0.7),
                              fontSize: screenWidth * 0.035,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Container(
                            height: 1,
                            color: colorScheme.onBackground.withOpacity(0.3),
                          ),
                        ),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildLoginOption(
                          icon: Icons.credit_card,
                          text: context.translate('login_with_card'),
                          onTap: () => _showNFCScanDialog(context, screenWidth),
                          size: screenWidth * 0.28,
                          fontSize: screenWidth * 0.033,
                          iconSize: screenWidth * 0.07,
                          colorScheme: colorScheme,
                        ),
                        SizedBox(width: screenWidth * 0.08),
                        _buildLoginOption(
                          icon: Icons.qr_code,
                          text: context.translate('login_with_qr'),
                          onTap: () {
                            _showSnackBar(
                                context.translate('qr_login_coming_soon'),
                                Colors.blue);
                          },
                          size: screenWidth * 0.28,
                          fontSize: screenWidth * 0.033,
                          iconSize: screenWidth * 0.07,
                          colorScheme: colorScheme,
                        ),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Text(
                          context.translate('dont_have_account'),
                          style: TextStyle(
                            fontSize: screenWidth * 0.035,
                            color: colorScheme.onBackground,
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => SignupPage(),
                              ),
                            );
                          },
                          child: Text(
                            context.translate('register'),
                            style: TextStyle(
                              color: colorScheme.primary,
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
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoginOption({
    required IconData icon,
    required String text,
    required VoidCallback onTap,
    required double size,
    required double fontSize,
    required double iconSize,
    required ColorScheme colorScheme,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: colorScheme.primary,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 4,
              spreadRadius: 1,
              offset: Offset(2, 3),
            )
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              text,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: fontSize,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: size * 0.07),
            Icon(icon, size: iconSize, color: Colors.white),
          ],
        ),
      ),
    );
  }

  void _showForgotPasswordDialog(BuildContext context, double screenWidth) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final isDarkMode = themeProvider.isDarkMode;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final emailController = TextEditingController();
    var isProcessing = false;
    var errorMessage = '';

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: colorScheme.surface,
              title: Text(
                context.translate('reset_password'),
                style: TextStyle(color: colorScheme.onSurface),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    context.translate('reset_password_instructions'),
                    style: TextStyle(color: colorScheme.onSurface),
                  ),
                  SizedBox(height: 16),
                  TextField(
                    controller: emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: isDarkMode
                          ? const Color(0xFF2C2C2C)
                          : Colors.grey[200],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                      hintText: context.translate('email_address'),
                      hintStyle: TextStyle(
                        color:
                            isDarkMode ? const Color(0xFFAAAAAA) : Colors.grey,
                      ),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    style: TextStyle(color: colorScheme.onSurface),
                  ),
                  if (errorMessage.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        errorMessage,
                        style: const TextStyle(
                          color: Colors.red,
                          fontSize: 14,
                        ),
                      ),
                    ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  style: TextButton.styleFrom(
                    foregroundColor: colorScheme.primary,
                  ),
                  child: Text(context.translate('cancel')),
                ),
                isProcessing
                    ? CircularProgressIndicator(
                        strokeWidth: 2,
                        color: colorScheme.primary,
                      )
                    : TextButton(
                        onPressed: () async {
                          final email = emailController.text.trim();
                          if (email.isEmpty) {
                            setState(() {
                              errorMessage = context
                                  .translate('please_enter_email_address');
                            });
                            return;
                          }

                          setState(() {
                            isProcessing = true;
                            errorMessage = '';
                          });

                          try {
                            await resetPassword(email);
                            if (mounted) Navigator.pop(context);
                          } on FirebaseAuthException catch (e) {
                            setState(() {
                              isProcessing = false;
                              if (e.code == 'user-not-found') {
                                errorMessage =
                                    context.translate('no_user_with_email');
                              } else if (e.code == 'invalid-email') {
                                errorMessage =
                                    context.translate('invalid_email');
                              } else {
                                errorMessage = context.translate('error') +
                                    ": ${e.message}";
                              }
                            });
                          } catch (e) {
                            setState(() {
                              isProcessing = false;
                              errorMessage = context.translate('general_error');
                            });
                          }
                        },
                        style: TextButton.styleFrom(
                          foregroundColor: colorScheme.primary,
                        ),
                        child: Text(context.translate('reset')),
                      ),
              ],
            );
          },
        );
      },
    );
  }
}
