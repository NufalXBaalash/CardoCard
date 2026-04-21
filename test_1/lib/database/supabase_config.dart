import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  static SupabaseClient get client => Supabase.instance.client;

  // ==================== Doctors ====================

  static Future<List<Map<String, dynamic>>> fetchDoctors({String? specialty}) async {
    var query = client.from('doctors').select();
    if (specialty != null && specialty.isNotEmpty) {
      query = query.eq('specialty', specialty);
    }
    final response = await query;
    return List<Map<String, dynamic>>.from(response);
  }

  static Future<Map<String, dynamic>?> fetchDoctorById(String id) async {
    return await client.from('doctors').select().eq('id', id).maybeSingle();
  }

  // ==================== Doctor Availability ====================

  static Future<List<Map<String, dynamic>>> fetchDoctorAvailability(
    String doctorId,
    int dayOfWeek,
  ) async {
    final response = await client
        .from('doctor_availability')
        .select()
        .eq('doctor_id', doctorId)
        .eq('day_of_week', dayOfWeek)
        .eq('is_available', true)
        .order('start_time');
    return List<Map<String, dynamic>>.from(response);
  }

  static Future<List<Map<String, dynamic>>> fetchDoctorWeeklyAvailability(
    String doctorId,
  ) async {
    final response = await client
        .from('doctor_availability')
        .select()
        .eq('doctor_id', doctorId)
        .eq('is_available', true)
        .order('day_of_week');
    return List<Map<String, dynamic>>.from(response);
  }

  // ==================== Appointments ====================

  static Future<List<Map<String, dynamic>>> fetchUserAppointments(
    String userId, {
    String? status,
  }) async {
    PostgrestFilterBuilder<List<Map<String, dynamic>>> query;
    if (status != null) {
      query = client
          .from('appointments')
          .select('*, doctors(*)')
          .eq('patient_id', userId)
          .eq('status', status);
    } else {
      query = client
          .from('appointments')
          .select('*, doctors(*)')
          .eq('patient_id', userId);
    }
    final response = await query.order('appointment_date', ascending: true);
    return List<Map<String, dynamic>>.from(response);
  }

  static Future<Map<String, dynamic>> bookAppointment({
    required String patientId,
    required String doctorId,
    required DateTime date,
    required String startTime,
    required String endTime,
    String? notes,
  }) async {
    final response = await client.from('appointments').insert({
      'patient_id': patientId,
      'doctor_id': doctorId,
      'appointment_date': date.toIso8601String().split('T').first,
      'start_time': startTime,
      'end_time': endTime,
      'status': 'scheduled',
      'notes': notes,
    }).select().single();
    return response;
  }

  static Future<void> cancelAppointment(String appointmentId) async {
    await client
        .from('appointments')
        .update({'status': 'cancelled'})
        .eq('id', appointmentId);
  }

  static Future<bool> isSlotBooked(
    String doctorId,
    String date,
    String startTime,
  ) async {
    final response = await client
        .from('appointments')
        .select()
        .eq('doctor_id', doctorId)
        .eq('appointment_date', date)
        .eq('start_time', startTime)
        .neq('status', 'cancelled');
    return response.isNotEmpty;
  }

  // ==================== Users / Profiles ====================

  static Future<Map<String, dynamic>?> fetchUserProfile(String userId) async {
    return await client.from('profiles').select().eq('id', userId).maybeSingle();
  }

  static Future<void> upsertProfile(String userId, Map<String, dynamic> data) async {
    data['id'] = userId;
    await client.from('profiles').upsert(data);
  }

  static Future<void> updateProfile(String userId, Map<String, dynamic> data) async {
    await client.from('profiles').update(data).eq('id', userId);
  }

  static Future<void> deleteProfile(String userId) async {
    await client.from('profiles').delete().eq('id', userId);
  }

  // ==================== Medical Info ====================

  static Future<Map<String, dynamic>?> fetchMedicalInfo(String userId) async {
    return await client.from('medical_info').select().eq('user_id', userId).maybeSingle();
  }

  static Future<void> upsertMedicalInfo(String userId, Map<String, dynamic> data) async {
    data['user_id'] = userId;
    await client.from('medical_info').upsert(data);
  }

  // ==================== Medications ====================

  static Future<List<Map<String, dynamic>>> fetchMedications(String userId) async {
    final response = await client
        .from('medications')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }

  static Future<Map<String, dynamic>> addMedication(String userId, Map<String, dynamic> data) async {
    data['user_id'] = userId;
    return await client.from('medications').insert(data).select().single();
  }

  static Future<void> updateMedication(String medicationId, Map<String, dynamic> data) async {
    await client.from('medications').update(data).eq('id', medicationId);
  }

  static Future<void> deleteMedication(String medicationId) async {
    await client.from('medications').delete().eq('id', medicationId);
  }

  // ==================== Medical Records ====================

  static Future<List<Map<String, dynamic>>> fetchMedicalRecords(String userId) async {
    final response = await client
        .from('medical_records')
        .select('*, doctors(name, specialty)')
        .eq('patient_id', userId)
        .order('date', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }

  static Future<Map<String, dynamic>> addMedicalRecord(Map<String, dynamic> data) async {
    return await client.from('medical_records').insert(data).select().single();
  }

  // ==================== Prescriptions ====================

  static Future<List<Map<String, dynamic>>> fetchPrescriptions(String userId) async {
    final response = await client
        .from('prescriptions')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }

  static Future<Map<String, dynamic>> addPrescription(String userId, Map<String, dynamic> data) async {
    data['user_id'] = userId;
    return await client.from('prescriptions').insert(data).select().single();
  }

  // ==================== Health Metrics ====================

  static Future<List<Map<String, dynamic>>> fetchHealthMetrics(String userId) async {
    final response = await client
        .from('health_metrics')
        .select()
        .eq('user_id', userId)
        .order('recorded_at', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }

  static Future<Map<String, dynamic>> addHealthMetric(String userId, Map<String, dynamic> data) async {
    data['user_id'] = userId;
    return await client.from('health_metrics').insert(data).select().single();
  }

  // ==================== Doctor-Specific Methods ====================

  static Future<Map<String, dynamic>?> fetchDoctorByUserId(String userId) async {
    return await client
        .from('doctors')
        .select()
        .eq('supabase_user_id', userId)
        .maybeSingle();
  }

  static Future<List<Map<String, dynamic>>> fetchDoctorPatients(String doctorId) async {
    final response = await client
        .from('appointments')
        .select('patient_id, profiles(id, full_name, email, phone_number)')
        .eq('doctor_id', doctorId);
    // Deduplicate by patient_id
    final seen = <String>{};
    final patients = <Map<String, dynamic>>[];
    for (final row in response) {
      final profile = row['profiles'] as Map<String, dynamic>?;
      if (profile == null) continue;
      final pid = profile['id']?.toString();
      if (pid != null && !seen.contains(pid)) {
        seen.add(pid);
        patients.add(profile);
      }
    }
    return patients;
  }

  static Future<List<Map<String, dynamic>>> fetchDoctorAppointments(
    String doctorId, {
    String? status,
  }) async {
    PostgrestFilterBuilder<List<Map<String, dynamic>>> query;
    if (status != null) {
      query = client
          .from('appointments')
          .select('*, profiles(id, full_name, email)')
          .eq('doctor_id', doctorId)
          .eq('status', status);
    } else {
      query = client
          .from('appointments')
          .select('*, profiles(id, full_name, email)')
          .eq('doctor_id', doctorId);
    }
    final response = await query.order('appointment_date', ascending: true);
    return List<Map<String, dynamic>>.from(response);
  }

  static Future<List<Map<String, dynamic>>> fetchPatientMedicalRecords(String patientId) async {
    final response = await client
        .from('medical_records')
        .select('*, doctors(name, specialty)')
        .eq('patient_id', patientId)
        .order('date', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }

  static Future<List<Map<String, dynamic>>> fetchDoctorMedicalRecords(
      String doctorId) async {
    final response = await client
        .from('medical_records')
        .select('*, profiles(full_name)')
        .eq('doctor_id', doctorId)
        .order('date', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }

  static Future<void> updateAppointmentStatus(String appointmentId, String status) async {
    await client
        .from('appointments')
        .update({'status': status})
        .eq('id', appointmentId);
  }

  static Future<Map<String, dynamic>> addAvailabilitySlot({
    required String doctorId,
    required int dayOfWeek,
    required String startTime,
    required String endTime,
  }) async {
    return await client.from('doctor_availability').insert({
      'doctor_id': doctorId,
      'day_of_week': dayOfWeek,
      'start_time': startTime,
      'end_time': endTime,
      'is_available': true,
    }).select().single();
  }

  static Future<void> removeAvailabilitySlot(String slotId) async {
    await client.from('doctor_availability').delete().eq('id', slotId);
  }

  static Future<void> toggleAvailabilitySlot(String slotId, bool isAvailable) async {
    await client
        .from('doctor_availability')
        .update({'is_available': isAvailable})
        .eq('id', slotId);
  }

  // ==================== Role Helper ====================

  static Future<String> getUserRole(String userId) async {
    final profile = await fetchUserProfile(userId);
    return profile?['role']?.toString() ?? 'patient';
  }
}
