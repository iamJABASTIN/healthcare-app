import 'dart:convert'; // For decoding JSON response
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http; // Required for Cloudinary
import 'package:cloud_firestore/cloud_firestore.dart'; // Required for Database
import 'package:firebase_auth/firebase_auth.dart'; // Required to get User ID

class DoctorProfileViewModel extends ChangeNotifier {
  // --- Basic Details Controllers ---
  final TextEditingController nameController = TextEditingController();
  final TextEditingController cityController = TextEditingController();
  final TextEditingController experienceController = TextEditingController();

  // --- Education Details Controllers ---
  final TextEditingController qualificationController = TextEditingController();
  final TextEditingController regNumberController = TextEditingController();
  final TextEditingController regCouncilController = TextEditingController();
  final TextEditingController regYearController = TextEditingController();

  // --- Dropdown Values ---
  String? selectedSpecialty;
  String? selectedGender;

  // --- File Upload State ---
  // 1. Identity Proof (Admin Only)
  File? _identityProofFile;
  File? get identityProofFile => _identityProofFile;
  String? identityProofFileName; // To show in UI

  // 2. Profile Picture (Public)
  File? _profileImageFile;
  File? get profileImageFile => _profileImageFile;
  String? profileImageUrl; // Existing URL from DB

  bool isLoading = false;

  // --- CLOUDINARY CONFIGURATION (Replace these!) ---
  final String cloudName = "dn04pdikt";
  final String uploadPreset = "healthcare";

  // Lists for Dropdowns
  final List<String> specialties = [
    "General",
    "Cardiology",
    "Dentist",
    "General Physician",
    "Dermatology",
  ];
  final List<String> genders = ["Male", "Female", "Other"];

  // --- Logic: Setters ---
  void setSpecialty(String? val) {
    selectedSpecialty = val;
    notifyListeners();
  }

  void setGender(String? val) {
    selectedGender = val;
    notifyListeners();
  }

  // --- Logic: Image Pickers ---
  Future<void> pickIdentityProof() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      _identityProofFile = File(image.path);
      identityProofFileName = image.name;
      notifyListeners();
    }
  }

  Future<void> pickProfileImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      _profileImageFile = File(image.path);
      notifyListeners();
    }
  }

  // --- Logic: Upload to Cloudinary ---
  Future<String?> _uploadToCloudinary(File file) async {
    try {
      final url = Uri.parse(
        'https://api.cloudinary.com/v1_1/$cloudName/image/upload',
      );

      final request = http.MultipartRequest('POST', url)
        ..fields['upload_preset'] = uploadPreset
        ..files.add(await http.MultipartFile.fromPath('file', file.path));

      final response = await request.send();

      if (response.statusCode == 200) {
        final responseData = await response.stream.toBytes();
        final responseString = String.fromCharCodes(responseData);
        final jsonMap = jsonDecode(responseString);
        return jsonMap['secure_url']; // This is the public URL
      } else {
        print("Cloudinary Upload Failed: ${response.statusCode}");
        return null;
      }
    } catch (e) {
      print("Error uploading to Cloudinary: $e");
      return null;
    }
  }

  // --- Logic: Save Profile ---
  Future<void> saveProfile() async {
    // 1. Basic Validation
    if (nameController.text.isEmpty || selectedSpecialty == null) {
      print("Basic details missing");
      return;
    }

    isLoading = true;
    notifyListeners();

    try {
      // 2. Get Current User ID
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception("No user logged in");
      }

      // 3. Upload Images (if selected)
      String? proofUrl;
      if (_identityProofFile != null) {
        proofUrl = await _uploadToCloudinary(_identityProofFile!);
      }

      String? newProfileImageUrl;
      if (_profileImageFile != null) {
        newProfileImageUrl = await _uploadToCloudinary(_profileImageFile!);
      }

      // 4. Create Data Map
      final doctorData = {
        "name": nameController.text,
        "email": user.email,
        "role": "doctor", // Ensure role is set
        // Root level fields for easier Filtering
        "specialization": selectedSpecialty,
        "location": cityController.text,

        // Detailed Profile Data
        "profile": {
          "gender": selectedGender,
          "experience": experienceController.text,
          "profileImageUrl":
              newProfileImageUrl ??
              profileImageUrl ??
              "", // Use new, or existing, or empty
          "education": {
            "qualification": qualificationController.text,
            "regNumber": regNumberController.text,
            "regCouncil": regCouncilController.text,
            "regYear": regYearController.text,
            // Only update proof URL if a new one was uploaded, otherwise keep existing (logic handled by merge, but explicit here for clarity if we were not merging deep maps)
            // Since we are doing SetOptions(merge: true), we need to be careful.
            // If proofUrl is null (no new file), we don't want to overwrite with null if we were replacing.
            // But here we are constructing the map.
            if (proofUrl != null) "identityProofUrl": proofUrl,
          },
        },
        "updatedAt": FieldValue.serverTimestamp(),
      };

      // 5. Save to Firestore (Merge = true updates existing fields without deleting others)
      await FirebaseFirestore.instance
          .collection('doctors')
          .doc(user.uid)
          .set(doctorData, SetOptions(merge: true));

      print("Profile Saved Successfully: $doctorData");

      // Update local state if needed
      if (newProfileImageUrl != null) {
        profileImageUrl = newProfileImageUrl;
        _profileImageFile = null; // Clear selection
      }
      if (proofUrl != null) {
        _identityProofFile = null;
      }
    } catch (e) {
      print("Error saving profile: $e");
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // --- Logic: Fetch Profile ---
  Future<void> fetchProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    isLoading = true;
    notifyListeners();

    try {
      final doc = await FirebaseFirestore.instance
          .collection('doctors')
          .doc(user.uid)
          .get();

      if (doc.exists) {
        final data = doc.data()!;
        nameController.text = data['name'] ?? '';
        cityController.text = data['location'] ?? '';
        selectedSpecialty = data['specialization'];

        if (data['profile'] != null) {
          final profile = data['profile'];
          selectedGender = profile['gender'];
          experienceController.text = profile['experience'] ?? '';
          profileImageUrl = profile['profileImageUrl'];

          if (profile['education'] != null) {
            final edu = profile['education'];
            qualificationController.text = edu['qualification'] ?? '';
            regNumberController.text = edu['regNumber'] ?? '';
            regCouncilController.text = edu['regCouncil'] ?? '';
            regYearController.text = edu['regYear'] ?? '';
          }
        }
        notifyListeners();
      }
    } catch (e) {
      print("Error fetching profile: $e");
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // Cleanup
  @override
  void dispose() {
    nameController.dispose();
    cityController.dispose();
    experienceController.dispose();
    qualificationController.dispose();
    regNumberController.dispose();
    regCouncilController.dispose();
    regYearController.dispose();
    super.dispose();
  }
}
