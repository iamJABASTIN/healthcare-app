import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AppointmentSummary {
  final String id;
  final String patientId;
  final String patientName;
  final DateTime dateTime;
  final String status;

  AppointmentSummary({
    required this.id,
    required this.patientId,
    required this.patientName,
    required this.dateTime,
    required this.status,
  });
}

class DoctorHomeViewModel extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool isLoading = false;
  String? error;

  int todayCount = 0;
  int upcomingCount = 0;
  int totalPatients = 0;
  List<AppointmentSummary> upcomingAppointments = [];

  Future<void> fetchOverview() async {
    final user = _auth.currentUser;
    if (user == null) return;

    isLoading = true;
    error = null;
    notifyListeners();

    try {
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      // Query all appointments for this doctor
      final snapshot = await _db.collection('appointments').where('doctorId', isEqualTo: user.uid).get();
      final docs = snapshot.docs;

      todayCount = 0;
      upcomingCount = 0;
      final patientIds = <String>{};
      upcomingAppointments = [];

      final buffer = const Duration(minutes: 10);
      final defaultDuration = const Duration(minutes: 30);

      for (var doc in docs) {
        final data = doc.data();

        DateTime? apptDate;
        if (data['date'] is Timestamp) {
          apptDate = (data['date'] as Timestamp).toDate();
        } else if (data['date'] is String) {
          try {
            apptDate = DateTime.parse(data['date']);
          } catch (_) {
            apptDate = null;
          }
        }

        DateTime startDt = apptDate ?? DateTime.now();
        if (data['time'] is String && (data['time'] as String).isNotEmpty) {
          try {
            final t = (data['time'] as String).trim();
            if (t.toLowerCase().contains('am') || t.toLowerCase().contains('pm')) {
              final parsed = DateFormat.jm().parseLoose(t);
              startDt = DateTime(startDt.year, startDt.month, startDt.day, parsed.hour, parsed.minute);
            } else {
              final parts = t.split(':');
              final h = int.parse(parts[0]);
              final m = parts.length > 1 ? int.parse(parts[1]) : 0;
              startDt = DateTime(startDt.year, startDt.month, startDt.day, h, m);
            }
          } catch (_) {}
        }

        final endDt = startDt.add(defaultDuration);

        final patientId = data['patientId'] as String? ?? '';
        final patientName = data['patientName'] as String? ?? 'Patient';
        final status = data['status'] as String? ?? 'scheduled';

        if (patientId.isNotEmpty) patientIds.add(patientId);

        // classify as upcoming if end time is after now - buffer
        if (endDt.isAfter(now.subtract(buffer))) {
          upcomingCount += 1;
          upcomingAppointments.add(AppointmentSummary(
            id: doc.id,
            patientId: patientId,
            patientName: patientName,
            dateTime: startDt,
            status: status,
          ));
        }

        // today's count uses start time within the day
        if (startDt.isAfter(startOfDay) && startDt.isBefore(endOfDay)) {
          todayCount += 1;
        }
      }

      totalPatients = patientIds.length;

      upcomingAppointments.sort((a, b) => a.dateTime.compareTo(b.dateTime));
      if (upcomingAppointments.length > 10) upcomingAppointments = upcomingAppointments.sublist(0, 10);

      isLoading = false;
      notifyListeners();
    } catch (e) {
      isLoading = false;
      error = e.toString();
      notifyListeners();
    }
  }
}
