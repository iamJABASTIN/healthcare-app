import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../data/models/patient_profile_model.dart';

class ProfileViewModel extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  // Basic User Info (Name, Role)
  Map<String, dynamic>? _userData;
  Map<String, dynamic>? get userData => _userData;

  // Detailed Patient Info
  PatientProfileModel? _patientProfile;
  PatientProfileModel? get patientProfile => _patientProfile;

  // Fetch Data
  Future<void> fetchUserProfile() async {
    User? user = _auth.currentUser;
    if (user == null) return;

    _setLoading(true);
    try {
      // 1. Fetch Basic Info (Name, etc from 'users' or 'patients')
      DocumentSnapshot userDoc = await _firestore
          .collection('users')
          .doc(user.uid)
          .get();
      if (userDoc.exists) {
        _userData = userDoc.data() as Map<String, dynamic>;
      }

      // 2. Fetch Detailed Profile (This might be in a subcollection or the same doc)
      // For this example, we assume it's in 'patients/{uid}' merged with basic info
      DocumentSnapshot patientDoc = await _firestore
          .collection('patients')
          .doc(user.uid)
          .get();

      if (patientDoc.exists) {
        // We merge the data to fill the model
        _patientProfile = PatientProfileModel.fromMap(
          patientDoc.data() as Map<String, dynamic>,
        );
      } else {
        // If no profile yet, create empty
        _patientProfile = PatientProfileModel();
      }
    } catch (e) {
      print("Error fetching profile: $e");
    } finally {
      _setLoading(false);
    }
  }

  // Fetch Current Location
  Future<void> fetchCurrentLocation() async {
    _setLoading(true);
    try {
      bool serviceEnabled;
      LocationPermission permission;

      // 1. Check Service
      serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw 'Location services are disabled.';
      }

      // 2. Check Permissions
      permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw 'Location permissions are denied';
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw 'Location permissions are permanently denied, we cannot request permissions.';
      }

      // 3. Get Position
      Position position = await Geolocator.getCurrentPosition();

      // 4. Get Address
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        // Construct location string (e.g., "Locality, City")
        String locationString =
            "${place.locality ?? ''}, ${place.administrativeArea ?? ''}";
        if (locationString.startsWith(", ")) {
          locationString = locationString.substring(2);
        }
        if (locationString.endsWith(", ")) {
          locationString = locationString.substring(
            0,
            locationString.length - 2,
          );
        }

        // Update Profile
        await updateProfileField('location', locationString);
      }
    } catch (e) {
      print("Error fetching location: $e");
      // You might want to expose an error message to the UI
    } finally {
      _setLoading(false);
    }
  }

  // Helper to handle updates
  Future<void> updateProfileField(String field, String value) async {
    print("DEBUG: updateProfileField called with field: $field, value: $value");
    User? user = _auth.currentUser;
    if (user == null) {
      print("DEBUG: User is null, returning.");
      return;
    }

    _setLoading(true);
    try {
      // Update Firestore
      print("DEBUG: Updating Firestore...");
      await _firestore.collection('patients').doc(user.uid).set({
        field: value,
      }, SetOptions(merge: true));
      print("DEBUG: Firestore updated.");

      // Update Local State
      if (_patientProfile != null) {
        print("DEBUG: Updating existing profile.");
        Map<String, dynamic> currentMap = _patientProfile!.toMap();
        currentMap[field] = value;
        _patientProfile = PatientProfileModel.fromMap(currentMap);
      } else {
        print("DEBUG: Creating new profile.");
        _patientProfile = PatientProfileModel.fromMap({field: value});
      }

      print("DEBUG: New location in profile: ${_patientProfile?.location}");

      notifyListeners();
    } catch (e) {
      print("Error updating profile field $field: $e");
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
