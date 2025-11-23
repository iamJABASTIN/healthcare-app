import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../data/models/appointment_model.dart';
import '../data/models/doctor_model.dart';

class BookingViewModel extends ChangeNotifier {
  final String doctorId;
  DateTime _selectedDate = DateTime.now();
  String? _selectedSlot;
  bool _isLoading = false;
  List<String> _availableSlots = [];
  String _statusMessage = "";

  // Getters
  DateTime get selectedDate => _selectedDate;
  String? get selectedSlot => _selectedSlot;
  bool get isLoading => _isLoading;
  List<String> get availableSlots => _availableSlots;
  String get statusMessage => _statusMessage;

  // Constructor
  BookingViewModel({required this.doctorId}) {
    fetchSlots(_selectedDate);
  }

  // --- Logic: Select Date ---
  void selectDate(DateTime date) {
    _selectedDate = date;
    _selectedSlot = null; // Reset slot when date changes
    fetchSlots(date);
  }

  // --- Logic: Select Slot ---
  void selectSlot(String slot) {
    _selectedSlot = slot;
    notifyListeners();
  }

  // --- Logic: Fetch Slots ---
  Future<void> fetchSlots(DateTime date) async {
    _isLoading = true;
    _statusMessage = "Checking availability...";
    notifyListeners();

    try {
      // 1. Fetch Doctor's Availability for this day
      final dayOfWeek = date.weekday;
      debugPrint("Fetching slots for Doctor: $doctorId");
      debugPrint("Date: $date, DayOfWeek: $dayOfWeek");

      // Fetch ALL availability docs to avoid query issues
      final availabilitySnapshot = await FirebaseFirestore.instance
          .collection('doctors')
          .doc(doctorId)
          .collection('availability')
          .get();

      debugPrint(
        "Total availability docs found: ${availabilitySnapshot.docs.length}",
      );

      List<String> allSlots = [];

      // Find the document for the current day of week (handling Int or String)
      QueryDocumentSnapshot? targetDoc;

      for (var doc in availabilitySnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final docDay = data['dayOfWeek'];

        int? dayInt;
        if (docDay is int) {
          dayInt = docDay;
        } else if (docDay is String) {
          dayInt = int.tryParse(docDay);
          if (dayInt == null) {
            // Try parsing day name "Monday", "Tuesday", etc.
            const days = [
              "Monday",
              "Tuesday",
              "Wednesday",
              "Thursday",
              "Friday",
              "Saturday",
              "Sunday",
            ];
            final index = days.indexOf(docDay);
            if (index != -1) {
              dayInt = index + 1;
            }
          }
        }

        if (dayInt == dayOfWeek) {
          targetDoc = doc;
          break;
        }
      }

      if (targetDoc != null) {
        final data = targetDoc.data() as Map<String, dynamic>;
        debugPrint("Found matching availability doc: ${targetDoc.id}");
        debugPrint("Raw Availability Data: $data");

        // Check if the day is active
        final isActive = data['isActive'] as bool? ?? true;
        debugPrint("Is Active: $isActive");

        if (isActive) {
          // Parse time slots
          if (data['timeSlots'] is List) {
            final slotsList = data['timeSlots'] as List;
            debugPrint("Found ${slotsList.length} slots in list");

            for (var slotData in slotsList) {
              if (slotData is Map<String, dynamic>) {
                // NEW FORMAT: Map with start/end times
                final startHour = slotData['startHour'] as int;
                final startMinute = slotData['startMinute'] as int;
                final endHour = slotData['endHour'] as int;
                final endMinute = slotData['endMinute'] as int;

                final startTime = TimeOfDay(
                  hour: startHour,
                  minute: startMinute,
                );
                final endTime = TimeOfDay(hour: endHour, minute: endMinute);

                final startStr = _formatTimeOfDay(startTime);
                final endStr = _formatTimeOfDay(endTime);
                allSlots.add("$startStr - $endStr");
                debugPrint("Parsed slot: $startStr - $endStr");
              } else if (slotData is String) {
                // LEGACY FORMAT: String "09:00 AM"
                try {
                  var timeStr = slotData;
                  TimeOfDay? startTime;
                  if (timeStr.contains(":")) {
                    final parts = timeStr.split(" ");
                    final timeParts = parts[0].split(":");
                    int hour = int.parse(timeParts[0]);
                    int minute = int.parse(timeParts[1]);
                    if (parts.length > 1 &&
                        parts[1].toUpperCase() == "PM" &&
                        hour != 12) {
                      hour += 12;
                    } else if (parts.length > 1 &&
                        parts[1].toUpperCase() == "AM" &&
                        hour == 12) {
                      hour = 0;
                    }
                    startTime = TimeOfDay(hour: hour, minute: minute);
                  }

                  if (startTime != null) {
                    // Create 30 min slot
                    final endMinute = startTime.minute + 30;
                    final endHour = startTime.hour + (endMinute >= 60 ? 1 : 0);
                    final endTime = TimeOfDay(
                      hour: endHour % 24,
                      minute: endMinute % 60,
                    );

                    final startStr = _formatTimeOfDay(startTime);
                    final endStr = _formatTimeOfDay(endTime);
                    allSlots.add("$startStr - $endStr");
                    debugPrint("Parsed legacy slot: $startStr - $endStr");
                  }
                } catch (e) {
                  debugPrint("Error parsing legacy slot '$slotData': $e");
                }
              }
            }
          } else {
            debugPrint("timeSlots is not a List: ${data['timeSlots']}");
            _statusMessage =
                "Availability data is corrupted (timeSlots not a list).";
          }
        } else {
          _statusMessage = "Doctor is not available on this day.";
        }
      } else {
        debugPrint("No availability document found for day $dayOfWeek");
        _statusMessage = "No availability set for this day.";
      }

      debugPrint("Total slots found before filtering: ${allSlots.length}");

      if (allSlots.isEmpty && _statusMessage == "Checking availability...") {
        _statusMessage = "No time slots configured for this day.";
      }

      // 2. Fetch booked slots from Firestore
      // Note: We fetch all appointments for the doctor and filter in memory to avoid
      // needing a composite index (doctorId + date + status) for this assessment.
      final bookedAppointmentsSnapshot = await FirebaseFirestore.instance
          .collection('appointments')
          .where('doctorId', isEqualTo: doctorId)
          .get();

      final bookedSlots = bookedAppointmentsSnapshot.docs
          .where((doc) {
            final data = doc.data();
            final appointmentDate = (data['date'] as Timestamp).toDate();
            final status = data['status'] as String;

            final isSameDay =
                appointmentDate.year == date.year &&
                appointmentDate.month == date.month &&
                appointmentDate.day == date.day;

            final isValidStatus = ['pending', 'confirmed'].contains(status);

            return isSameDay && isValidStatus;
          })
          .map((doc) => doc.data()['time'] as String)
          .toSet();

      debugPrint("Booked slots: $bookedSlots");

      // 3. Filter out past slots and booked slots
      final now = DateTime.now();
      _availableSlots = allSlots.where((slot) {
        // Check if slot is booked
        if (bookedSlots.contains(slot)) {
          debugPrint("Slot $slot is booked");
          return false;
        }

        // Check if slot is in the past (only if looking at today)
        if (date.year == now.year &&
            date.month == now.month &&
            date.day == now.day) {
          try {
            // Parse the start time from the range "09:00 AM - 09:30 AM"
            final parts = slot.split(' - ');
            final startTimeStr = parts[0];

            final format = DateFormat.jm();
            final time = format.parse(startTimeStr);
            final slotDateTime = DateTime(
              date.year,
              date.month,
              date.day,
              time.hour,
              time.minute,
            );

            if (slotDateTime.isBefore(now)) {
              debugPrint("Slot $slot is in the past");
              return false;
            }
            return true;
          } catch (e) {
            debugPrint("Error parsing slot time: $e");
            return true; // Keep if parsing fails
          }
        }
        return true;
      }).toList();

      debugPrint("Final available slots: ${_availableSlots.length}");

      if (_availableSlots.isEmpty && allSlots.isNotEmpty) {
        _statusMessage = "All slots are fully booked or in the past.";
      } else if (_availableSlots.isNotEmpty) {
        _statusMessage = ""; // Clear message if we have slots
      }

      // Sort slots chronologically
      _availableSlots.sort((a, b) {
        try {
          final format = DateFormat.jm();
          final timeA = format.parse(a.split(' - ')[0]);
          final timeB = format.parse(b.split(' - ')[0]);
          return timeA.compareTo(timeB);
        } catch (e) {
          return 0;
        }
      });
    } catch (e, stack) {
      debugPrint("Error fetching slots: $e");
      debugPrint("Stack trace: $stack");
      _availableSlots = [];
      _statusMessage = "Error loading slots: $e";
    }

    _isLoading = false;
    notifyListeners();
  }

  String _formatTimeOfDay(TimeOfDay time) {
    final now = DateTime.now();
    final dt = DateTime(now.year, now.month, now.day, time.hour, time.minute);
    final format = DateFormat.jm(); // "5:08 PM"
    return format.format(dt);
  }

  // --- Logic: Format Date for UI ---
  String getFormattedDate() {
    return DateFormat('MMMM d, y').format(_selectedDate);
  }

  // --- Logic: Book Appointment ---
  Future<bool> bookAppointment(DoctorModel doctor) async {
    if (_selectedSlot == null) return false;

    _isLoading = true;
    notifyListeners();

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception("User not logged in");

      // Fetch user name (optional, can be optimized)
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      final userName = userDoc.data()?['name'] ?? 'Unknown';

      final appointmentId = FirebaseFirestore.instance
          .collection('appointments')
          .doc()
          .id;

      final appointment = AppointmentModel(
        id: appointmentId,
        doctorId: doctor.uid,
        doctorName: doctor.name,
        patientId: user.uid,
        patientName: userName,
        date: _selectedDate,
        time: _selectedSlot!,
        status: 'pending',
        createdAt: DateTime.now(),
      );

      await FirebaseFirestore.instance
          .collection('appointments')
          .doc(appointmentId)
          .set(appointment.toMap());

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint("Error booking appointment: $e");
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
}
