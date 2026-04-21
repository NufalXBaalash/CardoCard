import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:test_1/utils/theme_provider.dart';
import 'package:test_1/utils/language_provider.dart';
import 'package:test_1/utils/app_localizations.dart';
import 'package:test_1/database/supabase_config.dart';

class DoctorSchedulePage extends StatefulWidget {
  const DoctorSchedulePage({super.key});

  @override
  State<DoctorSchedulePage> createState() => _DoctorSchedulePageState();
}

class _DoctorSchedulePageState extends State<DoctorSchedulePage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool _isLoading = true;
  String? _doctorId;
  List<Map<String, dynamic>> _availability = [];

  static const List<String> _dayNames = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  @override
  void initState() {
    super.initState();
    _loadSchedule();
  }

  Future<void> _loadSchedule() async {
    setState(() => _isLoading = true);
    try {
      final uid = _auth.currentUser?.uid;
      if (uid == null) return;

      if (_doctorId == null) {
        final doctorData = await SupabaseService.fetchDoctorByUserId(uid);
        if (doctorData == null) {
          if (mounted) setState(() => _isLoading = false);
          return;
        }
        _doctorId = doctorData['id'] as String?;
      }

      if (_doctorId == null) {
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      // Fetch all availability including unavailable slots
      final response = await SupabaseService.client
          .from('doctor_availability')
          .select()
          .eq('doctor_id', _doctorId!)
          .order('day_of_week');

      if (mounted) {
        setState(() {
          _availability = List<Map<String, dynamic>>.from(response);
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading schedule: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<Map<String, dynamic>> _getSlotsForDay(int dayIndex) {
    // dayIndex: 0=Monday ... 6=Sunday, matching day_of_week in DB
    return _availability
        .where((slot) => slot['day_of_week'] == dayIndex)
        .toList();
  }

  void _showAddSlotDialog() {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final isDarkMode = themeProvider.isDarkMode;
    final languageProvider =
        Provider.of<LanguageProvider>(context, listen: false);
    final isRTL = languageProvider.isRTL;

    int selectedDay = 0;
    TimeOfDay startTime = const TimeOfDay(hour: 9, minute: 0);
    TimeOfDay endTime = const TimeOfDay(hour: 17, minute: 0);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return Directionality(
          textDirection: isRTL ? TextDirection.rtl : TextDirection.ltr,
          child: StatefulBuilder(
            builder: (context, setModalState) {
              return Container(
                height: MediaQuery.of(context).size.height * 0.55,
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom,
                ),
                decoration: BoxDecoration(
                  color:
                      isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
                  borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(24)),
                ),
                child: Column(
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 10),
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Text(
                        'Add Time Slot',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: isDarkMode ? Colors.white : Colors.black,
                        ),
                      ),
                    ),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Column(
                          children: [
                            // Day selector
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12),
                              decoration: BoxDecoration(
                                color: isDarkMode
                                    ? const Color(0xFF2C2C2C)
                                    : Colors.grey[100],
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isDarkMode
                                      ? Colors.white10
                                      : Colors.grey.withOpacity(0.3),
                                ),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<int>(
                                  value: selectedDay,
                                  isExpanded: true,
                                  icon: Icon(
                                    Icons.arrow_drop_down,
                                    color: AppTheme.cardoBlue,
                                  ),
                                  items: List.generate(7, (index) {
                                    return DropdownMenuItem<int>(
                                      value: index,
                                      child: Text(
                                        _dayNames[index],
                                        style: TextStyle(
                                          color: isDarkMode
                                              ? Colors.white
                                              : Colors.black,
                                        ),
                                      ),
                                    );
                                  }),
                                  onChanged: (value) {
                                    if (value != null) {
                                      setModalState(() {
                                        selectedDay = value;
                                      });
                                    }
                                  },
                                ),
                              ),
                            ),
                            SizedBox(height: 20),
                            // Start Time
                            GestureDetector(
                              onTap: () async {
                                final time = await showTimePicker(
                                  context: context,
                                  initialTime: startTime,
                                  builder: (context, child) {
                                    return Theme(
                                      data: Theme.of(context).copyWith(
                                        timePickerTheme:
                                            TimePickerThemeData(
                                          dayPeriodColor:
                                              AppTheme.cardoBlue,
                                          dialHandColor: AppTheme.cardoBlue,
                                        ),
                                      ),
                                      child: child!,
                                    );
                                  },
                                );
                                if (time != null) {
                                  setModalState(() {
                                    startTime = time;
                                  });
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: isDarkMode
                                      ? const Color(0xFF2C2C2C)
                                      : Colors.grey[100],
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isDarkMode
                                        ? Colors.white10
                                        : Colors.grey
                                            .withOpacity(0.3),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.access_time,
                                        color: AppTheme.cardoBlue),
                                    SizedBox(width: 12),
                                    Text(
                                      'Start: ${_formatTimeOfDay(startTime)}',
                                      style: TextStyle(
                                        fontSize: 15,
                                        color: isDarkMode
                                            ? Colors.white
                                            : Colors.black,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            SizedBox(height: 16),
                            // End Time
                            GestureDetector(
                              onTap: () async {
                                final time = await showTimePicker(
                                  context: context,
                                  initialTime: endTime,
                                  builder: (context, child) {
                                    return Theme(
                                      data: Theme.of(context).copyWith(
                                        timePickerTheme:
                                            TimePickerThemeData(
                                          dayPeriodColor:
                                              AppTheme.cardoBlue,
                                          dialHandColor: AppTheme.cardoBlue,
                                        ),
                                      ),
                                      child: child!,
                                    );
                                  },
                                );
                                if (time != null) {
                                  setModalState(() {
                                    endTime = time;
                                  });
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: isDarkMode
                                      ? const Color(0xFF2C2C2C)
                                      : Colors.grey[100],
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isDarkMode
                                        ? Colors.white10
                                        : Colors.grey
                                            .withOpacity(0.3),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.access_time_filled,
                                        color: AppTheme.cardoBlue),
                                    SizedBox(width: 12),
                                    Text(
                                      'End: ${_formatTimeOfDay(endTime)}',
                                      style: TextStyle(
                                        fontSize: 15,
                                        color: isDarkMode
                                            ? Colors.white
                                            : Colors.black,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            SizedBox(height: 24),
                            SizedBox(
                              width: double.infinity,
                              height: 50,
                              child: ElevatedButton(
                                onPressed: () => _addSlot(
                                    selectedDay, startTime, endTime),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.cardoBlue,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 0,
                                ),
                                child: Text(
                                  'Add Slot',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(height: 30),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  String _formatTimeOfDay(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  Future<void> _addSlot(
      int dayOfWeek, TimeOfDay start, TimeOfDay end) async {
    if (_doctorId == null) return;
    try {
      await SupabaseService.addAvailabilitySlot(
        doctorId: _doctorId!,
        dayOfWeek: dayOfWeek,
        startTime: _formatTimeOfDay(start),
        endTime: _formatTimeOfDay(end),
      );
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Time slot added successfully'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
      _loadSchedule();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to add slot: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  Future<void> _deleteSlot(String slotId) async {
    try {
      await SupabaseService.removeAvailabilitySlot(slotId);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Time slot removed'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      _loadSchedule();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to remove slot: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  Future<void> _toggleSlot(String slotId, bool currentAvailable) async {
    try {
      await SupabaseService.toggleAvailabilitySlot(
          slotId, !currentAvailable);
      _loadSchedule();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update slot: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    final languageProvider = Provider.of<LanguageProvider>(context);
    final isRTL = languageProvider.isRTL;
    final colorScheme = Theme.of(context).colorScheme;

    return Directionality(
      textDirection: isRTL ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: colorScheme.background,
        appBar: AppBar(
          title: Text(
            'Schedule',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
          centerTitle: true,
          elevation: 0,
          backgroundColor: colorScheme.surface,
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: _showAddSlotDialog,
          backgroundColor: AppTheme.cardoBlue,
          child: Icon(Icons.add, color: Colors.white),
        ),
        body: _isLoading
            ? Center(
                child: CircularProgressIndicator(color: AppTheme.cardoBlue))
            : RefreshIndicator(
                color: AppTheme.cardoBlue,
                onRefresh: _loadSchedule,
                child: _availability.isEmpty
                    ? _buildEmptyState(isDarkMode)
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: 7,
                        itemBuilder: (context, index) {
                          final slots = _getSlotsForDay(index);
                          return _buildDaySection(
                              index, slots, isDarkMode, colorScheme);
                        },
                      ),
              ),
      ),
    );
  }

  Widget _buildEmptyState(bool isDarkMode) {
    return ListView(
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.2),
        Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.event_note_outlined,
                size: 64,
                color: Colors.grey.withOpacity(0.5),
              ),
              SizedBox(height: 16),
              Text(
                'No schedule set',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: isDarkMode ? Colors.white54 : Colors.black45,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Tap the + button to add your weekly availability.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: isDarkMode ? Colors.white38 : Colors.black38,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDaySection(
    int dayIndex,
    List<Map<String, dynamic>> slots,
    bool isDarkMode,
    ColorScheme colorScheme,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF2C2C2C) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDarkMode ? 0.2 : 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Day header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: AppTheme.cardoBlue.withOpacity(0.06),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(14),
                topRight: Radius.circular(14),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.calendar_today, size: 18, color: AppTheme.cardoBlue),
                SizedBox(width: 8),
                Text(
                  _dayNames[dayIndex],
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.cardoBlue,
                  ),
                ),
                Spacer(),
                Text(
                  '${slots.length} slot${slots.length != 1 ? 's' : ''}',
                  style: TextStyle(
                    fontSize: 13,
                    color: isDarkMode ? Colors.white54 : Colors.black45,
                  ),
                ),
              ],
            ),
          ),
          if (slots.isEmpty)
            Padding(
              padding: const EdgeInsets.all(14),
              child: Text(
                'No availability set',
                style: TextStyle(
                  fontSize: 14,
                  color: isDarkMode ? Colors.white38 : Colors.black38,
                ),
              ),
            )
          else
            ...slots.map((slot) => _buildSlotItem(slot, isDarkMode, colorScheme)),
        ],
      ),
    );
  }

  Widget _buildSlotItem(
    Map<String, dynamic> slot,
    bool isDarkMode,
    ColorScheme colorScheme,
  ) {
    final isAvailable = slot['is_available'] as bool? ?? true;
    final startTime = slot['start_time'] as String? ?? '';
    final endTime = slot['end_time'] as String? ?? '';
    final slotId = slot['id']?.toString() ?? '';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: Row(
        children: [
          Icon(Icons.access_time, size: 16,
              color: isDarkMode ? Colors.white54 : Colors.black45),
          SizedBox(width: 6),
          Text(
            '$startTime - $endTime',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: isAvailable
                  ? (isDarkMode ? Colors.white : Colors.black)
                  : (isDarkMode ? Colors.white38 : Colors.black38),
              decoration: isAvailable ? null : TextDecoration.lineThrough,
            ),
          ),
          Spacer(),
          Switch(
            value: isAvailable,
            onChanged: slotId.isNotEmpty
                ? (value) => _toggleSlot(slotId, isAvailable)
                : null,
            activeColor: AppTheme.cardoBlue,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          SizedBox(width: 4),
          IconButton(
            icon: Icon(Icons.delete_outline, size: 20, color: Colors.redAccent),
            onPressed: slotId.isNotEmpty
                ? () => _confirmDeleteSlot(slotId)
                : null,
            padding: EdgeInsets.zero,
            constraints: BoxConstraints(minWidth: 36, minHeight: 36),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteSlot(String slotId) {
    final languageProvider =
        Provider.of<LanguageProvider>(context, listen: false);
    final isRTL = languageProvider.isRTL;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return Directionality(
          textDirection: isRTL ? TextDirection.rtl : TextDirection.ltr,
          child: AlertDialog(
            title: Text('Remove Time Slot'),
            content: Text(
                'Are you sure you want to remove this time slot?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: Text(context.translate('cancel')),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(dialogContext);
                  _deleteSlot(slotId);
                },
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: Text(context.translate('delete')),
              ),
            ],
          ),
        );
      },
    );
  }
}
