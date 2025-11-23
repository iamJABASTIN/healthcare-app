import 'package:flutter/material.dart';
import 'patient_home_screen.dart';
import 'patient_appointments_screen.dart';
import 'profile/patient_profile_screen.dart';
import '../widgets/patient_scaffold.dart';

class PatientNavigation extends StatefulWidget {
  const PatientNavigation({super.key});

  @override
  State<PatientNavigation> createState() => _PatientNavigationState();
}

class _PatientNavigationState extends State<PatientNavigation> {
  int _currentIndex = 0;

  final List<String> _titles = [
    '',
    'My Bookings',
    '',
  ];

  @override
  Widget build(BuildContext context) {
    return PatientScaffold(
      title: _titles[_currentIndex],
      currentIndex: _currentIndex,
      onTabChanged: (index) {
        setState(() {
          _currentIndex = index;
        });
      },
      body: IndexedStack(
        index: _currentIndex,
        children: [
          PatientHomeScreen(onTabChanged: (index) {
            setState(() {
              _currentIndex = index;
            });
          }),
          const PatientAppointmentsScreen(),
          const PatientProfileScreen(),
        ],
      ),
    );
  }
}
