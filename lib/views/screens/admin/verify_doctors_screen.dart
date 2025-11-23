import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/themes/app_colors.dart';
import '../../../view_models/admin_doctors_view_model.dart';

class VerifyDoctorsScreen extends StatefulWidget {
  const VerifyDoctorsScreen({super.key});

  @override
  State<VerifyDoctorsScreen> createState() => _VerifyDoctorsScreenState();
}

class _VerifyDoctorsScreenState extends State<VerifyDoctorsScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() =>
        Provider.of<AdminDoctorsViewModel>(context, listen: false).fetchPendingDoctors());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Verify Doctors'),
        backgroundColor: AppColors.primaryBlue,
      ),
      body: Consumer<AdminDoctorsViewModel>(
        builder: (context, vm, child) {
          if (vm.isLoading) return const Center(child: CircularProgressIndicator());
          if (vm.error != null) return Center(child: Text('Error: ${vm.error}'));

          if (vm.pendingDoctors.isEmpty) {
            return const Center(child: Text('No pending doctor registrations'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: vm.pendingDoctors.length,
            itemBuilder: (context, index) {
              final d = vm.pendingDoctors[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(d.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 6),
                      Text(d.specialization),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                            onPressed: () async {
                              final ok = await vm.approveDoctor(d.uid);
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ok ? 'Doctor approved' : 'Failed to approve')));
                            },
                            child: const Text('Approve'),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                            onPressed: () async {
                              final ok = await vm.rejectDoctor(d.uid);
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ok ? 'Doctor rejected' : 'Failed to reject')));
                            },
                            child: const Text('Reject'),
                          ),
                          const Spacer(),
                          if (d.identityProofUrl.isNotEmpty)
                            TextButton(
                              onPressed: () async {
                                final uri = Uri.tryParse(d.identityProofUrl);
                                if (uri == null) return;
                                await launchUrl(uri, mode: LaunchMode.externalApplication);
                              },
                              child: const Text('View ID'),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
