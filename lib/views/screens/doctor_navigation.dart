import 'package:flutter/material.dart';
import 'doctor_home_screen.dart';
import 'doctor_appointments_screen.dart';
import 'post_availability_screen.dart';
import 'profile/doctor_profile_view.dart';
import '../widgets/doctor_scaffold.dart';

class DoctorNavigation extends StatefulWidget {
  const DoctorNavigation({super.key});

  @override
  State<DoctorNavigation> createState() => _DoctorNavigationState();
}

class _DoctorNavigationState extends State<DoctorNavigation> {
  int _currentIndex = 0;

  // Define screen titles
  final List<String> _titles = [
    '', // Home screen has its own custom header
    '', // Appointments has its own AppBar
    'Post Availability',
    '', // Profile has its own AppBar
  ];

  @override
  Widget build(BuildContext context) {
    return DoctorScaffold(
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
          DoctorHomeScreen(),
          DoctorAppointmentsScreen(),
          PostAvailabilityScreen(),
          DoctorProfileView(),
        ],
      ),
    );
  }
}
