import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../data/models/appointment_model.dart';
import '../data/models/doctor_model.dart';

class AppointmentWithDoctorDetails {
  final AppointmentModel appointment;
  final DoctorModel? doctor;

  AppointmentWithDoctorDetails({required this.appointment, this.doctor});
}

class PatientAppointmentsViewModel extends ChangeNotifier {
  List<AppointmentWithDoctorDetails> _upcomingAppointments = [];
  List<AppointmentWithDoctorDetails> _pastAppointments = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<AppointmentWithDoctorDetails> get upcomingAppointments => _upcomingAppointments;
  List<AppointmentWithDoctorDetails> get pastAppointments => _pastAppointments;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> fetchAppointments() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('User not logged in');

      // Fetch all appointments for the patient and partition client-side by end time
      final snapshot = await FirebaseFirestore.instance
          .collection('appointments')
          .where('patientId', isEqualTo: user.uid)
          .orderBy('date')
          .orderBy('time')
          .get();

      final all = await _fetchDoctorDetails(snapshot);

      final now = DateTime.now();
      _upcomingAppointments = [];
      _pastAppointments = [];

      for (var item in all) {
        final appt = item.appointment;
        final end = _computeAppointmentEndDateTime(appt);
        if (end.isBefore(now)) {
          _pastAppointments.add(item);
        } else {
          _upcomingAppointments.add(item);
        }
      }
    } catch (e) {
      debugPrint('Error fetching appointments: $e');
      _errorMessage = 'Failed to load appointments';
      _upcomingAppointments = [];
      _pastAppointments = [];
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> fetchUpcomingAppointments() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('User not logged in');

      final now = DateTime.now();
      final snapshot = await FirebaseFirestore.instance
          .collection('appointments')
          .where('patientId', isEqualTo: user.uid)
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(now))
          .orderBy('date')
          .orderBy('time')
          .get();

      _upcomingAppointments = await _fetchDoctorDetails(snapshot);
    } catch (e) {
      debugPrint('Error fetching upcoming appointments: $e');
      _errorMessage = 'Failed to load upcoming appointments';
      _upcomingAppointments = [];
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> fetchPastAppointments() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('User not logged in');

      final now = DateTime.now();
      final snapshot = await FirebaseFirestore.instance
          .collection('appointments')
          .where('patientId', isEqualTo: user.uid)
          .where('date', isLessThan: Timestamp.fromDate(now))
          .orderBy('date', descending: true)
          .orderBy('time', descending: true)
          .get();

      _pastAppointments = await _fetchDoctorDetails(snapshot);
    } catch (e) {
      debugPrint('Error fetching past appointments: $e');
      _errorMessage = 'Failed to load past appointments';
      _pastAppointments = [];
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<List<AppointmentWithDoctorDetails>> _fetchDoctorDetails(
      QuerySnapshot<Map<String, dynamic>> snapshot) async {
    List<AppointmentWithDoctorDetails> list = [];

    for (var doc in snapshot.docs) {
      var appointment = AppointmentModel.fromMap(doc.data(), doc.id);

      DoctorModel? doctor;
      try {
        final docRef = await FirebaseFirestore.instance
            .collection('doctors')
            .doc(appointment.doctorId)
            .get();

        if (docRef.exists && docRef.data() != null) {
          doctor = DoctorModel.fromMap(docRef.data() as Map<String, dynamic>);
        }
      } catch (e) {
        debugPrint('Error fetching doctor details: $e');
      }

      list.add(AppointmentWithDoctorDetails(
        appointment: appointment,
        doctor: doctor,
      ));
    }

    return list;
  }

  // Compute the end DateTime of an appointment by parsing the `time` string.
  // Supports formats like "11:00 AM - 2:00 PM" or single times like "11:00 AM" or "14:00".
  DateTime _computeAppointmentEndDateTime(AppointmentModel appt) {
    final date = appt.date;
    final timeStr = appt.time;

    String endPart = timeStr;
    if (timeStr.contains('-')) {
      final parts = timeStr.split('-');
      if (parts.length > 1) endPart = parts[1].trim();
    }

    DateTime? parsed;
    // Try parsing common formats
    try {
      // e.g. "11:00 AM"
      parsed = DateFormat.jm().parseLoose(endPart);
    } catch (_) {}

    if (parsed == null) {
      try {
        // e.g. "14:00"
        parsed = DateFormat('HH:mm').parseLoose(endPart);
      } catch (_) {}
    }

    if (parsed == null) {
      // Fallback: treat end of day
      return DateTime(date.year, date.month, date.day, 23, 59, 59);
    }

    // Combine date with parsed time's hour and minute
    final endDateTime = DateTime(date.year, date.month, date.day, parsed.hour, parsed.minute);
    return endDateTime;
  }
}
