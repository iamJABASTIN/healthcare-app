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
    Future.microtask(() async {
      final profileVM = Provider.of<ProfileViewModel>(context, listen: false);
      final homeVM = Provider.of<PatientHomeViewModel>(context, listen: false);

      // Fetch data
      await profileVM.fetchUserProfile();

      // Pass location to HomeVM for filtering
      if (profileVM.patientProfile?.location != null) {
        homeVM.setUserLocation(profileVM.patientProfile!.location);
      }

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

    // Update location in HomeVM if it changes in ProfileVM
    if (profileVM.patientProfile?.location != null &&
        homeVM.filterByLocation &&
        homeVM.doctors.isEmpty &&
        !homeVM.isLoading) {
      // Optional: Retry logic or just ensure sync
      // homeVM.setUserLocation(profileVM.patientProfile!.location);
    }

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
                                          profileVM.fetchCurrentLocation().then(
                                            (_) {
                                              // Update HomeVM with new location
                                              if (profileVM
                                                      .patientProfile
                                                      ?.location !=
                                                  null) {
                                                homeVM.setUserLocation(
                                                  profileVM
                                                      .patientProfile!
                                                      .location,
                                                );
                                              }
                                            },
                                          );
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
                                            homeVM,
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

                // --- SEARCH BAR WITH FILTER ---
                Container(
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (value) {
                      homeVM.setSearchQuery(value);
                    },
                    decoration: InputDecoration(
                      hintText: "Search for clinics, doctors...",
                      hintStyle: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 14,
                      ),
                      prefixIcon: const Icon(Icons.search, color: Colors.grey),
                      suffixIcon: IconButton(
                        icon: const Icon(
                          Icons.filter_list,
                          color: AppColors.primaryBlue,
                        ),
                        onPressed: () {
                          _showFilterBottomSheet(context, homeVM);
                        },
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              ],
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
                        if (homeVM.filterByLocation)
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              "Try turning off 'Nearby Only' filter",
                              style: TextStyle(
                                color: Colors.blue,
                                fontSize: 12,
                              ),
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

  void _showFilterBottomSheet(
    BuildContext context,
    PatientHomeViewModel homeVM,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Allow full height
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) {
            return Consumer<PatientHomeViewModel>(
              builder: (context, vm, child) {
                return SingleChildScrollView(
                  controller: scrollController,
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              "Filter Doctors",
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textDark,
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                vm.resetFilters();
                                _searchController.clear();
                                Navigator.pop(context);
                              },
                              child: const Text("Reset"),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // 1. Sort By
                        const Text(
                          "Sort By",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textDark,
                          ),
                        ),
                        const SizedBox(height: 10),
                        FilterChip(
                          label: const Text("Rating (High to Low)"),
                          selected: vm.sortByRating,
                          onSelected: (bool selected) {
                            vm.toggleSortByRating(selected);
                          },
                          selectedColor: AppColors.primaryBlue.withOpacity(0.2),
                          checkmarkColor: AppColors.primaryBlue,
                        ),
                        const SizedBox(height: 20),

                        // 2. Location Filter
                        const Text(
                          "Location",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textDark,
                          ),
                        ),
                        const SizedBox(height: 10),
                        SwitchListTile(
                          title: const Text("Show Nearby Only"),
                          subtitle: Text(
                            "Doctors in ${Provider.of<ProfileViewModel>(context, listen: false).patientProfile?.location ?? 'your city'}",
                          ),
                          value: vm.filterByLocation,
                          onChanged: (bool value) {
                            vm.toggleLocationFilter(value);
                          },
                          activeColor: AppColors.primaryBlue,
                          contentPadding: EdgeInsets.zero,
                        ),
                        const SizedBox(height: 20),

                        // 3. Specialty Filter
                        const Text(
                          "Specialty",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textDark,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: vm.categories.map((category) {
                            final isSelected = category == vm.selectedCategory;
                            return ChoiceChip(
                              label: Text(category),
                              selected: isSelected,
                              onSelected: (selected) {
                                if (selected) {
                                  vm.setCategory(category);
                                }
                              },
                              selectedColor: AppColors.primaryBlue,
                              labelStyle: TextStyle(
                                color: isSelected
                                    ? Colors.white
                                    : AppColors.textDark,
                              ),
                              backgroundColor: Colors.grey[200],
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 20),

                        // 4. Gender Filter
                        const Text(
                          "Gender",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textDark,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 10,
                          children: vm.genders.map((gender) {
                            final isSelected = gender == vm.selectedGender;
                            return ChoiceChip(
                              label: Text(gender),
                              selected: isSelected,
                              onSelected: (selected) {
                                if (selected) {
                                  vm.setGender(gender);
                                }
                              },
                              selectedColor: AppColors.primaryBlue,
                              labelStyle: TextStyle(
                                color: isSelected
                                    ? Colors.white
                                    : AppColors.textDark,
                              ),
                              backgroundColor: Colors.grey[200],
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 30),

                        // Apply Button
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: () => Navigator.pop(context),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryBlue,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              "Apply Filters",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  void _showManualLocationDialog(
    BuildContext context,
    ProfileViewModel profileVM,
    PatientHomeViewModel homeVM,
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
                  final newLocation = controller.text.trim();
                  profileVM.updateProfileField('location', newLocation);
                  // Update HomeVM
                  homeVM.setUserLocation(newLocation);
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
