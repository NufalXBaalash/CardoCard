import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:test_1/pages/Main_page.dart';
import 'package:test_1/pages/login_screen.dart';
import 'package:test_1/pages/doctor_main_page.dart';
import 'package:test_1/database/supabase_config.dart';
import 'package:firebase_analytics/firebase_analytics.dart';

class Iflogin extends StatefulWidget {
  const Iflogin({super.key});

  @override
  State<Iflogin> createState() => _IfloginState();
}

class _IfloginState extends State<Iflogin> {
  FirebaseAnalytics? _analytics;
  String? _lastLoggedUserId;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    // Enable analytics collection
    if (Firebase.apps.isNotEmpty) {
      _analytics = FirebaseAnalytics.instance;
      _analytics?.setAnalyticsCollectionEnabled(true);
    }

    if (kIsWeb || defaultTargetPlatform != TargetPlatform.linux) {
      if (Firebase.apps.isNotEmpty) {
        try {
          final currentUser = FirebaseAuth.instance.currentUser;
          if (currentUser != null && !_isInitialized) {
            _isInitialized = true;
            _lastLoggedUserId = currentUser.uid;
            print("Initial auth check: User is signed in: ${currentUser.uid}");
            _trackLogin(currentUser);
          } else {
            print("Initial auth check: No user is signed in");
          }
        } catch (e) {
          print("Firebase auth check failed: $e");
        }
      } else {
        print("Skipping auth check because Firebase is not initialized");
      }
    } else {
      print("Skipping auto-login check on Linux desktop");
    }
  }

  @override
  Widget build(BuildContext context) {
    // Firebase Auth is not officially supported on Linux and will crash
    if (!kIsWeb && Theme.of(context).platform == TargetPlatform.linux) {
      return const Scaffold(
        body: Center(
          child: Text(
            "Firebase is not supported natively on Linux Desktop.\nPlease run using: flutter run -d web-server\nThen open localhost in your browser.",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 18),
          ),
        ),
      );
    }

    if (Firebase.apps.isEmpty) {
      return const Scaffold(
        body: Center(
          child: Text(
            "Firebase failed to initialize.\nPlease check your API key in firebase_options.dart.",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 18, color: Colors.red),
          ),
        ),
      );
    }

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
            return _RoleRouter(userId: currentUser.uid);
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
      await _analytics?.logLogin(
        loginMethod: 'firebase_authentication',
      );

      // Detailed login event
      await _analytics?.logEvent(
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
      await _analytics?.setUserId(id: user.uid);
      await _analytics?.setUserProperty(
        name: 'email',
        value: user.email,
      );
      await _analytics?.setUserProperty(
        name: 'account_created',
        value: user.metadata.creationTime?.toUtc().toIso8601String(),
      );
      await _analytics?.setUserProperty(
        name: 'email_verified',
        value: user.emailVerified.toString(),
      );

      debugPrint('Logged login for user: ${user.uid}');
    } catch (e) {
      debugPrint('Error logging login event: $e');

      // Log the error to analytics
      await _analytics?.logEvent(
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
      await _analytics?.logEvent(
        name: 'user_logout',
        parameters: {
          'logout_time': DateTime.now().toUtc().toIso8601String(),
        },
      );

      // Clear user ID when logging out
      await _analytics?.setUserId();

      debugPrint('Logged logout event');
    } catch (e) {
      debugPrint('Error logging logout event: $e');

      await _analytics?.logEvent(
        name: 'logout_tracking_error',
        parameters: {
          'error': e.toString(),
          'time': DateTime.now().toUtc().toIso8601String(),
        },
      );
    }
  }
}

class _RoleRouter extends StatefulWidget {
  final String userId;
  const _RoleRouter({required this.userId});

  @override
  State<_RoleRouter> createState() => _RoleRouterState();
}

class _RoleRouterState extends State<_RoleRouter> {
  bool _isLoading = true;
  bool _isDoctor = false;

  @override
  void initState() {
    super.initState();
    _checkRole();
  }

  Future<void> _checkRole() async {
    try {
      final role = await SupabaseService.getUserRole(widget.userId);
      if (mounted) {
        setState(() {
          _isDoctor = role == 'doctor';
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error checking user role: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: Color(0xff5680DC)),
        ),
      );
    }

    if (_isDoctor) {
      return const DoctorMainPage();
    }
    return const MainPage();
  }
}
