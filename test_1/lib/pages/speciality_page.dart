import 'package:flutter/material.dart';
import 'package:test_1/database/DB.dart';
import 'package:provider/provider.dart';
import 'package:test_1/utils/theme_provider.dart';
import 'package:test_1/utils/language_provider.dart';
import 'package:test_1/utils/app_localizations.dart';

import '../database/DB.dart';

class SpecialityPage extends StatefulWidget {
  final String specialtyName;
  const SpecialityPage({super.key, required this.specialtyName});

  @override
  State<SpecialityPage> createState() => _SpecialityPageState();
}

class _SpecialityPageState extends State<SpecialityPage> {
  Specializations_DB db = Specializations_DB();

  List<Map<String, dynamic>> get filteredDoctors {
    // Get the specialty name/key from the widget
    final String specialtyNameOrKey = widget.specialtyName;

    // First try to find doctors by specialty_key
    var doctors = db.doctors
        .where((doctor) =>
            context.translate(doctor["specialty_key"] ?? "") ==
            specialtyNameOrKey)
        .toList();

    // If no doctors found, try with the direct specialty name
    if (doctors.isEmpty) {
      doctors = db.doctors
          .where((doctor) => doctor["specialty"] == specialtyNameOrKey)
          .toList();
    }

    return doctors;
  }

  void _showMedicalRecords(BuildContext context, Map<String, dynamic> doctor) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final isDarkMode = themeProvider.isDarkMode;
    final colorScheme = Theme.of(context).colorScheme;

    // Get RTL information
    final languageProvider =
        Provider.of<LanguageProvider>(context, listen: false);
    final isRTL = languageProvider.isRTL;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: colorScheme.background,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.9,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (_, scrollController) {
            return Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header with title and close button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        context.translate('medical_records'),
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.cardoBlue,
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.close, color: colorScheme.onSurface),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),

                  // Doctor info section
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color:
                          isDarkMode ? colorScheme.background : Colors.grey[50],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: AppTheme.cardoBlue.withOpacity(0.2),
                          child: Icon(Icons.medical_services,
                              color: AppTheme.cardoBlue),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isRTL && doctor["name_ar"] != null
                                    ? doctor["name_ar"]
                                    : doctor["name"],
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: colorScheme.onSurface,
                                ),
                              ),
                              Text(
                                isRTL && doctor["organization_ar"] != null
                                    ? doctor["organization_ar"]
                                    : doctor["organization"],
                                style: TextStyle(
                                  color: isDarkMode
                                      ? Colors.grey[400]
                                      : Colors.grey[600],
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 16),

                  // Records list header
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          context.translate('patient_records'),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        Text(
                          '${doctor["medicalRecords"].length} ${context.translate('records')}',
                          style: TextStyle(
                            color: isDarkMode
                                ? Colors.grey[500]
                                : Colors.grey[500],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 8),

                  // Records list
                  Expanded(
                    child: ListView.separated(
                      controller: scrollController,
                      itemCount: doctor["medicalRecords"].length,
                      separatorBuilder: (context, index) =>
                          SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final record = doctor["medicalRecords"][index];
                        return Container(
                          decoration: BoxDecoration(
                            color: colorScheme.surface,
                            borderRadius: BorderRadius.circular(12),
                            border: isDarkMode
                                ? Border.all(color: Colors.grey[800]!)
                                : null,
                            boxShadow: [
                              if (!isDarkMode)
                                BoxShadow(
                                  color: Colors.grey.withOpacity(0.1),
                                  blurRadius: 6,
                                  offset: Offset(0, 2),
                                ),
                            ],
                          ),
                          child: ExpansionTile(
                            leading: CircleAvatar(
                              backgroundColor: isDarkMode
                                  ? AppTheme.cardoBlue.withOpacity(0.2)
                                  : Colors.blue[50],
                              child: Icon(Icons.person,
                                  size: 20, color: AppTheme.cardoBlue),
                            ),
                            title: Text(
                              isRTL && record["patientName_ar"] != null
                                  ? record["patientName_ar"]
                                  : record["patientName"],
                              style: TextStyle(
                                fontWeight: FontWeight.w500,
                                color: colorScheme.onSurface,
                              ),
                            ),
                            subtitle: Text(
                              record["date"].toString().split(' ')[0],
                              style: TextStyle(
                                fontSize: 12,
                                color: isDarkMode
                                    ? Colors.grey[400]
                                    : Colors.grey[600],
                              ),
                            ),
                            iconColor: colorScheme.onSurface,
                            collapsedIconColor: colorScheme.onSurface,
                            children: [
                              Padding(
                                padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    _buildRecordItem(
                                      context,
                                      context.translate('diagnosis'),
                                      record["diagnosis_key"] != null
                                          ? context.translate(
                                              record["diagnosis_key"])
                                          : record["diagnosis"],
                                    ),
                                    SizedBox(height: 8),
                                    _buildRecordItem(
                                      context,
                                      context.translate('treatment'),
                                      record["treatment_key"] != null
                                          ? context.translate(
                                              record["treatment_key"])
                                          : record["treatment"],
                                    ),
                                    SizedBox(height: 8),
                                    _buildRecordItem(
                                      context,
                                      context.translate('notes'),
                                      isRTL && record["notes_ar"] != null
                                          ? record["notes_ar"]
                                          : record["notes"],
                                    ),
                                  ],
                                ),
                              ),
                            ],
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

  // Helper to build record items with correct alignment for RTL
  Widget _buildRecordItem(BuildContext context, String label, String value) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDarkMode = Provider.of<ThemeProvider>(context).isDarkMode;
    final isRTL = Provider.of<LanguageProvider>(context).isRTL;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
          ),
        ),
        SizedBox(height: 4),
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isDarkMode
                ? Colors.grey[800]!.withOpacity(0.3)
                : Colors.grey[100],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            value,
            textAlign: isRTL ? TextAlign.right : TextAlign.left,
            style: TextStyle(
              fontSize: 15,
              color: colorScheme.onSurface,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Get RTL information
    final languageProvider = Provider.of<LanguageProvider>(context);
    final isRTL = languageProvider.isRTL;

    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isPortrait =
        MediaQuery.of(context).orientation == Orientation.portrait;

    return Directionality(
      textDirection: isRTL ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            widget.specialtyName,
            style: TextStyle(
              color: colorScheme.onBackground,
              fontWeight: FontWeight.bold,
            ),
          ),
          leading: IconButton(
            icon: Icon(
              isRTL ? Icons.arrow_forward : Icons.arrow_back,
              color: colorScheme.onBackground,
            ),
            onPressed: () => Navigator.pop(context),
          ),
          backgroundColor: colorScheme.background,
          elevation: 0,
          centerTitle: true,
        ),
        backgroundColor: colorScheme.background,
        body: filteredDoctors.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.medical_services_outlined,
                      size: 64,
                      color: AppTheme.cardoBlue.withOpacity(0.7),
                    ),
                    SizedBox(height: 16),
                    Text(
                      context.translate('no_doctors_found'),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        color: colorScheme.onBackground,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      context.translate('no_doctors_found_message'),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: colorScheme.onBackground.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              )
            : ListView.builder(
                padding: EdgeInsets.all(16),
                itemCount: filteredDoctors.length,
                itemBuilder: (context, index) {
                  final doctor = filteredDoctors[index];
                  return _buildDoctorCard(context, doctor);
                },
              ),
      ),
    );
  }

  Container _buildDoctorCard(
      BuildContext context, Map<String, dynamic> doctor) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    final colorScheme = Theme.of(context).colorScheme;

    // Get RTL information
    final languageProvider = Provider.of<LanguageProvider>(context);
    final isRTL = languageProvider.isRTL;

    return Container(
      margin: EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: isDarkMode
                ? Colors.black.withOpacity(0.2)
                : Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: Offset(0, 1),
          )
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _showMedicalRecords(context, doctor),
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: AppTheme.cardoBlue.withOpacity(0.15),
                      child: Icon(
                        Icons.medical_services,
                        color: AppTheme.cardoBlue,
                        size: 20,
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isRTL && doctor["name_ar"] != null
                                ? doctor["name_ar"]
                                : doctor["name"],
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: colorScheme.onSurface,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            isRTL && doctor["organization_ar"] != null
                                ? doctor["organization_ar"]
                                : doctor["organization"],
                            style: TextStyle(
                              color: isDarkMode
                                  ? Colors.grey[400]
                                  : Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      isRTL ? Icons.arrow_back_ios : Icons.arrow_forward_ios,
                      size: 16,
                      color: colorScheme.onSurface.withOpacity(0.5),
                    ),
                  ],
                ),
                SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildBadge(
                      context,
                      "${doctor["medicalRecords"].length} ${context.translate('records')}",
                      AppTheme.cardoBlue.withOpacity(0.1),
                      AppTheme.cardoBlue,
                      isDarkMode,
                    ),
                    _buildBadge(
                      context,
                      context.translate('tap_to_view'),
                      isDarkMode
                          ? colorScheme.primary.withOpacity(0.15)
                          : Colors.grey.shade100,
                      colorScheme.primary,
                      isDarkMode,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBadge(BuildContext context, String text, Color bgColor,
      Color textColor, bool isDarkMode) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: isDarkMode
            ? Border.all(color: textColor.withOpacity(0.3), width: 1)
            : null,
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          color: textColor,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
