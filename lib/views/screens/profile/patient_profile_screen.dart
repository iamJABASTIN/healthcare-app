import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/themes/app_colors.dart';
import '../../../view_models/profile_view_model.dart';
import '../../../data/models/patient_profile_model.dart';
import '../../widgets/profile_field_tile.dart';

class PatientProfileScreen extends StatefulWidget {
  const PatientProfileScreen({super.key});

  @override
  State<PatientProfileScreen> createState() => _PatientProfileScreenState();
}

class _PatientProfileScreenState extends State<PatientProfileScreen> {
  @override
  void initState() {
    super.initState();
    // Fetch data on load
    Future.microtask(
      () => Provider.of<ProfileViewModel>(
        context,
        listen: false,
      ).fetchUserProfile(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final profileVM = Provider.of<ProfileViewModel>(context);
    final profile = profileVM.patientProfile;
    final percentage = profile?.completionPercentage ?? 0;

    return DefaultTabController(
      length: 3, // Personal, Medical, Lifestyle
      child: Scaffold(
        appBar: AppBar(
          title: Text(profileVM.userData?['name'] ?? "User"), // "Jabastin"
          centerTitle: false,
          elevation: 0,
          bottom: const TabBar(
            indicatorColor: Colors.white,
            indicatorWeight: 3,
            labelStyle: TextStyle(fontWeight: FontWeight.bold),
            unselectedLabelColor: Colors.white70,
            tabs: [
              Tab(text: "Personal"),
              Tab(text: "Medical"),
              Tab(text: "Lifestyle"),
            ],
          ),
        ),
        body: Column(
          children: [
            // --- Expanded Tab View ---
            Expanded(
              child: TabBarView(
                children: [
                  // 1. Personal Tab
                  _buildPersonalTab(
                    context,
                    profile,
                    profileVM.userData?['name'],
                    profileVM.userData?['email'],
                  ),

                  // 2. Medical Tab
                  _buildMedicalTab(context, profile),

                  // 3. Lifestyle Tab
                  _buildLifestyleTab(context, profile),
                ],
              ),
            ),

            // --- Bottom Completion Bar ---
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.2),
                    blurRadius: 5,
                    offset: const Offset(0, -3),
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: () {
                  // Action to complete or save
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryBlue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: Column(
                  children: [
                    const Text(
                      "Complete profile",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "$percentage% completed",
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Tab Builders ---

  Widget _buildPersonalTab(
    BuildContext context,
    PatientProfileModel? profile,
    String? name,
    String? email,
  ) {
    return SingleChildScrollView(
      child: Column(
        children: [
          // Photo Section (Custom layout for the top part)
          Container(
            padding: const EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Name",
                      style: TextStyle(
                        color: AppColors.textLight,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      name ?? "User",
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: AppColors.lightGrey,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  alignment: Alignment.center,
                  child: const Text(
                    "add\nphoto",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 10,
                      color: AppColors.primaryBlue,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Fields
          ProfileFieldTile(
            label: "Contact Number",
            value: profile?.contactNumber ?? "+91-7904686738",
            placeholder: "add number",
            onTap: () {},
          ),
          ProfileFieldTile(
            label: "Email Id",
            value: email,
            placeholder: "add email",
            onTap: () {},
          ),
          ProfileFieldTile(
            label: "Gender",
            value: profile?.gender,
            placeholder: "Add gender",
            onTap: () {},
          ),
          ProfileFieldTile(
            label: "Date of Birth",
            value: profile?.dob,
            placeholder: "yyyy mm dd",
            onTap: () {},
          ),
          ProfileFieldTile(
            label: "Blood Group",
            value: profile?.bloodGroup,
            placeholder: "add blood group",
            onTap: () {},
          ),
          ProfileFieldTile(
            label: "Marital Status",
            value: profile?.maritalStatus,
            placeholder: "add marital status",
            onTap: () {},
          ),
          ProfileFieldTile(
            label: "Height",
            value: profile?.height,
            placeholder: "add height",
            onTap: () {},
          ),
          ProfileFieldTile(
            label: "Weight",
            value: profile?.weight,
            placeholder: "add weight",
            onTap: () {},
          ),
          ProfileFieldTile(
            label: "Emergency Contact",
            value: profile?.emergencyContact,
            placeholder: "add emergency details",
            onTap: () {},
          ),
          ProfileFieldTile(
            label: "Location",
            value: profile?.location,
            placeholder: "add details",
            onTap: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildMedicalTab(BuildContext context, PatientProfileModel? profile) {
    return SingleChildScrollView(
      child: Column(
        children: [
          ProfileFieldTile(
            label: "Allergies",
            value: profile?.allergies,
            placeholder: "add allergies",
            onTap: () {},
          ),
          ProfileFieldTile(
            label: "Current Medications",
            value: profile?.currentMedications,
            placeholder: "add medications",
            onTap: () {},
          ),
          ProfileFieldTile(
            label: "Past Medications",
            value: profile?.pastMedications,
            placeholder: "add medications",
            onTap: () {},
          ),
          ProfileFieldTile(
            label: "Chronic Diseases",
            value: profile?.chronicDiseases,
            placeholder: "add disease",
            onTap: () {},
          ),
          ProfileFieldTile(
            label: "Injuries",
            value: profile?.injuries,
            placeholder: "add incident",
            onTap: () {},
          ),
          ProfileFieldTile(
            label: "Surgeries",
            value: profile?.surgeries,
            placeholder: "add surgeries",
            onTap: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildLifestyleTab(
    BuildContext context,
    PatientProfileModel? profile,
  ) {
    return SingleChildScrollView(
      child: Column(
        children: [
          ProfileFieldTile(
            label: "Smoking Habits",
            value: profile?.smokingHabits,
            placeholder: "add details",
            onTap: () {},
          ),
          ProfileFieldTile(
            label: "Alcohol consumption",
            value: profile?.alcoholConsumption,
            placeholder: "add details",
            onTap: () {},
          ),
          ProfileFieldTile(
            label: "Activity level",
            value: profile?.activityLevel,
            placeholder: "add details",
            onTap: () {},
          ),
          ProfileFieldTile(
            label: "Food Preference",
            value: profile?.foodPreference,
            placeholder: "add lifestyle",
            onTap: () {},
          ),
          ProfileFieldTile(
            label: "Occupation",
            value: profile?.occupation,
            placeholder: "add occupation",
            onTap: () {},
          ),
        ],
      ),
    );
  }
}
