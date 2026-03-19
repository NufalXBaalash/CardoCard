import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:test_1/pages/Main_page.dart';
import 'package:test_1/pages/login_screen.dart';
import 'package:firebase_analytics/firebase_analytics.dart';

class Iflogin extends StatefulWidget {
  const Iflogin({super.key});

  @override
  State<Iflogin> createState() => _IfloginState();
}

class _IfloginState extends State<Iflogin> {
  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;
  String? _lastLoggedUserId;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    // Enable analytics collection
    _analytics.setAnalyticsCollectionEnabled(true);

    // Check current auth state immediately on startup
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null && !_isInitialized) {
      _isInitialized = true;
      _lastLoggedUserId = currentUser.uid;
      print("Initial auth check: User is signed in: ${currentUser.uid}");
      _trackLogin(currentUser);
    } else {
      print("Initial auth check: No user is signed in");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          // Add debugging information
          print(
              "Auth state changed. Connection state: ${snapshot.connectionState}");
          print(
              "Has data: ${snapshot.hasData}, Has error: ${snapshot.hasError}");
          if (snapshot.hasData) {
            print("Current user: ${snapshot.data!.uid}");
          }

          // Add loading state
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                color: Color(0xff5680DC),
              ),
            );
          }

          if (snapshot.hasData) {
            final currentUser = snapshot.data!;
            print("Auth state detected signed-in user: ${currentUser.uid}");

            // Log login for a different user or first login
            if (_lastLoggedUserId != currentUser.uid) {
              print(
                  "New login detected: ${currentUser.uid}, previous: ${_lastLoggedUserId ?? 'none'}");
              _trackLogin(currentUser);
              _lastLoggedUserId = currentUser.uid;
            }

            // Important: Return MainPage immediately without any conditions
            return const MainPage();
          } else {
            // Reset when logged out
            if (_lastLoggedUserId != null) {
              print(
                  "Auth state detected signed-out user. Previously was: $_lastLoggedUserId");
              _trackLogout();
              _lastLoggedUserId = null;
            } else {
              print("Auth state shows no signed-in user");
            }

            // Return your custom LoginScreen
            return const LoginScreen();
          }
        },
      ),
    );
  }

  Future<void> _trackLogin(User user) async {
    try {
      // Standard login event
      await _analytics.logLogin(
        loginMethod: 'firebase_authentication',
      );

      // Detailed login event
      await _analytics.logEvent(
        name: 'user_login_details',
        parameters: {
          'user_id': user.uid,
          'email': user.email ?? 'N/A',
          'display_name': user.displayName ?? 'N/A',
          'login_time': DateTime.now().toUtc().toIso8601String(),
          'is_email_verified': user.emailVerified,
          'creation_timestamp':
              user.metadata.creationTime?.toUtc().toIso8601String() ?? 'N/A',
          'last_sign_in_timestamp':
              user.metadata.lastSignInTime?.toUtc().toIso8601String() ?? 'N/A',
        },
      );

      // Set user properties
      await _analytics.setUserId(id: user.uid);
      await _analytics.setUserProperty(
        name: 'email',
        value: user.email,
      );
      await _analytics.setUserProperty(
        name: 'account_created',
        value: user.metadata.creationTime?.toUtc().toIso8601String(),
      );
      await _analytics.setUserProperty(
        name: 'email_verified',
        value: user.emailVerified.toString(),
      );

      debugPrint('Logged login for user: ${user.uid}');
    } catch (e) {
      debugPrint('Error logging login event: $e');

      // Log the error to analytics
      await _analytics.logEvent(
        name: 'login_tracking_error',
        parameters: {
          'error': e.toString(),
          'time': DateTime.now().toUtc().toIso8601String(),
        },
      );
    }
  }

  Future<void> _trackLogout() async {
    try {
      await _analytics.logEvent(
        name: 'user_logout',
        parameters: {
          'logout_time': DateTime.now().toUtc().toIso8601String(),
        },
      );

      // Clear user ID when logging out
      await _analytics.setUserId();

      debugPrint('Logged logout event');
    } catch (e) {
      debugPrint('Error logging logout event: $e');

      await _analytics.logEvent(
        name: 'logout_tracking_error',
        parameters: {
          'error': e.toString(),
          'time': DateTime.now().toUtc().toIso8601String(),
        },
      );
    }
  }
}
