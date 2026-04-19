import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:test_1/utils/theme_provider.dart';
import 'package:test_1/utils/language_provider.dart';
import 'package:test_1/utils/app_localizations.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  bool _isLoading = true;
  List<Map<String, dynamic>> _doctors = [];
  String _searchQuery = '';
  String? _selectedSpecialty;
  
  final TextEditingController _searchController = TextEditingController();

  // Bio-Tech Colors
  static const Color biotechBlack = Color(0xFF0F0F0F);
  static const Color biotechCyan = Color(0xFF00E5FF);
  static const Color biotechCyanDeep = Color(0xFF00B8D4); // WCAG-compliant for Light Mode
  
  @override
  void initState() {
    super.initState();
    _selectedSpecialty = widget.specialtyFilter;
    _loadDoctors();
  }
  
  Future<void> _loadDoctors() async {
    setState(() => _isLoading = true);
    try {
      Query query = _firestore.collection('doctors');
      if (_selectedSpecialty != null && _selectedSpecialty!.isNotEmpty) {
        query = query.where('specialty', isEqualTo: _selectedSpecialty);
      }
      
      final QuerySnapshot snapshot = await query.get();
      final List<Map<String, dynamic>> loadedDoctors = [];
      
      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        double avgRating = 4.5;
        if (data.containsKey('ratings') && data['ratings'] is List) {
          final ratings = List<num>.from(data['ratings']);
          if (ratings.isNotEmpty) {
            avgRating = ratings.reduce((a, b) => a + b) / ratings.length;
          }
        }
        
        loadedDoctors.add({
          'id': doc.id,
          ...data,
          'rating': avgRating,
        });
      }
      
      if (loadedDoctors.isEmpty) {
        loadedDoctors.addAll([
          {
            'id': '1',
            'name': 'Dr. Ahmed Hassan',
            'specialty': 'Cardiologist',
            'bio': 'Specialist in heart diseases and treatments',
            'location': 'Cairo Medical Center',
            'price': 300,
            'appointmentDuration': 30,
            'rating': 4.8,
            'reviewCount': 253,
          },
          {
            'id': '2',
            'name': 'Dr. Sarah Mohamed',
            'specialty': 'Neurologist',
            'bio': 'Specialist in brain and nervous system',
            'location': 'Neurology Center',
            'price': 350,
            'appointmentDuration': 45,
            'rating': 4.7,
            'reviewCount': 187,
          },
        ]);
      }
      
      setState(() {
        _doctors = loadedDoctors;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading doctors: $e');
      setState(() => _isLoading = false);
    }
  }
  
  List<Map<String, dynamic>> get _filteredDoctors {
    if (_searchQuery.isEmpty) return _doctors;
    return _doctors.where((doctor) {
      final name = doctor['name'].toString().toLowerCase();
      final specialty = doctor['specialty'].toString().toLowerCase();
      final query = _searchQuery.toLowerCase();
      return name.contains(query) || specialty.contains(query);
    }).toList();
  }
  
  @override
  Widget build(BuildContext context) {
    final isRTL = Provider.of<LanguageProvider>(context).isRTL;
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    final dynamicCyan = isDarkMode ? biotechCyan : biotechCyanDeep;
    
    final scaffoldBg = isDarkMode ? biotechBlack : const Color(0xFFF5F7FA);
    final textColor = isDarkMode ? Colors.white : biotechBlack;

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
          context.translate('find_doctor').toUpperCase(),
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
      ),
      body: Stack(
        children: [
          Positioned(
            top: -100,
            left: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(shape: BoxShape.circle, color: dynamicCyan.withOpacity(isDarkMode ? 0.05 : 0.08)),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                _buildSearchBar(context, dynamicCyan, isDarkMode, textColor),
                _buildQuickFilters(context, dynamicCyan, isDarkMode, textColor),
                Expanded(
                  child: _isLoading
                      ? Center(child: CircularProgressIndicator(color: dynamicCyan))
                      : _buildDoctorList(isRTL, dynamicCyan, isDarkMode, textColor),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context, Color dynamicCyan, bool isDarkMode, Color textColor) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Container(
        decoration: BoxDecoration(
          color: isDarkMode ? Colors.white.withOpacity(0.03) : Colors.white,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: dynamicCyan.withOpacity(0.2)),
          boxShadow: isDarkMode ? [] : [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: TextField(
          controller: _searchController,
          onChanged: (v) => setState(() => _searchQuery = v),
          style: GoogleFonts.poppins(color: textColor),
          decoration: InputDecoration(
            hintText: context.translate('search_doctors').toUpperCase(),
            hintStyle: GoogleFonts.orbitron(color: isDarkMode ? Colors.white24 : Colors.black26, fontSize: 10),
            prefixIcon: Icon(Icons.search, color: dynamicCyan),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 15),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickFilters(BuildContext context, Color dynamicCyan, bool isDarkMode, Color textColor) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          _buildFilterChip("TOP RATED", true, dynamicCyan, isDarkMode, textColor),
          _buildFilterChip("NEAREST", false, dynamicCyan, isDarkMode, textColor),
          _buildFilterChip("AVAILABLE", false, dynamicCyan, isDarkMode, textColor),
          _buildFilterChip("PRICE: LOW", false, dynamicCyan, isDarkMode, textColor),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, bool isSelected, Color dynamicCyan, bool isDarkMode, Color textColor) {
    return Container(
      margin: const EdgeInsets.only(right: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isSelected ? dynamicCyan.withOpacity(0.1) : (isDarkMode ? Colors.white.withOpacity(0.02) : Colors.white),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: isSelected ? dynamicCyan : (isDarkMode ? Colors.white10 : Colors.black12)),
      ),
      child: Text(
        label,
        style: GoogleFonts.orbitron(
          color: isSelected ? dynamicCyan : (isDarkMode ? Colors.white38 : Colors.black38),
          fontSize: 9,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildDoctorList(bool isRTL, Color dynamicCyan, bool isDarkMode, Color textColor) {
    if (_filteredDoctors.isEmpty) {
      return Center(
        child: Text("NO PERSONNEL MATCHING CRITERIA", 
          style: GoogleFonts.orbitron(color: isDarkMode ? Colors.white24 : Colors.black26, fontSize: 12)),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: _filteredDoctors.length,
      itemBuilder: (context, index) => _buildDoctorBioCard(_filteredDoctors[index], isRTL, dynamicCyan, isDarkMode, textColor),
    );
  }

  Widget _buildDoctorBioCard(Map<String, dynamic> doctor, bool isRTL, Color dynamicCyan, bool isDarkMode, Color textColor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.white.withOpacity(0.02) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: dynamicCyan.withOpacity(0.1)),
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
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(color: dynamicCyan.withOpacity(0.3)),
                        image: doctor['imageUrl'] != null
                            ? DecorationImage(image: NetworkImage(doctor['imageUrl']), fit: BoxFit.cover)
                            : null,
                      ),
                      child: doctor['imageUrl'] == null
                          ? Icon(Icons.person, color: dynamicCyan, size: 40)
                          : null,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            doctor['name'].toString().toUpperCase(),
                            style: GoogleFonts.orbitron(
                              color: textColor,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            doctor['specialty'].toString().toUpperCase(),
                            style: GoogleFonts.poppins(color: dynamicCyan, fontSize: 12, fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(Icons.star, color: Colors.amber, size: 14),
                              const SizedBox(width: 4),
                              Text(
                                doctor['rating'].toString(),
                                style: GoogleFonts.orbitron(color: textColor, fontSize: 12),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                "(${doctor['reviewCount']} REVIEWS)",
                                style: GoogleFonts.orbitron(color: isDarkMode ? Colors.white24 : Colors.black26, fontSize: 10),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildStat("RATE", "${doctor['price']} EGP", isDarkMode, textColor),
                    _buildStat("DURATION", "${doctor['appointmentDuration']}M", isDarkMode, textColor),
                    _buildStat("LOCATION", "CORE-X", isDarkMode, textColor),
                  ],
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: dynamicCyan,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: () {},
                    child: Text(
                      "INITIATE SESSION",
                      style: GoogleFonts.orbitron(fontWeight: FontWeight.bold, letterSpacing: 1),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStat(String label, String value, bool isDarkMode, Color textColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.orbitron(color: isDarkMode ? Colors.white38 : Colors.black38, fontSize: 8, letterSpacing: 1)),
        const SizedBox(height: 4),
        Text(value, style: GoogleFonts.orbitron(color: textColor, fontSize: 11, fontWeight: FontWeight.bold)),
      ],
    );
  }
}
