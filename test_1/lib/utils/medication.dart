import 'package:flutter/material.dart';

class Medication {
  final String name;
  final String dosage;
  final String instructions;
  final List<TimeOfDay> times;
  bool taken;

  Medication({
    required this.name,
    required this.dosage,
    required this.instructions,
    required this.times,
    this.taken = false,
  });
}
