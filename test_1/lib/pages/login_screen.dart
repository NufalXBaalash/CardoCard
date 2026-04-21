import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:test_1/utils/ifLogin.dart';
import 'package:nfc_manager/nfc_manager.dart';
import 'package:nfc_manager/nfc_manager_android.dart';
import 'package:test_1/pages/signup_page.dart';
import 'package:test_1/utils/theme_provider.dart';
import 'package:test_1/utils/app_localizations.dart';
import 'package:test_1/utils/language_provider.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:test_1/utils/serial_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  // Firebase instances (nullable for platform safety)
  FirebaseAuth? _auth;
  FirebaseAnalytics? _analytics;

  // Controllers
  final TextEditingController _cardIdController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  // State variables
  String cardIDHint = "";
  String passwordHint = "";
  bool isAuthenticating = false;
  bool _passwordVisible = false;

  // Hardware / NFC state (from f098f66)
  bool isNFCAvailable = false;
  bool tagProcessed = false;
  bool isSerialConnected = false;

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

    // Platform-safe Firebase initialization
    if (!kIsWeb) {
      _auth = FirebaseAuth.instance;
      _analytics = FirebaseAnalytics.instance;
      _analytics?.setAnalyticsCollectionEnabled(true);
    }

    cardIDHint = "Please enter your card id";
    passwordHint = "Please enter your password";

    // NFC availability check (from f098f66)
    if (!kIsWeb) {
      _checkNFCAvailability();
    }

    // SerialService integration (from f098f66)
    if (!kIsWeb) {
      SerialService().init(
        onTag: (id) {
          if (!tagProcessed && !isAuthenticating) {
            _logHardwareEvent("SERIAL_TAG_DETECTED: $id");
            _authenticateWithNFCToken(id.trim());
          }
        },
        onDebug: (msg) {
          if (msg.contains("CONNECTED")) {
            setState(() => isSerialConnected = true);
          } else if (msg.contains("Disconnected") || msg.contains("Unplugged")) {
            setState(() => isSerialConnected = false);
          }
          _showDebugSnackBar(msg);
        },
      );
    }
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

  // ---------------------------------------------------------------------------
  // Original 1953cf2 helper methods
  // ---------------------------------------------------------------------------

  Future<void> _reloadAuthState() async {
    try {
      final currentUser = _auth?.currentUser;
      if (currentUser != null) {
        await currentUser.reload();
      }
    } catch (e) {
      print("Error reloading auth state: $e");
    }
  }

  Future<void> signIn() async {
    if (isAuthenticating) return;
    if (_auth == null) return;

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

      final userCredential = await _auth!.signInWithEmailAndPassword(
        email: email,
        password: _passwordController.text,
      );

      if (userCredential.user != null) {
        await _reloadAuthState();
        await Future.wait([
          _analytics?.logLogin(loginMethod: 'email') ?? Future.value(),
          _analytics?.setUserId(id: userCredential.user!.uid) ?? Future.value(),
          _analytics?.setUserProperty(
            name: 'email',
            value: userCredential.user!.email,
          ) ?? Future.value(),
        ]);

        if (mounted) {
          _showSnackBar(
              context.translate('authentication_successful'), Colors.green);
          Future.delayed(const Duration(seconds: 1), () {
            if (mounted && _auth?.currentUser != null) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const Iflogin()),
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
      await _analytics?.logEvent(name: name, parameters: parameters);
    } catch (e) {
      debugPrint('Analytics error: $e');
    }
  }

  Future<void> _logValidationError(String errorType) async {
    await _logEvent(_validationErrorEvent, {'error_type': errorType});
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
    if (_auth == null) return;
    try {
      await _logEvent(_passwordResetAttemptEvent, {'email': email});
      await _auth!.sendPasswordResetEmail(email: email);
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

  // ---------------------------------------------------------------------------
  // f098f66 NFC Authentication (Firebase Functions approach)
  // ---------------------------------------------------------------------------

  Future<void> _checkNFCAvailability() async {
    bool isAvailable = await NfcManager.instance.isAvailable();
    setState(() {
      isNFCAvailable = isAvailable;
    });
  }

  void _startNFCSession() {
    setState(() {
      tagProcessed = false;
    });

    NfcManager.instance.startSession(
      pollingOptions: {NfcPollingOption.iso14443, NfcPollingOption.iso15693},
      onDiscovered: (NfcTag tag) async {
        if (tagProcessed) return;
        tagProcessed = true;

        try {
          String? tokenData;
          final ndef = NdefAndroid.from(tag);
          if (ndef != null && ndef.cachedNdefMessage != null) {
            final records = ndef.cachedNdefMessage!.records;
            if (records.isNotEmpty) {
              final payload = records.first.payload;
              if (payload.isNotEmpty) {
                int languageCodeLength = payload[0] & 0x3F;
                tokenData =
                    utf8.decode(payload.sublist(1 + languageCodeLength)).trim();
              }
            }
          }

          if (tokenData == null || tokenData.isEmpty) {
            final dynamic data = tag.data;
            List<int>? id;
            try {
              id = data.identifier as List<int>?;
            } catch (e) {
              try {
                id = (data['identifier'] ??
                    data['id'] ??
                    data['mifare']?['identifier']) as List<int>?;
              } catch (_) {}
            }
            if (id != null) {
              tokenData = id
                  .map((e) => e.toRadixString(16).padLeft(2, '0'))
                  .join();
            }
          }

          if (tokenData != null && tokenData.isNotEmpty) {
            String finalUid = tokenData;
            if (tokenData.contains('?id=')) {
              final uri = Uri.parse(tokenData);
              finalUid = uri.queryParameters['id'] ?? tokenData;
            } else if (tokenData.contains('/')) {
              finalUid = tokenData.split('/').last;
            }
            await _authenticateWithNFCToken(finalUid.trim());
          }
        } catch (e) {
          _showErrorSnackBar("Error accessing NFC data: $e");
        } finally {
          await Future.delayed(const Duration(milliseconds: 500));
          await NfcManager.instance.stopSession();
        }
      },
    );

    _showNfcDialog();
  }

  Future<void> _authenticateWithNFCToken(String tokenData) async {
    if (_auth == null) return;
    setState(() => isAuthenticating = true);
    try {
      await _logEvent(_nfcLoginAttemptEvent, {'method': 'nfc_token', 'token_data': tokenData});

      final HttpsCallable callable =
          FirebaseFunctions.instance.httpsCallable('getCustomToken');
      final result = await callable.call({'uid': tokenData});
      final customToken = result.data['customToken'];

      if (customToken == null) throw Exception("No token returned");

      await _auth!.signInWithCustomToken(customToken);

      await _logEvent(_nfcLoginSuccessEvent, {'method': 'nfc_custom_token'});

      if (mounted) {
        _showSnackBar(
            context.translate('authentication_successful'), Colors.green);
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const Iflogin()),
        );
      }
    } catch (e) {
      await _logEvent(_nfcLoginFailureEvent, {
        'error': 'processing_error',
        'message': e.toString(),
      });
      _showErrorSnackBar("Authorization denied: $e");
    } finally {
      if (mounted) setState(() => isAuthenticating = false);
    }
  }

  // ---------------------------------------------------------------------------
  // f098f66 NFC Dialog
  // ---------------------------------------------------------------------------

  void _showNfcDialog() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final screenSize = MediaQuery.of(context).size;
    final screenWidth = screenSize.width;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: colorScheme.surface.withOpacity(0.9),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                "lib/images/contactless.png",
                width: screenWidth * 0.2,
                height: screenWidth * 0.2,
              ),
              const SizedBox(height: 24),
              Text(
                context.translate('card_authentication'),
                style: TextStyle(
                  fontSize: screenWidth * 0.05,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                context.translate('tap_card'),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: screenWidth * 0.04,
                  color: colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
              const SizedBox(height: 16),
              CircularProgressIndicator(
                color: colorScheme.primary,
                strokeWidth: 3,
              ),
              const SizedBox(height: 24),
              TextButton(
                onPressed: () {
                  NfcManager.instance.stopSession();
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
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // f098f66 Hardware Event Logging
  // ---------------------------------------------------------------------------

  void _logHardwareEvent(String event) {
    _analytics?.logEvent(
        name: 'hardware_auth_attempt', parameters: {'event': event});
    debugPrint("HW_AUTH: $event");
  }

  // ---------------------------------------------------------------------------
  // f098f66 Debug / Error SnackBars
  // ---------------------------------------------------------------------------

  void _showDebugSnackBar(String message) {
    if (!mounted) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final theme = Theme.of(context);
      final colorScheme = theme.colorScheme;
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message,
              style: TextStyle(fontSize: 10, color: colorScheme.primary)),
          backgroundColor: colorScheme.surface.withOpacity(0.9),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
    });
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.redAccent.withOpacity(0.9),
        content: Text(message,
            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // f098f66 Status Indicator Widget
  // ---------------------------------------------------------------------------

  Widget _buildStatusDot(String label, bool isActive, Color activeColor) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isActive ? activeColor : Colors.grey.withOpacity(0.5),
            boxShadow: [
              if (isActive)
                BoxShadow(
                    color: activeColor.withOpacity(0.5),
                    blurRadius: 4,
                    spreadRadius: 1)
            ],
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 8,
            fontWeight: FontWeight.bold,
            color: isActive ? activeColor : Colors.grey.withOpacity(0.5),
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // f098f66 Manual Login Dialog
  // ---------------------------------------------------------------------------

  void _showManualLoginDialog() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final screenSize = MediaQuery.of(context).size;
    final screenWidth = screenSize.width;

    final manualEmailController = TextEditingController();
    final manualPasswordController = TextEditingController();
    bool manualLoading = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[400],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    context.translate('login'),
                    style: TextStyle(
                      fontSize: screenWidth * 0.05,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: manualEmailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: colorScheme.surfaceVariant,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                      hintText: context.translate('please_enter_email'),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                    ),
                    style: TextStyle(color: colorScheme.onSurface),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: manualPasswordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: colorScheme.surfaceVariant,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                      hintText: context.translate('please_enter_password'),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                    ),
                    style: TextStyle(color: colorScheme.onSurface),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: manualLoading
                          ? null
                          : () async {
                              if (manualEmailController.text.trim().isEmpty ||
                                  manualPasswordController.text.isEmpty) {
                                _showErrorSnackBar("Please fill in all fields");
                                return;
                              }
                              setModalState(() => manualLoading = true);
                              try {
                                if (_auth != null) {
                                  await _auth!.signInWithEmailAndPassword(
                                    email:
                                        manualEmailController.text.trim(),
                                    password:
                                        manualPasswordController.text,
                                  );
                                  if (mounted) {
                                    Navigator.pop(context);
                                    Navigator.pushReplacement(
                                      context,
                                      MaterialPageRoute(
                                          builder: (context) =>
                                              const Iflogin()),
                                    );
                                  }
                                }
                              } on FirebaseAuthException catch (e) {
                                _showErrorSnackBar(e.message ?? "Login failed");
                              } catch (e) {
                                _showErrorSnackBar("Login failed: $e");
                              } finally {
                                if (mounted) {
                                  setModalState(
                                      () => manualLoading = false);
                                }
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorScheme.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: manualLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Text(
                              context.translate('login'),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Original 1953cf2 NFC Scan Dialog (adapted to call f098f66 session)
  // ---------------------------------------------------------------------------

  void _showNFCScanDialog(BuildContext context, double screenWidth) async {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    bool isAvailable = false;
    String statusMessage = context.translate('checking_nfc');

    try {
      isAvailable = await NfcManager.instance.isAvailable();
      statusMessage = isAvailable
          ? context.translate('tap_card')
          : context.translate('nfc_unavailable');
    } catch (e) {
      statusMessage = context.translate('error_checking_nfc');
    }

    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
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
              if (isAvailable) ...[
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
                if (isAvailable) NfcManager.instance.stopSession();
                Navigator.pop(dialogContext);
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

    if (isAvailable) _startNFCSession();
  }

  // ---------------------------------------------------------------------------
  // Build method (1953cf2 UI preserved)
  // ---------------------------------------------------------------------------

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
              SizedBox(height: screenHeight * 0.01),
              // Hardware status indicators (from f098f66)
              if (!kIsWeb)
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    _buildStatusDot("NFC", isNFCAvailable, colorScheme.primary),
                    const SizedBox(width: 15),
                    _buildStatusDot(
                        "SERIAL", isSerialConnected, colorScheme.primary),
                  ],
                ),
              SizedBox(height: screenHeight * 0.03),
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
                                _showForgotPasswordDialog(
                                    context, screenWidth);
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
                            color:
                                colorScheme.onBackground.withOpacity(0.3),
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 10),
                          child: Text(
                            context.translate('or_continue_with'),
                            style: TextStyle(
                              color:
                                  colorScheme.onBackground.withOpacity(0.7),
                              fontSize: screenWidth * 0.035,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Container(
                            height: 1,
                            color:
                                colorScheme.onBackground.withOpacity(0.3),
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
                    // Manual override button (from f098f66 working directory additions)
                    TextButton(
                      onPressed: _showManualLoginDialog,
                      child: Text(
                        "Manual Override",
                        style: TextStyle(
                          color: colorScheme.onBackground.withOpacity(0.3),
                          fontSize: screenWidth * 0.035,
                        ),
                      ),
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

  // ---------------------------------------------------------------------------
  // Original 1953cf2 UI helper widgets
  // ---------------------------------------------------------------------------

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
