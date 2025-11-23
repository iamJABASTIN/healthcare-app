import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../data/models/appointment_model.dart';
import '../data/models/patient_profile_model.dart';

class AppointmentWithPatientDetails {
  final AppointmentModel appointment;
  final PatientProfileModel? patientProfile;

  AppointmentWithPatientDetails({
    required this.appointment,
    this.patientProfile,
  });
}

class DoctorAppointmentsViewModel extends ChangeNotifier {
  List<AppointmentWithPatientDetails> _upcomingAppointments = [];
  List<AppointmentWithPatientDetails> _pastAppointments = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<AppointmentWithPatientDetails> get upcomingAppointments =>
      _upcomingAppointments;
  List<AppointmentWithPatientDetails> get pastAppointments => _pastAppointments;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Fetch all appointments (both past and upcoming)
  Future<void> fetchAppointments() async {
    await Future.wait([fetchUpcomingAppointments(), fetchPastAppointments()]);
  }

  // Fetch upcoming appointments only
  Future<void> fetchUpcomingAppointments() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception("User not logged in");

      final now = DateTime.now();
      final appointmentsSnapshot = await FirebaseFirestore.instance
          .collection('appointments')
          .where('doctorId', isEqualTo: user.uid)
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(now))
          .orderBy('date')
          .orderBy('time')
          .get();

      _upcomingAppointments = await _fetchPatientDetails(appointmentsSnapshot);
    } catch (e) {
      debugPrint("Error fetching upcoming appointments: $e");
      _errorMessage = "Failed to load upcoming appointments";
      _upcomingAppointments = [];
    }

    _isLoading = false;
    notifyListeners();
  }

  // Fetch past appointments only
  Future<void> fetchPastAppointments() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception("User not logged in");

      final now = DateTime.now();
      final appointmentsSnapshot = await FirebaseFirestore.instance
          .collection('appointments')
          .where('doctorId', isEqualTo: user.uid)
          .where('date', isLessThan: Timestamp.fromDate(now))
          .orderBy('date', descending: true)
          .orderBy('time', descending: true)
          .get();

      _pastAppointments = await _fetchPatientDetails(appointmentsSnapshot);
    } catch (e) {
      debugPrint("Error fetching past appointments: $e");
      _errorMessage = "Failed to load past appointments";
      _pastAppointments = [];
    }

    _isLoading = false;
    notifyListeners();
  }

  // Helper method to fetch patient details for appointments
  Future<List<AppointmentWithPatientDetails>> _fetchPatientDetails(
    QuerySnapshot<Map<String, dynamic>> snapshot,
  ) async {
    List<AppointmentWithPatientDetails> appointmentsWithDetails = [];

    for (var doc in snapshot.docs) {
      final appointment = AppointmentModel.fromMap(doc.data(), doc.id);

      // Fetch patient profile
      PatientProfileModel? patientProfile;
      try {
        final profileDoc = await FirebaseFirestore.instance
            .collection('patients')
            .doc(appointment.patientId)
            .collection('profile')
            .doc('data')
            .get();

        if (profileDoc.exists && profileDoc.data() != null) {
          patientProfile = PatientProfileModel.fromMap(profileDoc.data()!);
        }
      } catch (e) {
        debugPrint("Error fetching patient profile: $e");
      }

      appointmentsWithDetails.add(
        AppointmentWithPatientDetails(
          appointment: appointment,
          patientProfile: patientProfile,
        ),
      );
    }

    return appointmentsWithDetails;
  }
}
