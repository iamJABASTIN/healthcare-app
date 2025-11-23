import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/themes/app_colors.dart';
import '../../../view_models/patient_profile_view_model.dart';
import '../../../view_models/auth_view_model.dart';
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
    // Load profile data
    Future.microtask(
      () => Provider.of<ProfileViewModel>(
        context,
        listen: false,
      ).fetchUserProfile(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ProfileViewModel>(
      builder: (context, profileVM, _) {
        final profile = profileVM.patientProfile;
        final percentage = profile?.completionPercentage ?? 0;

        return DefaultTabController(
          length: 3,
          child: Scaffold(
            appBar: AppBar(
              title: Text(profileVM.userData?['name'] ?? 'User'),
              actions: [
                IconButton(
                  icon: const Icon(Icons.logout, color: Colors.white),
                  onPressed: () {
                    Provider.of<AuthViewModel>(
                      context,
                      listen: false,
                    ).signOut();
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
                labelColor: Colors.white,
                labelStyle: TextStyle(fontWeight: FontWeight.bold),
                unselectedLabelColor: Colors.white70,
                tabs: [
                  Tab(text: 'Personal'),
                  Tab(text: 'Medical'),
                  Tab(text: 'Lifestyle'),
                ],
              ),
            ),
            body: Column(
              children: [
                Expanded(
                  child: TabBarView(
                    children: [
                      _buildPersonalTab(context, profileVM),
                      _buildMedicalTab(context, profileVM),
                      _buildLifestyleTab(context, profileVM),
                    ],
                  ),
                ),
                // Save button with completion percentage
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  color: Colors.white,
                  child: ElevatedButton(
                    onPressed: () {
                      // Trigger save functionality here if needed in VM
                      // profileVM.saveProfile();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Profile Saved Successfully'),
                        ),
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
                          'Complete profile',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$percentage% completed',
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
      },
    );
  }

  // ---------- Tab Builders ----------
  Widget _buildPersonalTab(BuildContext context, ProfileViewModel vm) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Profile picture section
          Stack(
            alignment: Alignment.bottomRight,
            children: [
              CircleAvatar(
                radius: 50,
                backgroundColor: AppColors.lightGrey,
                backgroundImage:
                    vm.profileImageUrl != null && vm.profileImageUrl!.isNotEmpty
                    ? NetworkImage(vm.profileImageUrl!)
                    : null,
                child: vm.profileImageUrl == null || vm.profileImageUrl!.isEmpty
                    ? const Icon(
                        Icons.person,
                        size: 50,
                        color: AppColors.textDark,
                      )
                    : null,
              ),
              Positioned(
                bottom: 0,
                right: 4,
                child: IconButton(
                  icon: const Icon(Icons.edit, color: AppColors.primaryBlue),
                  // This calls the VM function. Ensure logic is updated in VM for Cloudinary.
                  onPressed: () => vm.uploadProfileImage(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Name Field (now bound to VM controller)
          TextFormField(
            controller: vm.nameController,
            decoration: const InputDecoration(
              labelText: 'Name',
              border: OutlineInputBorder(),
            ),
            onChanged: (value) => vm.updateProfileField('name', value),
          ),

          const SizedBox(height: 16),
          // Email (bound to VM emailController, read-only)
          TextFormField(
            controller: vm.emailController,
            decoration: const InputDecoration(
              labelText: 'Email',
              border: OutlineInputBorder(),
            ),
            readOnly: true,
          ),
          const SizedBox(height: 16),
          // Contact Number
          _buildTextField(
            label: 'Contact Number',
            controller: vm.contactNumberController,
            placeholder: 'Add number',
            fieldKey: 'contactNumber',
            vm: vm,
          ),
          const SizedBox(height: 16),
          // Gender
          _buildTextField(
            label: 'Gender',
            controller: vm.genderController,
            placeholder: 'Add gender',
            fieldKey: 'gender',
            vm: vm,
          ),
          const SizedBox(height: 16),
          // Date of Birth
          _buildTextField(
            label: 'Date of Birth',
            controller: vm.dobController,
            placeholder: 'yyyy-mm-dd',
            fieldKey: 'dob',
            vm: vm,
          ),
          const SizedBox(height: 16),
          // Blood Group
          _buildTextField(
            label: 'Blood Group',
            controller: vm.bloodGroupController,
            placeholder: 'Add blood group',
            fieldKey: 'bloodGroup',
            vm: vm,
          ),
          const SizedBox(height: 16),
          // Marital Status
          _buildTextField(
            label: 'Marital Status',
            controller: vm.maritalStatusController,
            placeholder: 'Add marital status',
            fieldKey: 'maritalStatus',
            vm: vm,
          ),
          const SizedBox(height: 16),
          // Height
          _buildTextField(
            label: 'Height',
            controller: vm.heightController,
            placeholder: 'Add height',
            fieldKey: 'height',
            vm: vm,
          ),
          const SizedBox(height: 16),
          // Weight
          _buildTextField(
            label: 'Weight',
            controller: vm.weightController,
            placeholder: 'Add weight',
            fieldKey: 'weight',
            vm: vm,
          ),
          const SizedBox(height: 16),
          // Emergency Contact
          _buildTextField(
            label: 'Emergency Contact',
            controller: vm.emergencyContactController,
            placeholder: 'Add emergency details',
            fieldKey: 'emergencyContact',
            vm: vm,
          ),
          const SizedBox(height: 16),
          // Location
          _buildTextField(
            label: 'Location',
            controller: vm.locationController,
            placeholder: 'Add details',
            fieldKey: 'location',
            vm: vm,
          ),
        ],
      ),
    );
  }

  Widget _buildMedicalTab(BuildContext context, ProfileViewModel vm) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildTextField(
            label: 'Allergies',
            controller: vm.allergiesController,
            placeholder: 'Add allergies',
            fieldKey: 'allergies',
            vm: vm,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            label: 'Current Medications',
            controller: vm.currentMedicationsController,
            placeholder: 'Add medications',
            fieldKey: 'currentMedications',
            vm: vm,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            label: 'Past Medications',
            controller: vm.pastMedicationsController,
            placeholder: 'Add medications',
            fieldKey: 'pastMedications',
            vm: vm,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            label: 'Chronic Diseases',
            controller: vm.chronicDiseasesController,
            placeholder: 'Add disease',
            fieldKey: 'chronicDiseases',
            vm: vm,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            label: 'Injuries',
            controller: vm.injuriesController,
            placeholder: 'Add incident',
            fieldKey: 'injuries',
            vm: vm,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            label: 'Surgeries',
            controller: vm.surgeriesController,
            placeholder: 'Add surgeries',
            fieldKey: 'surgeries',
            vm: vm,
          ),
        ],
      ),
    );
  }

  Widget _buildLifestyleTab(BuildContext context, ProfileViewModel vm) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildTextField(
            label: 'Smoking Habits',
            controller: vm.smokingHabitsController,
            placeholder: 'Add details',
            fieldKey: 'smokingHabits',
            vm: vm,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            label: 'Alcohol Consumption',
            controller: vm.alcoholConsumptionController,
            placeholder: 'Add details',
            fieldKey: 'alcoholConsumption',
            vm: vm,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            label: 'Activity Level',
            controller: vm.activityLevelController,
            placeholder: 'Add details',
            fieldKey: 'activityLevel',
            vm: vm,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            label: 'Food Preference',
            controller: vm.foodPreferenceController,
            placeholder: 'Add lifestyle',
            fieldKey: 'foodPreference',
            vm: vm,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            label: 'Occupation',
            controller: vm.occupationController,
            placeholder: 'Add occupation',
            fieldKey: 'occupation',
            vm: vm,
          ),
        ],
      ),
    );
  }

  // Helper to build a styled TextFormField bound to a controller
  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required String placeholder,
    required String fieldKey,
    required ProfileViewModel vm,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: placeholder,
        border: const OutlineInputBorder(),
      ),
      onChanged: (value) => vm.updateProfileField(fieldKey, value),
    );
  }
}
