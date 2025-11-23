import 'dart:convert'; // For JSON decoding
import 'dart:io'; // For File operations
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http; // DIRECT HTTP REQUEST
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:image_picker/image_picker.dart';

import '../data/models/patient_profile_model.dart';

class ProfileViewModel extends ChangeNotifier {
  // ---------------------------------------------------------------------
  // Firebase Services
  // ---------------------------------------------------------------------
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // ---------------------------------------------------------------------
  // Cloudinary Configuration (Matches your Doctor VM)
  // ---------------------------------------------------------------------
  final String cloudName = "dn04pdikt";
  final String uploadPreset = "healthcare";

  // ---------------------------------------------------------------------
  // Loading State
  // ---------------------------------------------------------------------
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  // ---------------------------------------------------------------------
  // User Data & Model
  // ---------------------------------------------------------------------
  Map<String, dynamic>? _userData;
  Map<String, dynamic>? get userData => _userData;

  PatientProfileModel? _patientProfile;
  PatientProfileModel? get patientProfile => _patientProfile;

  String? _profileImageUrl;
  String? get profileImageUrl => _profileImageUrl;

  // ---------------------------------------------------------------------
  // Controllers
  // ---------------------------------------------------------------------
  final TextEditingController nameController = TextEditingController();
  final TextEditingController contactNumberController = TextEditingController();
  final TextEditingController genderController = TextEditingController();
  final TextEditingController dobController = TextEditingController();
  final TextEditingController bloodGroupController = TextEditingController();
  final TextEditingController maritalStatusController = TextEditingController();
  final TextEditingController heightController = TextEditingController();
  final TextEditingController weightController = TextEditingController();
  final TextEditingController emergencyContactController =
      TextEditingController();
  final TextEditingController locationController = TextEditingController();

  // Medical
  final TextEditingController allergiesController = TextEditingController();
  final TextEditingController currentMedicationsController =
      TextEditingController();
  final TextEditingController pastMedicationsController =
      TextEditingController();
  final TextEditingController chronicDiseasesController =
      TextEditingController();
  final TextEditingController injuriesController = TextEditingController();
  final TextEditingController surgeriesController = TextEditingController();

  // Lifestyle
  final TextEditingController smokingHabitsController = TextEditingController();
  final TextEditingController alcoholConsumptionController =
      TextEditingController();
  final TextEditingController activityLevelController = TextEditingController();
  final TextEditingController foodPreferenceController =
      TextEditingController();
  final TextEditingController occupationController = TextEditingController();

  // ---------------------------------------------------------------------
  // Data Fetching
  // ---------------------------------------------------------------------
  Future<void> fetchUserProfile() async {
    final User? user = _auth.currentUser;
    if (user == null) return;

    _setLoading(true);
    try {
      // 1. Fetch Basic User Doc (Name, Profile Image)
      final DocumentSnapshot userDoc = await _firestore
          .collection('users')
          .doc(user.uid)
          .get();

      if (userDoc.exists) {
        _userData = userDoc.data() as Map<String, dynamic>;
        // Load image from user doc initially
        _profileImageUrl = _userData?['profileImageUrl'];
        nameController.text = _userData?['name'] ?? '';
      }

      // 2. Fetch Detailed Patient Doc
      final DocumentSnapshot patientDoc = await _firestore
          .collection('patients')
          .doc(user.uid)
          .get();

      if (patientDoc.exists) {
        _patientProfile = PatientProfileModel.fromMap(
          patientDoc.data() as Map<String, dynamic>,
        );

        // If patient doc has a specific image, override the user doc image
        if (_patientProfile?.profileImageUrl != null &&
            _patientProfile!.profileImageUrl!.isNotEmpty) {
          _profileImageUrl = _patientProfile?.profileImageUrl;
        }

        _populateControllersFromModel();
      } else {
        _patientProfile = PatientProfileModel();
      }
    } catch (e) {
      print('Error fetching profile: $e');
    } finally {
      _setLoading(false);
    }
  }

  void _populateControllersFromModel() {
    if (_patientProfile == null) return;
    contactNumberController.text = _patientProfile?.contactNumber ?? '';
    genderController.text = _patientProfile?.gender ?? '';
    dobController.text = _patientProfile?.dob ?? '';
    bloodGroupController.text = _patientProfile?.bloodGroup ?? '';
    maritalStatusController.text = _patientProfile?.maritalStatus ?? '';
    heightController.text = _patientProfile?.height ?? '';
    weightController.text = _patientProfile?.weight ?? '';
    emergencyContactController.text = _patientProfile?.emergencyContact ?? '';
    locationController.text = _patientProfile?.location ?? '';

    allergiesController.text = _patientProfile?.allergies ?? '';
    currentMedicationsController.text =
        _patientProfile?.currentMedications ?? '';
    pastMedicationsController.text = _patientProfile?.pastMedications ?? '';
    chronicDiseasesController.text = _patientProfile?.chronicDiseases ?? '';
    injuriesController.text = _patientProfile?.injuries ?? '';
    surgeriesController.text = _patientProfile?.surgeries ?? '';

    smokingHabitsController.text = _patientProfile?.smokingHabits ?? '';
    alcoholConsumptionController.text =
        _patientProfile?.alcoholConsumption ?? '';
    activityLevelController.text = _patientProfile?.activityLevel ?? '';
    foodPreferenceController.text = _patientProfile?.foodPreference ?? '';
    occupationController.text = _patientProfile?.occupation ?? '';
  }

  // ---------------------------------------------------------------------
  // Cloudinary Upload Logic (Direct HTTP)
  // ---------------------------------------------------------------------
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
        return jsonMap['secure_url'];
      } else {
        print("Cloudinary Upload Failed: ${response.statusCode}");
        return null;
      }
    } catch (e) {
      print("Error uploading to Cloudinary: $e");
      return null;
    }
  }

  // ---------------------------------------------------------------------
  // Profile Image Workflow
  // ---------------------------------------------------------------------
  Future<void> uploadProfileImage() async {
    final User? user = _auth.currentUser;
    if (user == null) return;

    // 1. Pick Image
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image == null) return;

    _setLoading(true);

    try {
      // 2. Upload to Cloudinary using HTTP helper
      final File file = File(image.path);
      final String? downloadUrl = await _uploadToCloudinary(file);

      if (downloadUrl != null) {
        // 3. Update Firestore (Users Collection)
        await _firestore.collection('users').doc(user.uid).set({
          'profileImageUrl': downloadUrl,
        }, SetOptions(merge: true));

        // 4. Update Firestore (Patients Collection)
        await _firestore.collection('patients').doc(user.uid).set({
          'profileImageUrl': downloadUrl,
        }, SetOptions(merge: true));

        // 5. Update Local State
        _profileImageUrl = downloadUrl;
        if (_patientProfile != null) {
          _patientProfile = _patientProfile!.copyWith(
            profileImageUrl: downloadUrl,
          );
        } else {
          _patientProfile = PatientProfileModel(profileImageUrl: downloadUrl);
        }
        notifyListeners();
      }
    } catch (e) {
      print('Error processing profile image: $e');
    } finally {
      _setLoading(false);
    }
  }

  // ---------------------------------------------------------------------
  // Location Logic
  // ---------------------------------------------------------------------
  Future<void> fetchCurrentLocation() async {
    _setLoading(true);
    try {
      final bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) throw 'Location services are disabled.';

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied)
          throw 'Location permissions denied';
      }
      if (permission == LocationPermission.deniedForever)
        throw 'Location permissions permanently denied.';

      final Position position = await Geolocator.getCurrentPosition();
      final List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        final Placemark place = placemarks.first;
        String locationString =
            "${place.locality ?? ''}, ${place.administrativeArea ?? ''}";

        // Cleanup strings
        if (locationString.startsWith(', '))
          locationString = locationString.substring(2);
        if (locationString.endsWith(', '))
          locationString = locationString.substring(
            0,
            locationString.length - 2,
          );

        await updateProfileField('location', locationString);
      }
    } catch (e) {
      print('Error fetching location: $e');
    } finally {
      _setLoading(false);
    }
  }

  // ---------------------------------------------------------------------
  // Field Updates
  // ---------------------------------------------------------------------
  Future<void> updateProfileField(String field, String value) async {
    final User? user = _auth.currentUser;
    if (user == null) return;

    try {
      // CASE 1: Name (Stored in 'users' collection)
      if (field == 'name') {
        await _firestore.collection('users').doc(user.uid).set({
          'name': value,
        }, SetOptions(merge: true));

        if (_userData != null) _userData!['name'] = value;
        nameController.text = value;
      }
      // CASE 2: All other fields (Stored in 'patients' collection)
      else {
        await _firestore.collection('patients').doc(user.uid).set({
          field: value,
        }, SetOptions(merge: true));

        // Update local model
        if (_patientProfile != null) {
          final Map<String, dynamic> map = _patientProfile!.toMap();
          map[field] = value;
          _patientProfile = PatientProfileModel.fromMap(map);
        } else {
          _patientProfile = PatientProfileModel.fromMap({field: value});
        }

        _updateLocalController(field, value);
      }
      notifyListeners();
    } catch (e) {
      print('Error updating profile field $field: $e');
    }
  }

  void _updateLocalController(String field, String value) {
    switch (field) {
      case 'contactNumber':
        contactNumberController.text = value;
        break;
      case 'gender':
        genderController.text = value;
        break;
      case 'dob':
        dobController.text = value;
        break;
      case 'bloodGroup':
        bloodGroupController.text = value;
        break;
      case 'maritalStatus':
        maritalStatusController.text = value;
        break;
      case 'height':
        heightController.text = value;
        break;
      case 'weight':
        weightController.text = value;
        break;
      case 'emergencyContact':
        emergencyContactController.text = value;
        break;
      case 'location':
        locationController.text = value;
        break;
      case 'allergies':
        allergiesController.text = value;
        break;
      case 'currentMedications':
        currentMedicationsController.text = value;
        break;
      case 'pastMedications':
        pastMedicationsController.text = value;
        break;
      case 'chronicDiseases':
        chronicDiseasesController.text = value;
        break;
      case 'injuries':
        injuriesController.text = value;
        break;
      case 'surgeries':
        surgeriesController.text = value;
        break;
      case 'smokingHabits':
        smokingHabitsController.text = value;
        break;
      case 'alcoholConsumption':
        alcoholConsumptionController.text = value;
        break;
      case 'activityLevel':
        activityLevelController.text = value;
        break;
      case 'foodPreference':
        foodPreferenceController.text = value;
        break;
      case 'occupation':
        occupationController.text = value;
        break;
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  @override
  void dispose() {
    nameController.dispose();
    contactNumberController.dispose();
    genderController.dispose();
    dobController.dispose();
    bloodGroupController.dispose();
    maritalStatusController.dispose();
    heightController.dispose();
    weightController.dispose();
    emergencyContactController.dispose();
    locationController.dispose();
    allergiesController.dispose();
    currentMedicationsController.dispose();
    pastMedicationsController.dispose();
    chronicDiseasesController.dispose();
    injuriesController.dispose();
    surgeriesController.dispose();
    smokingHabitsController.dispose();
    alcoholConsumptionController.dispose();
    activityLevelController.dispose();
    foodPreferenceController.dispose();
    occupationController.dispose();
    super.dispose();
  }
}
