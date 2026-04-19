import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:test_1/database/DB.dart';
import 'package:provider/provider.dart';
import 'package:test_1/utils/theme_provider.dart';
import 'package:test_1/utils/language_provider.dart';
import 'package:test_1/utils/app_localizations.dart';

class SpecialityPage extends StatefulWidget {
  final String specialtyName;
  const SpecialityPage({super.key, required this.specialtyName});

  @override
  State<SpecialityPage> createState() => _SpecialityPageState();
}

class _SpecialityPageState extends State<SpecialityPage> {
  Specializations_DB db = Specializations_DB();

  // Bio-Tech Colors
  static const Color biotechBlack = Color(0xFF0F0F0F);
  static const Color biotechCyan = Color(0xFF00E5FF);
  static const Color biotechCyanDeep = Color(0xFF00B8D4); // WCAG-compliant for Light Mode

  List<Map<String, dynamic>> get filteredDoctors {
    final String specialtyNameOrKey = widget.specialtyName;
    var doctors = db.doctors
        .where((doctor) =>
            context.translate(doctor["specialty_key"] ?? "") ==
            specialtyNameOrKey)
        .toList();

    if (doctors.isEmpty) {
      doctors = db.doctors
          .where((doctor) => doctor["specialty"] == specialtyNameOrKey)
          .toList();
    }
    return doctors;
  }

  void _showMedicalRecords(BuildContext context, Map<String, dynamic> doctor) {
    final isRTL = Provider.of<LanguageProvider>(context, listen: false).isRTL;
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final isDarkMode = themeProvider.isDarkMode;
    final dynamicCyan = isDarkMode ? biotechCyan : biotechCyanDeep;

    final sheetBgColor = isDarkMode ? biotechBlack.withOpacity(0.8) : Colors.white.withOpacity(0.9);
    final headerTextColor = isDarkMode ? Colors.white : biotechBlack;
    final subTextColor = isDarkMode ? Colors.white70 : Colors.black87;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            height: MediaQuery.of(context).size.height * 0.9,
            decoration: BoxDecoration(
              color: sheetBgColor,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
              border: Border.all(color: dynamicCyan.withOpacity(0.3)),
            ),
            child: Column(
              children: [
                const SizedBox(height: 15),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: dynamicCyan.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: dynamicCyan.withOpacity(0.1),
                          shape: BoxShape.circle,
                          border: Border.all(color: dynamicCyan.withOpacity(0.3)),
                        ),
                        child: Icon(Icons.folder_shared, color: dynamicCyan),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              context.translate('medical_records').toUpperCase(),
                              style: GoogleFonts.orbitron(
                                color: dynamicCyan,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.5,
                              ),
                            ),
                            Text(
                              isRTL && doctor["name_ar"] != null ? doctor["name_ar"] : doctor["name"],
                              style: GoogleFonts.poppins(color: subTextColor, fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.close, color: isDarkMode ? Colors.white54 : Colors.black54),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: doctor["medicalRecords"].length,
                    itemBuilder: (context, index) {
                      final record = doctor["medicalRecords"][index];
                      return _buildRecordEntry(record, isRTL, isDarkMode, headerTextColor, subTextColor, dynamicCyan);
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

  Widget _buildRecordEntry(Map<String, dynamic> record, bool isRTL, bool isDarkMode, Color headerTextColor, Color subTextColor, Color dynamicCyan) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.white.withOpacity(0.03) : Colors.black.withOpacity(0.03),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: dynamicCyan.withOpacity(0.1)),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          iconColor: dynamicCyan,
          collapsedIconColor: isDarkMode ? Colors.white54 : Colors.black54,
          title: Text(
            (isRTL && record["patientName_ar"] != null ? record["patientName_ar"] : record["patientName"]).toUpperCase(),
            style: GoogleFonts.orbitron(color: headerTextColor, fontSize: 14, fontWeight: FontWeight.bold),
          ),
          subtitle: Text(
            record["date"].toString().split(' ')[0],
            style: GoogleFonts.poppins(color: dynamicCyan, fontSize: 12),
          ),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Column(
                children: [
                  _buildProtocolDetail("DIAGNOSIS", 
                    record["diagnosis_key"] != null ? context.translate(record["diagnosis_key"]) : record["diagnosis"], isDarkMode, subTextColor, dynamicCyan),
                  const SizedBox(height: 12),
                  _buildProtocolDetail("TREATMENT", 
                    record["treatment_key"] != null ? context.translate(record["treatment_key"]) : record["treatment"], isDarkMode, subTextColor, dynamicCyan),
                  const SizedBox(height: 12),
                  _buildProtocolDetail("OBSERVATIONS", 
                    isRTL && record["notes_ar"] != null ? record["notes_ar"] : record["notes"], isDarkMode, subTextColor, dynamicCyan),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProtocolDetail(String label, String value, bool isDarkMode, Color subTextColor, Color dynamicCyan) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode ? biotechBlack.withOpacity(0.4) : Colors.white.withOpacity(0.8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: dynamicCyan.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: GoogleFonts.orbitron(color: dynamicCyan, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
          const SizedBox(height: 8),
          Text(value, style: GoogleFonts.poppins(color: subTextColor, fontSize: 13)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isRTL = Provider.of<LanguageProvider>(context).isRTL;
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    final dynamicCyan = isDarkMode ? biotechCyan : biotechCyanDeep;

    final backgroundColor = isDarkMode ? biotechBlack : const Color(0xFFF5F7FA);
    final headerTextColor = isDarkMode ? Colors.white : biotechBlack;
    final appBarColor = isDarkMode ? biotechBlack.withOpacity(0.5) : Colors.white.withOpacity(0.5);

    return Directionality(
      textDirection: isRTL ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: backgroundColor,
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          flexibleSpace: ClipRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(color: appBarColor),
            ),
          ),
          title: Text(
            widget.specialtyName.toUpperCase(),
            style: GoogleFonts.orbitron(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: dynamicCyan,
              letterSpacing: 2,
            ),
          ),
          leading: IconButton(
            icon: Icon(isRTL ? Icons.arrow_forward : Icons.arrow_back, color: dynamicCyan),
            onPressed: () => Navigator.pop(context),
          ),
          centerTitle: true,
        ),
        body: Stack(
          children: [
             Positioned(
              top: -100,
              right: -100,
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: dynamicCyan.withOpacity(isDarkMode ? 0.05 : 0.1),
                ),
              ),
            ),
            SafeArea(
              child: filteredDoctors.isEmpty
                  ? _buildEmptyState(headerTextColor, dynamicCyan)
                  : ListView.builder(
                      padding: const EdgeInsets.all(20),
                      itemCount: filteredDoctors.length,
                      itemBuilder: (context, index) => _buildDoctorBioCard(filteredDoctors[index], isRTL, isDarkMode, headerTextColor, dynamicCyan),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(Color headerTextColor, Color dynamicCyan) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 80, color: dynamicCyan.withOpacity(0.2)),
          const SizedBox(height: 20),
          Text(
            "NO PERSONNEL FOUND",
            style: GoogleFonts.orbitron(color: headerTextColor.withOpacity(0.2), letterSpacing: 2),
          ),
        ],
      ),
    );
  }

  Widget _buildDoctorBioCard(Map<String, dynamic> doctor, bool isRTL, bool isDarkMode, Color headerTextColor, Color dynamicCyan) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.white.withOpacity(0.02) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: dynamicCyan.withOpacity(isDarkMode ? 0.2 : 0.4)),
        boxShadow: isDarkMode ? [] : [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: InkWell(
            onTap: () => _showMedicalRecords(context, doctor),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: dynamicCyan.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(color: dynamicCyan.withOpacity(0.3)),
                        ),
                        child: Icon(Icons.medical_services, color: dynamicCyan),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              (isRTL && doctor["name_ar"] != null ? doctor["name_ar"] : doctor["name"]).toUpperCase(),
                              style: GoogleFonts.orbitron(
                                color: headerTextColor,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1,
                              ),
                            ),
                            Text(
                              isRTL && doctor["organization_ar"] != null ? doctor["organization_ar"] : doctor["organization"],
                              style: GoogleFonts.poppins(color: dynamicCyan, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.chevron_right, color: dynamicCyan),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildStat("RECORDS", doctor["medicalRecords"].length.toString(), isDarkMode, headerTextColor, dynamicCyan),
                      _buildStat("CLEARANCE", "LEVEL 4", isDarkMode, headerTextColor, dynamicCyan),
                      _buildStat("STATUS", "ACTIVE", isDarkMode, headerTextColor, dynamicCyan),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStat(String label, String value, bool isDarkMode, Color headerTextColor, Color dynamicCyan) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.orbitron(color: isDarkMode ? Colors.white38 : Colors.black38, fontSize: 8, letterSpacing: 1)),
        const SizedBox(height: 4),
        Text(value, style: GoogleFonts.orbitron(color: dynamicCyan, fontSize: 12, fontWeight: FontWeight.bold)),
      ],
    );
  }
}
