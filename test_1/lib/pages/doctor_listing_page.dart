import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:test_1/utils/theme_provider.dart';
import 'package:test_1/utils/language_provider.dart';
import 'package:test_1/utils/app_localizations.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:test_1/database/supabase_config.dart';

class DoctorListingPage extends StatefulWidget {
  final String? specialtyFilter;

  const DoctorListingPage({
    Key? key,
    this.specialtyFilter,
  }) : super(key: key);

  @override
  State<DoctorListingPage> createState() => _DoctorListingPageState();
}

class _DoctorListingPageState extends State<DoctorListingPage> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _doctors = [];
  String _searchQuery = '';
  String? _selectedSpecialty;

  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedSpecialty = widget.specialtyFilter;
    _loadDoctors();
  }

  Future<void> _loadDoctors() async {
    setState(() => _isLoading = true);

    try {
      final doctors = await SupabaseService.fetchDoctors(
        specialty: _selectedSpecialty,
      );
      if (mounted) {
        setState(() {
          _doctors = doctors;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading doctors: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<Map<String, dynamic>> get _filteredDoctors {
    if (_searchQuery.isEmpty) return _doctors;
    return _doctors.where((doctor) {
      final name = (doctor['name'] ?? '').toString().toLowerCase();
      final specialty = (doctor['specialty'] ?? '').toString().toLowerCase();
      final query = _searchQuery.toLowerCase();
      return name.contains(query) || specialty.contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    final languageProvider = Provider.of<LanguageProvider>(context);
    final isRTL = languageProvider.isRTL;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          context.translate('find_doctor'),
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isDarkMode ? Colors.white : Colors.black,
          ),
        ),
        backgroundColor: isDarkMode ? const Color(0xFF121212) : Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            isRTL ? Icons.arrow_forward : Icons.arrow_back,
            color: isDarkMode ? Colors.white : Colors.black,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // Search bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: isDarkMode ? const Color(0xFF121212) : Colors.white,
            child: TextField(
              controller: _searchController,
              onChanged: (value) => setState(() => _searchQuery = value),
              decoration: InputDecoration(
                hintText: context.translate('search_doctors'),
                prefixIcon: Icon(Icons.search,
                    color: isDarkMode ? Colors.white70 : Colors.grey),
                filled: true,
                fillColor: isDarkMode ? const Color(0xFF2C2C2C) : Colors.grey[200],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
            ),
          ),

          // Doctor count
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Align(
              alignment: isRTL ? Alignment.centerRight : Alignment.centerLeft,
              child: Text(
                '${_filteredDoctors.length} ${context.translate('doctors_found')}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isDarkMode ? Colors.white70 : Colors.grey[700],
                ),
              ),
            ),
          ),

          // Doctor list
          Expanded(
            child: _isLoading
                ? Center(
                    child: CircularProgressIndicator(color: AppTheme.cardoBlue))
                : _filteredDoctors.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.search_off,
                                size: 48,
                                color: isDarkMode ? Colors.white38 : Colors.black26),
                            SizedBox(height: 12),
                            Text(
                              context.translate('no_doctors_found'),
                              style: TextStyle(
                                color:
                                    isDarkMode ? Colors.white54 : Colors.black45,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: _filteredDoctors.length,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemBuilder: (context, index) {
                          return _buildDoctorCard(
                              _filteredDoctors[index], isDarkMode, isRTL);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildDoctorCard(
      Map<String, dynamic> doctor, bool isDarkMode, bool isRTL) {
    final double rating = (doctor['rating'] ?? 0).toDouble();
    final int reviewCount = doctor['review_count'] ?? 0;
    final double price = (doctor['price'] ?? 0).toDouble();

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
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
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: AppTheme.cardoBlue.withOpacity(0.1),
                  backgroundImage: doctor['image_url'] != null
                      ? NetworkImage(doctor['image_url'])
                      : null,
                  child: doctor['image_url'] == null
                      ? Icon(Icons.person,
                          size: 28, color: AppTheme.cardoBlue)
                      : null,
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        doctor['name'] ?? 'Doctor',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: isDarkMode ? Colors.white : Colors.black,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        doctor['specialty'] ?? '',
                        style: TextStyle(
                          color: isDarkMode ? Colors.white70 : Colors.grey[700],
                          fontSize: 14,
                        ),
                      ),
                      if (rating > 0) ...[
                        SizedBox(height: 6),
                        Row(
                          children: [
                            ...List.generate(5, (index) {
                              return Icon(
                                index < rating.floor()
                                    ? Icons.star
                                    : index < rating
                                        ? Icons.star_half
                                        : Icons.star_border,
                                color: Colors.amber,
                                size: 16,
                              );
                            }),
                            SizedBox(width: 4),
                            Text(
                              '($reviewCount)',
                              style: TextStyle(
                                color: isDarkMode
                                    ? Colors.white54
                                    : Colors.grey[600],
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (doctor['bio'] != null && doctor['bio'].toString().isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.medical_services_outlined,
                      size: 16, color: AppTheme.cardoBlue),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      doctor['bio'],
                      style: TextStyle(
                        fontSize: 13,
                        color:
                            isDarkMode ? Colors.white60 : Colors.grey[600],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          if (doctor['location'] != null)
            Padding(
              padding: EdgeInsets.only(left: 16, right: 16, top: 8),
              child: Row(
                children: [
                  Icon(Icons.location_on_outlined,
                      size: 16, color: Colors.red),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      doctor['location'] ?? '',
                      style: TextStyle(
                        fontSize: 13,
                        color:
                            isDarkMode ? Colors.white60 : Colors.grey[600],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                if (price > 0) ...[
                  Text(
                    '\$${price.toStringAsFixed(0)}',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.cardoBlue,
                    ),
                  ),
                  Text(
                    ' / ${context.translate('visit')}',
                    style: TextStyle(
                      fontSize: 13,
                      color: isDarkMode ? Colors.white38 : Colors.black38,
                    ),
                  ),
                ],
                Spacer(),
                ElevatedButton(
                  onPressed: () => _showBookingDialog(doctor),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.cardoBlue,
                    foregroundColor: Colors.white,
                    padding:
                        EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    elevation: 0,
                  ),
                  child: Text(
                    context.translate('book_now'),
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
        ],
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
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                children: [
                  Container(
                    margin: EdgeInsets.only(top: 10),
                    width: 40,
                    height: 4,
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
                              backgroundColor:
                                  AppTheme.cardoBlue.withOpacity(0.1),
                              child: Icon(Icons.person,
                                  color: AppTheme.cardoBlue),
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(doctor['name'] ?? 'Doctor',
                                      style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold)),
                                  Text(doctor['specialty'] ?? '',
                                      style: TextStyle(
                                          fontSize: 14, color: Colors.grey)),
                                ],
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 20),
                        Text('Select Date',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w600)),
                        SizedBox(height: 10),
                        SizedBox(
                          height: 70,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: 7,
                            itemBuilder: (context, index) {
                              final date =
                                  DateTime.now().add(Duration(days: index + 1));
                              final isSelected = date.day == selectedDate.day &&
                                  date.month == selectedDate.month;
                              return GestureDetector(
                                onTap: () async {
                                  setDialogState(() {
                                    selectedDate = date;
                                    isLoadingSlots = true;
                                  });
                                  try {
                                    final slots = await SupabaseService
                                        .fetchDoctorAvailability(
                                      doctor['id'],
                                      date.weekday - 1,
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
                                    color: isSelected
                                        ? AppTheme.cardoBlue
                                        : Colors.transparent,
                                    border: Border.all(
                                      color: isSelected
                                          ? AppTheme.cardoBlue
                                          : Colors.grey.withOpacity(0.3),
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        _weekdayShort(date),
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
                                          color: isSelected
                                              ? Colors.white
                                              : null,
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
                        ? Center(
                            child: CircularProgressIndicator(
                                color: AppTheme.cardoBlue))
                        : availableSlots.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.event_busy,
                                        size: 48, color: Colors.grey),
                                    SizedBox(height: 12),
                                    Text('No availability on this day',
                                        style: TextStyle(
                                            color: Colors.grey, fontSize: 15)),
                                    SizedBox(height: 4),
                                    Text('Try selecting a different date',
                                        style: TextStyle(
                                            color: Colors.grey, fontSize: 13)),
                                  ],
                                ),
                              )
                            : GridView.builder(
                                padding:
                                    EdgeInsets.symmetric(horizontal: 20),
                                gridDelegate:
                                    SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 3,
                                  crossAxisSpacing: 10,
                                  mainAxisSpacing: 10,
                                  childAspectRatio: 2.5,
                                ),
                                itemCount: availableSlots.length,
                                itemBuilder: (context, slotIndex) {
                                  final slot = availableSlots[slotIndex];
                                  return ElevatedButton(
                                    onPressed: () =>
                                        _confirmBooking(doctor, selectedDate,
                                            slot['start_time'], slot['end_time']),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor:
                                          AppTheme.cardoBlue.withOpacity(0.1),
                                      foregroundColor: AppTheme.cardoBlue,
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                        side: BorderSide(
                                          color: AppTheme.cardoBlue
                                              .withOpacity(0.3),
                                        ),
                                      ),
                                    ),
                                    child: Text(
                                      slot['start_time'],
                                      style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600),
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

  String _weekdayShort(DateTime date) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[date.weekday - 1];
  }

  Future<void> _confirmBooking(
    Map<String, dynamic> doctor,
    DateTime date,
    String startTime,
    String endTime,
  ) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
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

      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Appointment booked successfully'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Booking failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
