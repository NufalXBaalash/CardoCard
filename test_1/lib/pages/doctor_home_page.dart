import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:test_1/utils/theme_provider.dart';
import 'package:test_1/utils/language_provider.dart';
import 'package:test_1/utils/app_localizations.dart';
import 'package:test_1/database/supabase_config.dart';
import 'package:test_1/pages/doctor_main_page.dart';
import 'package:test_1/pages/doctor_reports_page.dart';

class DoctorHomePage extends StatefulWidget {
  const DoctorHomePage({super.key});

  @override
  State<DoctorHomePage> createState() => _DoctorHomePageState();
}

class _DoctorHomePageState extends State<DoctorHomePage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool _isLoading = true;
  String _doctorName = '';
  String? _doctorId;
  int _totalPatients = 0;
  int _todayAppointments = 0;
  int _pendingReports = 0;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);
    try {
      final uid = _auth.currentUser?.uid;
      if (uid == null) return;

      final doctorData = await SupabaseService.fetchDoctorByUserId(uid);
      if (doctorData == null) {
        if (mounted) {
          setState(() => _isLoading = false);
        }
        return;
      }

      _doctorId = doctorData['id'] as String?;
      _doctorName = doctorData['name'] as String? ?? '';

      final results = await Future.wait([
        SupabaseService.fetchDoctorPatients(_doctorId!),
        SupabaseService.fetchDoctorAppointments(_doctorId!),
        SupabaseService.fetchDoctorMedicalRecords(_doctorId!),
      ]);

      final patients = results[0] as List<Map<String, dynamic>>;
      final appointments = results[1] as List<Map<String, dynamic>>;
      final records = results[2] as List<Map<String, dynamic>>;

      final today = DateTime.now().toIso8601String().split('T').first;
      final todayCount = appointments
          .where((a) =>
              a['appointment_date'] == today && a['status'] == 'scheduled')
          .length;

      final pendingCount =
          records.where((r) => r['status'] == 'pending').length;

      if (mounted) {
        setState(() {
          _totalPatients = patients.length;
          _todayAppointments = todayCount;
          _pendingReports = pendingCount;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading doctor dashboard: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    final languageProvider = Provider.of<LanguageProvider>(context);
    final isRTL = languageProvider.isRTL;
    final colorScheme = Theme.of(context).colorScheme;
    final screenSize = MediaQuery.of(context).size;

    return Directionality(
      textDirection: isRTL ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: colorScheme.background,
        extendBodyBehindAppBar: true,
        body: _isLoading
            ? Center(
                child: CircularProgressIndicator(color: AppTheme.cardoBlue),
              )
            : RefreshIndicator(
                color: AppTheme.cardoBlue,
                onRefresh: _loadDashboardData,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(isDarkMode, colorScheme, screenSize),
                      SizedBox(height: screenSize.height * 0.025),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildStatsGrid(
                                isDarkMode, colorScheme, screenSize),
                            SizedBox(height: screenSize.height * 0.03),
                            _buildQuickActions(
                                isDarkMode, colorScheme, screenSize),
                            SizedBox(height: 80),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildHeader(
      bool isDarkMode, ColorScheme colorScheme, Size screenSize) {
    return Container(
      width: double.infinity,
      height: screenSize.height * 0.22 + MediaQuery.of(context).padding.top,
      padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
      decoration: BoxDecoration(
        color: AppTheme.cardoBlue,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(25),
          bottomRight: Radius.circular(25),
        ),
        boxShadow: [
          BoxShadow(
            color:
                Colors.black.withOpacity(isDarkMode ? 0.4 : 0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: screenSize.width * 0.05,
          vertical: screenSize.width * 0.02,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: screenSize.height * 0.015),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.translate('welcome_back'),
                        style: TextStyle(
                          fontSize: screenSize.width * 0.035,
                          color: Colors.white.withOpacity(0.9),
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        _doctorName.isNotEmpty
                            ? 'Dr. $_doctorName'
                            : 'Doctor',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: screenSize.width * 0.045,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.3,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.notifications_none_rounded,
                    size: screenSize.width * 0.07,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            SizedBox(height: screenSize.height * 0.02),
            Text(
              'Dashboard',
              style: TextStyle(
                color: Colors.white.withOpacity(0.85),
                fontSize: screenSize.width * 0.04,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsGrid(
      bool isDarkMode, ColorScheme colorScheme, Size screenSize) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            icon: Icons.people_rounded,
            title: 'Total Patients',
            value: '$_totalPatients',
            color: AppTheme.cardoBlue,
            isDarkMode: isDarkMode,
            colorScheme: colorScheme,
            screenSize: screenSize,
          ),
        ),
        SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            icon: Icons.calendar_today_rounded,
            title: "Today's Appointments",
            value: '$_todayAppointments',
            color: Colors.green,
            isDarkMode: isDarkMode,
            colorScheme: colorScheme,
            screenSize: screenSize,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
    required bool isDarkMode,
    required ColorScheme colorScheme,
    required Size screenSize,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF2C2C2C) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDarkMode ? 0.2 : 0.06),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(isDarkMode ? 0.2 : 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.white : Colors.black,
            ),
          ),
          SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: isDarkMode ? Colors.white60 : Colors.black54,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(
      bool isDarkMode, ColorScheme colorScheme, Size screenSize) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: isDarkMode ? Colors.white : Colors.black,
          ),
        ),
        SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildActionButton(
                icon: Icons.schedule_rounded,
                label: 'View Schedule',
                onTap: () {
                  final state = DoctorMainPage.of(context);
                  state?.navigateToTab(3);
                },
                isDarkMode: isDarkMode,
                colorScheme: colorScheme,
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: _buildActionButton(
                icon: Icons.upload_file_rounded,
                label: 'Upload Report',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const DoctorReportsPage()),
                  );
                },
                isDarkMode: isDarkMode,
                colorScheme: colorScheme,
              ),
            ),
          ],
        ),
        SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildActionButton(
                icon: Icons.people_rounded,
                label: 'Patients',
                onTap: () {
                  final state = DoctorMainPage.of(context);
                  state?.navigateToTab(1);
                },
                isDarkMode: isDarkMode,
                colorScheme: colorScheme,
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: _buildActionButton(
                icon: Icons.assignment_rounded,
                label: 'Appointments',
                onTap: () {
                  final state = DoctorMainPage.of(context);
                  state?.navigateToTab(2);
                },
                isDarkMode: isDarkMode,
                colorScheme: colorScheme,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required bool isDarkMode,
    required ColorScheme colorScheme,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isDarkMode ? const Color(0xFF2C2C2C) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: AppTheme.cardoBlue.withOpacity(0.2),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDarkMode ? 0.2 : 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(icon, color: AppTheme.cardoBlue, size: 22),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isDarkMode ? Colors.white : Colors.black,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
