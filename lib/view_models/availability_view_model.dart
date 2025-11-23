import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../data/models/availability_model.dart';

class AvailabilityViewModel extends ChangeNotifier {
  // State for each day of the week (1-7)
  Map<int, AvailabilityModel?> _availability = {};
  bool _isLoading = false;
  String? _errorMessage;
  bool _isSaving = false;

  // Getters
  Map<int, AvailabilityModel?> get availability => _availability;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isSaving => _isSaving;

  // Fetch availability for the logged-in doctor
  Future<void> fetchAvailability() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception("User not logged in");

      debugPrint("\n=== FETCHING AVAILABILITY ===");
      debugPrint("User ID: ${user.uid}");
      debugPrint("Path: doctors/${user.uid}/availability");

      final snapshot = await FirebaseFirestore.instance
          .collection('doctors')
          .doc(user.uid)
          .collection('availability')
          .get();

      debugPrint("Documents found: ${snapshot.docs.length}");

      _availability = {};
      for (var doc in snapshot.docs) {
        debugPrint("\n--- Document: ${doc.id} ---");
        debugPrint("Data: ${doc.data()}");

        final model = AvailabilityModel.fromMap(doc.data(), doc.id);
        debugPrint(
          "Parsed model - Day: ${model.dayOfWeek}, Active: ${model.isActive}, Time slots: ${model.timeSlots.length}",
        );

        _availability[model.dayOfWeek] = model;
      }

      debugPrint(
        "\n✅ Fetch complete - Total days loaded: ${_availability.length}",
      );
    } catch (e, stackTrace) {
      debugPrint("❌ Error fetching availability: $e");
      debugPrint("Stack trace: $stackTrace");
      _errorMessage = "Failed to load availability";
      _availability = {};
    }

    _isLoading = false;
    notifyListeners();
  }

  // Check if a day is enabled
  bool isDayEnabled(int dayOfWeek) {
    final model = _availability[dayOfWeek];
    return model?.isActive ?? false;
  }

  // Get time slots for a day
  List<TimeSlotModel> getTimeSlots(int dayOfWeek) {
    final model = _availability[dayOfWeek];
    return model?.timeSlots ?? [];
  }

  // Toggle day enabled/disabled
  void toggleDay(int dayOfWeek, bool enabled) {
    final existing = _availability[dayOfWeek];

    if (enabled) {
      _availability[dayOfWeek] =
          existing?.copyWith(isActive: true, updatedAt: DateTime.now()) ??
          AvailabilityModel(
            id: '',
            doctorId: FirebaseAuth.instance.currentUser?.uid ?? '',
            dayOfWeek: dayOfWeek,
            timeSlots: [],
            isActive: true,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );
    } else {
      if (existing != null) {
        _availability[dayOfWeek] = existing.copyWith(
          isActive: false,
          updatedAt: DateTime.now(),
        );
      }
    }

    notifyListeners();
  }

  // Add a time slot to a specific day
  String? addTimeSlot(
    int dayOfWeek,
    TimeOfDay startTime,
    TimeOfDay endTime, {
    RecurringRule? recurringRule,
  }) {
    // Validate time range
    final newSlot = TimeSlotModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      startTime: startTime,
      endTime: endTime,
    );

    if (!newSlot.isValid) {
      return "End time must be after start time";
    }

    // Get existing slots for the day
    final existing = _availability[dayOfWeek];
    final existingSlots = existing?.timeSlots ?? [];

    // Check for overlaps
    for (var slot in existingSlots) {
      if (newSlot.overlapsWith(slot)) {
        return "This time slot overlaps with existing slot: ${slot.displayTime}";
      }
    }

    // If recurring rule is provided, apply to multiple days
    if (recurringRule != null && recurringRule.type == RecurringType.weekly) {
      for (var day in recurringRule.daysOfWeek) {
        _addSlotToDay(
          day,
          newSlot.copyWith(id: '${newSlot.id}_day$day'),
          recurringRule,
        );
      }
    } else {
      // Add to single day
      _addSlotToDay(dayOfWeek, newSlot, null);
    }

    notifyListeners();
    return null; // Success
  }

  void _addSlotToDay(int dayOfWeek, TimeSlotModel slot, RecurringRule? rule) {
    final existing = _availability[dayOfWeek];
    final updatedSlots = List<TimeSlotModel>.from(existing?.timeSlots ?? []);
    updatedSlots.add(slot);

    _availability[dayOfWeek] =
        (existing ??
                AvailabilityModel(
                  id: '',
                  doctorId: FirebaseAuth.instance.currentUser?.uid ?? '',
                  dayOfWeek: dayOfWeek,
                  timeSlots: [],
                  isActive: true,
                  createdAt: DateTime.now(),
                  updatedAt: DateTime.now(),
                ))
            .copyWith(
              timeSlots: updatedSlots,
              recurringRule: rule,
              updatedAt: DateTime.now(),
            );

    notifyListeners();
  }

  // Remove a time slot from a specific day
  void removeTimeSlot(int dayOfWeek, String slotId) {
    final existing = _availability[dayOfWeek];
    if (existing == null) return;

    final updatedSlots = existing.timeSlots
        .where((slot) => slot.id != slotId)
        .toList();

    _availability[dayOfWeek] = existing.copyWith(
      timeSlots: updatedSlots,
      updatedAt: DateTime.now(),
    );

    notifyListeners();
  }

  // Update an existing time slot
  String? updateTimeSlot(
    int dayOfWeek,
    String slotId,
    TimeOfDay startTime,
    TimeOfDay endTime,
  ) {
    final existing = _availability[dayOfWeek];
    if (existing == null) return "Day not found";

    final updatedSlot = TimeSlotModel(
      id: slotId,
      startTime: startTime,
      endTime: endTime,
    );

    if (!updatedSlot.isValid) {
      return "End time must be after start time";
    }

    // Check for overlaps (excluding current slot)
    for (var slot in existing.timeSlots) {
      if (slot.id != slotId && updatedSlot.overlapsWith(slot)) {
        return "This time slot overlaps with: ${slot.displayTime}";
      }
    }

    final updatedSlots = existing.timeSlots.map((slot) {
      return slot.id == slotId ? updatedSlot : slot;
    }).toList();

    _availability[dayOfWeek] = existing.copyWith(
      timeSlots: updatedSlots,
      updatedAt: DateTime.now(),
    );

    notifyListeners();
    return null; // Success
  }

  // Save all availability to Firestore
  Future<bool> saveAvailability() async {
    _isSaving = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception("User not logged in");

      debugPrint("=== SAVING AVAILABILITY ===");
      debugPrint("User ID: ${user.uid}");
      debugPrint("Days to save: ${_availability.length}");

      final batch = FirebaseFirestore.instance.batch();
      final availabilityRef = FirebaseFirestore.instance
          .collection('doctors')
          .doc(user.uid)
          .collection('availability');

      int documentsToSave = 0;

      // Update or create documents for each day
      for (var entry in _availability.entries) {
        final dayOfWeek = entry.key;
        final model = entry.value;

        debugPrint("\n--- Day $dayOfWeek ---");
        debugPrint("Model exists: ${model != null}");

        if (model != null) {
          debugPrint("Is Active: ${model.isActive}");
          debugPrint("Time Slots Count: ${model.timeSlots.length}");
          debugPrint(
            "Time Slots: ${model.timeSlots.map((s) => s.displayTime).toList()}",
          );

          final docId = model.id.isEmpty ? 'day_$dayOfWeek' : model.id;
          final docRef = availabilityRef.doc(docId);

          final updatedModel = model.copyWith(id: docId, doctorId: user.uid);
          final dataToSave = updatedModel.toMap();

          debugPrint("Document ID: $docId");
          debugPrint("Full path: doctors/${user.uid}/availability/$docId");
          debugPrint("Data to save: $dataToSave");

          batch.set(docRef, dataToSave);
          documentsToSave++;
        }
      }

      debugPrint("\n=== COMMITTING BATCH ===");
      debugPrint("Total documents to save: $documentsToSave");

      if (documentsToSave == 0) {
        debugPrint("WARNING: No documents to save!");
        _isSaving = false;
        notifyListeners();
        return false;
      }

      await batch.commit();
      debugPrint("✅ Batch committed successfully!");

      // Refresh data
      debugPrint("\n=== REFRESHING DATA ===");
      await fetchAvailability();

      _isSaving = false;
      notifyListeners();
      debugPrint("✅ Save complete!");
      return true;
    } catch (e, stackTrace) {
      debugPrint("❌ Error saving availability: $e");
      debugPrint("Stack trace: $stackTrace");
      _errorMessage = "Failed to save availability: $e";
      _isSaving = false;
      notifyListeners();
      return false;
    }
  }

  // Delete availability for a specific day
  Future<bool> deleteDay(int dayOfWeek) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception("User not logged in");

      final model = _availability[dayOfWeek];
      if (model != null && model.id.isNotEmpty) {
        await FirebaseFirestore.instance
            .collection('doctors')
            .doc(user.uid)
            .collection('availability')
            .doc(model.id)
            .delete();
      }

      _availability.remove(dayOfWeek);
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint("Error deleting availability: $e");
      return false;
    }
  }
}
