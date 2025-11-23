import 'package:flutter/material.dart';
import '../../core/themes/app_colors.dart';

class PatientAppointmentsScreen extends StatefulWidget {
  const PatientAppointmentsScreen({super.key});

  @override
  State<PatientAppointmentsScreen> createState() => _PatientAppointmentsScreenState();
}

class _PatientAppointmentsScreenState extends State<PatientAppointmentsScreen> {
  @override
  void initState() {
    super.initState();
    // TODO: load patient appointments from ViewModel when available
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Appointments'),
        backgroundColor: AppColors.primaryBlue,
        foregroundColor: Colors.white,
      ),
      body: const Center(
        child: Text('No appointments yet'),
      ),
    );
  }
}
