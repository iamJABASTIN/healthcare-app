import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminAppointmentsViewModel extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool isLoading = false;
  String? error;

  int totalCount = 0;
  int todayCount = 0;
  int monthCount = 0;
  // Status breakdown
  int scheduledCount = 0;
  int confirmedCount = 0;
  int completedCount = 0;
  int cancelledCount = 0;

  Future<void> fetchCounts() async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      // All-time count
      final allSnapshot = await _firestore.collection('appointments').get();
      totalCount = allSnapshot.docs.length;

      final now = DateTime.now();

      // Today range (start of day to end of day)
      final startOfDay = DateTime(now.year, now.month, now.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final todaySnapshot = await _firestore
          .collection('appointments')
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('date', isLessThan: Timestamp.fromDate(endOfDay))
          .get();

      todayCount = todaySnapshot.docs.length;

        // Month range (start of month to start of next month)
      final startOfMonth = DateTime(now.year, now.month, 1);
      final startOfNextMonth = (now.month == 12)
          ? DateTime(now.year + 1, 1, 1)
          : DateTime(now.year, now.month + 1, 1);

      final monthSnapshot = await _firestore
          .collection('appointments')
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth))
          .where('date', isLessThan: Timestamp.fromDate(startOfNextMonth))
          .get();

      monthCount = monthSnapshot.docs.length;
      // Status breakdown - compute from allSnapshot (already retrieved)
      final Map<String, int> statusCounts = {};
      for (final doc in allSnapshot.docs) {
        final data = doc.data();
        final status = (data['status'] ?? 'pending').toString();
        statusCounts[status] = (statusCounts[status] ?? 0) + 1;
      }

      scheduledCount = statusCounts['pending'] ?? 0;
      confirmedCount = statusCounts['confirmed'] ?? 0;
      completedCount = statusCounts['completed'] ?? 0;
      cancelledCount = statusCounts['cancelled'] ?? 0;
    } catch (e) {
      error = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
