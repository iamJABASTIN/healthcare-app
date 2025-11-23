import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/themes/app_colors.dart';

import '../../view_models/patient_profile_view_model.dart';
import '../../view_models/patient_home_view_model.dart';
import 'profile/patient_profile_screen.dart';
import '../widgets/doctor_card.dart';
import 'doctor_details_screen.dart';

class PatientHomeScreen extends StatefulWidget {
  const PatientHomeScreen({super.key});

  @override
  State<PatientHomeScreen> createState() => _PatientHomeScreenState();
}

class _PatientHomeScreenState extends State<PatientHomeScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // MVVM: Fetch the latest profile data and doctors as soon as the Home Screen loads
    Future.microtask(() {
      final profileVM = Provider.of<ProfileViewModel>(context, listen: false);
      final homeVM = Provider.of<PatientHomeViewModel>(context, listen: false);

      // Fetch data
      profileVM.fetchUserProfile();
      homeVM.fetchDoctors();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Watch the ViewModels
    final profileVM = Provider.of<ProfileViewModel>(context);
    final homeVM = Provider.of<PatientHomeViewModel>(context);

    return Scaffold(
      backgroundColor: AppColors.lightGrey,
      body: Column(
        children: [
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
                    controller: _searchController,
                    onChanged: (value) {
                      homeVM.searchDoctors(value);
                    },
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

          // --- CATEGORIES (Horizontal List) ---
          Container(
            height: 50,
            margin: const EdgeInsets.symmetric(vertical: 10),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: homeVM.categories.length,
              itemBuilder: (context, index) {
                final category = homeVM.categories[index];
                final isSelected = category == homeVM.selectedCategory;
                return GestureDetector(
                  onTap: () {
                    homeVM.filterByCategory(category);
                    _searchController
                        .clear(); // Clear search when changing category
                  },
                  child: Container(
                    margin: const EdgeInsets.only(right: 10),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.primaryBlue : Colors.white,
                      borderRadius: BorderRadius.circular(25),
                      border: isSelected
                          ? null
                          : Border.all(color: Colors.grey[300]!),
                    ),
                    child: Center(
                      child: Text(
                        category,
                        style: TextStyle(
                          color: isSelected ? Colors.white : AppColors.textDark,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // --- DOCTOR LIST ---
          Expanded(
            child: homeVM.isLoading
                ? const Center(child: CircularProgressIndicator())
                : homeVM.doctors.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search_off,
                          size: 60,
                          color: Colors.grey[300],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          "No doctors found",
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: homeVM.doctors.length,
                    itemBuilder: (context, index) {
                      final doctor = homeVM.doctors[index];
                      return DoctorCard(
                        doctor: doctor,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  DoctorDetailsScreen(doctor: doctor),
                            ),
                          );
                        },
                      );
                    },
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
