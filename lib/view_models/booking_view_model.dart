import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class BookingViewModel extends ChangeNotifier {
  DateTime _selectedDate = DateTime.now();
  String? _selectedSlot;
  bool _isLoading = false;
  List<String> _availableSlots = [];

  // Getters
  DateTime get selectedDate => _selectedDate;
  String? get selectedSlot => _selectedSlot;
  bool get isLoading => _isLoading;
  List<String> get availableSlots => _availableSlots;

  // Constructor
  BookingViewModel() {
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

  // --- Logic: Fetch Slots (Mocked) ---
  Future<void> fetchSlots(DateTime date) async {
    _isLoading = true;
    notifyListeners();

    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 500));

    // Mock Logic:
    // - Weekends have fewer slots
    // - Weekdays have standard slots
    final isWeekend =
        date.weekday == DateTime.saturday || date.weekday == DateTime.sunday;

    List<String> allSlots;
    if (isWeekend) {
      allSlots = ["10:00 AM", "10:30 AM", "11:00 AM", "11:30 AM"];
    } else {
      allSlots = [
        "09:00 AM",
        "09:30 AM",
        "10:00 AM",
        "10:30 AM",
        "11:00 AM",
        "11:30 AM",
        "02:00 PM",
        "02:30 PM",
        "03:00 PM",
        "03:30 PM",
        "04:00 PM",
        "04:30 PM",
        "05:00 PM",
      ];
    }

    // Filter out past slots
    final now = DateTime.now();
    _availableSlots = allSlots.where((slot) {
      try {
        final format = DateFormat("hh:mm a");
        final time = format.parse(slot);
        final slotDateTime = DateTime(
          date.year,
          date.month,
          date.day,
          time.hour,
          time.minute,
        );
        return slotDateTime.isAfter(now);
      } catch (e) {
        return true; // Keep if parsing fails
      }
    }).toList();

    _isLoading = false;
    notifyListeners();
  }

  // --- Logic: Format Date for UI ---
  String getFormattedDate() {
    return DateFormat('MMMM d, y').format(_selectedDate);
  }
}
