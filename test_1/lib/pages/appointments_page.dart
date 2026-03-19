import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:test_1/utils/theme_provider.dart';
import 'package:test_1/utils/language_provider.dart';
import 'package:test_1/utils/app_localizations.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:test_1/pages/doctor_listing_page.dart';

class AppointmentsPage extends StatefulWidget {
  const AppointmentsPage({super.key});

  @override
  State<AppointmentsPage> createState() => _AppointmentsPageState();
}

class _AppointmentsPageState extends State<AppointmentsPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String userName = '';
  String? profileImageBase64;
  bool _isLoading = true;

  // Specialties with their icons and colors
  final List<Map<String, dynamic>> _specialties = [
    {
      'name': 'Neurologist',
      'icon': Icons.psychology,
      'color': Colors.red.shade200,
    },
    {
      'name': 'Cardiologist',
      'icon': Icons.favorite,
      'color': Colors.blue.shade200,
    },
    {
      'name': 'Orthopedist',
      'icon': Icons.accessibility_new,
      'color': Colors.orange.shade200,
    },
    {
      'name': 'Pulmonologist',
      'icon': Icons.air,
      'color': Colors.purple.shade200,
    },
    {
      'name': 'Dentist',
      'icon': Icons.face,
      'color': Colors.green.shade200,
    },
    {
      'name': 'Pediatrician',
      'icon': Icons.child_care,
      'color': Colors.amber.shade200,
    },
  ];

  // Sample upcoming appointment
  final Map<String, dynamic> _upcomingAppointment = {
    'doctorName': 'Dr. Jennifer Smith',
    'specialty': 'Orthopedic Consultation (Foot & Ankle)',
    'date': 'Wed, 7 Sep 2024',
    'time': '10:30 - 11:30 AM',
    'image': 'assets/doctor1.png',
  };

  // Sample recent doctors
  final List<Map<String, dynamic>> _recentDoctors = [
    {
      'name': 'Dr. Warner',
      'specialty': 'Neurology',
      'experience': '5',
      'image': 'assets/doctor2.png',
    },
    {
      'name': 'Dr. Patel',
      'specialty': 'Cardiology',
      'experience': '8',
      'image': 'assets/doctor3.png',
    },
    {
      'name': 'Dr. Johnson',
      'specialty': 'Dermatology',
      'experience': '10',
      'image': 'assets/doctor4.png',
    },
    {
      'name': 'Dr. Garcia',
      'specialty': 'Pediatrics',
      'experience': '7',
      'image': 'assets/doctor5.png',
    },
  ];

  @override
  void initState() {
    super.initState();
    _getUserData();
  }

  Future<void> _getUserData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      User? currentUser = _auth.currentUser;
      if (currentUser != null) {
        final userDoc =
            await _firestore.collection('users').doc(currentUser.uid).get();

        if (userDoc.exists) {
          setState(() {
            userName = userDoc.data()?['fullName'] ?? 'User';
            profileImageBase64 = userDoc.data()?['profileImage'];
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      print('Error fetching user data: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    final colorScheme = Theme.of(context).colorScheme;

    // Get RTL information
    final languageProvider = Provider.of<LanguageProvider>(context);
    final isRTL = languageProvider.isRTL;

    // Get screen size for responsive layout
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 360;

    return Scaffold(
      backgroundColor: isDarkMode ? Colors.grey.shade900 : Colors.grey.shade50,
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: colorScheme.primary))
          : SafeArea(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                    horizontal: isSmallScreen ? 12 : 16,
                    vertical: isSmallScreen ? 16 : 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header with greeting and profile
                    _buildHeader(isDarkMode, colorScheme, isSmallScreen),

                    SizedBox(height: isSmallScreen ? 16 : 24),

                    // Search bar
                    _buildSearchBar(isDarkMode, colorScheme),

                    SizedBox(height: isSmallScreen ? 16 : 24),

                    // Specialties row (scrollable)
                    _buildSpecialtiesRow(isDarkMode, colorScheme),

                    SizedBox(height: isSmallScreen ? 20 : 30),

                    // Upcoming appointment section
                    _buildSectionTitle(
                        context.tr.translate("upcoming_appointments"),
                        isDarkMode),
                    SizedBox(height: isSmallScreen ? 8 : 12),
                    _buildUpcomingAppointmentCard(
                        isDarkMode, colorScheme, screenSize),

                    SizedBox(height: isSmallScreen ? 20 : 30),

                    // Recent visits section
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildSectionTitle(
                            context.tr.translate("make_an_appointment"),
                            isDarkMode),
                        TextButton(
                          onPressed: () {
                            // Navigate to all recent visits
                          },
                          child: GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const DoctorListingPage(),
                                ),
                              );
                            },
                            child: Text(
                              context.tr.translate('see_all'),
                              style: TextStyle(
                                color: colorScheme.primary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: isSmallScreen ? 8 : 12),
                    _buildRecentDoctorsGrid(
                        isDarkMode, colorScheme, screenSize),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildHeader(
      bool isDarkMode, ColorScheme colorScheme, bool isSmallScreen) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.tr.translate("hello"),
                style: TextStyle(
                  fontSize: isSmallScreen ? 20 : 24,
                  fontWeight: FontWeight.w500,
                  color: isDarkMode ? Colors.white70 : Colors.black54,
                ),
              ),
              Text(
                userName,
                style: TextStyle(
                  fontSize: isSmallScreen ? 20 : 24,
                  fontWeight: FontWeight.bold,
                  color: isDarkMode ? Colors.white : Colors.black,
                  overflow: TextOverflow.ellipsis,
                ),
                maxLines: 1,
              ),
            ],
          ),
        ),
        Row(
          children: [
            Container(
              decoration: BoxDecoration(
                color: isDarkMode ? Colors.grey.shade800 : Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: IconButton(
                icon: Icon(
                  Icons.notifications_outlined,
                  color: isDarkMode ? Colors.white70 : Colors.black54,
                  size: isSmallScreen ? 20 : 24,
                ),
                onPressed: () {
                  // Handle notification
                },
                constraints: BoxConstraints(
                  minWidth: isSmallScreen ? 36 : 40,
                  minHeight: isSmallScreen ? 36 : 40,
                ),
              ),
            ),
            SizedBox(width: isSmallScreen ? 8 : 12),
            Stack(
              children: [
                CircleAvatar(
                  radius: isSmallScreen ? 20 : 24,
                  backgroundColor: colorScheme.primary.withOpacity(0.2),
                  backgroundImage: profileImageBase64 != null
                      ? MemoryImage(
                          Uri.parse(profileImageBase64!).data!.contentAsBytes())
                      : null,
                  child: profileImageBase64 == null
                      ? Icon(Icons.person,
                          color: colorScheme.primary,
                          size: isSmallScreen ? 20 : 24)
                      : null,
                ),
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    padding: EdgeInsets.all(isSmallScreen ? 3 : 4),
                    decoration: BoxDecoration(
                      color: colorScheme.primary,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      'PRO',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: isSmallScreen ? 6 : 8,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSearchBar(bool isDarkMode, ColorScheme colorScheme) {
    return Container(
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey.shade800 : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(
            Icons.search,
            color: isDarkMode ? Colors.white54 : Colors.black38,
          ),
          const SizedBox(width: 12),
          Text(
            context.tr.translate('search_doctor'),
            style: TextStyle(
              color: isDarkMode ? Colors.white38 : Colors.black38,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpecialtiesRow(bool isDarkMode, ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _buildSectionTitle(
              context.tr.translate("specialities"), isDarkMode),
        ),
        SizedBox(
          height: 100, // Fixed height for the scrollable row
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _specialties.length,
            itemBuilder: (context, index) {
              final specialty = _specialties[index];
              return Container(
                width: 80,
                margin: EdgeInsets.only(right: 16),
                child: Column(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: specialty['color'],
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        specialty['icon'],
                        color: Colors.white,
                        size: 30,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      context.tr.translate(
                          specialty['name'].toString().toLowerCase()),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: isDarkMode ? Colors.white70 : Colors.black87,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title, bool isDarkMode) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: isDarkMode ? Colors.white : Colors.black,
      ),
    );
  }

  Widget _buildUpcomingAppointmentCard(
      bool isDarkMode, ColorScheme colorScheme, Size screenSize) {
    final isSmallScreen = screenSize.width < 360;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.primary,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
      child: Row(
        children: [
          CircleAvatar(
            radius: isSmallScreen ? 24 : 30,
            backgroundColor: Colors.white.withOpacity(0.2),
            child: Icon(
              Icons.person,
              color: Colors.white,
              size: isSmallScreen ? 28 : 36,
            ),
          ),
          SizedBox(width: isSmallScreen ? 12 : 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _upcomingAppointment['doctorName'],
                  style: TextStyle(
                    fontSize: isSmallScreen ? 16 : 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: isSmallScreen ? 2 : 4),
                Text(
                  context.tr.translate(_upcomingAppointment['specialty']),
                  style: TextStyle(
                    fontSize: isSmallScreen ? 12 : 14,
                    color: Colors.white.withOpacity(0.9),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: isSmallScreen ? 8 : 12),
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      color: Colors.white.withOpacity(0.9),
                      size: isSmallScreen ? 14 : 16,
                    ),
                    SizedBox(width: isSmallScreen ? 6 : 8),
                    Expanded(
                      child: Text(
                        context.tr.translate(_upcomingAppointment['date']),
                        style: TextStyle(
                          fontSize: isSmallScreen ? 12 : 14,
                          color: Colors.white.withOpacity(0.9),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: isSmallScreen ? 2 : 4),
                Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      color: Colors.white.withOpacity(0.9),
                      size: isSmallScreen ? 14 : 16,
                    ),
                    SizedBox(width: isSmallScreen ? 6 : 8),
                    Text(
                      context.tr.translate(_upcomingAppointment['time']),
                      style: TextStyle(
                        fontSize: isSmallScreen ? 12 : 14,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentDoctorsGrid(
      bool isDarkMode, ColorScheme colorScheme, Size screenSize) {
    final isSmallScreen = screenSize.width < 360;

    return SizedBox(
      height: isSmallScreen ? 180 : 200,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _recentDoctors.length,
        itemBuilder: (context, index) {
          final doctor = _recentDoctors[index];
          return Container(
            width: screenSize.width * 0.7,
            margin: EdgeInsets.only(right: 12),
            child: Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              color: isDarkMode ? Colors.grey.shade800 : Colors.white,
              child: Padding(
                padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: isSmallScreen ? 20 : 24,
                          backgroundColor: colorScheme.primary.withOpacity(0.1),
                          child: const Icon(
                            Icons.person,
                            color: Colors.grey,
                          ),
                        ),
                        SizedBox(width: isSmallScreen ? 8 : 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                doctor['name'],
                                style: TextStyle(
                                  fontSize: isSmallScreen ? 14 : 16,
                                  fontWeight: FontWeight.bold,
                                  color:
                                      isDarkMode ? Colors.white : Colors.black,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                context.tr.translate(doctor['specialty']
                                    .toString()
                                    .toLowerCase()),
                                style: TextStyle(
                                  fontSize: isSmallScreen ? 12 : 14,
                                  color: isDarkMode
                                      ? Colors.white70
                                      : Colors.black54,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                "${context.tr.translate("years_of_experience")} " +
                                    doctor['experience'],
                                style: TextStyle(
                                  fontSize: isSmallScreen ? 10 : 12,
                                  color: isDarkMode
                                      ? Colors.white54
                                      : Colors.black45,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    Spacer(),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              // Book appointment
                            },
                            icon: Icon(
                              Icons.calendar_today,
                              size: isSmallScreen ? 14 : 16,
                              color: colorScheme.primary,
                            ),
                            label: Text(
                              context.tr.translate('book_now'),
                              style: TextStyle(
                                color: colorScheme.primary,
                                fontSize: isSmallScreen ? 12 : 14,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: colorScheme.primary),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              padding: EdgeInsets.symmetric(
                                  vertical: isSmallScreen ? 6 : 8),
                            ),
                          ),
                        ),
                        SizedBox(width: 8),
                        Container(
                          decoration: BoxDecoration(
                            color: colorScheme.primary.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            icon: Icon(
                              Icons.phone,
                              color: colorScheme.primary,
                              size: isSmallScreen ? 18 : 20,
                            ),
                            onPressed: () {
                              // Call doctor
                            },
                            constraints: BoxConstraints(
                              minWidth: isSmallScreen ? 32 : 36,
                              minHeight: isSmallScreen ? 32 : 36,
                            ),
                            padding: EdgeInsets.zero,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
