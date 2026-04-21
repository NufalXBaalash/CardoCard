import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:test_1/database/supabase_config.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:test_1/utils/theme_provider.dart';
import 'package:test_1/utils/language_provider.dart';
import 'package:test_1/utils/app_localizations.dart';
import 'package:test_1/utils/app_theme.dart';

class MedicalReminderPage extends StatefulWidget {
  const MedicalReminderPage({Key? key}) : super(key: key);

  @override
  State<MedicalReminderPage> createState() => _MedicalReminderPageState();
}

class _MedicalReminderPageState extends State<MedicalReminderPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool _isLoading = true;
  DateTime _selectedDate = DateTime.now();
  List<Map<String, dynamic>> _medications = [];

  @override
  void initState() {
    super.initState();
    _loadMedications();
  }

  Future<void> _loadMedications() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        final meds = await SupabaseService.fetchMedications(user.uid);

        if (meds.isEmpty) {
          await _addSampleMedications();
          return _loadMedications();
        }

        setState(() {
          _medications = meds;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading medications: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _addSampleMedications() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final samples = [
      {
        'name': 'Paracetamol',
        'dosage': '500mg',
        'quantity': '1 pill',
        'time': '8:00 am',
        'instructions': 'Before meal',
        'frequency': 'Everyday',
        'taken': false,
      },
      {
        'name': 'Omega 3',
        'dosage': '500mg',
        'quantity': '1 pill',
        'time': '12:00 pm',
        'instructions': 'After Meal',
        'frequency': 'Every Tue, Sat',
        'taken': false,
      },
      {
        'name': 'Doxycycline',
        'dosage': '100mg',
        'quantity': '1 pill',
        'time': '3:00 pm',
        'instructions': 'After meal',
        'frequency': 'Every Tue, Sat',
        'taken': false,
      },
    ];

    for (var med in samples) {
      await SupabaseService.addMedication(user.uid, med);
    }
  }

  Future<void> _toggleMedicationStatus(
      String medicationId, bool currentStatus) async {
    try {
      await SupabaseService.updateMedication(medicationId, {'taken': !currentStatus});

      setState(() {
        _medications = _medications.map((med) {
          if (med['id'] == medicationId) {
            return {...med, 'taken': !currentStatus};
          }
          return med;
        }).toList();
      });
    } catch (e) {
      print('Error toggling medication status: $e');
    }
  }

  void _selectDate(DateTime date) {
    setState(() {
      _selectedDate = date;
    });
  }

  void _showAddMedicationDialog() {
    showDialog(
      context: context,
      builder: (context) => AddMedicationDialog(
        onAdd: (medication) {
          _addMedication(medication);
        },
      ),
    );
  }

  Future<void> _addMedication(Map<String, dynamic> medication) async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        final result = await SupabaseService.addMedication(user.uid, medication);

        setState(() {
          _medications.add(result);
        });
      }
    } catch (e) {
      print('Error adding medication: $e');
    }
  }

  // Add this new method to delete medication
  Future<bool> _deleteMedication(String medicationId) async {
    try {
      // Show confirmation dialog
      bool confirmDelete = await showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Text(
                context.translate('delete_medication'),
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                ),
              ),
              content: Text(
                context.translate('delete_medication_confirmation'),
                style: GoogleFonts.poppins(),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: Text(
                    context.translate('cancel'),
                    style: GoogleFonts.poppins(
                      color: Colors.grey[600],
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: Text(
                    context.translate('delete'),
                    style: GoogleFonts.poppins(
                      color: Colors.red,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ) ??
          false;

      if (!confirmDelete) return false;

      // Delete from Supabase
      await SupabaseService.deleteMedication(medicationId);

      // Update local state
      setState(() {
        _medications.removeWhere((med) => med['id'] == medicationId);
      });

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              context.translate('medication_deleted'),
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
      return true;
    } catch (e) {
      print('Error deleting medication: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              context.translate('error_deleting_medication'),
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
      }
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    final languageProvider = Provider.of<LanguageProvider>(context);
    final isRTL = languageProvider.isRTL;

    // Get screen size information
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 360;
    final isMediumScreen = screenSize.width >= 360 && screenSize.width < 400;
    final isLargeScreen = screenSize.width >= 400;

    // Adjust sizes based on screen width
    final dateTileWidth = isSmallScreen ? 45.0 : (isMediumScreen ? 50.0 : 55.0);
    final dateFontSize = isSmallScreen ? 12.0 : (isMediumScreen ? 14.0 : 16.0);
    final dayFontSize = isSmallScreen ? 16.0 : (isMediumScreen ? 17.0 : 18.0);
    final titleFontSize = isSmallScreen ? 16.0 : (isMediumScreen ? 18.0 : 20.0);
    final medicationNameSize =
        isSmallScreen ? 16.0 : (isMediumScreen ? 17.0 : 18.0);
    final medicationInfoSize =
        isSmallScreen ? 12.0 : (isMediumScreen ? 13.0 : 14.0);
    final cardHeight = isSmallScreen ? 110.0 : (isMediumScreen ? 115.0 : 120.0);
    final actionButtonWidth =
        isSmallScreen ? 70.0 : (isMediumScreen ? 75.0 : 80.0);
    final horizontalPadding =
        isSmallScreen ? 12.0 : (isMediumScreen ? 14.0 : 16.0);

    return Scaffold(
      backgroundColor: isDarkMode ? Colors.black : Colors.grey[50],
      appBar: AppBar(
        backgroundColor: isDarkMode ? Colors.black : Colors.white,
        elevation: 0,
        title: Text(
          context.translate('medications'),
          style: GoogleFonts.poppins(
            fontSize: titleFontSize,
            fontWeight: FontWeight.w600,
            color: CardoTheme.cardoBlue,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(
              Icons.notifications_none_rounded,
              color: CardoTheme.cardoBlue,
            ),
            onPressed: () {
              // Handle notifications
            },
          ),
        ],
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(color: CardoTheme.cardoBlue))
          : SafeArea(
              child: Column(
                children: [
                  // Month and date selector
                  Container(
                    padding: EdgeInsets.fromLTRB(horizontalPadding,
                        horizontalPadding, horizontalPadding, 8),
                    decoration: BoxDecoration(
                      color: isDarkMode ? Colors.black : Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          DateFormat('MMMM yyyy').format(_selectedDate),
                          style: GoogleFonts.poppins(
                            fontSize: isSmallScreen ? 16.0 : 18.0,
                            fontWeight: FontWeight.w600,
                            color: CardoTheme.cardoBlue,
                          ),
                        ),
                        SizedBox(height: isSmallScreen ? 8.0 : 12.0),
                        SizedBox(
                          height: isSmallScreen ? 70.0 : 80.0,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: 14, // Show two weeks
                            controller: ScrollController(
                              initialScrollOffset: dateTileWidth * 7 +
                                  (isSmallScreen ? 6.0 : 10.0) * 7,
                            ),
                            itemBuilder: (context, index) {
                              final date =
                                  DateTime.now().add(Duration(days: index - 7));
                              final isSelected =
                                  DateUtils.isSameDay(date, _selectedDate);

                              return GestureDetector(
                                onTap: () => _selectDate(date),
                                child: Container(
                                  width: dateTileWidth,
                                  margin: EdgeInsets.only(
                                      right: isSmallScreen ? 6.0 : 10.0),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? CardoTheme.cardoBlue
                                        : isDarkMode
                                            ? Colors.grey[900]
                                            : Colors.grey[100],
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: isSelected
                                        ? [
                                            BoxShadow(
                                              color: CardoTheme.cardoBlue
                                                  .withOpacity(0.3),
                                              blurRadius: 8,
                                              offset: const Offset(0, 3),
                                            ),
                                          ]
                                        : null,
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        DateFormat('E')
                                            .format(date)
                                            .substring(0, 3),
                                        style: GoogleFonts.poppins(
                                          fontSize: dateFontSize,
                                          fontWeight: FontWeight.w500,
                                          color: isSelected
                                              ? Colors.white
                                              : isDarkMode
                                                  ? Colors.white70
                                                  : Colors.black54,
                                        ),
                                      ),
                                      SizedBox(
                                          height: isSmallScreen ? 4.0 : 6.0),
                                      Text(
                                        date.day.toString(),
                                        style: GoogleFonts.poppins(
                                          fontSize: dayFontSize,
                                          fontWeight: FontWeight.w600,
                                          color: isSelected
                                              ? Colors.white
                                              : isDarkMode
                                                  ? Colors.white
                                                  : Colors.black87,
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

                  // Medications count
                  Padding(
                    padding: EdgeInsets.fromLTRB(horizontalPadding,
                        horizontalPadding, horizontalPadding, 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            context.translate('medications_for_today') +
                                ' (' +
                                _medications.length.toString() +
                                ')',
                            style: GoogleFonts.poppins(
                              fontSize: isSmallScreen ? 12.0 : 14.0,
                              fontWeight: FontWeight.w600,
                              color: isDarkMode ? Colors.white : Colors.black87,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: isSmallScreen ? 8.0 : 12.0,
                              vertical: isSmallScreen ? 4.0 : 6.0),
                          decoration: BoxDecoration(
                            color: CardoTheme.cardoBlue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            DateFormat(isSmallScreen ? 'd MMM' : 'EEEE, d MMM')
                                .format(_selectedDate),
                            style: GoogleFonts.poppins(
                              fontSize: isSmallScreen ? 12.0 : 14.0,
                              fontWeight: FontWeight.w500,
                              color: CardoTheme.cardoBlue,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Medications list
                  Expanded(
                    child: _medications.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.medication_outlined,
                                  size: isSmallScreen ? 48.0 : 64.0,
                                  color: isDarkMode
                                      ? Colors.white30
                                      : Colors.black26,
                                ),
                                SizedBox(height: isSmallScreen ? 12.0 : 16.0),
                                Text(
                                  context.translate('no_medications'),
                                  style: GoogleFonts.poppins(
                                    fontSize: isSmallScreen ? 16.0 : 18.0,
                                    fontWeight: FontWeight.w500,
                                    color: isDarkMode
                                        ? Colors.white70
                                        : Colors.black54,
                                  ),
                                ),
                                SizedBox(height: isSmallScreen ? 6.0 : 8.0),
                                TextButton.icon(
                                  onPressed: _showAddMedicationDialog,
                                  icon: Icon(Icons.add,
                                      color: CardoTheme.cardoBlue),
                                  label: Text(
                                    context.translate('add_medication'),
                                    style: GoogleFonts.poppins(
                                      color: CardoTheme.cardoBlue,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )
                        : Expanded(
                            child: ListView.builder(
                              shrinkWrap: true,
                              padding: EdgeInsets.all(horizontalPadding),
                              itemCount: _medications.length,
                              itemBuilder: (context, index) {
                                final medication = _medications[index];
                                final isTaken = medication['taken'] ?? false;

                                return Dismissible(
                                  key: Key(medication['id']),
                                  direction: DismissDirection.endToStart,
                                  background: Container(
                                    alignment: Alignment.centerRight,
                                    padding: const EdgeInsets.only(right: 20.0),
                                    decoration: BoxDecoration(
                                      color: Colors.red.shade400,
                                      borderRadius: BorderRadius.circular(16),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.red.withOpacity(0.2),
                                          blurRadius: 8,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        Text(
                                          context.translate('delete'),
                                          style: GoogleFonts.poppins(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w500,
                                            fontSize: medicationInfoSize,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        const Icon(
                                          Icons.delete_outline,
                                          color: Colors.white,
                                          size: 22,
                                        ),
                                        const SizedBox(width: 8),
                                      ],
                                    ),
                                  ),
                                  confirmDismiss: (direction) async {
                                    return await _deleteMedication(
                                        medication['id'].toString());
                                  },
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 300),
                                    margin: const EdgeInsets.only(bottom: 16),
                                    decoration: BoxDecoration(
                                      color: isDarkMode
                                          ? Colors.grey[900]
                                          : Colors.white,
                                      borderRadius: BorderRadius.circular(16),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.05),
                                          blurRadius: 10,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: isSmallScreen ? 8.0 : 12.0,
                                          height: cardHeight,
                                          decoration: BoxDecoration(
                                            color: isTaken
                                                ? Colors.green
                                                : CardoTheme.cardoBlue,
                                            borderRadius:
                                                const BorderRadius.only(
                                              topLeft: Radius.circular(16),
                                              bottomLeft: Radius.circular(16),
                                            ),
                                          ),
                                        ),
                                        Expanded(
                                          child: Padding(
                                            padding: EdgeInsets.all(
                                                isSmallScreen ? 12.0 : 16.0),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  children: [
                                                    Expanded(
                                                      child: Text(
                                                        medication['name'],
                                                        style:
                                                            GoogleFonts.poppins(
                                                          fontSize:
                                                              medicationNameSize,
                                                          fontWeight:
                                                              FontWeight.w600,
                                                          color: isDarkMode
                                                              ? Colors.white
                                                              : Colors.black87,
                                                        ),
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                      ),
                                                    ),
                                                    const SizedBox(width: 4),
                                                    Text(
                                                      '- ${medication['dosage']}',
                                                      style:
                                                          GoogleFonts.poppins(
                                                        fontSize:
                                                            medicationInfoSize,
                                                        color: isDarkMode
                                                            ? Colors.white70
                                                            : Colors.black54,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                SizedBox(
                                                    height: isSmallScreen
                                                        ? 6.0
                                                        : 8.0),
                                                Row(
                                                  children: [
                                                    Icon(
                                                      Icons.medication_outlined,
                                                      size: isSmallScreen
                                                          ? 16.0
                                                          : 18.0,
                                                      color: isDarkMode
                                                          ? Colors.white60
                                                          : Colors.black45,
                                                    ),
                                                    const SizedBox(width: 6),
                                                    Expanded(
                                                      child: Text(
                                                        medication['quantity'],
                                                        style:
                                                            GoogleFonts.poppins(
                                                          fontSize:
                                                              medicationInfoSize,
                                                          color: isDarkMode
                                                              ? Colors.white70
                                                              : Colors.black54,
                                                        ),
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                SizedBox(
                                                    height: isSmallScreen
                                                        ? 4.0
                                                        : 6.0),
                                                Row(
                                                  children: [
                                                    Icon(
                                                      Icons.info_outline,
                                                      size: isSmallScreen
                                                          ? 16.0
                                                          : 18.0,
                                                      color: isDarkMode
                                                          ? Colors.white60
                                                          : Colors.black45,
                                                    ),
                                                    const SizedBox(width: 6),
                                                    Expanded(
                                                      child: Text(
                                                        medication[
                                                            'instructions'],
                                                        style:
                                                            GoogleFonts.poppins(
                                                          fontSize:
                                                              medicationInfoSize,
                                                          color: isDarkMode
                                                              ? Colors.white70
                                                              : Colors.black54,
                                                        ),
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                SizedBox(
                                                    height: isSmallScreen
                                                        ? 6.0
                                                        : 8.0),
                                                Row(
                                                  children: [
                                                    Icon(
                                                      Icons.access_time,
                                                      size: isSmallScreen
                                                          ? 16.0
                                                          : 18.0,
                                                      color:
                                                          CardoTheme.cardoBlue,
                                                    ),
                                                    const SizedBox(width: 6),
                                                    Expanded(
                                                      child: Text(
                                                        '${medication['frequency']} at ${medication['time']}',
                                                        style:
                                                            GoogleFonts.poppins(
                                                          fontSize:
                                                              medicationInfoSize,
                                                          fontWeight:
                                                              FontWeight.w500,
                                                          color: CardoTheme
                                                              .cardoBlue,
                                                        ),
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                        Container(
                                          width: actionButtonWidth,
                                          height: cardHeight,
                                          decoration: BoxDecoration(
                                            color: isTaken
                                                ? Colors.green
                                                : CardoTheme.cardoBlue,
                                            borderRadius:
                                                const BorderRadius.only(
                                              topRight: Radius.circular(16),
                                              bottomRight: Radius.circular(16),
                                            ),
                                          ),
                                          child: InkWell(
                                            onTap: () =>
                                                _toggleMedicationStatus(
                                              medication['id'],
                                              isTaken,
                                            ),
                                            child: Column(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                Icon(
                                                  isTaken
                                                      ? Icons.check
                                                      : Icons.access_time,
                                                  color: Colors.white,
                                                  size: isSmallScreen
                                                      ? 24.0
                                                      : 28.0,
                                                ),
                                                SizedBox(
                                                    height: isSmallScreen
                                                        ? 6.0
                                                        : 8.0),
                                                Text(
                                                  isTaken
                                                      ? context
                                                          .translate('taken')
                                                      : context
                                                          .translate('take'),
                                                  style: GoogleFonts.poppins(
                                                    fontSize: isSmallScreen
                                                        ? 12.0
                                                        : 14.0,
                                                    fontWeight: FontWeight.w500,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                  ),
                  SizedBox(
                    height: 40,
                  )
                ],
              ),
            ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 80.0, right: 0.0),
        child: FloatingActionButton(
          backgroundColor: CardoTheme.cardoBlue,
          child: const Icon(Icons.add, color: Colors.white),
          onPressed: _showAddMedicationDialog,
        ),
      ),
    );
  }
}

class AddMedicationDialog extends StatefulWidget {
  final Function(Map<String, dynamic>) onAdd;

  const AddMedicationDialog({
    Key? key,
    required this.onAdd,
  }) : super(key: key);

  @override
  State<AddMedicationDialog> createState() => _AddMedicationDialogState();
}

class _AddMedicationDialogState extends State<AddMedicationDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _dosageController = TextEditingController();
  final _quantityController = TextEditingController();
  final _instructionsController = TextEditingController();
  String _frequency = 'Everyday';
  TimeOfDay _selectedTime = TimeOfDay.now();

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;

    return AlertDialog(
      title: Text(
        context.translate('add_medication'),
        style: GoogleFonts.poppins(
          fontWeight: FontWeight.w600,
          color: isDarkMode ? Colors.white : Colors.black87,
        ),
      ),
      backgroundColor: isDarkMode ? Colors.grey[900] : Colors.white,
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: context.translate('medication_name'),
                  labelStyle: TextStyle(
                    color: isDarkMode ? Colors.white70 : Colors.black54,
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return context.translate('please_enter_name');
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _dosageController,
                decoration: InputDecoration(
                  labelText: context.translate('dosage'),
                  labelStyle: TextStyle(
                    color: isDarkMode ? Colors.white70 : Colors.black54,
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return context.translate('please_enter_dosage');
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _quantityController,
                decoration: InputDecoration(
                  labelText: context.translate('quantity'),
                  labelStyle: TextStyle(
                    color: isDarkMode ? Colors.white70 : Colors.black54,
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return context.translate('please_enter_quantity');
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _instructionsController,
                decoration: InputDecoration(
                  labelText: context.translate('instructions'),
                  labelStyle: TextStyle(
                    color: isDarkMode ? Colors.white70 : Colors.black54,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _frequency,
                decoration: InputDecoration(
                  labelText: context.translate('frequency'),
                  labelStyle: TextStyle(
                    color: isDarkMode ? Colors.white70 : Colors.black54,
                  ),
                ),
                items: [
                  'Everyday',
                  'Every Mon, Wed, Fri',
                  'Every Tue, Thu',
                  'Every Tue, Sat',
                  'Weekly',
                ].map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    setState(() {
                      _frequency = newValue;
                    });
                  }
                },
              ),
              const SizedBox(height: 16),
              ListTile(
                title: Text(
                  context.translate('time') +
                      ': ${_selectedTime.format(context)}',
                  style: TextStyle(
                    color: isDarkMode ? Colors.white : Colors.black87,
                  ),
                ),
                trailing: Icon(
                  Icons.access_time,
                  color: CardoTheme.cardoBlue,
                ),
                onTap: () async {
                  final TimeOfDay? time = await showTimePicker(
                    context: context,
                    initialTime: _selectedTime,
                  );
                  if (time != null) {
                    setState(() {
                      _selectedTime = time;
                    });
                  }
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          child: Text(
            context.translate('cancel'),
            style: TextStyle(color: Colors.grey),
          ),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: CardoTheme.cardoBlue,
          ),
          child: Text(
            context.translate('add'),
            style: TextStyle(color: Colors.white),
          ),
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              widget.onAdd({
                'name': _nameController.text,
                'dosage': _dosageController.text,
                'quantity': _quantityController.text,
                'instructions': _instructionsController.text,
                'frequency': _frequency,
                'time': _selectedTime.format(context),
                'taken': false,
              });
              Navigator.of(context).pop();
            }
          },
        ),
      ],
    );
  }
}
