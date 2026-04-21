import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:test_1/utils/theme_provider.dart';
import 'package:test_1/utils/language_provider.dart';
import 'package:test_1/utils/app_localizations.dart';
import 'package:test_1/database/supabase_config.dart';

class DoctorPatientsPage extends StatefulWidget {
  const DoctorPatientsPage({super.key});

  @override
  State<DoctorPatientsPage> createState() => _DoctorPatientsPageState();
}

class _DoctorPatientsPageState extends State<DoctorPatientsPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController _searchController = TextEditingController();

  bool _isLoading = true;
  String? _doctorId;
  List<Map<String, dynamic>> _allPatients = [];
  List<Map<String, dynamic>> _filteredPatients = [];

  @override
  void initState() {
    super.initState();
    _loadPatients();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadPatients() async {
    setState(() => _isLoading = true);
    try {
      final uid = _auth.currentUser?.uid;
      if (uid == null) return;

      final doctorData = await SupabaseService.fetchDoctorByUserId(uid);
      if (doctorData == null) {
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      _doctorId = doctorData['id'] as String?;
      if (_doctorId == null) {
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      final patients =
          await SupabaseService.fetchDoctorPatients(_doctorId!);
      if (mounted) {
        setState(() {
          _allPatients = patients;
          _filteredPatients = patients;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading patients: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _filterPatients(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredPatients = _allPatients;
      } else {
        _filteredPatients = _allPatients.where((patient) {
          final name =
              (patient['full_name'] as String? ?? '').toLowerCase();
          return name.contains(query.toLowerCase());
        }).toList();
      }
    });
  }

  void _showPatientDetails(Map<String, dynamic> patient) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final isDarkMode = themeProvider.isDarkMode;
    final colorScheme = Theme.of(context).colorScheme;
    final languageProvider =
        Provider.of<LanguageProvider>(context, listen: false);
    final isRTL = languageProvider.isRTL;
    final patientId = patient['id'] as String?;
    final patientName = patient['full_name'] as String? ?? 'Unknown';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return Directionality(
          textDirection: isRTL ? TextDirection.rtl : TextDirection.ltr,
          child: Container(
            height: MediaQuery.of(context).size.height * 0.7,
            decoration: BoxDecoration(
              color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(24)),
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
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundColor:
                            AppTheme.cardoBlue.withOpacity(0.15),
                        child: Icon(Icons.person,
                            color: AppTheme.cardoBlue, size: 28),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              patientName,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: isDarkMode
                                    ? Colors.white
                                    : Colors.black,
                              ),
                            ),
                            if (patient['email'] != null)
                              Text(
                                patient['email'],
                                style: TextStyle(
                                  fontSize: 13,
                                  color: isDarkMode
                                      ? Colors.white54
                                      : Colors.black45,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Divider(
                    color: isDarkMode
                        ? Colors.white12
                        : Colors.grey.withOpacity(0.2)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      context.translate('medical_records'),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isDarkMode ? Colors.white : Colors.black,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 12),
                Expanded(
                  child: patientId == null
                      ? Center(
                          child: Text(
                            'Patient ID not available',
                            style: TextStyle(
                              color: isDarkMode
                                  ? Colors.white54
                                  : Colors.black45,
                            ),
                          ),
                        )
                      : FutureBuilder<List<Map<String, dynamic>>>(
                          future: SupabaseService.fetchPatientMedicalRecords(
                              patientId),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return Center(
                                child: CircularProgressIndicator(
                                    color: AppTheme.cardoBlue),
                              );
                            }
                            if (snapshot.hasError) {
                              return Center(
                                child: Text(
                                  'Error loading records',
                                  style: TextStyle(
                                    color: isDarkMode
                                        ? Colors.white54
                                        : Colors.black45,
                                  ),
                                ),
                              );
                            }
                            final records = snapshot.data ?? [];
                            if (records.isEmpty) {
                              return Center(
                                child: Column(
                                  mainAxisAlignment:
                                      MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.folder_open_outlined,
                                      size: 48,
                                      color: Colors.grey
                                          .withOpacity(0.5),
                                    ),
                                    SizedBox(height: 12),
                                    Text(
                                      'No medical records found',
                                      style: TextStyle(
                                        fontSize: 15,
                                        color: isDarkMode
                                            ? Colors.white54
                                            : Colors.black45,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }
                            return ListView.builder(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 20),
                              itemCount: records.length,
                              itemBuilder: (context, index) {
                                final record = records[index];
                                final doctorInfo =
                                    record['doctors']
                                        as Map<String, dynamic>?;
                                return Container(
                                  margin: EdgeInsets.only(bottom: 10),
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: isDarkMode
                                        ? const Color(0xFF2C2C2C)
                                        : Colors.grey[50],
                                    borderRadius:
                                        BorderRadius.circular(12),
                                    border: Border.all(
                                      color: isDarkMode
                                          ? Colors.white10
                                          : Colors.grey
                                              .withOpacity(0.2),
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        record['diagnosis'] ?? 'N/A',
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                          color: isDarkMode
                                              ? Colors.white
                                              : Colors.black,
                                        ),
                                      ),
                                      SizedBox(height: 6),
                                      Text(
                                        '${context.translate('treatment')}: ${record['treatment'] ?? 'N/A'}',
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: isDarkMode
                                              ? Colors.white60
                                              : Colors.black54,
                                        ),
                                      ),
                                      SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Icon(Icons.calendar_today,
                                              size: 13,
                                              color: AppTheme.cardoBlue),
                                          SizedBox(width: 4),
                                          Text(
                                            record['date'] ?? 'N/A',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: AppTheme.cardoBlue,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                );
                              },
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
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
            'Patients',
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
        body: _isLoading
            ? Center(
                child: CircularProgressIndicator(color: AppTheme.cardoBlue))
            : RefreshIndicator(
                color: AppTheme.cardoBlue,
                onRefresh: _loadPatients,
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Container(
                        decoration: BoxDecoration(
                          color: isDarkMode
                              ? const Color(0xFF2C2C2C)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color:
                                  Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: TextField(
                          controller: _searchController,
                          onChanged: _filterPatients,
                          decoration: InputDecoration(
                            hintText:
                                context.translate('search'),
                            hintStyle: TextStyle(
                              color: isDarkMode
                                  ? Colors.white38
                                  : Colors.black38,
                              fontSize: 15,
                            ),
                            prefixIcon: Icon(Icons.search,
                                color: isDarkMode
                                    ? Colors.white38
                                    : Colors.black38,
                                size: 22),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 14),
                          ),
                          style: TextStyle(
                            color:
                                isDarkMode ? Colors.white : Colors.black,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: _filteredPatients.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment:
                                    MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.people_outline,
                                    size: 64,
                                    color: Colors.grey
                                        .withOpacity(0.5),
                                  ),
                                  SizedBox(height: 16),
                                  Text(
                                    'No patients found',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                      color: isDarkMode
                                          ? Colors.white54
                                          : Colors.black45,
                                    ),
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    'Patients will appear here once they book appointments with you.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: isDarkMode
                                          ? Colors.white38
                                          : Colors.black38,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16),
                              itemCount: _filteredPatients.length,
                              itemBuilder: (context, index) {
                                final patient = _filteredPatients[index];
                                return _buildPatientCard(
                                    patient, isDarkMode, colorScheme);
                              },
                            ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildPatientCard(
      Map<String, dynamic> patient, bool isDarkMode, ColorScheme colorScheme) {
    final name = patient['full_name'] as String? ?? 'Unknown Patient';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
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
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => _showPatientDetails(patient),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor: AppTheme.cardoBlue.withOpacity(0.15),
                  child: Text(
                    name.isNotEmpty ? name[0].toUpperCase() : '?',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.cardoBlue,
                    ),
                  ),
                ),
                SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: isDarkMode ? Colors.white : Colors.black,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Tap to view medical records',
                        style: TextStyle(
                          fontSize: 13,
                          color: isDarkMode
                              ? Colors.white54
                              : Colors.black45,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: isDarkMode ? Colors.white38 : Colors.black38,
                  size: 24,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
