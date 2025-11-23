import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

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
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception("User not logged in");

      final now = DateTime.now();
      // buffer: treat appointments whose end time is within 10 minutes in the past as upcoming
      final buffer = Duration(minutes: 10);

      final snapshot = await FirebaseFirestore.instance
          .collection('appointments')
          .where('doctorId', isEqualTo: user.uid)
          .orderBy('date')
          .orderBy('time')
          .get();

      final all = await _fetchPatientDetails(snapshot);

      // Partition client-side using computed end time (default duration 30 mins)
      final List<AppointmentWithPatientDetails> upcoming = [];
      final List<AppointmentWithPatientDetails> past = [];

      for (var item in all) {
        final appt = item.appointment;

        DateTime? startDt;
        try {
          startDt = _combineDateAndTime(appt.date, appt.time);
        } catch (_) {
          startDt = appt.date;
        }

        final duration = const Duration(minutes: 30);
        final endDt = (startDt ?? appt.date).add(duration);

        if (endDt.isAfter(now.subtract(buffer))) {
          upcoming.add(item);
        } else {
          past.add(item);
        }
      }

      // sort upcoming ascending, past descending
      upcoming.sort((a, b) => _compareAppointmentDate(a.appointment, b.appointment));
      past.sort((a, b) => _compareAppointmentDate(b.appointment, a.appointment));

      _upcomingAppointments = upcoming;
      _pastAppointments = past;
    } catch (e) {
      debugPrint("Error fetching appointments: $e");
      _errorMessage = "Failed to load appointments";
      _upcomingAppointments = [];
      _pastAppointments = [];
    }

    _isLoading = false;
    notifyListeners();
  }

  DateTime? _combineDateAndTime(DateTime date, String timeStr) {
    if (timeStr.isEmpty) return date;

    // try formats: 'HH:mm' or 'h:mm a'
    try {
      final t = timeStr.trim();
      if (t.toLowerCase().contains('am') || t.toLowerCase().contains('pm')) {
        final parsed = DateFormat.jm().parseLoose(t);
        return DateTime(date.year, date.month, date.day, parsed.hour, parsed.minute);
      } else {
        final parts = t.split(':');
        final h = int.parse(parts[0]);
        final m = parts.length > 1 ? int.parse(parts[1]) : 0;
        return DateTime(date.year, date.month, date.day, h, m);
      }
    } catch (e) {
      debugPrint('Error parsing time "$timeStr": $e');
      return date;
    }
  }

  int _compareAppointmentDate(AppointmentModel a, AppointmentModel b) {
    final da = _combineDateAndTime(a.date, a.time) ?? a.date;
    final db = _combineDateAndTime(b.date, b.time) ?? b.date;
    return da.compareTo(db);
  }

  // Helper method to fetch patient details for appointments
  Future<List<AppointmentWithPatientDetails>> _fetchPatientDetails(
    QuerySnapshot<Map<String, dynamic>> snapshot,
  ) async {
    List<AppointmentWithPatientDetails> appointmentsWithDetails = [];

    for (var doc in snapshot.docs) {
      var appointment = AppointmentModel.fromMap(doc.data(), doc.id);

      // Fetch patient name if missing
      if (appointment.patientName.isEmpty) {
        try {
          final patientDoc = await FirebaseFirestore.instance
              .collection('patients')
              .doc(appointment.patientId)
              .get();
          if (patientDoc.exists) {
            final name = patientDoc.data()?['name'] as String?;
            if (name != null && name.isNotEmpty) {
              appointment = appointment.copyWith(patientName: name);
            }
          }
        } catch (e) {
          debugPrint("Error fetching patient name: $e");
        }
      }

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
