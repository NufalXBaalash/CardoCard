// ignore_for_file: use_full_hex_values_for_flutter_colors

import 'package:flutter/material.dart';

class Specializations_DB {
  List Categories = [
    {
      "category": "Heart",
      "translation_key": "cardiology",
      "icon": "lib/images/icons8-heartbeat-90.png",
      "color": Color(0xffFF8484),
    },
    {
      "category": "Bone",
      "translation_key": "orthopedics",
      "icon": "lib/images/icons8-bone-100.png",
      "color": Color(0xFFFFD062),
    },
    {
      "category": "Nutrition",
      "translation_key": "nutrition",
      "icon": "lib/images/icons8-apple-fruit-100.png",
      "color": Color(0xFFAEF99D),
    },
    {
      "category": "Tooth",
      "translation_key": "dentistry",
      "icon": "lib/images/icons8-tooth-64.png",
      "color": Color(0xFF7EAFFF),
    },
    {
      "category": "Disease",
      "translation_key": "disease",
      "icon": "lib/images/icons8-disease-64.png",
      "color": Color(0xFFE28BFF),
    },
    {
      "category": "Lungs",
      "translation_key": "pulmonology",
      "icon": "lib/images/icons8-lung-100.png",
      "color": Color.fromARGB(255, 255, 143, 124),
    }
  ];
  List Health_overview = [
    {
      "title": "Blood Type",
      "translation_key": "blood_type",
      "icon": "lib/images/icons8-drop-of-blood-100.png",
      "description": "",
      "status_color": Color(0xffFF0404),
      "color": Color(0xffFFF1F2)
    },
    {
      "title": "Diabetes",
      "translation_key": "diabetes",
      "icon": "lib/images/icons8-hypertension-100.png",
      "description": "",
      "status_color": Color(0xffF87878),
      "color": Color(0xffF0EFFF)
    },
    {
      "title": "Asthma",
      "translation_key": "asthma",
      "icon": "lib/images/icons8-lung-100 (1).png",
      "description": "",
      "status_color": Color(0xff78C188),
      "color": Color(0xffEBF5FF)
    }
  ];

  // ignore: non_constant_identifier_names
  final List<Map<String, dynamic>> prescribingSpecialties = [
    {
      'name': 'General Practitioner',
      'icon': Icons.medical_services,
      'translation_key': 'general_practitioner'
    },
    {
      'name': 'Internal Medicine',
      'icon': Icons.local_hospital,
      'translation_key': 'internal_medicine'
    },
    {
      'name': 'Cardiologist',
      'icon': Icons.favorite,
      'translation_key': 'cardiologist'
    },
    {
      'name': 'Endocrinologist',
      'icon': Icons.bloodtype,
      'translation_key': 'endocrinologist'
    },
    {
      'name': 'Hematologist',
      'icon': Icons.bloodtype,
      'translation_key': 'hematologist'
    },
    {
      'name': 'Gastroenterologist',
      'icon': Icons.restaurant,
      'translation_key': 'gastroenterologist'
    },
    {
      'name': 'Urologist',
      'icon': Icons.water_drop,
      'translation_key': 'urologist'
    },
    {
      'name': 'Nephrologist',
      'icon': Icons.live_tv_rounded,
      'translation_key': 'nephrologist'
    },
    {
      'name': 'Pulmonologist',
      'icon': Icons.air,
      'translation_key': 'pulmonologist'
    },
    {
      'name': 'Obstetrician & Gynecologist',
      'icon': Icons.pregnant_woman,
      'translation_key': 'obgyn'
    },
    {
      'name': 'Pediatrician',
      'icon': Icons.child_care,
      'translation_key': 'pediatrician'
    },
    {
      'name': 'Psychiatrist',
      'icon': Icons.psychology,
      'translation_key': 'psychiatrist'
    },
    {
      'name': 'Dermatologist',
      'icon': Icons.face,
      'translation_key': 'dermatologist'
    },
    {
      'name': 'Allergist & Immunologist',
      'icon': Icons.coronavirus,
      'translation_key': 'allergist_immunologist'
    },
    {
      'name': 'Oncologist',
      'icon': Icons.biotech,
      'translation_key': 'oncologist'
    },
    {
      'name': 'Rheumatologist',
      'icon': Icons.accessibility,
      'translation_key': 'rheumatologist'
    },
    {
      'name': 'Pain Management Specialist',
      'icon': Icons.healing,
      'translation_key': 'pain_specialist'
    },
    {
      'name': 'Neurology',
      'icon': Icons.trending_neutral_rounded,
      'translation_key': 'neurology'
    },
  ];

  final List<Map<String, dynamic>> doctors = [
    {
      "id": "DR001",
      "name": "Dr. Emily Rodriguez",
      "name_ar": "د. إيملي رودريغيز",
      "specialty": "Cardiologist",
      "specialty_key": "cardiologist",
      "organization": "Central City Heart Institute",
      "organization_ar": "معهد القلب للمدينة المركزية",
      "medicalRecords": [
        {
          "patientId": "PT001",
          "patientName": "John Doe",
          "patientName_ar": "جون دو",
          "date": DateTime(2024, 3, 15),
          "diagnosis": "Coronary Artery Disease",
          "diagnosis_key": "coronary_artery_disease",
          "treatment": "Prescribed Statins and Lifestyle Modification",
          "treatment_key": "lifestyle_changes",
          "notes": "Regular cardiac monitoring required",
          "notes_ar": "مطلوب مراقبة القلب بانتظام"
        }
      ]
    },
    {
      "id": "DR002",
      "name": "Dr. Michael Chen",
      "name_ar": "د. مايكل تشن",
      "specialty": "Neurology",
      "specialty_key": "neurology",
      "organization": "Metropolitan Neurological Center",
      "organization_ar": "مركز الأعصاب المتروبوليتاني",
      "medicalRecords": [
        {
          "patientId": "PT002",
          "patientName": "Sarah Johnson",
          "patientName_ar": "سارة جونسون",
          "date": DateTime(2024, 3, 20),
          "diagnosis": "Migraine Disorder",
          "diagnosis_key": "migraine",
          "treatment": "Preventive Medication and Trigger Identification",
          "treatment_key": "medication",
          "notes": "Recommended stress management techniques",
          "notes_ar": "يوصى بتقنيات إدارة التوتر"
        }
      ]
    },
    {
      "id": "DR003",
      "name": "Dr. Sofia Patel",
      "name_ar": "د. صوفيا باتيل",
      "specialty": "Pediatrician",
      "specialty_key": "pediatrician",
      "organization": "Children's Regional Medical Center",
      "organization_ar": "المركز الطبي الإقليمي للأطفال",
      "medicalRecords": [
        {
          "patientId": "PT003",
          "patientName": "Emma Thompson",
          "patientName_ar": "إيما طومسون",
          "date": DateTime(2024, 3, 22),
          "diagnosis": "Childhood Immunization",
          "diagnosis_key": "childhood_immunization",
          "treatment": "Routine Vaccination Schedule",
          "treatment_key": "vaccination",
          "notes": "Child developing normally, all milestones met",
          "notes_ar": "الطفل ينمو بشكل طبيعي، وتم تحقيق جميع المراحل"
        }
      ]
    },
    {
      "id": "DR004",
      "name": "Dr. Alexander Wright",
      "name_ar": "د. ألكسندر رايت",
      "specialty": "Orthopedics",
      "specialty_key": "orthopedics",
      "organization": "Sports Medicine and Rehabilitation Center",
      "organization_ar": "مركز طب الرياضة وإعادة التأهيل",
      "medicalRecords": [
        {
          "patientId": "PT004",
          "patientName": "Mike Peterson",
          "patientName_ar": "مايك بيترسون",
          "date": DateTime(2024, 3, 18),
          "diagnosis": "Knee Ligament Injury",
          "diagnosis_key": "knee_injury",
          "treatment": "Physical Therapy and Rehabilitation Program",
          "treatment_key": "physical_therapy",
          "notes": "Recommended gradual return to sports activities",
          "notes_ar": "يوصى بالعودة التدريجية إلى الأنشطة الرياضية"
        }
      ]
    },
    {
      "id": "DR005",
      "name": "Dr. Olivia Martinez",
      "name_ar": "د. أوليفيا مارتينيز",
      "specialty": "Dermatologist",
      "specialty_key": "dermatologist",
      "organization": "Skin Health Clinic",
      "organization_ar": "عيادة صحة الجلد",
      "medicalRecords": [
        {
          "patientId": "PT005",
          "patientName": "Lisa Kim",
          "patientName_ar": "ليزا كيم",
          "date": DateTime(2024, 3, 25),
          "diagnosis": "Severe Acne",
          "diagnosis_key": "acne",
          "treatment": "Topical and Oral Medication Plan",
          "treatment_key": "medication",
          "notes": "Follow-up in 6 weeks to assess treatment effectiveness",
          "notes_ar": "متابعة بعد 6 أسابيع لتقييم فعالية العلاج"
        }
      ]
    },
    {
      "id": "DR006",
      "name": "Dr. Daniel Kim",
      "name_ar": "د. دانيال كيم",
      "specialty": "Psychiatrist",
      "specialty_key": "psychiatrist",
      "organization": "Mental Wellness Institute",
      "organization_ar": "معهد العافية النفسية",
      "medicalRecords": [
        {
          "patientId": "PT006",
          "patientName": "Alex Rivera",
          "patientName_ar": "أليكس ريفيرا",
          "date": DateTime(2024, 3, 17),
          "diagnosis": "Generalized Anxiety Disorder",
          "diagnosis_key": "anxiety",
          "treatment": "Cognitive Behavioral Therapy and Medication Management",
          "treatment_key": "cognitive_therapy",
          "notes": "Recommended weekly therapy sessions",
          "notes_ar": "يوصى بجلسات علاجية أسبوعية"
        }
      ]
    },
    {
      "id": "DR007",
      "name": "Dr. Rachel Goldman",
      "name_ar": "د. راشيل غولدمان",
      "specialty": "Oncologist",
      "specialty_key": "oncologist",
      "organization": "Cancer Research and Treatment Center",
      "organization_ar": "مركز أبحاث وعلاج السرطان",
      "medicalRecords": [
        {
          "patientId": "PT007",
          "patientName": "David Chen",
          "patientName_ar": "ديفيد تشن",
          "date": DateTime(2024, 3, 23),
          "diagnosis": "Early Stage Lymphoma",
          "diagnosis_key": "lymphoma",
          "treatment": "Chemotherapy Treatment Plan",
          "treatment_key": "chemotherapy",
          "notes": "Comprehensive support system recommended",
          "notes_ar": "يوصى بنظام دعم شامل"
        }
      ]
    },
    {
      "id": "DR008",
      "name": "Dr. Thomas Anderson",
      "name_ar": "د. توماس أندرسون",
      "specialty": "Gastroenterologist",
      "specialty_key": "gastroenterologist",
      "organization": "Digestive Health Clinic",
      "organization_ar": "عيادة صحة الجهاز الهضمي",
      "medicalRecords": [
        {
          "patientId": "PT008",
          "patientName": "Maria Rodriguez",
          "patientName_ar": "ماريا رودريغيز",
          "date": DateTime(2024, 3, 21),
          "diagnosis": "Chronic Acid Reflux",
          "diagnosis_key": "acid_reflux",
          "treatment": "Dietary Modification and Medication",
          "treatment_key": "dietary_changes",
          "notes": "Detailed nutrition plan provided",
          "notes_ar": "تم تقديم خطة تغذية مفصلة"
        }
      ]
    },
    {
      "id": "DR009",
      "name": "Dr. Ahmed Baalash",
      "name_ar": "د. أحمد بعلش",
      "specialty": "Cardiologist",
      "specialty_key": "cardiologist",
      "organization": "Central City Heart Institute",
      "organization_ar": "معهد القلب للمدينة المركزية",
      "medicalRecords": [
        {
          "patientId": "PT001",
          "patientName": "John Doe",
          "patientName_ar": "جون دو",
          "date": DateTime(2024, 3, 15),
          "diagnosis": "Coronary Artery Disease",
          "diagnosis_key": "coronary_artery_disease",
          "treatment": "Prescribed Statins and Lifestyle Modification",
          "treatment_key": "lifestyle_changes",
          "notes": "Regular cardiac monitoring required",
          "notes_ar": "مطلوب مراقبة القلب بانتظام"
        }
      ]
    },
  ];
}
