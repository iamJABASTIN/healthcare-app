import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/themes/app_colors.dart';
import '../../../view_models/profile_view_model.dart';
import '../../../view_models/auth_view_model.dart';
import '../../../data/models/patient_profile_model.dart';
import '../../widgets/profile_field_tile.dart';
import '../auth/login_view.dart';

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
          actions: [
            IconButton(
              icon: const Icon(Icons.logout, color: Colors.white),
              onPressed: () {
                // Logout Logic
                final authVM = Provider.of<AuthViewModel>(
                  context,
                  listen: false,
                );
                authVM.signOut();
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginView()),
                  (route) => false,
                );
              },
            ),
          ],
          bottom: const TabBar(
            indicatorColor: Colors.white,
            indicatorWeight: 3,
            labelColor: Colors.white, // Explicitly set selected color
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
                    profileVM,
                  ),

                  // 2. Medical Tab
                  _buildMedicalTab(context, profile, profileVM),

                  // 3. Lifestyle Tab
                  _buildLifestyleTab(context, profile, profileVM),
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
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Profile Saved Successfully")),
                  );
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
    ProfileViewModel profileVM,
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
            onTap: () => _showEditDialog(
              context,
              "Contact Number",
              "contactNumber",
              profile?.contactNumber,
              profileVM,
            ),
          ),
          ProfileFieldTile(
            label: "Email Id",
            value: email,
            placeholder: "add email",
            onTap: () {
              // Email usually not editable here or needs specific flow
            },
          ),
          ProfileFieldTile(
            label: "Gender",
            value: profile?.gender,
            placeholder: "Add gender",
            onTap: () => _showEditDialog(
              context,
              "Gender",
              "gender",
              profile?.gender,
              profileVM,
            ),
          ),
          ProfileFieldTile(
            label: "Date of Birth",
            value: profile?.dob,
            placeholder: "yyyy mm dd",
            onTap: () => _selectDate(context, "dob", profile?.dob, profileVM),
          ),
          ProfileFieldTile(
            label: "Blood Group",
            value: profile?.bloodGroup,
            placeholder: "add blood group",
            onTap: () => _showEditDialog(
              context,
              "Blood Group",
              "bloodGroup",
              profile?.bloodGroup,
              profileVM,
            ),
          ),
          ProfileFieldTile(
            label: "Marital Status",
            value: profile?.maritalStatus,
            placeholder: "add marital status",
            onTap: () => _showEditDialog(
              context,
              "Marital Status",
              "maritalStatus",
              profile?.maritalStatus,
              profileVM,
            ),
          ),
          ProfileFieldTile(
            label: "Height",
            value: profile?.height,
            placeholder: "add height",
            onTap: () => _showEditDialog(
              context,
              "Height",
              "height",
              profile?.height,
              profileVM,
            ),
          ),
          ProfileFieldTile(
            label: "Weight",
            value: profile?.weight,
            placeholder: "add weight",
            onTap: () => _showEditDialog(
              context,
              "Weight",
              "weight",
              profile?.weight,
              profileVM,
            ),
          ),
          ProfileFieldTile(
            label: "Emergency Contact",
            value: profile?.emergencyContact,
            placeholder: "add emergency details",
            onTap: () => _showEditDialog(
              context,
              "Emergency Contact",
              "emergencyContact",
              profile?.emergencyContact,
              profileVM,
            ),
          ),
          ProfileFieldTile(
            label: "Location",
            value: profile?.location,
            placeholder: "add details",
            onTap: () => _showEditDialog(
              context,
              "Location",
              "location",
              profile?.location,
              profileVM,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMedicalTab(
    BuildContext context,
    PatientProfileModel? profile,
    ProfileViewModel profileVM,
  ) {
    return SingleChildScrollView(
      child: Column(
        children: [
          ProfileFieldTile(
            label: "Allergies",
            value: profile?.allergies,
            placeholder: "add allergies",
            onTap: () => _showEditDialog(
              context,
              "Allergies",
              "allergies",
              profile?.allergies,
              profileVM,
            ),
          ),
          ProfileFieldTile(
            label: "Current Medications",
            value: profile?.currentMedications,
            placeholder: "add medications",
            onTap: () => _showEditDialog(
              context,
              "Current Medications",
              "currentMedications",
              profile?.currentMedications,
              profileVM,
            ),
          ),
          ProfileFieldTile(
            label: "Past Medications",
            value: profile?.pastMedications,
            placeholder: "add medications",
            onTap: () => _showEditDialog(
              context,
              "Past Medications",
              "pastMedications",
              profile?.pastMedications,
              profileVM,
            ),
          ),
          ProfileFieldTile(
            label: "Chronic Diseases",
            value: profile?.chronicDiseases,
            placeholder: "add disease",
            onTap: () => _showEditDialog(
              context,
              "Chronic Diseases",
              "chronicDiseases",
              profile?.chronicDiseases,
              profileVM,
            ),
          ),
          ProfileFieldTile(
            label: "Injuries",
            value: profile?.injuries,
            placeholder: "add incident",
            onTap: () => _showEditDialog(
              context,
              "Injuries",
              "injuries",
              profile?.injuries,
              profileVM,
            ),
          ),
          ProfileFieldTile(
            label: "Surgeries",
            value: profile?.surgeries,
            placeholder: "add surgeries",
            onTap: () => _showEditDialog(
              context,
              "Surgeries",
              "surgeries",
              profile?.surgeries,
              profileVM,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLifestyleTab(
    BuildContext context,
    PatientProfileModel? profile,
    ProfileViewModel profileVM,
  ) {
    return SingleChildScrollView(
      child: Column(
        children: [
          ProfileFieldTile(
            label: "Smoking Habits",
            value: profile?.smokingHabits,
            placeholder: "add details",
            onTap: () => _showEditDialog(
              context,
              "Smoking Habits",
              "smokingHabits",
              profile?.smokingHabits,
              profileVM,
            ),
          ),
          ProfileFieldTile(
            label: "Alcohol consumption",
            value: profile?.alcoholConsumption,
            placeholder: "add details",
            onTap: () => _showEditDialog(
              context,
              "Alcohol Consumption",
              "alcoholConsumption",
              profile?.alcoholConsumption,
              profileVM,
            ),
          ),
          ProfileFieldTile(
            label: "Activity level",
            value: profile?.activityLevel,
            placeholder: "add details",
            onTap: () => _showEditDialog(
              context,
              "Activity Level",
              "activityLevel",
              profile?.activityLevel,
              profileVM,
            ),
          ),
          ProfileFieldTile(
            label: "Food Preference",
            value: profile?.foodPreference,
            placeholder: "add lifestyle",
            onTap: () => _showEditDialog(
              context,
              "Food Preference",
              "foodPreference",
              profile?.foodPreference,
              profileVM,
            ),
          ),
          ProfileFieldTile(
            label: "Occupation",
            value: profile?.occupation,
            placeholder: "add occupation",
            onTap: () => _showEditDialog(
              context,
              "Occupation",
              "occupation",
              profile?.occupation,
              profileVM,
            ),
          ),
        ],
      ),
    );
  }

  // --- Helpers ---

  Future<void> _showEditDialog(
    BuildContext context,
    String label,
    String fieldKey,
    String? currentValue,
    ProfileViewModel profileVM,
  ) async {
    final TextEditingController controller = TextEditingController(
      text: currentValue,
    );

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Edit $label"),
          content: TextField(
            controller: controller,
            decoration: InputDecoration(
              hintText: "Enter $label",
              border: const OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                profileVM.updateProfileField(fieldKey, controller.text);
                Navigator.pop(context);
              },
              child: const Text("Save"),
            ),
          ],
        );
      },
    );
  }

  Future<void> _selectDate(
    BuildContext context,
    String fieldKey,
    String? currentDate,
    ProfileViewModel profileVM,
  ) async {
    DateTime initialDate = DateTime.now();
    if (currentDate != null && currentDate.isNotEmpty) {
      try {
        initialDate = DateTime.parse(currentDate);
      } catch (_) {}
    }

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      // Format as yyyy-MM-dd
      String formattedDate =
          "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
      profileVM.updateProfileField(fieldKey, formattedDate);
    }
  }
}
