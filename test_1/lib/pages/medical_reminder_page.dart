import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:test_1/utils/theme_provider.dart';
import 'package:test_1/utils/language_provider.dart';
import 'package:test_1/utils/app_localizations.dart';

class MedicalReminderPage extends StatefulWidget {
  const MedicalReminderPage({Key? key}) : super(key: key);

  @override
  State<MedicalReminderPage> createState() => _MedicalReminderPageState();
}

class _MedicalReminderPageState extends State<MedicalReminderPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

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
        final medicationsSnapshot = await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('medications')
            .get();

        List<Map<String, dynamic>> meds = [];
        for (var doc in medicationsSnapshot.docs) {
          meds.add({
            'id': doc.id,
            ...doc.data(),
            'taken': doc.data()['taken'] ?? false,
          });
        }

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
      debugPrint('Error loading medications: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _addSampleMedications() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final batch = _firestore.batch();
    final medsCollection =
        _firestore.collection('users').doc(user.uid).collection('medications');

    final samples = [
      {
        'name': 'Paracetamol',
        'dosage': '500mg',
        'quantity': '1 pill',
        'time': '08:00 AM',
        'instructions': 'Before meal',
        'frequency': 'Everyday',
        'taken': false,
      },
      {
        'name': 'Omega 3',
        'dosage': '1000mg',
        'quantity': '1 capsule',
        'time': '12:00 PM',
        'instructions': 'After Meal',
        'frequency': 'Everyday',
        'taken': false,
      },
      {
        'name': 'Vitamin D3',
        'dosage': '5000 IU',
        'quantity': '1 softgel',
        'time': '09:00 PM',
        'instructions': 'With dinner',
        'frequency': 'Everyday',
        'taken': false,
      },
    ];

    for (var med in samples) {
      final docRef = medsCollection.doc();
      batch.set(docRef, med);
    }
    await batch.commit();
  }

  Future<void> _toggleMedicationStatus(
      String medicationId, bool currentStatus) async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('medications')
            .doc(medicationId)
            .update({'taken': !currentStatus});

        setState(() {
          _medications = _medications.map((med) {
            if (med['id'] == medicationId) {
              return {...med, 'taken': !currentStatus};
            }
            return med;
          }).toList();
        });
      }
    } catch (e) {
      debugPrint('Error toggling medication status: $e');
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
        final docRef = await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('medications')
            .add(medication);

        setState(() {
          _medications.add({
            'id': docRef.id,
            ...medication,
          });
        });
      }
    } catch (e) {
      debugPrint('Error adding medication: $e');
    }
  }

  Future<void> _deleteMedication(String medicationId) async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('medications')
            .doc(medicationId)
            .delete();

        setState(() {
          _medications.removeWhere((med) => med['id'] == medicationId);
        });
      }
    } catch (e) {
      debugPrint('Error deleting medication: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    
    final biotechCyan = const Color(0xFF00E5FF);
    final biotechCyanDeep = const Color(0xFF00B8D4); // WCAG-compliant for Light Mode
    final dynamicCyan = isDarkMode ? biotechCyan : biotechCyanDeep;

    final biotechBlack = const Color(0xFF0F0F0F);
    final scaffoldBg = isDarkMode ? biotechBlack : const Color(0xFFF5F7FA);
    final textColor = isDarkMode ? Colors.white : const Color(0xFF0F0F0F);
    final cardBg = isDarkMode ? Colors.white.withOpacity(0.03) : Colors.white;
    final borderColor = isDarkMode ? Colors.white.withOpacity(0.1) : dynamicCyan.withOpacity(0.2);

    return Scaffold(
      backgroundColor: scaffoldBg,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(color: scaffoldBg.withOpacity(0.5)),
          ),
        ),
        title: Text(
          context.translate('medications').toUpperCase(),
          style: GoogleFonts.orbitron(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: dynamicCyan,
            letterSpacing: 2,
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: dynamicCyan))
          : Stack(
              children: [
                Positioned(
                  top: -100,
                  right: -100,
                  child: Container(
                    width: 300,
                    height: 300,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: dynamicCyan.withOpacity(isDarkMode ? 0.05 : 0.08),
                    ),
                  ),
                ),
                SafeArea(
                  child: Column(
                    children: [
                      _buildDateSelector(dynamicCyan, textColor, isDarkMode),
                      _buildStatusHeader(dynamicCyan, textColor),
                      _buildMedicationList(dynamicCyan, cardBg, borderColor, textColor, isDarkMode),
                    ],
                  ),
                ),
              ],
            ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 90.0),
        child: FloatingActionButton(
          backgroundColor: dynamicCyan,
          elevation: 10,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          child: const Icon(Icons.add_rounded, color: Colors.black, size: 30),
          onPressed: _showAddMedicationDialog,
        ),
      ),
    );
  }

  Widget _buildDateSelector(Color primary, Color textColor, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  DateFormat('MMMM yyyy').format(_selectedDate).toUpperCase(),
                  style: GoogleFonts.orbitron(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: textColor,
                    letterSpacing: 1,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: primary.withOpacity(0.2)),
                  ),
                  child: Icon(Icons.calendar_today_rounded, color: primary, size: 18),
                )
              ],
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 95,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 15),
              physics: const BouncingScrollPhysics(),
              itemCount: 14,
              itemBuilder: (context, index) {
                final date = DateTime.now().add(Duration(days: index - 3));
                final isSelected = DateUtils.isSameDay(date, _selectedDate);

                return GestureDetector(
                  onTap: () => _selectDate(date),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: 65,
                    margin: const EdgeInsets.symmetric(horizontal: 6),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? primary
                          : (isDark ? Colors.white.withOpacity(0.03) : Colors.white),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected ? primary : primary.withOpacity(0.1),
                        width: isSelected ? 2 : 1,
                      ),
                      boxShadow: isSelected
                          ? [BoxShadow(color: primary.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 4))]
                          : [],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          DateFormat('E').format(date).toUpperCase(),
                          style: GoogleFonts.orbitron(
                            fontSize: 10,
                            color: isSelected ? Colors.black : textColor.withOpacity(0.5),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          date.day.toString(),
                          style: GoogleFonts.orbitron(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: isSelected ? Colors.black : textColor,
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
    );
  }

  Widget _buildStatusHeader(Color primary, Color textColor) {
    int takenCount = _medications.where((m) => m['taken'] == true).length;
    double progress = _medications.isEmpty ? 0 : takenCount / _medications.length;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 4, height: 18,
                decoration: BoxDecoration(
                  color: primary,
                  borderRadius: BorderRadius.circular(2),
                  boxShadow: [BoxShadow(color: primary.withOpacity(0.5), blurRadius: 8)]
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'DAILY PROTOCOL',
                style: GoogleFonts.orbitron(
                  color: textColor,
                  fontSize: 14,
                  letterSpacing: 1.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Spacer(),
              Text(
                '$takenCount/${_medications.length} COMPLETE',
                style: GoogleFonts.orbitron(
                  color: primary,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: primary.withOpacity(0.1),
              color: primary,
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMedicationList(Color primary, Color bg, Color border, Color textColor, bool isDark) {
    if (_medications.isEmpty) {
      return Expanded(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.auto_fix_high_rounded, size: 60, color: primary.withOpacity(0.1)),
              const SizedBox(height: 16),
              Text(
                'NO ACTIVE PROTOCOLS',
                style: GoogleFonts.orbitron(color: textColor.withOpacity(0.2), fontWeight: FontWeight.bold, letterSpacing: 1),
              ),
            ],
          ),
        ),
      );
    }

    return Expanded(
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        physics: const BouncingScrollPhysics(),
        itemCount: _medications.length,
        itemBuilder: (context, index) {
          final med = _medications[index];
          final bool isTaken = med['taken'] ?? false;

          return Dismissible(
            key: Key(med['id']),
            direction: DismissDirection.endToStart,
            background: Container(
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 25),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.redAccent.withOpacity(0.15),
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(Icons.delete_sweep_rounded, color: Colors.redAccent, size: 28),
            ),
            onDismissed: (_) => _deleteMedication(med['id']),
            child: Container(
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: isTaken ? primary.withOpacity(0.5) : border,
                  width: isTaken ? 1.5 : 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.2 : 0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                ]
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Row(
                      children: [
                        _buildMedIcon(isTaken, primary, isDark),
                        const SizedBox(width: 18),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                med['name'].toUpperCase(),
                                style: GoogleFonts.orbitron(
                                  color: textColor,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.5,
                                  decoration: isTaken ? TextDecoration.lineThrough : null,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  Icon(Icons.access_time_filled_rounded, size: 14, color: primary),
                                  const SizedBox(width: 6),
                                  Text(
                                    med['time'],
                                    style: GoogleFonts.orbitron(
                                      color: primary,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    med['dosage'],
                                    style: GoogleFonts.poppins(
                                      color: textColor.withOpacity(0.5),
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                med['instructions'],
                                style: GoogleFonts.poppins(
                                  color: textColor.withOpacity(0.4),
                                  fontSize: 11,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ],
                          ),
                        ),
                        _buildCheckButton(med['id'], isTaken, primary),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMedIcon(bool isTaken, Color primary, bool isDark) {
    return Container(
      width: 54, height: 54,
      decoration: BoxDecoration(
        color: isTaken ? primary : primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        boxShadow: isTaken
            ? [BoxShadow(color: primary.withOpacity(0.4), blurRadius: 12)]
            : [],
      ),
      child: Icon(
        Icons.medication_rounded,
        color: isTaken ? Colors.black : primary,
        size: 28,
      ),
    );
  }

  Widget _buildCheckButton(String id, bool isTaken, Color primary) {
    return GestureDetector(
      onTap: () => _toggleMedicationStatus(id, isTaken),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: isTaken ? primary : Colors.grey.withOpacity(0.3),
            width: 2,
          ),
          color: isTaken ? primary.withOpacity(0.1) : Colors.transparent,
        ),
        child: Icon(
          isTaken ? Icons.done_all_rounded : Icons.radio_button_off_rounded,
          color: isTaken ? primary : Colors.grey.withOpacity(0.3),
          size: 22,
        ),
      ),
    );
  }
}

class AddMedicationDialog extends StatefulWidget {
  final Function(Map<String, dynamic>) onAdd;
  const AddMedicationDialog({Key? key, required this.onAdd}) : super(key: key);

  @override
  State<AddMedicationDialog> createState() => _AddMedicationDialogState();
}

class _AddMedicationDialogState extends State<AddMedicationDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _dosageController = TextEditingController();
  final _instructionsController = TextEditingController();
  String _time = '08:00 AM';

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;
    final biotechCyan = const Color(0xFF00E5FF);
    final biotechCyanDeep = const Color(0xFF00B8D4);
    final primary = isDark ? biotechCyan : biotechCyanDeep;
    final bgDark = const Color(0xFF0F0F0F);

    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
      child: AlertDialog(
        backgroundColor: Colors.transparent,
        contentPadding: EdgeInsets.zero,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
        ),
        content: Container(
          decoration: BoxDecoration(
            color: isDark ? bgDark.withOpacity(0.8) : Colors.white.withOpacity(0.8),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: primary.withOpacity(0.3)),
            boxShadow: [
              BoxShadow(
                color: primary.withOpacity(0.1),
                blurRadius: 20,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: SingleChildScrollView(
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'NEW PROTOCOL',
                      style: GoogleFonts.orbitron(
                        color: primary,
                        fontWeight: FontWeight.w900,
                        fontSize: 18,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 24),
                    _buildField(_nameController, 'SUBSTANCE NAME', primary, isDark),
                    const SizedBox(height: 18),
                    _buildField(_dosageController, 'DOSAGE (e.g. 500mg)', primary, isDark),
                    const SizedBox(height: 18),
                    _buildField(_instructionsController, 'INSTRUCTIONS', primary, isDark),
                    const SizedBox(height: 24),
                    Text(
                      'ADMINISTRATION TIME',
                      style: GoogleFonts.orbitron(
                        color: (isDark ? Colors.white : Colors.black).withOpacity(0.4),
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: () async {
                        final picked = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay.now(),
                        );
                        if (picked != null) {
                          setState(() => _time = picked.format(context));
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: (isDark ? Colors.white : Colors.black).withOpacity(0.05),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: (isDark ? Colors.white : Colors.black).withOpacity(0.1),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _time,
                              style: GoogleFonts.orbitron(
                                color: primary,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            Icon(Icons.access_time_rounded, color: primary, size: 20),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text(
                            'ABORT',
                            style: GoogleFonts.orbitron(
                              color: Colors.redAccent,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primary,
                            foregroundColor: Colors.black,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          ),
                          onPressed: () {
                            if (_formKey.currentState!.validate()) {
                              widget.onAdd({
                                'name': _nameController.text,
                                'dosage': _dosageController.text,
                                'instructions': _instructionsController.text,
                                'time': _time,
                                'taken': false,
                                'quantity': '1 unit',
                                'frequency': 'Everyday',
                              });
                              Navigator.pop(context);
                            }
                          },
                          child: Text(
                            'INITIATE',
                            style: GoogleFonts.orbitron(
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildField(TextEditingController controller, String label, Color primary, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.orbitron(
            color: (isDark ? Colors.white : Colors.black).withOpacity(0.4),
            fontSize: 10,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: (isDark ? Colors.white : Colors.black).withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: (isDark ? Colors.white : Colors.black).withOpacity(0.1),
            ),
          ),
          child: TextFormField(
            controller: controller,
            style: GoogleFonts.poppins(
              color: isDark ? Colors.white : Colors.black,
              fontSize: 14,
            ),
            decoration: const InputDecoration(
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            validator: (v) => v!.isEmpty ? 'REQUIRED' : null,
          ),
        ),
      ],
    );
  }
}
