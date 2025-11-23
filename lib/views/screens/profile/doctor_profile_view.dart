import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../view_models/auth_view_model.dart';
import '../../../view_models/doctor_profile_view_model.dart'; // Corrected import path

class DoctorProfileView extends StatefulWidget {
  @override
  State<DoctorProfileView> createState() => _DoctorProfileViewState();
}

class _DoctorProfileViewState extends State<DoctorProfileView> {
  @override
  void initState() {
    super.initState();
    // Fetch profile data when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<DoctorProfileViewModel>(
        context,
        listen: false,
      ).fetchProfile();
    });
  }

  @override
  Widget build(BuildContext context) {
    // Access your ViewModel
    final viewModel = Provider.of<DoctorProfileViewModel>(context);

    return DefaultTabController(
      length: 2, // Number of tabs
      child: Scaffold(
        appBar: AppBar(
          title: Text("Edit Profile"),
          actions: [
            IconButton(
              icon: Icon(Icons.logout),
              onPressed: () async {
                // Sign out
                await Provider.of<AuthViewModel>(
                  context,
                  listen: false,
                ).signOut();
                // Navigate to Login (clearing stack)
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/',
                  (route) => false,
                );
              },
            ),
          ],
          bottom: TabBar(
            indicatorColor: Colors.white54,
            labelColor: Colors.white54,
            unselectedLabelColor: Colors.white,
            tabs: [
              Tab(text: "Basic Details", icon: Icon(Icons.person)),
              Tab(text: "Education & Proof", icon: Icon(Icons.school)),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildBasicDetailsTab(viewModel),
            _buildEducationTab(viewModel),
          ],
        ),
        bottomNavigationBar: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SizedBox(
            height: 50,
            child: ElevatedButton(
              onPressed: viewModel.isLoading
                  ? null
                  : () => viewModel.saveProfile(),
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: viewModel.isLoading
                  ? CircularProgressIndicator(color: Colors.white)
                  : Text("Save Profile", style: TextStyle(fontSize: 16)),
            ),
          ),
        ),
      ),
    );
  }

  // --- TAB 1: Basic Details ---
  Widget _buildBasicDetailsTab(DoctorProfileViewModel vm) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Personal Information",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 15),

          // Name
          TextFormField(
            controller: vm.nameController,
            decoration: InputDecoration(
              labelText: "Full Name",
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.person_outline),
            ),
          ),
          SizedBox(height: 15),

          // City
          TextFormField(
            controller: vm.cityController,
            decoration: InputDecoration(
              labelText: "City",
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.location_city),
            ),
          ),
          SizedBox(height: 15),

          // Specialty Dropdown
          DropdownButtonFormField<String>(
            value: vm.selectedSpecialty,
            items: vm.specialties
                .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                .toList(),
            onChanged: (val) => vm.setSpecialty(val),
            decoration: InputDecoration(
              labelText: "Specialty",
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.medical_services_outlined),
            ),
          ),
          SizedBox(height: 15),

          // Gender Dropdown
          DropdownButtonFormField<String>(
            value: vm.selectedGender,
            items: vm.genders
                .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                .toList(),
            onChanged: (val) => vm.setGender(val),
            decoration: InputDecoration(
              labelText: "Gender",
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.people_outline),
            ),
          ),
          SizedBox(height: 15),

          // Experience
          TextFormField(
            controller: vm.experienceController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: "Experience (Years)",
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.timeline),
            ),
          ),
        ],
      ),
    );
  }

  // --- TAB 2: Education & Proof ---
  Widget _buildEducationTab(DoctorProfileViewModel vm) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Medical Registration",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 15),

          // Qualification
          TextFormField(
            controller: vm.qualificationController,
            decoration: InputDecoration(
              labelText: "Qualification (e.g., MBBS, MD)",
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.school_outlined),
            ),
          ),
          SizedBox(height: 15),

          // Registration Number
          TextFormField(
            controller: vm.regNumberController,
            decoration: InputDecoration(
              labelText: "Registration Number",
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.confirmation_number_outlined),
            ),
          ),
          SizedBox(height: 15),

          // Registration Council
          TextFormField(
            controller: vm.regCouncilController,
            decoration: InputDecoration(
              labelText: "Registration Council",
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.account_balance_outlined),
            ),
          ),
          SizedBox(height: 15),

          // Registration Year
          TextFormField(
            controller: vm.regYearController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: "Registration Year",
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.calendar_today),
            ),
          ),
          SizedBox(height: 25),

          Divider(),
          SizedBox(height: 10),

          Text(
            "Identity Proof",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 10),

          // Identity Proof Upload Button (Custom UI)
          InkWell(
            onTap: () => vm.pickIdentityProof(),
            child: Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.upload_file, color: Colors.blue),
                  SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          vm.identityProofFileName ?? "Upload ID / Certificate",
                          style: TextStyle(fontWeight: FontWeight.bold),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          vm.identityProofFileName == null
                              ? "Tap to select image"
                              : "Image selected successfully",
                          style: TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  if (vm.identityProofFileName != null)
                    Icon(Icons.check_circle, color: Colors.green),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
