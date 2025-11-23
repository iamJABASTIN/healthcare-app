import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../data/models/doctor_model.dart';

class AdminDoctorsViewModel extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool isLoading = false;
  String? error;

  List<DoctorModel> _pendingDoctors = [];
  List<DoctorModel> get pendingDoctors => _pendingDoctors;
  int totalDoctorsCount = 0;
  int pendingDoctorsCount = 0;
  List<MapEntry<String, int>> topSpecialties = [];

  Future<void> fetchPendingDoctors() async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      final snapshot = await _firestore
          .collection('doctors')
          .where('status', isEqualTo: 'pending_approval')
          .get();

        _pendingDoctors = snapshot.docs
          .map((d) => DoctorModel.fromMap(d.data()))
          .toList();
        // update pending count
        pendingDoctorsCount = _pendingDoctors.length;
        // update total count as well
        final allSnapshot = await _firestore.collection('doctors').get();
        totalDoctorsCount = allSnapshot.docs.length;
    } catch (e) {
      error = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

    Future<void> fetchCounts() async {
      isLoading = true;
      error = null;
      notifyListeners();

      try {
        final allSnapshot = await _firestore.collection('doctors').get();
        totalDoctorsCount = allSnapshot.docs.length;
        final pendingSnapshot = await _firestore
            .collection('doctors')
            .where('status', isEqualTo: 'pending_approval')
            .get();
        pendingDoctorsCount = pendingSnapshot.docs.length;

        // Compute top specialties
        final Map<String, int> counts = {};
        for (final doc in allSnapshot.docs) {
          final data = doc.data();
          final spec = (data['specialization'] ?? 'Unknown').toString();
          counts[spec] = (counts[spec] ?? 0) + 1;
        }
        final entries = counts.entries.toList();
        entries.sort((a, b) => b.value.compareTo(a.value));
        topSpecialties = entries.take(5).toList();
      } catch (e) {
        error = e.toString();
      } finally {
        isLoading = false;
        notifyListeners();
      }
    }

  Future<bool> approveDoctor(String uid) async {
    try {
      await _firestore.collection('doctors').doc(uid).update({
        'status': 'approved',
        'approvedAt': FieldValue.serverTimestamp(),
      });

      // Also update the central users collection isVerified flag
      await _firestore.collection('users').doc(uid).update({'isVerified': true});

      // Remove locally
      _pendingDoctors.removeWhere((d) => d.uid == uid);
      notifyListeners();
      return true;
    } catch (e) {
      error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> rejectDoctor(String uid, {String? reason}) async {
    try {
      await _firestore.collection('doctors').doc(uid).update({
        'status': 'rejected',
        'rejectedAt': FieldValue.serverTimestamp(),
        if (reason != null) 'rejectionReason': reason,
      });

      await _firestore.collection('users').doc(uid).update({'isVerified': false});

      _pendingDoctors.removeWhere((d) => d.uid == uid);
      notifyListeners();
      return true;
    } catch (e) {
      error = e.toString();
      notifyListeners();
      return false;
    }
  }
}
