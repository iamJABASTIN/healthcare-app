import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/themes/app_colors.dart';
import '../../view_models/patient_medical_records_view_model.dart';

class PatientMedicalRecordsScreen extends StatefulWidget {
  const PatientMedicalRecordsScreen({super.key});

  @override
  State<PatientMedicalRecordsScreen> createState() => _PatientMedicalRecordsScreenState();
}

class _PatientMedicalRecordsScreenState extends State<PatientMedicalRecordsScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => Provider.of<PatientMedicalRecordsViewModel>(context, listen: false).fetchRecords());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Medical Records'),
        backgroundColor: AppColors.primaryBlue,
        foregroundColor: Colors.white,
      ),
      body: Consumer<PatientMedicalRecordsViewModel>(
        builder: (context, vm, child) {
          if (vm.isLoading) return const Center(child: CircularProgressIndicator());
          if (vm.error != null) return Center(child: Text('Error: ${vm.error}'));

          if (vm.records.isEmpty) {
            return Center(child: Text('No records uploaded yet', style: TextStyle(color: Colors.grey[600])));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: vm.records.length,
            itemBuilder: (context, index) {
              final r = vm.records[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  title: Text(r.fileName),
                  subtitle: Text(r.description ?? ''),
                  trailing: Text(r.fileType.toUpperCase()),
                  onTap: () {
                    final url = r.fileUrl;
                    final ext = r.fileType.toLowerCase();

                    final isImage = ['png', 'jpg', 'jpeg', 'gif', 'webp'].contains(ext);

                    if (isImage) {
                      // Show image preview dialog
                      showDialog(
                        context: context,
                        builder: (_) => Dialog(
                          insetPadding: const EdgeInsets.all(8),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Text(r.fileName, style: const TextStyle(fontWeight: FontWeight.bold)),
                              ),
                              SizedBox(
                                width: MediaQuery.of(context).size.width * 0.9,
                                height: MediaQuery.of(context).size.height * 0.7,
                                child: InteractiveViewer(
                                  panEnabled: true,
                                  minScale: 0.5,
                                  maxScale: 4.0,
                                  child: Image.network(url, fit: BoxFit.contain),
                                ),
                              ),
                              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
                            ],
                          ),
                        ),
                      );
                    } else {
                      // Non-image: show URL and allow copy
                      showDialog(
                        context: context,
                        builder: (_) => AlertDialog(
                          title: Text(r.fileName),
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Uploaded at: ${r.uploadedAt}'),
                              const SizedBox(height: 8),
                              SelectableText(url),
                            ],
                          ),
                          actions: [
                            TextButton(
                              onPressed: () {
                                Clipboard.setData(ClipboardData(text: url));
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('URL copied to clipboard')));
                              },
                              child: const Text('Copy URL'),
                            ),
                            TextButton(
                              onPressed: () async {
                                Navigator.pop(context);
                                final uri = Uri.tryParse(url);
                                if (uri == null) {
                                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invalid URL')));
                                  return;
                                }
                                try {
                                  final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
                                  if (!launched) {
                                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not open file')));
                                  }
                                } catch (e) {
                                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to open file')));
                                }
                              },
                              child: const Text('Open'),
                            ),
                            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
                          ],
                        ),
                      );
                    }
                  },
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primaryBlue,
        child: const Icon(Icons.upload_file),
        onPressed: () async {
          // Pick and upload
          await Provider.of<PatientMedicalRecordsViewModel>(context, listen: false).pickAndUpload();
        },
      ),
    );
  }
}
