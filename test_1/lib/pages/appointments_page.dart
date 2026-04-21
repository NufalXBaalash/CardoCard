import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:test_1/utils/theme_provider.dart';
import 'package:test_1/utils/language_provider.dart';
import 'package:test_1/utils/app_localizations.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:test_1/database/supabase_config.dart';
import 'package:test_1/pages/doctor_listing_page.dart';
import 'dart:convert';

class AppointmentsPage extends StatefulWidget {
  const AppointmentsPage({super.key});

  @override
  State<AppointmentsPage> createState() => _AppointmentsPageState();
}

class _AppointmentsPageState extends State<AppointmentsPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String userName = '';
  String? profileImageBase64;
  bool _isLoading = true;
  List<Map<String, dynamic>> _doctors = [];
  List<Map<String, dynamic>> _appointments = [];

  final List<Map<String, dynamic>> _specialties = [
    {'name': 'Neurologist', 'icon': Icons.psychology, 'color': Color(0xFFE28BFF)},
    {'name': 'Cardiologist', 'icon': Icons.favorite, 'color': Color(0xFFff8484)},
    {'name': 'Orthopedist', 'icon': Icons.accessibility_new, 'color': Color(0xFFFFD062)},
    {'name': 'Pulmonologist', 'icon': Icons.air, 'color': Color(0xFFFF8F7C)},
    {'name': 'Dentist', 'icon': Icons.face, 'color': Color(0xFF7EAFFF)},
    {'name': 'Pediatrician', 'icon': Icons.child_care, 'color': Color(0xFFAEF99D)},
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      await Future.wait([
        _getUserData(),
        _fetchDoctors(),
        _fetchAppointments(),
      ]);
    } catch (e) {
      debugPrint('Error loading data: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _getUserData() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser != null) {
        // Try Supabase first, fallback to minimal data
        setState(() {
          userName = currentUser.displayName ?? 'User';
        });
      }
    } catch (e) {
      debugPrint('Error fetching user data: $e');
    }
  }

  Future<void> _fetchDoctors() async {
    try {
      final doctors = await SupabaseService.fetchDoctors();
      if (mounted) {
        setState(() => _doctors = doctors);
      }
    } catch (e) {
      debugPrint('Error fetching doctors: $e');
    }
  }

  Future<void> _fetchAppointments() async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return;
      final appointments = await SupabaseService.fetchUserAppointments(
        userId,
        status: 'scheduled',
      );
      if (mounted) {
        setState(() => _appointments = appointments);
      }
    } catch (e) {
      debugPrint('Error fetching appointments: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    final colorScheme = Theme.of(context).colorScheme;
    final languageProvider = Provider.of<LanguageProvider>(context);
    final isRTL = languageProvider.isRTL;
    final screenSize = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: isDarkMode ? const Color(0xFF121212) : const Color(0xFFF5F7FA),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: colorScheme.primary))
          : RefreshIndicator(
              color: colorScheme.primary,
              onRefresh: _loadData,
              child: SafeArea(
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(isDarkMode, colorScheme, screenSize),
                      SizedBox(height: 20),
                      _buildSearchBar(isDarkMode, colorScheme, screenSize),
                      SizedBox(height: 24),
                      _buildSpecialtiesSection(isDarkMode, colorScheme, screenSize),
                      SizedBox(height: 24),
                      if (_appointments.isNotEmpty) ...[
                        _buildSectionTitle(context.translate('upcoming_appointments'), isDarkMode, colorScheme),
                        SizedBox(height: 12),
                        _buildAppointmentsList(isDarkMode, colorScheme, screenSize),
                        SizedBox(height: 24),
                      ],
                      _buildDoctorsSection(isDarkMode, colorScheme, screenSize),
                      SizedBox(height: 80),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildHeader(bool isDarkMode, ColorScheme colorScheme, Size screenSize) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.translate('hello'),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  color: isDarkMode ? Colors.white54 : Colors.black45,
                ),
              ),
              Text(
                userName,
                style: TextStyle(
                  fontSize: 22,
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
                color: isDarkMode ? const Color(0xFF2C2C2C) : Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: IconButton(
                icon: Icon(Icons.notifications_outlined,
                    color: isDarkMode ? Colors.white70 : Colors.black54, size: 22),
                onPressed: () {},
              ),
            ),
            SizedBox(width: 12),
            CircleAvatar(
              radius: 22,
              backgroundColor: AppTheme.cardoBlue.withOpacity(0.15),
              backgroundImage: profileImageBase64 != null
                  ? MemoryImage(base64Decode(profileImageBase64!))
                  : null,
              child: profileImageBase64 == null
                  ? Icon(Icons.person, color: AppTheme.cardoBlue, size: 24)
                  : null,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSearchBar(bool isDarkMode, ColorScheme colorScheme, Size screenSize) {
    return Container(
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF2C2C2C) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: TextField(
        decoration: InputDecoration(
          hintText: context.translate('search_doctor'),
          hintStyle: TextStyle(
            color: isDarkMode ? Colors.white38 : Colors.black38,
            fontSize: 15,
          ),
          prefixIcon: Icon(Icons.search,
              color: isDarkMode ? Colors.white38 : Colors.black38, size: 22),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        style: TextStyle(
          color: isDarkMode ? Colors.white : Colors.black,
          fontSize: 15,
        ),
        onSubmitted: (query) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DoctorListingPage(specialtyFilter: query),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSpecialtiesSection(bool isDarkMode, ColorScheme colorScheme, Size screenSize) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(context.translate('specialities'), isDarkMode, colorScheme),
        SizedBox(height: 12),
        SizedBox(
          height: 100,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _specialties.length,
            itemBuilder: (context, index) {
              final specialty = _specialties[index];
              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => DoctorListingPage(
                        specialtyFilter: specialty['name'],
                      ),
                    ),
                  );
                },
                child: Container(
                  width: 76,
                  margin: EdgeInsets.only(right: 12),
                  child: Column(
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: specialty['color'].withOpacity(isDarkMode ? 0.2 : 0.15),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(
                          specialty['icon'],
                          color: specialty['color'],
                          size: 28,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        specialty['name'],
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: isDarkMode ? Colors.white70 : Colors.black87,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildAppointmentsList(bool isDarkMode, ColorScheme colorScheme, Size screenSize) {
    return SizedBox(
      height: 160,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _appointments.length,
        itemBuilder: (context, index) {
          final appointment = _appointments[index];
          final doctor = appointment['doctors'] as Map<String, dynamic>?;
          return _buildAppointmentCard(appointment, doctor, isDarkMode, colorScheme, screenSize);
        },
      ),
    );
  }

  Widget _buildAppointmentCard(
    Map<String, dynamic> appointment,
    Map<String, dynamic>? doctor,
    bool isDarkMode,
    ColorScheme colorScheme,
    Size screenSize,
  ) {
    return Container(
      width: screenSize.width * 0.75,
      margin: EdgeInsets.only(right: 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.cardoBlue, AppTheme.cardoDarkBlue],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: AppTheme.cardoBlue.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: Colors.white.withOpacity(0.2),
                child: Icon(Icons.person, color: Colors.white, size: 24),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      doctor?['name'] ?? 'Doctor',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      doctor?['specialty'] ?? '',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white.withOpacity(0.85),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 14),
          Divider(color: Colors.white.withOpacity(0.2)),
          SizedBox(height: 10),
          Row(
            children: [
              Icon(Icons.calendar_today, color: Colors.white.withOpacity(0.9), size: 15),
              SizedBox(width: 8),
              Text(
                appointment['appointment_date'] ?? '',
                style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.9)),
              ),
            ],
          ),
          SizedBox(height: 6),
          Row(
            children: [
              Icon(Icons.access_time, color: Colors.white.withOpacity(0.9), size: 15),
              SizedBox(width: 8),
              Text(
                '${appointment['start_time'] ?? ''} - ${appointment['end_time'] ?? ''}',
                style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.9)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDoctorsSection(bool isDarkMode, ColorScheme colorScheme, Size screenSize) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildSectionTitle(context.translate('make_an_appointment'), isDarkMode, colorScheme),
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const DoctorListingPage()),
                );
              },
              child: Text(
                context.translate('see_all'),
                style: TextStyle(
                  color: AppTheme.cardoBlue,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 12),
        _doctors.isEmpty
            ? _buildEmptyDoctorsState(isDarkMode, colorScheme, screenSize)
            : _buildDoctorsList(isDarkMode, colorScheme, screenSize),
      ],
    );
  }

  Widget _buildEmptyDoctorsState(bool isDarkMode, ColorScheme colorScheme, Size screenSize) {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF2C2C2C) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.medical_services_outlined,
                size: 48, color: Colors.grey.withOpacity(0.5)),
            SizedBox(height: 12),
            Text(
              'No doctors available yet',
              style: TextStyle(
                fontSize: 15,
                color: isDarkMode ? Colors.white54 : Colors.black45,
              ),
            ),
            SizedBox(height: 4),
            Text(
              'Add doctors in Supabase to get started',
              style: TextStyle(
                fontSize: 12,
                color: isDarkMode ? Colors.white38 : Colors.black38,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDoctorsList(bool isDarkMode, ColorScheme colorScheme, Size screenSize) {
    return SizedBox(
      height: 210,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _doctors.length,
        itemBuilder: (context, index) {
          final doctor = _doctors[index];
          return _buildDoctorCard(doctor, isDarkMode, colorScheme, screenSize);
        },
      ),
    );
  }

  Widget _buildDoctorCard(
    Map<String, dynamic> doctor,
    bool isDarkMode,
    ColorScheme colorScheme,
    Size screenSize,
  ) {
    final double rating = (doctor['rating'] ?? 0).toDouble();
    final int reviewCount = doctor['review_count'] ?? 0;
    final double price = (doctor['price'] ?? 0).toDouble();

    return Container(
      width: screenSize.width * 0.7,
      margin: EdgeInsets.only(right: 14),
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
      child: Padding(
        padding: EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: AppTheme.cardoBlue.withOpacity(0.1),
                  child: Icon(Icons.person, color: AppTheme.cardoBlue, size: 24),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        doctor['name'] ?? 'Doctor',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: isDarkMode ? Colors.white : Colors.black,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        doctor['specialty'] ?? '',
                        style: TextStyle(
                          fontSize: 13,
                          color: isDarkMode ? Colors.white60 : Colors.black54,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                if (rating > 0)
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.amber.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.star, color: Colors.amber, size: 14),
                        SizedBox(width: 3),
                        Text(
                          rating.toStringAsFixed(1),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.amber.shade800,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            SizedBox(height: 10),
            if (doctor['organization'] != null)
              Row(
                children: [
                  Icon(Icons.location_on_outlined,
                      size: 14, color: isDarkMode ? Colors.white38 : Colors.black38),
                  SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      doctor['organization'],
                      style: TextStyle(
                        fontSize: 12,
                        color: isDarkMode ? Colors.white38 : Colors.black45,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            Spacer(),
            Row(
              children: [
                if (price > 0) ...[
                  Text(
                    '\$${price.toStringAsFixed(0)}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.cardoBlue,
                    ),
                  ),
                  Text(
                    ' / visit',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDarkMode ? Colors.white38 : Colors.black38,
                    ),
                  ),
                  Spacer(),
                ] else
                  Spacer(),
                ElevatedButton(
                  onPressed: () => _showBookingDialog(doctor),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.cardoBlue,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    elevation: 0,
                  ),
                  child: Text(
                    context.translate('book_now'),
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showBookingDialog(Map<String, dynamic> doctor) {
    DateTime selectedDate = DateTime.now().add(const Duration(days: 1));
    List<Map<String, dynamic>> availableSlots = [];
    bool isLoadingSlots = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.75,
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                children: [
                  Container(
                    margin: EdgeInsets.only(top: 10),
                    width: 40, height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 20,
                              backgroundColor: AppTheme.cardoBlue.withOpacity(0.1),
                              child: Icon(Icons.person, color: AppTheme.cardoBlue),
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    doctor['name'] ?? 'Doctor',
                                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                  ),
                                  Text(
                                    doctor['specialty'] ?? '',
                                    style: TextStyle(fontSize: 14, color: Colors.grey),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 20),
                        Text(
                          'Select Date',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                        SizedBox(height: 10),
                        SizedBox(
                          height: 70,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: 7,
                            itemBuilder: (context, index) {
                              final date = DateTime.now().add(Duration(days: index + 1));
                              final isSelected = date.day == selectedDate.day &&
                                  date.month == selectedDate.month;
                              return GestureDetector(
                                onTap: () async {
                                  setDialogState(() {
                                    selectedDate = date;
                                    isLoadingSlots = true;
                                  });
                                  try {
                                    final slots = await SupabaseService.fetchDoctorAvailability(
                                      doctor['id'],
                                      date.weekday - 1, // 0=Mon, 6=Sun
                                    );
                                    setDialogState(() {
                                      availableSlots = slots;
                                      isLoadingSlots = false;
                                    });
                                  } catch (e) {
                                    setDialogState(() {
                                      availableSlots = [];
                                      isLoadingSlots = false;
                                    });
                                  }
                                },
                                child: Container(
                                  width: 52,
                                  margin: EdgeInsets.only(right: 10),
                                  decoration: BoxDecoration(
                                    color: isSelected ? AppTheme.cardoBlue : Colors.transparent,
                                    border: Border.all(
                                      color: isSelected ? AppTheme.cardoBlue : Colors.grey.withOpacity(0.3),
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        DateFormat('EEE').format(date),
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: isSelected
                                              ? Colors.white.withOpacity(0.8)
                                              : Colors.grey,
                                        ),
                                      ),
                                      SizedBox(height: 4),
                                      Text(
                                        '${date.day}',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: isSelected ? Colors.white : null,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: isLoadingSlots
                        ? Center(child: CircularProgressIndicator(color: AppTheme.cardoBlue))
                        : availableSlots.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.event_busy, size: 48, color: Colors.grey),
                                    SizedBox(height: 12),
                                    Text(
                                      'No availability on this day',
                                      style: TextStyle(color: Colors.grey, fontSize: 15),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      'Try selecting a different date',
                                      style: TextStyle(color: Colors.grey, fontSize: 13),
                                    ),
                                  ],
                                ),
                              )
                            : GridView.builder(
                                padding: EdgeInsets.symmetric(horizontal: 20),
                                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 3,
                                  crossAxisSpacing: 10,
                                  mainAxisSpacing: 10,
                                  childAspectRatio: 2.5,
                                ),
                                itemCount: availableSlots.length,
                                itemBuilder: (context, slotIndex) {
                                  final slot = availableSlots[slotIndex];
                                  return ElevatedButton(
                                    onPressed: () => _confirmBooking(
                                      doctor,
                                      selectedDate,
                                      slot['start_time'],
                                      slot['end_time'],
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppTheme.cardoBlue.withOpacity(0.1),
                                      foregroundColor: AppTheme.cardoBlue,
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                        side: BorderSide(
                                          color: AppTheme.cardoBlue.withOpacity(0.3),
                                        ),
                                      ),
                                    ),
                                    child: Text(
                                      slot['start_time'],
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  );
                                },
                              ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _confirmBooking(
    Map<String, dynamic> doctor,
    DateTime date,
    String startTime,
    String endTime,
  ) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    try {
      final isBooked = await SupabaseService.isSlotBooked(
        doctor['id'],
        date.toIso8601String().split('T').first,
        startTime,
      );

      if (isBooked) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('This slot is already booked'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      await SupabaseService.bookAppointment(
        patientId: userId,
        doctorId: doctor['id'],
        date: date,
        startTime: startTime,
        endTime: endTime,
      );

      Navigator.pop(context); // Close booking dialog

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Appointment booked successfully'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );

      _fetchAppointments(); // Refresh
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Booking failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildSectionTitle(String title, bool isDarkMode, ColorScheme colorScheme) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: isDarkMode ? Colors.white : Colors.black,
      ),
    );
  }
}
