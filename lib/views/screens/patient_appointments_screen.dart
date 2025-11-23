import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/themes/app_colors.dart';
import '../../view_models/patient_appointments_view_model.dart';

class PatientAppointmentsScreen extends StatefulWidget {
  const PatientAppointmentsScreen({super.key});

  @override
  State<PatientAppointmentsScreen> createState() => _PatientAppointmentsScreenState();
}

class _PatientAppointmentsScreenState extends State<PatientAppointmentsScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      Provider.of<PatientAppointmentsViewModel>(context, listen: false)
          .fetchAppointments();
    });
  }

  @override
  Widget build(BuildContext context) {
    // Removed inner Scaffold/AppBar so outer PatientScaffold presents the AppBar/title.
    return DefaultTabController(
      length: 2,
      child: Container(
        color: AppColors.lightGrey,
        child: Column(
          children: [
            // TabBar shown beneath outer AppBar provided by PatientScaffold
            Material(
              color: AppColors.primaryBlue,
              child: const TabBar(
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white70,
                indicatorColor: Colors.white,
                tabs: [
                  Tab(icon: Icon(Icons.upcoming), text: 'Upcoming'),
                  Tab(icon: Icon(Icons.history), text: 'Past'),
                ],
              ),
            ),
            Expanded(
              child: Consumer<PatientAppointmentsViewModel>(
                builder: (context, vm, child) {
                  if (vm.isLoading) return const Center(child: CircularProgressIndicator());
                  if (vm.errorMessage != null) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error_outline, size: 64, color: Colors.grey),
                          const SizedBox(height: 16),
                          Text(vm.errorMessage!),
                          const SizedBox(height: 16),
                          ElevatedButton(onPressed: vm.fetchAppointments, child: const Text('Retry')),
                        ],
                      ),
                    );
                  }

                  return TabBarView(
                    children: [
                      _buildAppointmentsList(vm.upcomingAppointments, isUpcoming: true),
                      _buildAppointmentsList(vm.pastAppointments, isUpcoming: false),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppointmentsList(List<AppointmentWithDoctorDetails> appointments, {required bool isUpcoming}) {
    if (appointments.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(isUpcoming ? Icons.calendar_today : Icons.history, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(isUpcoming ? 'No upcoming appointments' : 'No past appointments', style: TextStyle(fontSize: 18, color: Colors.grey[600])),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        final vm = Provider.of<PatientAppointmentsViewModel>(context, listen: false);
        if (isUpcoming) await vm.fetchUpcomingAppointments(); else await vm.fetchPastAppointments();
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: appointments.length,
        itemBuilder: (context, index) {
          final item = appointments[index];
          final appt = item.appointment;
          final doctor = item.doctor;

          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ExpansionTile(
              tilePadding: const EdgeInsets.all(16),
              childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              leading: CircleAvatar(
                backgroundColor: AppColors.primaryBlue,
                child: Text((doctor?.name.isNotEmpty ?? false) ? doctor!.name[0].toUpperCase() : appt.doctorName.isNotEmpty ? appt.doctorName[0].toUpperCase() : '?', style: const TextStyle(color: Colors.white)),
              ),
              title: Text(doctor?.name.isNotEmpty ?? false ? doctor!.name : (appt.doctorName.isNotEmpty ? appt.doctorName : 'Unknown Doctor'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const SizedBox(height: 4),
                Wrap(crossAxisAlignment: WrapCrossAlignment.center, spacing: 16, runSpacing: 4, children: [
                  Row(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.calendar_today, size: 14, color: AppColors.textLight), const SizedBox(width: 4), Text(DateFormat('MMM dd, yyyy').format(appt.date), style: const TextStyle(fontSize: 14, color: AppColors.textLight))]),
                  Row(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.access_time, size: 14, color: AppColors.textLight), const SizedBox(width: 4), Text(appt.time, style: const TextStyle(fontSize: 14, color: AppColors.textLight))]),
                ])
              ]),
              children: [
                if (doctor != null) ...[
                  const Divider(),
                  const SizedBox(height: 8),
                  _buildSectionTitle('Doctor Information'),
                  _buildInfoRow('Email', doctor.email),
                  _buildInfoRow('Location', doctor.location),
                  _buildInfoRow('Specialization', doctor.specialization),
                ] else ...[
                  const Padding(padding: EdgeInsets.all(16.0), child: Text('Doctor profile information not available', style: TextStyle(color: AppColors.textLight, fontStyle: FontStyle.italic))),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(padding: const EdgeInsets.only(bottom: 8), child: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primaryBlue)));
  }

  Widget _buildInfoRow(String label, String? value) {
    if (value == null || value.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SizedBox(width: 140, child: Text('$label:', style: const TextStyle(fontWeight: FontWeight.w500, color: AppColors.textDark))),
        Expanded(child: Text(value, style: const TextStyle(color: AppColors.textLight))),
      ]),
    );
  }
}
