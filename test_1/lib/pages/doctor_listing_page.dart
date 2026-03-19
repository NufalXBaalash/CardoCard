import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:test_1/utils/theme_provider.dart';
import 'package:test_1/utils/language_provider.dart';
import 'package:test_1/utils/app_localizations.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

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
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
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
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Query doctors collection
      Query query = _firestore.collection('doctors');
      
      // Apply specialty filter if selected
      if (_selectedSpecialty != null && _selectedSpecialty!.isNotEmpty) {
        query = query.where('specialty', isEqualTo: _selectedSpecialty);
      }
      
      final QuerySnapshot snapshot = await query.get();
      
      final List<Map<String, dynamic>> loadedDoctors = [];
      
      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        
        // Calculate average rating
        double avgRating = 4.5; // Default rating
        if (data.containsKey('ratings') && data['ratings'] is List) {
          final ratings = List<num>.from(data['ratings']);
          if (ratings.isNotEmpty) {
            avgRating = ratings.reduce((a, b) => a + b) / ratings.length;
          }
        }
        
        loadedDoctors.add({
          'id': doc.id,
          'name': data['name'] ?? 'Unknown Doctor',
          'specialty': data['specialty'] ?? 'General Practitioner',
          'bio': data['bio'] ?? '',
          'location': data['location'] ?? 'Unknown Location',
          'address': data['address'] ?? '',
          'price': data['price'] ?? 0,
          'appointmentDuration': data['appointmentDuration'] ?? 30,
          'rating': avgRating,
          'reviewCount': data['reviewCount'] ?? 0,
          'imageUrl': data['imageUrl'],
        });
      }
      
      // If no doctors in database, add some mock data
      if (loadedDoctors.isEmpty) {
        loadedDoctors.addAll([
          {
            'id': '1',
            'name': 'Dr. Ahmed Hassan',
            'specialty': 'Cardiologist',
            'bio': 'Specialist in heart diseases and treatments',
            'location': 'Cairo Medical Center',
            'address': 'Downtown, Cairo',
            'price': 300,
            'appointmentDuration': 30,
            'rating': 4.8,
            'reviewCount': 253,
            'imageUrl': null,
          },
          {
            'id': '2',
            'name': 'Dr. Sarah Mohamed',
            'specialty': 'Neurologist',
            'bio': 'Specialist in brain and nervous system',
            'location': 'Neurology Center',
            'address': 'Nasr City, Cairo',
            'price': 350,
            'appointmentDuration': 45,
            'rating': 4.7,
            'reviewCount': 187,
            'imageUrl': null,
          },
          {
            'id': '3',
            'name': 'Dr. Omar Khaled',
            'specialty': 'Orthopedist',
            'bio': 'Specialist in bone and joint treatments',
            'location': 'Orthopedic Clinic',
            'address': 'Maadi, Cairo',
            'price': 280,
            'appointmentDuration': 30,
            'rating': 4.5,
            'reviewCount': 142,
            'imageUrl': null,
          },
        ]);
      }
      
      setState(() {
        _doctors = loadedDoctors;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading doctors: $e');
      setState(() {
        _isLoading = false;
      });
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
        backgroundColor: isDarkMode ? Colors.grey[900] : Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: isDarkMode ? Colors.white : Colors.black,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(
              isDarkMode ? Icons.wb_sunny_outlined : Icons.nights_stay_outlined,
              color: isDarkMode ? Colors.white : Colors.black,
            ),
            onPressed: () {
              final provider = Provider.of<ThemeProvider>(context, listen: false);
              provider.toggleTheme();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: isDarkMode ? Colors.grey[900] : Colors.white,
            child: TextField(
              controller: _searchController,
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
              decoration: InputDecoration(
                hintText: context.translate('search_doctors'),
                prefixIcon: Icon(Icons.search, color: isDarkMode ? Colors.white70 : Colors.grey),
                filled: true,
                fillColor: isDarkMode ? Colors.grey[800] : Colors.grey[200],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
            ),
          ),
          
          // Filter options
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: isDarkMode ? Colors.grey[900] : Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    icon: Icon(Icons.filter_list, size: 18),
                    label: Text(context.translate('filter')),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isDarkMode ? Colors.grey[800] : Colors.grey[200],
                      foregroundColor: isDarkMode ? Colors.white : Colors.black,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: () {
                      // Show filter options
                    },
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    icon: Icon(Icons.sort, size: 18),
                    label: Text(context.translate('sort')),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isDarkMode ? Colors.grey[800] : Colors.grey[200],
                      foregroundColor: isDarkMode ? Colors.white : Colors.black,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: () {
                      // Show sort options
                    },
                  ),
                ),
              ],
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
                ? Center(child: CircularProgressIndicator())
                : _filteredDoctors.isEmpty
                    ? Center(
                        child: Text(
                          context.translate('no_doctors_found'),
                          style: TextStyle(
                            color: isDarkMode ? Colors.white70 : Colors.grey[700],
                          ),
                        ),
                      )
                    : ListView.builder(
                        itemCount: _filteredDoctors.length,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemBuilder: (context, index) {
                          final doctor = _filteredDoctors[index];
                          return _buildDoctorCard(doctor, context, isDarkMode, isRTL);
                        },
                      ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildDoctorCard(Map<String, dynamic> doctor, BuildContext context, bool isDarkMode, bool isRTL) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      color: isDarkMode ? Colors.grey[850] : Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Doctor info section
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Doctor image
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.blue.shade100,
                  backgroundImage: doctor['imageUrl'] != null
                      ? NetworkImage(doctor['imageUrl'])
                      : null,
                  child: doctor['imageUrl'] == null
                      ? Icon(Icons.person, size: 30, color: Colors.blue)
                      : null,
                ),
                SizedBox(width: 12),
                
                // Doctor details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Doctor name
                      Text(
                        doctor['name'],
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: isDarkMode ? Colors.white : Colors.black,
                        ),
                      ),
                      SizedBox(height: 4),
                      
                      // Doctor specialty
                      Text(
                        doctor['specialty'],
                        style: TextStyle(
                          color: isDarkMode ? Colors.white70 : Colors.grey[700],
                          fontSize: 14,
                        ),
                      ),
                      SizedBox(height: 8),
                      
                      // Rating stars
                      Row(
                        children: [
                          ...List.generate(5, (index) {
                            return Icon(
                              index < doctor['rating'].floor()
                                  ? Icons.star
                                  : index < doctor['rating']
                                      ? Icons.star_half
                                      : Icons.star_border,
                              color: Colors.amber,
                              size: 18,
                            );
                          }),
                          SizedBox(width: 4),
                          Text(
                            '${doctor['reviewCount']} ${context.translate('reviews')}',
                            style: TextStyle(
                              color: isDarkMode ? Colors.white70 : Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          Divider(height: 1, thickness: 1, color: isDarkMode ? Colors.grey[800] : Colors.grey[200]),
          
          // Doctor bio
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Icon(
                  Icons.medical_services_outlined,
                  size: 18,
                  color: Colors.blue,
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    doctor['bio'],
                    style: TextStyle(
                      fontSize: 13,
                      color: isDarkMode ? Colors.white70 : Colors.grey[700],
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          
          // Location
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Icon(
                  Icons.location_on_outlined,
                  size: 18,
                  color: Colors.red,
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    doctor['location'],
                    style: TextStyle(
                      fontSize: 13,
                      color: isDarkMode ? Colors.white70 : Colors.grey[700],
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Address
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Icon(
                  Icons.map_outlined,
                  size: 18,
                  color: Colors.green,
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    doctor['address'],
                    style: TextStyle(
                      fontSize: 13,
                      color: isDarkMode ? Colors.white70 : Colors.grey[700],
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Price
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Icon(
                  Icons.attach_money,
                  size: 18,
                  color: Colors.amber,
                ),
                SizedBox(width: 8),
                Text(
                  '${doctor['price']} ${context.translate('currency')}',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white : Colors.black87,
                  ),
                ),
              ],
            ),
          ),
          
          // Appointment duration
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Icon(
                  Icons.access_time,
                  size: 18,
                  color: Colors.purple,
                ),
                SizedBox(width: 8),
                Text(
                  '${doctor['appointmentDuration']} ${context.translate('minutes')}',
                  style: TextStyle(
                    fontSize: 13,
                    color: isDarkMode ? Colors.white70 : Colors.grey[700],
                  ),
                ),
              ],
            ),
          ),
          
          // Book button
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  // Handle booking
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(context.translate('book_now')),
              ),
            ),
          ),
        ],
      ),
    );
  }
}