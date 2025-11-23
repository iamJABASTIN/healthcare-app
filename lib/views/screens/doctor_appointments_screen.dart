import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/themes/app_colors.dart';
import '../../view_models/doctor_appointments_view_model.dart';

class DoctorAppointmentsScreen extends StatefulWidget {
  const DoctorAppointmentsScreen({super.key});

  @override
  State<DoctorAppointmentsScreen> createState() =>
      _DoctorAppointmentsScreenState();
}

class _DoctorAppointmentsScreenState extends State<DoctorAppointmentsScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      Provider.of<DoctorAppointmentsViewModel>(
        context,
        listen: false,
      ).fetchAppointments();
    });
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppColors.lightGrey,
        appBar: AppBar(
          title: const Text("My Appointments"),
          backgroundColor: AppColors.primaryBlue,
          foregroundColor: Colors.white,
          bottom: const TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.white,
            tabs: [
              Tab(icon: Icon(Icons.upcoming), text: "Upcoming"),
              Tab(icon: Icon(Icons.history), text: "Past"),
            ],
          ),
        ),
        body: Consumer<DoctorAppointmentsViewModel>(
          builder: (context, vm, child) {
            if (vm.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (vm.errorMessage != null) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Colors.grey,
                    ),
                    const SizedBox(height: 16),
                    Text(vm.errorMessage!),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: vm.fetchAppointments,
                      child: const Text("Retry"),
                    ),
                  ],
                ),
              );
            }

            return TabBarView(
              children: [
                _buildAppointmentsList(
                  vm.upcomingAppointments,
                  isUpcoming: true,
                ),
                _buildAppointmentsList(vm.pastAppointments, isUpcoming: false),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildAppointmentsList(
    List<AppointmentWithPatientDetails> appointments, {
    required bool isUpcoming,
  }) {
    if (appointments.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isUpcoming ? Icons.calendar_today : Icons.history,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              isUpcoming ? "No upcoming appointments" : "No past appointments",
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        final vm = Provider.of<DoctorAppointmentsViewModel>(
          context,
          listen: false,
        );
        if (isUpcoming) {
          await vm.fetchUpcomingAppointments();
        } else {
          await vm.fetchPastAppointments();
        }
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: appointments.length,
        itemBuilder: (context, index) {
          final item = appointments[index];
          final appointment = item.appointment;
          final profile = item.patientProfile;

          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: ExpansionTile(
              tilePadding: const EdgeInsets.all(16),
              childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              leading: CircleAvatar(
                backgroundColor: AppColors.primaryBlue,
                child: Text(
                  appointment.patientName[0].toUpperCase(),
                  style: const TextStyle(color: Colors.white),
                ),
              ),
              title: Text(
                appointment.patientName,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.calendar_today,
                        size: 14,
                        color: AppColors.textLight,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        DateFormat('MMM dd, yyyy').format(appointment.date),
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.textLight,
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Icon(
                        Icons.access_time,
                        size: 14,
                        color: AppColors.textLight,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        appointment.time,
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.textLight,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              children: [
                if (profile != null) ...[
                  const Divider(),
                  const SizedBox(height: 8),
                  _buildSectionTitle("Medical Information"),
                  _buildInfoRow("Allergies", profile.allergies),
                  _buildInfoRow(
                    "Current Medications",
                    profile.currentMedications,
                  ),
                  _buildInfoRow("Chronic Diseases", profile.chronicDiseases),
                  _buildInfoRow("Injuries", profile.injuries),
                  _buildInfoRow("Surgeries", profile.surgeries),
                  const SizedBox(height: 16),
                  _buildSectionTitle("Lifestyle Information"),
                  _buildInfoRow("Smoking Habits", profile.smokingHabits),
                  _buildInfoRow(
                    "Alcohol Consumption",
                    profile.alcoholConsumption,
                  ),
                  _buildInfoRow("Activity Level", profile.activityLevel),
                  _buildInfoRow("Food Preference", profile.foodPreference),
                ] else ...[
                  const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text(
                      "Patient profile information not available",
                      style: TextStyle(
                        color: AppColors.textLight,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: AppColors.primaryBlue,
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String? value) {
    if (value == null || value.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              "$label:",
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: AppColors.textDark,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: AppColors.textLight),
            ),
          ),
        ],
      ),
    );
  }
}
