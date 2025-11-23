import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../data/models/doctor_model.dart';

class PatientHomeViewModel extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<DoctorModel> _allDoctors = [];
  List<DoctorModel> _filteredDoctors = [];

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  List<DoctorModel> get doctors => _filteredDoctors;

  // Categories for the UI
  final List<String> categories = [
    "All",
    "Cardiology",
    "General Physician",
    "Dentist",
    "Dermatology",
    "Neurology",
  ];
  String _selectedCategory = "All";
  String get selectedCategory => _selectedCategory;

  // Filters
  String _searchQuery = "";
  String _selectedGender = "All";
  String get selectedGender => _selectedGender;

  // New Filters
  String? _userLocation;
  bool _filterByLocation = true; // Default to true
  bool get filterByLocation => _filterByLocation;

  bool _sortByRating = false;
  bool get sortByRating => _sortByRating;

  final List<String> genders = ["All", "Male", "Female"];

  // Fetch all doctors from Firestore
  Future<void> fetchDoctors() async {
    _setLoading(true);
    try {
      final QuerySnapshot snapshot = await _firestore
          .collection('doctors')
          // .where('status', isEqualTo: 'approved') // Commented out for testing
          .get();

      List<DoctorModel> loadedDoctors = [];

      if (snapshot.docs.isNotEmpty) {
        loadedDoctors = snapshot.docs.map((doc) {
          return DoctorModel.fromMap(doc.data() as Map<String, dynamic>);
        }).toList();
      }

      _allDoctors = loadedDoctors;
      _filteredDoctors = loadedDoctors;

      // Apply initial filters (like location if set)
      _applyFilters();

      notifyListeners();
    } catch (e) {
      print("Error fetching doctors: $e");
    } finally {
      _setLoading(false);
    }
  }

  // Set User Location (called from UI)
  void setUserLocation(String? location) {
    _userLocation = location;
    _applyFilters();
  }

  // Apply all filters (Search + Category + Gender + Location + Sort)
  void _applyFilters() {
    List<DoctorModel> temp = List.from(_allDoctors);

    // 1. Search
    if (_searchQuery.isNotEmpty) {
      final lowerQuery = _searchQuery.toLowerCase();
      temp = temp.where((doc) {
        final nameMatches = doc.name.toLowerCase().contains(lowerQuery);
        final specMatches = doc.specialization.toLowerCase().contains(
          lowerQuery,
        );
        return nameMatches || specMatches;
      }).toList();
    }

    // 2. Category (Specialization)
    if (_selectedCategory != "All") {
      temp = temp
          .where((doc) => doc.specialization == _selectedCategory)
          .toList();
    }

    // 3. Gender
    if (_selectedGender != "All") {
      temp = temp.where((doc) => doc.gender == _selectedGender).toList();
    }

    // 4. Location (Nearby)
    if (_filterByLocation &&
        _userLocation != null &&
        _userLocation!.isNotEmpty) {
      // Simple string match for now. In real app, use Geolocation distance.
      // We check if doctor's location contains the user's city (case-insensitive)
      final userLoc = _userLocation!.toLowerCase();
      temp = temp.where((doc) {
        return doc.location.toLowerCase().contains(userLoc);
      }).toList();
    }

    // 5. Sort by Rating
    if (_sortByRating) {
      temp.sort((a, b) => b.rating.compareTo(a.rating)); // High to Low
    }

    _filteredDoctors = temp;
    notifyListeners();
  }

  // Public Setters for Filters
  void setSearchQuery(String query) {
    _searchQuery = query;
    _applyFilters();
  }

  void setCategory(String category) {
    _selectedCategory = category;
    _applyFilters();
  }

  void setGender(String gender) {
    _selectedGender = gender;
    _applyFilters();
  }

  void toggleLocationFilter(bool value) {
    _filterByLocation = value;
    _applyFilters();
  }

  void toggleSortByRating(bool value) {
    _sortByRating = value;
    _applyFilters();
  }

  void resetFilters() {
    _searchQuery = "";
    _selectedCategory = "All";
    _selectedGender = "All";
    _filterByLocation = true; // Reset to default
    _sortByRating = false;
    _applyFilters();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
