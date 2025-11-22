import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/themes/app_colors.dart';

import '../../view_models/profile_view_model.dart';
import 'profile/patient_profile_screen.dart';

class PatientHomeScreen extends StatefulWidget {
  const PatientHomeScreen({super.key});

  @override
  State<PatientHomeScreen> createState() => _PatientHomeScreenState();
}

class _PatientHomeScreenState extends State<PatientHomeScreen> {
  @override
  void initState() {
    super.initState();
    // MVVM: Fetch the latest profile data as soon as the Home Screen loads
    // We use Microtask to ensure the build frame is done before fetching
    Future.microtask(() {
      final profileVM = Provider.of<ProfileViewModel>(context, listen: false);

      // Fetch the profile data
      profileVM.fetchUserProfile();
    });
  }

  @override
  Widget build(BuildContext context) {
    // Watch the ProfileViewModel for changes (like Location or Name)
    final profileVM = Provider.of<ProfileViewModel>(context);

    return Scaffold(
      backgroundColor: AppColors.lightGrey,
      body: Column(
        children: [
          // ==================================================
          // 1. CUSTOM HEADER (Blue Container)
          // ==================================================
          Container(
            padding: const EdgeInsets.only(
              top: 50,
              left: 16,
              right: 16,
              bottom: 25,
            ),
            decoration: const BoxDecoration(
              color: AppColors.primaryBlue,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(24),
                bottomRight: Radius.circular(24),
              ),
            ),
            child: Column(
              children: [
                // --- TOP ROW: Profile | Location | Action ---
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // A. PROFILE ICON (Navigates to Profile Page)
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const PatientProfileScreen(),
                          ),
                        );
                      },
                      child: CircleAvatar(
                        radius: 24,
                        backgroundColor: Colors.white.withOpacity(0.2),
                        child: const Icon(
                          Icons.person,
                          color: Colors.white,
                          size: 30,
                        ),
                      ),
                    ),

                    // B. LOCATION DROPDOWN
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12.0),
                        child: GestureDetector(
                          onTap: () {
                            showDialog(
                              context: context,
                              builder: (BuildContext context) {
                                return AlertDialog(
                                  title: const Text("Select Location Source"),
                                  content: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      ListTile(
                                        leading: const Icon(Icons.my_location),
                                        title: const Text(
                                          "Use Current Location",
                                        ),
                                        onTap: () {
                                          Navigator.pop(context);
                                          profileVM.fetchCurrentLocation();
                                        },
                                      ),
                                      ListTile(
                                        leading: const Icon(Icons.list),
                                        title: const Text("Select Manually"),
                                        onTap: () {
                                          Navigator.pop(context);
                                          _showManualLocationDialog(
                                            context,
                                            profileVM,
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                );
                              },
                            );
                          },
                          child: Row(
                            children: [
                              const Icon(
                                Icons.location_on,
                                color: Colors.white,
                                size: 16,
                              ),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  // Fetches from VM or defaults to Angampalayam
                                  profileVM.patientProfile?.location ??
                                      "Angampalayam",
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const Icon(
                                Icons.keyboard_arrow_down,
                                color: Colors.white,
                                size: 20,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // --- SEARCH BAR ---
                Container(
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: "Search for clinics, doctors...",
                      hintStyle: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 14,
                      ),
                      prefixIcon: const Icon(Icons.search, color: Colors.grey),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ==================================================
          // 2. BODY CONTENT (Placeholder for Grid)
          // ==================================================
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // This space is ready for the "Physical Appointment / Video Consult" grid
                  const SizedBox(height: 20),
                  Text(
                    "Services Coming Soon",
                    style: TextStyle(color: Colors.grey[400]),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showManualLocationDialog(
    BuildContext context,
    ProfileViewModel profileVM,
  ) {
    final TextEditingController controller = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Enter Location"),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              hintText: "City, State",
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                if (controller.text.trim().isNotEmpty) {
                  profileVM.updateProfileField(
                    'location',
                    controller.text.trim(),
                  );
                  Navigator.pop(context);
                }
              },
              child: const Text("Save"),
            ),
          ],
        );
      },
    );
  }
}
