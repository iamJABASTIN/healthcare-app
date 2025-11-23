import 'package:flutter/material.dart';
import '../../core/themes/app_colors.dart';

class DoctorScaffold extends StatelessWidget {
  final Widget body;
  final int currentIndex;
  final Function(int) onTabChanged;
  final String title;
  final List<Widget>? actions;

  const DoctorScaffold({
    super.key,
    required this.body,
    required this.currentIndex,
    required this.onTabChanged,
    this.title = '',
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightGrey,
      appBar: title.isNotEmpty
          ? AppBar(
              title: Text(title),
              backgroundColor: AppColors.primaryBlue,
              foregroundColor: Colors.white,
              actions: actions,
            )
          : null,
      body: body,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: onTabChanged,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppColors.primaryBlue,
        unselectedItemColor: AppColors.textLight,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today),
            label: 'Appointments',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.access_time),
            label: 'Availability',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}
