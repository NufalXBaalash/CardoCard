import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:test_1/utils/theme_provider.dart';
import 'package:test_1/utils/language_provider.dart';
import 'package:test_1/utils/app_localizations.dart';
import 'package:test_1/database/supabase_config.dart';

class DoctorAppointmentsPage extends StatefulWidget {
  const DoctorAppointmentsPage({super.key});

  @override
  State<DoctorAppointmentsPage> createState() =>
      _DoctorAppointmentsPageState();
}

class _DoctorAppointmentsPageState extends State<DoctorAppointmentsPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool _isLoading = true;
  String? _doctorId;
  String _selectedFilter = 'scheduled';
  List<Map<String, dynamic>> _appointments = [];

  final List<Map<String, String>> _filterTabs = [
    {'key': 'scheduled', 'label': 'Upcoming'},
    {'key': 'completed', 'label': 'Completed'},
    {'key': 'cancelled', 'label': 'Cancelled'},
  ];

  @override
  void initState() {
    super.initState();
    _loadAppointments();
  }

  Future<void> _loadAppointments() async {
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

      final appointments = await SupabaseService.fetchDoctorAppointments(
        _doctorId!,
        status: _selectedFilter,
      );

      if (mounted) {
        setState(() {
          _appointments = appointments;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading appointments: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _changeFilter(String status) {
    if (_selectedFilter == status) return;
    setState(() {
      _selectedFilter = status;
    });
    _loadAppointments();
  }

  Future<void> _updateStatus(String appointmentId, String status) async {
    try {
      await SupabaseService.updateAppointmentStatus(appointmentId, status);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Appointment marked as $status'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      _loadAppointments();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'scheduled':
        return AppTheme.cardoBlue;
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getStatusLabel(String status) {
    switch (status) {
      case 'scheduled':
        return 'Upcoming';
      case 'completed':
        return 'Completed';
      case 'cancelled':
        return 'Cancelled';
      default:
        return status;
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
            context.translate('appointments'),
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
        body: Column(
          children: [
            _buildFilterTabs(isDarkMode, colorScheme),
            Expanded(
              child: _isLoading
                  ? Center(
                      child: CircularProgressIndicator(
                          color: AppTheme.cardoBlue))
                  : RefreshIndicator(
                      color: AppTheme.cardoBlue,
                      onRefresh: _loadAppointments,
                      child: _appointments.isEmpty
                          ? _buildEmptyState(isDarkMode)
                          : ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: _appointments.length,
                              itemBuilder: (context, index) {
                                return _buildAppointmentCard(
                                  _appointments[index],
                                  isDarkMode,
                                  colorScheme,
                                );
                              },
                            ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterTabs(bool isDarkMode, ColorScheme colorScheme) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF2C2C2C) : Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: _filterTabs.map((tab) {
          final isSelected = _selectedFilter == tab['key'];
          return Expanded(
            child: GestureDetector(
              onTap: () => _changeFilter(tab['key']!),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppTheme.cardoBlue
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  tab['label']!,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.w500,
                    color: isSelected
                        ? Colors.white
                        : isDarkMode
                            ? Colors.white60
                            : Colors.black54,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
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
                Icons.event_available_outlined,
                size: 64,
                color: Colors.grey.withOpacity(0.5),
              ),
              SizedBox(height: 16),
              Text(
                'No ${_getStatusLabel(_selectedFilter).toLowerCase()} appointments',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: isDarkMode ? Colors.white54 : Colors.black45,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Appointments will appear here when patients book with you.',
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

  Widget _buildAppointmentCard(
    Map<String, dynamic> appointment,
    bool isDarkMode,
    ColorScheme colorScheme,
  ) {
    final profile = appointment['profiles'] as Map<String, dynamic>?;
    final patientName = profile?['full_name'] as String? ?? 'Unknown Patient';
    final status = appointment['status'] as String? ?? 'scheduled';
    final statusColor = _getStatusColor(status);
    final date = appointment['appointment_date'] as String? ?? '';
    final startTime = appointment['start_time'] as String? ?? '';
    final endTime = appointment['end_time'] as String? ?? '';
    final notes = appointment['notes'] as String?;

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
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor:
                      AppTheme.cardoBlue.withOpacity(0.15),
                  child: Text(
                    patientName.isNotEmpty
                        ? patientName[0].toUpperCase()
                        : '?',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.cardoBlue,
                    ),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        patientName,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: isDarkMode ? Colors.white : Colors.black,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.access_time,
                              size: 14,
                              color: isDarkMode
                                  ? Colors.white54
                                  : Colors.black45),
                          SizedBox(width: 4),
                          Text(
                            '$startTime - $endTime',
                            style: TextStyle(
                              fontSize: 13,
                              color: isDarkMode
                                  ? Colors.white54
                                  : Colors.black45,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _getStatusLabel(status),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 10),
            Row(
              children: [
                Icon(Icons.calendar_today,
                    size: 14, color: AppTheme.cardoBlue),
                SizedBox(width: 6),
                Text(
                  date,
                  style: TextStyle(
                    fontSize: 13,
                    color: AppTheme.cardoBlue,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            if (notes != null && notes.isNotEmpty) ...[
              SizedBox(height: 6),
              Text(
                notes,
                style: TextStyle(
                  fontSize: 13,
                  color: isDarkMode ? Colors.white54 : Colors.black45,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            if (status == 'scheduled') ...[
              SizedBox(height: 12),
              Divider(
                  color: isDarkMode
                      ? Colors.white10
                      : Colors.grey.withOpacity(0.2)),
              SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: () => _updateStatus(
                        appointment['id'], 'cancelled'),
                    icon: Icon(Icons.close, size: 16, color: Colors.red),
                    label: Text(
                      context.translate('cancel'),
                      style: TextStyle(color: Colors.red, fontSize: 13),
                    ),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                    ),
                  ),
                  SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: () => _updateStatus(
                        appointment['id'], 'completed'),
                    icon: Icon(Icons.check, size: 16),
                    label: Text(
                      context.translate('completed'),
                      style: TextStyle(fontSize: 13),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                      elevation: 0,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
