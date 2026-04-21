import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:test_1/utils/theme_provider.dart';
import 'package:test_1/utils/language_provider.dart';
import 'package:test_1/utils/app_localizations.dart';
import 'package:test_1/database/supabase_config.dart';

class DoctorReportsPage extends StatefulWidget {
  const DoctorReportsPage({super.key});

  @override
  State<DoctorReportsPage> createState() => _DoctorReportsPageState();
}

class _DoctorReportsPageState extends State<DoctorReportsPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final _formKey = GlobalKey<FormState>();
  final _diagnosisController = TextEditingController();
  final _treatmentController = TextEditingController();
  final _notesController = TextEditingController();

  bool _isLoading = true;
  bool _isSubmitting = false;
  String? _doctorId;
  String? _selectedPatientId;
  List<Map<String, dynamic>> _patients = [];
  List<Map<String, dynamic>> _reports = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _diagnosisController.dispose();
    _treatmentController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
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

      final results = await Future.wait([
        SupabaseService.fetchDoctorPatients(_doctorId!),
        SupabaseService.fetchDoctorMedicalRecords(_doctorId!),
      ]);

      if (mounted) {
        setState(() {
          _patients = results[0] as List<Map<String, dynamic>>;
          _reports = results[1] as List<Map<String, dynamic>>;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading reports data: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _submitReport() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedPatientId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please select a patient'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      await SupabaseService.addMedicalRecord({
        'patient_id': _selectedPatientId,
        'doctor_id': _doctorId,
        'diagnosis': _diagnosisController.text.trim(),
        'treatment': _treatmentController.text.trim(),
        'notes': _notesController.text.trim(),
        'date': DateTime.now().toIso8601String().split('T').first,
      });

      _diagnosisController.clear();
      _treatmentController.clear();
      _notesController.clear();
      setState(() => _selectedPatientId = null);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Report uploaded successfully'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
      _loadData();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to upload report: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showUploadForm() {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final isDarkMode = themeProvider.isDarkMode;
    final colorScheme = Theme.of(context).colorScheme;
    final languageProvider =
        Provider.of<LanguageProvider>(context, listen: false);
    final isRTL = languageProvider.isRTL;

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
                height: MediaQuery.of(context).size.height * 0.85,
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
                        'Upload Report',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: isDarkMode ? Colors.white : Colors.black,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Form(
                        key: _formKey,
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Column(
                            children: [
                              // Patient Dropdown
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
                                  child: DropdownButton<String>(
                                    value: _selectedPatientId,
                                    hint: Text(
                                      'Select Patient',
                                      style: TextStyle(
                                        color: isDarkMode
                                            ? Colors.white38
                                            : Colors.black38,
                                      ),
                                    ),
                                    isExpanded: true,
                                    icon: Icon(
                                      Icons.arrow_drop_down,
                                      color: AppTheme.cardoBlue,
                                    ),
                                    items: _patients.map((patient) {
                                      final id =
                                          patient['id']?.toString();
                                      final name = patient['full_name']
                                              as String? ??
                                          'Unknown';
                                      return DropdownMenuItem<String>(
                                        value: id,
                                        child: Text(
                                          name,
                                          style: TextStyle(
                                            color: isDarkMode
                                                ? Colors.white
                                                : Colors.black,
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                    onChanged: (value) {
                                      setModalState(() {
                                        _selectedPatientId = value;
                                      });
                                    },
                                  ),
                                ),
                              ),
                              SizedBox(height: 16),
                              TextFormField(
                                controller: _diagnosisController,
                                validator: (value) {
                                  if (value == null ||
                                      value.trim().isEmpty) {
                                    return 'Please enter a diagnosis';
                                  }
                                  return null;
                                },
                                decoration: InputDecoration(
                                  labelText: context
                                      .translate('diagnosis'),
                                  prefixIcon: Icon(Icons.medical_information,
                                      color: AppTheme.cardoBlue),
                                ),
                              ),
                              SizedBox(height: 16),
                              TextFormField(
                                controller: _treatmentController,
                                validator: (value) {
                                  if (value == null ||
                                      value.trim().isEmpty) {
                                    return 'Please enter a treatment';
                                  }
                                  return null;
                                },
                                decoration: InputDecoration(
                                  labelText: context
                                      .translate('treatment'),
                                  prefixIcon: Icon(Icons.healing,
                                      color: AppTheme.cardoBlue),
                                ),
                              ),
                              SizedBox(height: 16),
                              TextFormField(
                                controller: _notesController,
                                maxLines: 4,
                                decoration: InputDecoration(
                                  labelText:
                                      context.translate('notes') +
                                          ' (Optional)',
                                  alignLabelWithHint: true,
                                  prefixIcon: Padding(
                                    padding: const EdgeInsets.only(
                                        bottom: 48),
                                    child: Icon(Icons.note_alt_outlined,
                                        color: AppTheme.cardoBlue),
                                  ),
                                ),
                              ),
                              SizedBox(height: 24),
                              SizedBox(
                                width: double.infinity,
                                height: 50,
                                child: ElevatedButton(
                                  onPressed: _isSubmitting
                                      ? null
                                      : _submitReport,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.cardoBlue,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(12),
                                    ),
                                    elevation: 0,
                                  ),
                                  child: _isSubmitting
                                      ? SizedBox(
                                          width: 24,
                                          height: 24,
                                          child:
                                              CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : Text(
                                          'Submit Report',
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
            'Reports',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
          centerTitle: true,
          elevation: 0,
          backgroundColor: colorScheme.surface,
          actions: [
            IconButton(
              icon: Icon(Icons.upload_file_rounded,
                  color: AppTheme.cardoBlue),
              onPressed: _showUploadForm,
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: _showUploadForm,
          backgroundColor: AppTheme.cardoBlue,
          child: Icon(Icons.add, color: Colors.white),
        ),
        body: _isLoading
            ? Center(
                child: CircularProgressIndicator(color: AppTheme.cardoBlue))
            : RefreshIndicator(
                color: AppTheme.cardoBlue,
                onRefresh: _loadData,
                child: _reports.isEmpty
                    ? _buildEmptyState(isDarkMode)
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _reports.length,
                        itemBuilder: (context, index) {
                          return _buildReportCard(
                              _reports[index], isDarkMode, colorScheme);
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
                Icons.description_outlined,
                size: 64,
                color: Colors.grey.withOpacity(0.5),
              ),
              SizedBox(height: 16),
              Text(
                'No reports yet',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: isDarkMode ? Colors.white54 : Colors.black45,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Tap the + button to upload a new report.',
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

  Widget _buildReportCard(
      Map<String, dynamic> report, bool isDarkMode, ColorScheme colorScheme) {
    final profile = report['profiles'] as Map<String, dynamic>?;
    final patientName = profile?['full_name'] as String? ?? 'Unknown Patient';
    final diagnosis = report['diagnosis'] as String? ?? 'N/A';
    final treatment = report['treatment'] as String?;
    final date = report['date'] as String? ?? '';

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
                  radius: 20,
                  backgroundColor: AppTheme.cardoBlue.withOpacity(0.15),
                  child: Text(
                    patientName.isNotEmpty
                        ? patientName[0].toUpperCase()
                        : '?',
                    style: TextStyle(
                      fontSize: 16,
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
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: isDarkMode ? Colors.white : Colors.black,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(Icons.calendar_today,
                              size: 12, color: AppTheme.cardoBlue),
                          SizedBox(width: 4),
                          Text(
                            date,
                            style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.cardoBlue,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.cardoBlue.withOpacity(0.06),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.translate('diagnosis'),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.cardoBlue,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    diagnosis,
                    style: TextStyle(
                      fontSize: 14,
                      color: isDarkMode ? Colors.white70 : Colors.black87,
                    ),
                  ),
                  if (treatment != null && treatment.isNotEmpty) ...[
                    SizedBox(height: 6),
                    Text(
                      context.translate('treatment'),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.cardoBlue,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      treatment,
                      style: TextStyle(
                        fontSize: 13,
                        color:
                            isDarkMode ? Colors.white54 : Colors.black54,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
