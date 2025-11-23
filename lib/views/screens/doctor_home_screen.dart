import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../core/themes/app_colors.dart';
import '../../view_models/doctor_profile_view_model.dart';
import '../../view_models/doctor_home_view_model.dart';
import 'profile/doctor_profile_view.dart';

class DoctorHomeScreen extends StatefulWidget {
  const DoctorHomeScreen({super.key});

  @override
  State<DoctorHomeScreen> createState() => _DoctorHomeScreenState();
}

class _DoctorHomeScreenState extends State<DoctorHomeScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (mounted) {
        Provider.of<DoctorProfileViewModel>(context, listen: false).fetchProfile();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => DoctorHomeViewModel()..fetchOverview(),
      child: Scaffold(
        backgroundColor: AppColors.lightGrey,
        body: Consumer2<DoctorProfileViewModel, DoctorHomeViewModel>(
          builder: (context, profileVM, homeVM, child) {
            return Column(
              children: [
                // 1. Clean Header (No Search, No Notification)
                _buildHeaderSection(context, profileVM),

                // 2. Spacing between header and stats
                const SizedBox(height: 20),

                // 3. Stats Overview
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      _buildStatCard('Today', homeVM.todayCount.toString(), Icons.calendar_today, AppColors.primaryBlue),
                      const SizedBox(width: 12),
                      _buildStatCard('Upcoming', homeVM.upcomingCount.toString(), Icons.access_time_filled, AppColors.warning),
                      const SizedBox(width: 12),
                      _buildStatCard('Patients', homeVM.totalPatients.toString(), Icons.people_alt, AppColors.secondaryGreen),
                    ],
                  ),
                ),

                // 4. Section Title
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Upcoming Appointments',
                        style: TextStyle(
                          color: AppColors.textDark,
                          fontSize: 18, 
                          fontWeight: FontWeight.bold
                        ),
                      ),
                      TextButton(
                        onPressed: () {}, 
                        child: const Text('See All', style: TextStyle(color: AppColors.primaryBlue))
                      ),
                    ],
                  ),
                ),

                // 5. Appointment List
                Expanded(
                  child: homeVM.isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : homeVM.upcomingAppointments.isEmpty
                          ? _buildEmptyState()
                          : ListView.separated(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              itemCount: homeVM.upcomingAppointments.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 12),
                              itemBuilder: (context, index) {
                                return _buildAppointmentCard(homeVM.upcomingAppointments[index]);
                              },
                            ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  // --- WIDGET BUILDERS ---

  Widget _buildHeaderSection(BuildContext context, DoctorProfileViewModel profileVM) {
    // Removed Stack and Search Bar logic, kept simple container
    return Container(
      padding: const EdgeInsets.only(top: 60, left: 20, right: 20, bottom: 24),
      decoration: const BoxDecoration(
        color: AppColors.primaryBlue,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: GestureDetector(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => DoctorProfileView())),
        child: Row(
          children: [
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: CircleAvatar(
                radius: 28, // Slightly larger since it's the main focus now
                backgroundColor: Colors.white.withOpacity(0.2),
                backgroundImage: profileVM.profileImageUrl != null && profileVM.profileImageUrl!.isNotEmpty
                    ? NetworkImage(profileVM.profileImageUrl!)
                    : null,
                child: profileVM.profileImageUrl == null || profileVM.profileImageUrl!.isEmpty
                    ? const Icon(Icons.person, color: Colors.white, size: 32)
                    : null,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Welcome back,', style: TextStyle(color: Colors.white70, fontSize: 14)),
                  Text(
                    profileVM.nameController.text.isNotEmpty
                        ? 'Dr. ${profileVM.nameController.text}'
                        : 'Doctor',
                    style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            // Notification Button Removed here
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: const TextStyle(
                fontSize: 22, 
                fontWeight: FontWeight.bold, 
                color: AppColors.textDark
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                color: AppColors.textLight, 
                fontSize: 12, 
                fontWeight: FontWeight.w500
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildAppointmentCard(dynamic appt) {
    final timeStr = DateFormat('hh:mm a').format(appt.dateTime);
    final dateStr = DateFormat('MMM d').format(appt.dateTime);

    Color statusColor;
    switch (appt.status.toLowerCase()) {
      case 'confirmed': statusColor = AppColors.secondaryGreen; break;
      case 'pending': statusColor = AppColors.warning; break;
      case 'cancelled': statusColor = AppColors.error; break;
      default: statusColor = AppColors.primaryBlue;
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: () { /* TODO: Open Details */ },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                // Date Box
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                  decoration: BoxDecoration(
                    color: AppColors.lightGrey,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Text(dateStr.split(' ')[0], style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textLight)),
                      Text(dateStr.split(' ')[1], style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primaryBlue)),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                
                // Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        appt.patientName,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textDark),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.access_time, size: 14, color: AppColors.textLight),
                          const SizedBox(width: 4),
                          Text(timeStr, style: const TextStyle(fontSize: 13, color: AppColors.textLight)),
                        ],
                      ),
                    ],
                  ),
                ),

                // Status Badge
                  Column(
                    children: [
                      if (appt.status.toLowerCase() != 'pending')
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            appt.status,
                            style: TextStyle(
                              color: statusColor,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.event_available_outlined, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            'No upcoming appointments',
            style: TextStyle(color: Colors.grey[600], fontSize: 16),
          ),
        ],
      ),
    );
  }
}