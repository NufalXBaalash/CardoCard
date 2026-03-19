import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'language_provider.dart';

class AppLocalizations {
  final Locale locale;
  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  const AppLocalizations(this.locale);

  // Static method to load the AppLocalizations for a given locale
  static Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(AppLocalizations(locale));
  }

  // Helper method to get current language code
  String get languageCode => locale.languageCode;

  // English-Arabic translations map
  static final Map<String, Map<String, String>> _localizedValues = {
    // Common UI elements
    'app_name': {
      'en': 'CardoCare',
      'ar': 'كاردوكير',
    },
    'Medical Appointments': {
      'en': 'Medical Appointments',
      'ar': 'المواعيد الطبية',
    },
    'your_medical_schedule': {
      'en': 'Your Medical Schedule',
      'ar': 'جدول مواعيدك الطبية',
    },
    'add_medication': {
      'en': 'Add Medication',
      'ar': 'إضافة دواء',
    },
    'reminder_time': {
      'en': 'Reminder Time',
      'ar': 'وقت التذكير',
    },
    'dosage': {
      'en': 'Dosage',
      'ar': 'الجرعة',
    },
    'medication_name': {
      'en': 'Medication Name',
      'ar': 'اسم الدواء',
    },
    'add_new_medication': {
      'en': 'Add New Medication',
      'ar': 'إضافة دواء جديد ',
    },
    'instructions': {
      'en': 'Instructions',
      'ar': 'التعليمات',
    },
    'are_you_sure_delete': {
      'en': 'Are you sure you want to delete this medication?',
      'ar': 'هل أنت متأكد أنك تريد حذف هذا الدواء؟',
    },
    'delete_medication': {
      'en': 'Delete Medication',
      'ar': 'حذف الدواء',
    },
    'AI Health Assistant': {
      'en': 'AI Health Assistant',
      'ar': 'مساعد الذكاء الاصطناعي',
    },
    'side_effects': {
      'en': 'Side Effects',
      'ar': 'تأثيرات جانبية',
    },
    'No appointments scheduled': {
      'en': 'No appointments scheduled',
      'ar': 'لا توجد مواعيد مجدولة',
    },
    'Tap the + button to schedule one': {
      'en': 'Tap the + button to schedule one',
      'ar': 'انقر على زر + لجدولة موعد',
    },
    'Schedule Appointment': {
      'en': 'Schedule Appointment',
      'ar': 'جدولة موعد',
    },
    'Doctor Information': {
      'en': 'Doctor Information',
      'ar': 'معلومات الطبيب',
    },
    'Doctor Name': {
      'en': 'Doctor Name',
      'ar': 'اسم الطبيب',
    },
    'Please enter doctor name': {
      'en': 'Please enter doctor name',
      'ar': 'الرجاء إدخال اسم الطبيب',
    },
    'Specialty': {
      'en': 'Specialty',
      'ar': 'التخصص',
    },
    'Please enter specialty': {
      'en': 'Please enter specialty',
      'ar': 'الرجاء إدخال التخصص',
    },
    'Appointment Details': {
      'en': 'Appointment Details',
      'ar': 'تفاصيل الموعد',
    },
    'Select Date': {
      'en': 'Select Date',
      'ar': 'اختر التاريخ',
    },
    'Select Time': {
      'en': 'Select Time',
      'ar': 'اختر الوقت',
    },
    'Location': {
      'en': 'Location',
      'ar': 'الموقع',
    },
    'Please enter location': {
      'en': 'Please enter location',
      'ar': 'الرجاء إدخال الموقع',
    },
    'Notes (Optional)': {
      'en': 'Notes (Optional)',
      'ar': 'ملاحظات (اختياري)',
    },
    'Reschedule': {
      'en': 'Reschedule',
      'ar': 'إعادة جدولة',
    },
    'Details': {
      'en': 'Details',
      'ar': 'التفاصيل',
    },
    'login': {
      'en': 'Login',
      'ar': 'تسجيل الدخول',
    },
    'signup': {
      'en': 'Sign Up',
      'ar': 'إنشاء حساب',
    },
    'email': {
      'en': 'Email',
      'ar': 'البريد الإلكتروني',
    },
    'password': {
      'en': 'Password',
      'ar': 'كلمة المرور',
    },
    'continue': {
      'en': 'Continue',
      'ar': 'متابعة',
    },
    'next': {
      'en': 'Next',
      'ar': 'التالي',
    },
    'skip': {
      'en': 'Skip',
      'ar': 'تخطي',
    },
    'save': {
      'en': 'Save',
      'ar': 'حفظ',
    },
    'cancel': {
      'en': 'Cancel',
      'ar': 'إلغاء',
    },
    'delete': {
      'en': 'Delete',
      'ar': 'حذف',
    },
    'edit': {
      'en': 'Edit',
      'ar': 'تعديل',
    },
    'done': {
      'en': 'Done',
      'ar': 'تم',
    },
    'search': {
      'en': 'Search',
      'ar': 'بحث',
    },

    // Home page
    'welcome_back': {
      'en': 'Welcome back,',
      'ar': 'مرحبا بعودتك،',
    },
    'search_doctor': {
      'en': 'Search for doctors...',
      'ar': 'ابحث عن طبيب...',
    },
    'search_placeholder': {
      'en': 'Search for doctors, records...',
      'ar': 'البحث عن أطباء، سجلات...',
    },
    'medical_card': {
      'en': 'Medical Card',
      'ar': 'البطاقة الطبية',
    },
    'medical_specialties': {
      'en': 'Medical Specialties',
      'ar': 'التخصصات الطبية',
    },
    'see_all': {
      'en': 'See All',
      'ar': 'عرض الكل',
    },
    'appointments': {
      'en': 'Appointments',
      'ar': 'المواعيد',
    },
    'upcoming_appointment': {
      'en': 'Upcoming Appointment',
      'ar': 'الموعد القادم',
    },
    'confirmed': {
      'en': 'Confirmed',
      'ar': 'مؤكد',
    },
    'recent_doctors': {
      'en': 'Recent Doctors',
      'ar': 'الأطباء الأخيرون',
    },
    'hello': {
      'en': 'Hello',
      'ar': 'مرحباً',
    },
    'years_experience': {
      'en': 'years experience',
      'ar': 'سنوات خبرة',
    },
    'neurologist': {
      'en': 'Neurologist',
      'ar': 'طبيب أعصاب',
    },
    'orthopedist': {
      'en': 'Orthopedist',
      'ar': 'طبيب عظام',
    },
    'medications_for_today': {
      'en': 'Medications for Today',
      'ar': 'الدواء اليومي',
    },
    'upcoming_appointments': {
      'en': 'Upcoming Appointments',
      'ar': 'المواعيد القادمة',
    },
    'make_an_appointment': {
      'en': 'Make an Appointment',
      'ar': 'احجز موعد',
    },
    'dentist': {
      'en': 'Dentist',
      'ar': 'طبيب أسنان',
    },
    'orthopedic_consultation': {
      'en': 'Orthopedic Consultation (Foot & Ankle)',
      'ar': 'استشارة عظام (القدم والكاحل)',
    },
    'neurology': {
      'en': 'Neurology',
      'ar': 'طب الأعصاب',
    },
    'health_overview': {
      'en': 'Health Overview',
      'ar': 'نظرة عامة على الصحة',
    },
    'pull_to_refresh': {
      'en': 'Pull down to refresh',
      'ar': 'اسحب لأسفل للتحديث',
    },
    'member': {
      'en': 'MEMBER',
      'ar': 'عضو',
    },
    'no_medical_data': {
      'en': 'No Medical Information Found',
      'ar': 'لم يتم العثور على معلومات طبية',
    },
    'no_medical_data_message': {
      'en':
          'Your health data will appear here once added by your healthcare provider.',
      'ar':
          'ستظهر بيانات صحتك هنا بمجرد إضافتها من قبل مزود الرعاية الصحية الخاص بك.',
    },

    // Profile page
    'profile': {
      'en': 'Profile',
      'ar': 'الملف الشخصي',
    },
    'healthcare_provider': {
      'en': 'Healthcare Provider',
      'ar': 'مقدم خدمة الصحة',
    },
    'medication_side_effects': {
      'en': 'Medication Side Effects',
      'ar': 'تأثيرات جانبية للدواء',
    },

    'edit_profile': {
      'en': 'Edit Profile',
      'ar': 'تعديل الملف الشخصي',
    },
    'personal_information': {
      'en': 'Personal Information',
      'ar': 'المعلومات الشخصية',
    },
    'full_name': {
      'en': 'Full Name',
      'ar': 'الاسم الكامل',
    },
    'phone_number': {
      'en': 'Phone Number',
      'ar': 'رقم الهاتف',
    },
    'refills_remaining': {
      'en': 'Refills Remaining',
      'ar': 'الجرعات المتبقية',
    },
    'refill_information': {
      'en': 'Refill Information',
      'ar': 'معلومات الجرعة',
    },
    'next_refill_available': {
      'en': 'Next Refill Available',
      'ar': 'موعد الجرعة القادمة',
    },
    'address': {
      'en': 'Address',
      'ar': 'العنوان',
    },
    'role': {
      'en': 'Role',
      'ar': 'الدور',
    },
    'patient': {
      'en': 'Patient',
      'ar': 'مريض',
    },
    'app_settings': {
      'en': 'App Settings',
      'ar': 'إعدادات التطبيق',
    },
    'notifications': {
      'en': 'Notifications',
      'ar': 'الإشعارات',
    },
    'none': {
      'en': 'None',
      'ar': 'لا شيء',
    },
    'language': {
      'en': 'Language',
      'ar': 'اللغة',
    },
    'regional': {
      'en': 'Regional',
      'ar': 'الإعدادات الإقليمية',
    },
    'about_us': {
      'en': 'About Us',
      'ar': 'من نحن',
    },
    'change_profile_picture': {
      'en': 'Tap to change profile picture',
      'ar': 'انقر لتغيير صورة الملف الشخصي',
    },
    'delete_account': {
      'en': 'Delete Account',
      'ar': 'حذف الحساب',
    },
    'delete_account_warning': {
      'en':
          'Deleting your account will permanently remove all your data. This action cannot be undone.',
      'ar':
          'سيؤدي حذف حسابك إلى إزالة جميع بياناتك بشكل دائم. لا يمكن التراجع عن هذا الإجراء.',
    },
    'delete_account_confirmation': {
      'en': 'Are you sure you want to delete your account?',
      'ar': 'هل أنت متأكد أنك تريد حذف حسابك؟',
    },
    'delete_account_warning_detail': {
      'en':
          'All your data will be permanently deleted. This action cannot be undone.',
      'ar': 'سيتم حذف جميع بياناتك بشكل دائم. لا يمكن التراجع عن هذا الإجراء.',
    },
    'delete_my_account': {
      'en': 'Delete My Account',
      'ar': 'حذف حسابي',
    },

    // Language settings
    'choose_language': {
      'en': 'Choose Language',
      'ar': 'اختر اللغة',
    },
    'english': {
      'en': 'English',
      'ar': 'الإنجليزية',
    },
    'arabic': {
      'en': 'Arabic',
      'ar': 'العربية',
    },
    'auto_detect': {
      'en': 'Auto-detect based on region',
      'ar': 'كشف تلقائي حسب المنطقة',
    },

    // Medical specialties
    'cardiology': {
      'en': 'Cardiology',
      'ar': 'القلب',
    },
    'neurology': {
      'en': 'Neurology',
      'ar': 'الأعصاب',
    },
    'pediatrics': {
      'en': 'Pediatrics',
      'ar': 'الأطفال',
    },
    'orthopedics': {
      'en': 'Orthopedics',
      'ar': 'العظام',
    },
    'dermatology': {
      'en': 'Dermatology',
      'ar': 'الجلدية',
    },
    // Additional medical specialties
    'nutrition': {
      'en': 'Nutrition',
      'ar': 'التغذية',
    },
    'dentistry': {
      'en': 'Dentistry',
      'ar': 'الأسنان',
    },
    'disease': {
      'en': 'Disease',
      'ar': 'الأمراض',
    },
    'pulmonology': {
      'en': 'Pulmonology',
      'ar': 'الرئة',
    },

    // Health indicators
    'blood_type': {
      'en': 'Blood Type',
      'ar': 'فصيلة الدم',
    },
    'diabetes': {
      'en': 'Diabetes',
      'ar': 'السكري',
    },
    'asthma': {
      'en': 'Asthma',
      'ar': 'الربو',
    },
    'affected': {
      'en': 'Affected',
      'ar': 'مصاب',
    },
    'not_affected': {
      'en': 'Not Affected',
      'ar': 'غير مصاب',
    },
    'unknown': {
      'en': 'Unknown',
      'ar': 'غير معروف',
    },

    // Status and type labels
    'blood_type_label': {
      'en': 'Type: ',
      'ar': 'الفصيلة: ',
    },
    'status_label': {
      'en': 'Status: ',
      'ar': 'الحالة: ',
    },

    // Blood types
    'a+': {
      'en': 'A+',
      'ar': 'A+',
    },
    'a-': {
      'en': 'A-',
      'ar': 'A-',
    },
    'b+': {
      'en': 'B+',
      'ar': 'B+',
    },
    'b-': {
      'en': 'B-',
      'ar': 'B-',
    },
    'ab+': {
      'en': 'AB+',
      'ar': 'AB+',
    },
    'ab-': {
      'en': 'AB-',
      'ar': 'AB-',
    },
    'o+': {
      'en': 'O+',
      'ar': 'O+',
    },
    'o-': {
      'en': 'O-',
      'ar': 'O-',
    },

    // Additional translations for profile page
    'no_name': {
      'en': 'No name',
      'ar': 'بدون اسم',
    },
    'error_loading_user': {
      'en': 'Error loading user',
      'ar': 'خطأ في تحميل بيانات المستخدم',
    },
    'error_signing_out': {
      'en': 'Error signing out',
      'ar': 'خطأ في تسجيل الخروج',
    },
    'edit_personal_details': {
      'en': 'Edit personal details',
      'ar': 'تعديل البيانات الشخصية',
    },
    'appearance': {
      'en': 'Appearance',
      'ar': 'المظهر',
    },
    'dark_mode': {
      'en': 'Dark Mode',
      'ar': 'الوضع المظلم',
    },
    'change_password': {
      'en': 'Change Password',
      'ar': 'تغيير كلمة المرور',
    },
    'doctors': {
      'en': 'Doctors',
      'ar': 'الأطباء',
    },
    'community': {
      'en': 'Community',
      'ar': 'المجتمع',
    },
    'logout': {
      'en': 'Logout',
      'ar': 'تسجيل الخروج',
    },
    'app_version': {
      'en': 'App ver 2.0.1',
      'ar': 'الإصدار 2.0.1',
    },

    // Edit profile page translations
    'error_loading_user_data': {
      'en': 'Error loading user data',
      'ar': 'خطأ في تحميل بيانات المستخدم',
    },
    'please_enter_full_name': {
      'en': 'Please enter your full name',
      'ar': 'الرجاء إدخال الاسم الكامل',
    },
    'please_enter_phone': {
      'en': 'Please enter your phone number',
      'ar': 'الرجاء إدخال رقم الهاتف',
    },
    'image_too_large': {
      'en': 'Image size is too large. Please select a smaller image.',
      'ar': 'حجم الصورة كبير جدًا. الرجاء اختيار صورة أصغر.',
    },
    'profile_updated_success': {
      'en': 'Profile updated successfully',
      'ar': 'تم تحديث الملف الشخصي بنجاح',
    },
    'error_updating_profile': {
      'en': 'Error updating profile',
      'ar': 'خطأ في تحديث الملف الشخصي',
    },
    'type_confirm': {
      'en': 'Type "confirm" to proceed',
      'ar': 'اكتب "confirm" للمتابعة',
    },
    'confirm': {
      'en': 'confirm',
      'ar': 'confirm',
    },
    'account_deleted': {
      'en': 'Account deleted successfully',
      'ar': 'تم حذف الحساب بنجاح',
    },

    // Image picker translations
    'choose_option': {
      'en': 'Choose an option',
      'ar': 'اختر خيارًا',
    },
    'pick_from_gallery': {
      'en': 'Pick from Gallery',
      'ar': 'اختر من المعرض',
    },
    'take_photo': {
      'en': 'Take a Photo',
      'ar': 'التقط صورة',
    },
    'error_accessing_camera': {
      'en': 'Error accessing camera or gallery',
      'ar': 'خطأ في الوصول إلى الكاميرا أو المعرض',
    },
    'error_selecting_image': {
      'en': 'Error selecting image',
      'ar': 'خطأ في اختيار الصورة',
    },

    // Medical Records Page
    'medical_records': {
      'en': 'Medical Records',
      'ar': 'السجلات الطبية',
    },
    'your_health_records': {
      'en': 'Your Health Records',
      'ar': 'سجلاتك الصحية',
    },
    'select_specialty_access': {
      'en': 'Select a specialty to access your\nmedical history and diagnoses',
      'ar': 'اختر تخصصًا للوصول إلى\nتاريخك الطبي والتشخيصات',
    },
    'specialties': {
      'en': 'Specialties',
      'ar': 'التخصصات',
    },
    'patient_records': {
      'en': 'Patient Records',
      'ar': 'سجلات المريض',
    },
    'records': {
      'en': 'Records',
      'ar': 'سجلات',
    },
    'diagnosis': {
      'en': 'Diagnosis',
      'ar': 'التشخيص',
    },
    'treatment': {
      'en': 'Treatment',
      'ar': 'العلاج',
    },
    'book_now': {
      'en': 'Book Now',
      'ar': 'احجز الآن',
    },
    'find_doctor': {
      'en': 'Find a Doctor',
      'ar': 'ابحث عن طبيب',
    },
    'search_doctors': {
      'en': 'Search for Doctors...',
      'ar': 'أبحث عن طبيب...',
    },
    'doctors_found': {
      'en': 'Doctors found:',
      'ar': 'تم العثور على طبيب:',
    },
    'notes': {
      'en': 'Notes',
      'ar': 'ملاحظات',
    },
    'no_doctors_found': {
      'en': 'No Doctors Found',
      'ar': 'لم يتم العثور على أطباء',
    },
    'no_doctors_found_message': {
      'en': 'There are no doctors available in this specialty at the moment.',
      'ar': 'لا يوجد أطباء متاحين في هذا التخصص في الوقت الحالي.',
    },
    'tap_to_view': {
      'en': 'Tap to View',
      'ar': 'انقر للعرض',
    },

    // Common medical terms
    'coronary_artery_disease': {
      'en': 'Coronary Artery Disease',
      'ar': 'مرض الشريان التاجي',
    },
    'migraine': {
      'en': 'Migraine Disorder',
      'ar': 'اضطراب الصداع النصفي',
    },
    'childhood_immunization': {
      'en': 'Childhood Immunization',
      'ar': 'تطعيم الأطفال',
    },
    'knee_injury': {
      'en': 'Knee Ligament Injury',
      'ar': 'إصابة أربطة الركبة',
    },
    'acne': {
      'en': 'Severe Acne',
      'ar': 'حب الشباب الشديد',
    },
    'anxiety': {
      'en': 'Generalized Anxiety Disorder',
      'ar': 'اضطراب القلق العام',
    },
    'lymphoma': {
      'en': 'Early Stage Lymphoma',
      'ar': 'سرطان الغدد الليمفاوية في المرحلة المبكرة',
    },
    'acid_reflux': {
      'en': 'Chronic Acid Reflux',
      'ar': 'ارتجاع المريء المزمن',
    },

    // Common treatments
    'medication': {
      'en': 'Medication',
      'ar': 'الأدوية',
    },
    'adherence': {
      'en': 'Adherence',
      'ar': 'التزام بالادوية',
    },
    'next_dose': {
      'en': 'Next Dose',
      'ar': 'الدواء التالي',
    },
    'physical_therapy': {
      'en': 'Physical Therapy',
      'ar': 'العلاج الطبيعي',
    },
    'vaccination': {
      'en': 'Vaccination',
      'ar': 'التطعيم',
    },
    'lifestyle_changes': {
      'en': 'Lifestyle Modification',
      'ar': 'تعديل نمط الحياة',
    },
    'cognitive_therapy': {
      'en': 'Cognitive Behavioral Therapy',
      'ar': 'العلاج السلوكي المعرفي',
    },
    'chemotherapy': {
      'en': 'Chemotherapy',
      'ar': 'العلاج الكيميائي',
    },
    'dietary_changes': {
      'en': 'Dietary Modification',
      'ar': 'تعديل النظام الغذائي',
    },

    // Medical Specialties
    'general_practitioner': {
      'en': 'General Practitioner',
      'ar': 'طبيب عام',
    },
    'internal_medicine': {
      'en': 'Internal Medicine',
      'ar': 'الطب الباطني',
    },
    'cardiologist': {
      'en': 'Cardiologist',
      'ar': 'طبيب القلب',
    },
    'endocrinologist': {
      'en': 'Endocrinologist',
      'ar': 'طبيب الغدد الصماء',
    },
    'hematologist': {
      'en': 'Hematologist',
      'ar': 'طبيب أمراض الدم',
    },
    'gastroenterologist': {
      'en': 'Gastroenterologist',
      'ar': 'طبيب الجهاز الهضمي',
    },
    'urologist': {
      'en': 'Urologist',
      'ar': 'طبيب المسالك البولية',
    },
    'nephrologist': {
      'en': 'Nephrologist',
      'ar': 'طبيب الكلى',
    },
    'pulmonologist': {
      'en': 'Pulmonologist',
      'ar': 'طبيب الرئة',
    },
    'obgyn': {
      'en': 'Obstetrician & Gynecologist',
      'ar': 'طبيب النساء والتوليد',
    },
    'pediatrician': {
      'en': 'Pediatrician',
      'ar': 'طبيب الأطفال',
    },
    'psychiatrist': {
      'en': 'Psychiatrist',
      'ar': 'طبيب نفسي',
    },
    'dermatologist': {
      'en': 'Dermatologist',
      'ar': 'طبيب الجلدية',
    },
    'allergist_immunologist': {
      'en': 'Allergist & Immunologist',
      'ar': 'طبيب الحساسية والمناعة',
    },
    'oncologist': {
      'en': 'Oncologist',
      'ar': 'طبيب الأورام',
    },
    'rheumatologist': {
      'en': 'Rheumatologist',
      'ar': 'طبيب الروماتيزم',
    },
    'pain_specialist': {
      'en': 'Pain Management Specialist',
      'ar': 'أخصائي علاج الألم',
    },
    'specialities': {
      'en': 'Specialities',
      'ar': 'التخصصات',
    },
    'years_of_experience': {
      'en': 'Years of Experience:',
      'ar': 'عدد سنين الخبرة:',
    },

    // Additional login screen translations
    'please_enter_email': {
      'en': 'Please enter your card id',
      'ar': 'الرجاء إدخال معرف البطاقة',
    },
    'please_enter_password': {
      'en': 'Please enter your password',
      'ar': 'الرجاء إدخال كلمة المرور',
    },
    'card_id': {
      'en': 'Card ID',
      'ar': 'معرف البطاقة',
    },
    'email_empty_error': {
      'en': 'Email cannot be empty',
      'ar': 'البريد الإلكتروني لا يمكن أن يكون فارغًا',
    },
    'password_empty_error': {
      'en': 'Password cannot be empty',
      'ar': 'كلمة المرور لا يمكن أن تكون فارغة',
    },
    'general_error': {
      'en': 'An error occurred',
      'ar': 'حدث خطأ',
    },
    'authentication_successful': {
      'en': 'Authentication successful!',
      'ar': 'تم التحقق بنجاح!',
    },
    'user_not_found': {
      'en': 'User not found',
      'ar': 'المستخدم غير موجود',
    },
    'invalid_email': {
      'en': 'Invalid email address',
      'ar': 'عنوان البريد الإلكتروني غير صالح',
    },
    'wrong_password': {
      'en': 'Incorrect password',
      'ar': 'كلمة مرور غير صحيحة',
    },
    'auth_error': {
      'en': 'Authentication error',
      'ar': 'خطأ في المصادقة',
    },
    'password_reset_email_sent': {
      'en': 'Password reset email sent. Please check your inbox.',
      'ar':
          'تم إرسال بريد إلكتروني لإعادة تعيين كلمة المرور. يرجى التحقق من صندوق الوارد الخاص بك.',
    },
    'forgot_password': {
      'en': 'Forgot Password?',
      'ar': 'نسيت كلمة المرور؟',
    },
    'app_description': {
      'en':
          'stores and displays your medical records\nfor instant access anytime.',
      'ar': 'يخزن ويعرض سجلاتك الطبية\nللوصول الفوري في أي وقت.',
    },
    'or_continue_with': {
      'en': 'or continue with',
      'ar': 'أو تابع باستخدام',
    },
    'login_with_card': {
      'en': 'Login with:\nCard',
      'ar': 'تسجيل الدخول\nبالبطاقة',
    },
    'login_with_qr': {
      'en': 'Login with:\nQR code',
      'ar': 'تسجيل الدخول\nبرمز QR',
    },
    'qr_login_coming_soon': {
      'en': 'QR Code login coming soon!',
      'ar': 'تسجيل الدخول برمز QR قريبًا!',
    },
    'dont_have_account': {
      'en': "Don't have an account?",
      'ar': 'ليس لديك حساب؟',
    },
    'register': {
      'en': 'Register',
      'ar': 'تسجيل',
    },
    // Password reset dialog translations
    'reset_password': {
      'en': 'Reset Password',
      'ar': 'إعادة تعيين كلمة المرور',
    },
    'reset_password_instructions': {
      'en': 'Enter your email address to receive password reset instructions',
      'ar': 'أدخل عنوان بريدك الإلكتروني لتلقي تعليمات إعادة تعيين كلمة المرور'
    },
    // Reminder page translations
    'medical_reminders': {'en': 'Medical Reminders', 'ar': 'التذكيرات الطبية'},
    'search_reminders': {'en': 'Search reminders', 'ar': 'البحث في التذكيرات'},
    'no_reminders_yet': {'en': 'No reminders yet', 'ar': 'لا توجد تذكيرات بعد'},
    'no_matching_reminders': {
      'en': 'No matching reminders',
      'ar': 'لا توجد تذكيرات مطابقة'
    },
    'add_first_medication_reminder': {
      'en': 'Add your first medication reminder',
      'ar': 'أضف أول تذكير دوائي'
    },
    'try_changing_search_terms': {
      'en': 'Try changing your search terms',
      'ar': 'حاول تغيير مصطلحات البحث'
    },
    'please_fill_fields': {
      'en': 'Please fill in all fields',
      'ar': 'يرجى ملء جميع الحقول'
    },
    'reminder_added': {
      'en': 'Reminder added successfully',
      'ar': 'تمت إضافة التذكير بنجاح'
    },
    'reminder_deleted': {'en': 'Reminder deleted', 'ar': 'تم حذف التذكير'},
    'undo': {'en': 'Undo', 'ar': 'تراجع'},
    'edit_reminder': {'en': 'Edit Reminder', 'ar': 'تعديل التذكير'},
    'update_reminder_details': {
      'en': 'Update the reminder details',
      'ar': 'تحديث تفاصيل التذكير'
    },
    'update': {'en': 'Update', 'ar': 'تحديث'},
    'confirm': {'en': 'Confirm', 'ar': 'تأكيد'},
    'delete_reminder_confirm': {
      'en': 'Are you sure you want to delete this reminder?',
      'ar': 'هل أنت متأكد أنك تريد حذف هذا التذكير؟'
    },
    'all': {'en': 'All', 'ar': 'الكل'},
    'active': {'en': 'Active', 'ar': 'نشط'},
    'completed': {'en': 'Completed', 'ar': 'مكتمل'},
    'email_address': {
      'en': 'Email address',
      'ar': 'عنوان البريد الإلكتروني',
    },
    'please_enter_email_address': {
      'en': 'Please enter your email address',
      'ar': 'الرجاء إدخال عنوان بريدك الإلكتروني',
    },
    'no_user_with_email': {
      'en': 'No user found with this email',
      'ar': 'لم يتم العثور على مستخدم بهذا البريد الإلكتروني',
    },
    'error': {
      'en': 'Error',
      'ar': 'خطأ',
    },
    'reset': {
      'en': 'Reset',
      'ar': 'إعادة تعيين',
    },
    // NFC dialog translations
    'checking_nfc': {
      'en': 'Checking NFC availability...',
      'ar': 'جاري التحقق من توفر NFC...',
    },
    'tap_card': {
      'en': 'Please tap your authentication card on the back of your phone.',
      'ar': 'يرجى النقر ببطاقة المصادقة على ظهر هاتفك.',
    },
    'nfc_unavailable': {
      'en': 'NFC is not available on this device.',
      'ar': 'NFC غير متوفر على هذا الجهاز.',
    },
    'error_checking_nfc': {
      'en': 'Error checking NFC:\n maybe it is not available on this device',
      'ar': 'خطأ في التحقق من NFC:\n ربما لا يكون متاحًا على هذا الجهاز',
    },
    'card_authentication': {
      'en': 'Card Authentication',
      'ar': 'المصادقة بالبطاقة',
    },
    'waiting_for_card': {
      'en': 'Waiting for card...',
      'ar': 'في انتظار البطاقة...',
    },
    // NFC error messages
    'tag_not_support_ndef': {
      'en': 'This tag does not support NDEF format',
      'ar': 'هذه البطاقة لا تدعم تنسيق NDEF',
    },
    'error_reading_nfc_data': {
      'en': 'Error reading NFC data',
      'ar': 'خطأ في قراءة بيانات NFC',
    },
    'no_ndef_records': {
      'en': 'No NDEF records found on tag',
      'ar': 'لم يتم العثور على سجلات NDEF على البطاقة',
    },
    'empty_payload_text': {
      'en': 'Empty payload in text record',
      'ar': 'محتوى فارغ في سجل النص',
    },
    'payload_too_short': {
      'en': 'Payload too short for text record',
      'ar': 'المحتوى قصير جدًا لسجل النص',
    },
    'empty_payload': {
      'en': 'Empty payload',
      'ar': 'محتوى فارغ',
    },
    'cannot_read_text_from_nfc': {
      'en': 'Could not read text from NFC tag',
      'ar': 'تعذر قراءة النص من بطاقة NFC',
    },
    'empty_token_text': {
      'en': 'Empty token text extracted from NFC tag',
      'ar': 'نص رمز فارغ مستخرج من بطاقة NFC',
    },
    'error_extracting_data': {
      'en': 'Error extracting data from NFC tag',
      'ar': 'خطأ في استخراج البيانات من بطاقة NFC',
    },
    'error_reading_card': {
      'en': 'Error reading card',
      'ar': 'خطأ في قراءة البطاقة',
    },
    'nfc_error': {
      'en': 'NFC error',
      'ar': 'خطأ في NFC',
    },
    'error_starting_nfc': {
      'en': 'Error starting NFC',
      'ar': 'خطأ في بدء NFC',
    },
    'invalid_auth_token': {
      'en': 'Not a valid authentication token',
      'ar': 'رمز المصادقة غير صالح',
    },
    'invalid_token_format': {
      'en': 'Invalid token format',
      'ar': 'تنسيق الرمز غير صالح',
    },
    'auth_token_expired': {
      'en': 'Authentication token expired',
      'ar': 'انتهت صلاحية رمز المصادقة',
    },
    'invalid_token_signature': {
      'en': 'Invalid token signature',
      'ar': 'توقيع الرمز غير صالح',
    },
    'authentication_error': {
      'en': 'Authentication error',
      'ar': 'خطأ في المصادقة',
    },
    // NFC authentication failures
    'failed_to_authenticate_with_nfc': {
      'en':
          'Failed to authenticate with NFC token - please contact support for proper card configuration',
      'ar':
          'فشل المصادقة باستخدام رمز NFC - يرجى الاتصال بالدعم للحصول على تكوين البطاقة المناسب',
    },
    'card_auth_failed': {
      'en': 'Card authentication failed',
      'ar': 'فشلت المصادقة بالبطاقة',
    },
    'failed_card_auth': {
      'en': 'Failed to authenticate with card',
      'ar': 'فشل في المصادقة بالبطاقة',
    },

    // Signup page translations
    'create_account': {
      'en': 'Create Account',
      'ar': 'إنشاء حساب',
    },
    'register_step_1': {
      'en': 'Step 1: Register your account details',
      'ar': 'الخطوة 1: تسجيل تفاصيل حسابك',
    },
    'please_confirm_password': {
      'en': 'Please confirm your password',
      'ar': 'الرجاء تأكيد كلمة المرور',
    },
    'name_empty_error': {
      'en': 'Name cannot be empty',
      'ar': 'الاسم لا يمكن أن يكون فارغًا',
    },
    'passwords_dont_match': {
      'en': 'Passwords do not match',
      'ar': 'كلمات المرور غير متطابقة',
    },
    'password_too_short': {
      'en': 'Password must be at least 6 characters',
      'ar': 'يجب أن تكون كلمة المرور 6 أحرف على الأقل',
    },
    'invalid_email_format': {
      'en': 'Invalid email format',
      'ar': 'صيغة البريد الإلكتروني غير صالحة',
    },
    'email_in_use': {
      'en': 'Email already in use',
      'ar': 'البريد الإلكتروني مستخدم بالفعل',
    },
    'registration_error': {
      'en': 'Registration error',
      'ar': 'خطأ في التسجيل',
    },
    'password_too_weak': {
      'en': 'Password is too weak',
      'ar': 'كلمة المرور ضعيفة جدًا',
    },
    'select_role': {
      'en': 'Select your role',
      'ar': 'اختر دورك',
    },
    'confirm_password': {
      'en': 'Confirm Password',
      'ar': 'تأكيد كلمة المرور',
    },
    'terms_agreement': {
      'en':
          'By registering, you agree to our Terms of Service and Privacy Policy',
      'ar': 'بالتسجيل، فإنك توافق على شروط الخدمة وسياسة الخصوصية الخاصة بنا',
    },
    'already_have_account': {
      'en': 'Already have an account?',
      'ar': 'هل لديك حساب بالفعل؟',
    },
    'email_password_not_enabled': {
      'en': 'Email/password authentication is not enabled.',
      'ar': 'المصادقة بالبريد الإلكتروني/كلمة المرور غير ممكّنة.',
    },
    'registration_failed': {
      'en': 'Registration failed. Please try again.',
      'ar': 'فشل التسجيل. يرجى المحاولة مرة أخرى.',
    },
    'account_creation_error': {
      'en': 'Error creating account. Please try again.',
      'ar': 'خطأ في إنشاء الحساب. يرجى المحاولة مرة أخرى.',
    },

    // Medical Information Page
    'medical_information': {
      'en': 'Medical Information',
      'ar': 'المعلومات الطبية',
    },
    'complete_your_profile': {
      'en': 'Complete Your Profile',
      'ar': 'أكمل ملفك الشخصي',
    },
    'complete_profile': {
      'en': 'Complete Profile',
      'ar': 'أكمل الملف الشخصي',
    },
    'step3_provide_medical': {
      'en':
          'Step 3: Provide your medical information to complete your profile.',
      'ar': 'الخطوة 3: قدم معلوماتك الطبية لإكمال ملفك الشخصي.',
    },
    'welcome_user': {
      'en': 'Welcome, {name}!',
      'ar': 'مرحبًا، {name}!',
    },
    'enter_phone': {
      'en': 'Enter your phone number',
      'ar': 'أدخل رقم هاتفك',
    },
    'phone_required': {
      'en': 'Phone number is required',
      'ar': 'رقم الهاتف مطلوب',
    },
    'enter_address': {
      'en': 'Enter your address',
      'ar': 'أدخل عنوانك',
    },
    'address_required': {
      'en': 'Address is required',
      'ar': 'العنوان مطلوب',
    },
    'enter_national_id': {
      'en': 'Enter your national ID (optional)',
      'ar': 'أدخل هويتك الوطنية (اختياري)',
    },
    'national_id': {
      'en': 'National ID',
      'ar': 'الهوية الوطنية',
    },
    'gender': {
      'en': 'Gender',
      'ar': 'الجنس',
    },
    'male': {
      'en': 'Male',
      'ar': 'ذكر',
    },
    'female': {
      'en': 'Female',
      'ar': 'أنثى',
    },
    'medical_conditions': {
      'en': 'Medical Conditions',
      'ar': 'الحالات الطبية',
    },
    'have_asthma': {
      'en': 'Do you have asthma?',
      'ar': 'هل لديك ربو؟',
    },
    'have_diabetes': {
      'en': 'Do you have diabetes?',
      'ar': 'هل لديك سكري؟',
    },
    'yes': {
      'en': 'Yes',
      'ar': 'نعم',
    },
    'no': {
      'en': 'No',
      'ar': 'لا',
    },
    'blood_type': {
      'en': 'Blood Type',
      'ar': 'فصيلة الدم',
    },
    'a+': {
      'en': 'A+',
      'ar': 'A+',
    },
    'a-': {
      'en': 'A-',
      'ar': 'A-',
    },
    'b+': {
      'en': 'B+',
      'ar': 'B+',
    },
    'b-': {
      'en': 'B-',
      'ar': 'B-',
    },
    'ab+': {
      'en': 'AB+',
      'ar': 'AB+',
    },
    'ab-': {
      'en': 'AB-',
      'ar': 'AB-',
    },
    'o+': {
      'en': 'O+',
      'ar': 'O+',
    },
    'o-': {
      'en': 'O-',
      'ar': 'O-',
    },

    // Profile Image Page
    'profile_picture': {
      'en': 'Profile Picture',
      'ar': 'الصورة الشخصية',
    },
    'add_profile_picture': {
      'en': 'Add Your Profile Picture',
      'ar': 'أضف صورتك الشخصية',
    },
    'profile_picture_description': {
      'en':
          'This will help others recognize you and personalize your experience',
      'ar': 'هذا سيساعد الآخرين على التعرف عليك وتخصيص تجربتك',
    },
    'tap_add_photo': {
      'en': 'Tap to add photo',
      'ar': 'انقر لإضافة صورة',
    },
    'taken': {
      'en': 'Taken',
      'ar': 'مأخوذ',
    },
    'skip_for_now': {
      'en': 'Skip for now',
      'ar': 'تخطي الآن',
    },
    'choose_option': {
      'en': 'Choose an option',
      'ar': 'اختر خيارًا',
    },
    'pick_gallery': {
      'en': 'Pick from Gallery',
      'ar': 'اختر من المعرض',
    },
    'take_photo': {
      'en': 'Take a Photo',
      'ar': 'التقط صورة',
    },
    'today_progress': {
      'en': 'Today\'s Progress',
      'ar': 'تقدم اليوم',
    },
    'permission_required': {
      'en': '{type} permission is required. Please enable it in app settings.',
      'ar': 'إذن {type} مطلوب. يرجى تمكينه في إعدادات التطبيق.',
    },
    'settings': {
      'en': 'Settings',
      'ar': 'الإعدادات',
    },
    'retry': {
      'en': 'Retry',
      'ar': 'إعادة المحاولة',
    },
    'empty_image_error': {
      'en': 'Selected image appears to be empty. Please try another image.',
      'ar': 'تبدو الصورة المحددة فارغة. يرجى تجربة صورة أخرى.',
    },
    'image_access_error': {
      'en': 'Could not access the selected image. Please try again.',
      'ar': 'تعذر الوصول إلى الصورة المحددة. يرجى المحاولة مرة أخرى.',
    },
    'image_processing_error': {
      'en': 'Error processing the selected image. Please try again.',
      'ar': 'خطأ في معالجة الصورة المحددة. يرجى المحاولة مرة أخرى.',
    },
    'image_selection_error': {
      'en': 'Couldn\'t select image. Please try again.',
      'ar': 'تعذر تحديد الصورة. يرجى المحاولة مرة أخرى.',
    },
    'empty_photo_error': {
      'en': 'Captured photo appears to be empty. Please try again.',
      'ar': 'تبدو الصورة الملتقطة فارغة. يرجى المحاولة مرة أخرى.',
    },
    'photo_access_error': {
      'en': 'Could not access the captured photo. Please try again.',
      'ar': 'تعذر الوصول إلى الصورة الملتقطة. يرجى المحاولة مرة أخرى.',
    },
    'photo_processing_error': {
      'en': 'Error processing the captured photo. Please try again.',
      'ar': 'خطأ في معالجة الصورة الملتقطة. يرجى المحاولة مرة أخرى.',
    },
    'photo_capture_error': {
      'en': 'Couldn\'t take photo. Please try again.',
      'ar': 'تعذر التقاط الصورة. يرجى المحاولة مرة أخرى.',
    },
    'select_profile_image_first': {
      'en': 'Please select a profile image first',
      'ar': 'يرجى تحديد صورة الملف الشخصي أولاً',
    },
    'image_upload_failed': {
      'en': 'Failed to upload image. Please try again. Error: {error}',
      'ar': 'فشل تحميل الصورة. يرجى المحاولة مرة أخرى. خطأ: {error}',
    },
    'no_image_selected': {
      'en': 'No image file selected',
      'ar': 'لم يتم اختيار ملف الصورة',
    },
    'image_empty': {
      'en': 'Image is empty',
      'ar': 'الصورة فارغة',
    },
    'image_too_large': {
      'en': 'Image size is too large. Please select a smaller image.',
      'ar': 'حجم الصورة كبير جدًا. يرجى تحديد صورة أصغر.',
    },
    'profile_image_processed': {
      'en': 'Profile image processed successfully!',
      'ar': 'تمت معالجة صورة الملف الشخصي بنجاح!',
    },

    // Splash Screens
    'splash1_title': {
      'en': 'Instant Access to Your Medical Records',
      'ar': 'وصول فوري إلى سجلاتك الطبية',
    },
    'splash1_description': {
      'en':
          'Securely access your complete medical history anytime, anywhere with a simple NFC tap.',
      'ar':
          'الوصول الآمن إلى تاريخك الطبي الكامل في أي وقت وأي مكان بنقرة NFC بسيطة.',
    },
    'splash2_title': {
      'en': 'Seamless Doctor-Patient Management',
      'ar': 'إدارة سلسة بين الطبيب والمريض',
    },
    'splash2_description': {
      'en':
          'Doctors can assign, update, and review patient medical records instantly using CardoCard\'s NFC system.',
      'ar':
          'يمكن للأطباء تعيين وتحديث ومراجعة السجلات الطبية للمرضى فورًا باستخدام نظام NFC من كاردوكارد.',
    },
    'splash3_title': {
      'en': 'Secure & Private Connect to your Health Data',
      'ar': 'اتصال آمن وخاص ببياناتك الصحية',
    },
    'splash3_description': {
      'en':
          'With encrypted NFC technology, only authorized personnel can access and update your medical records.',
      'ar':
          'باستخدام تقنية NFC المشفرة، يمكن للموظفين المصرح لهم فقط الوصول إلى سجلاتك الطبية وتحديثها.',
    },
    'get_started': {
      'en': 'Get Started',
      'ar': 'ابدأ الآن',
    },
  };

  // Get translated value for a key
  String translate(String key) {
    if (!_localizedValues.containsKey(key)) {
      return key; // Return the key itself if no translation exists
    }

    return _localizedValues[key]?[languageCode] ??
        _localizedValues[key]?['en'] ??
        key;
  }
}

// Delegate for loading the localizations
class AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return ['en', 'ar'].contains(locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) {
    return AppLocalizations.load(locale);
  }

  @override
  bool shouldReload(AppLocalizationsDelegate old) => false;
}

// Extension on BuildContext for easier access to translations
extension LocalizationExtension on BuildContext {
  AppLocalizations get tr =>
      AppLocalizations.of(this) ?? const AppLocalizations(Locale('en'));

  // Convenience method for translating strings
  String translate(String key) {
    return tr.translate(key);
  }
}
