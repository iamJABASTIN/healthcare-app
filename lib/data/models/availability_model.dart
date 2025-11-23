import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TimeSlotModel {
  final String id;
  final TimeOfDay startTime;
  final TimeOfDay endTime;

  TimeSlotModel({
    required this.id,
    required this.startTime,
    required this.endTime,
  });

  // Convert TimeOfDay to minutes since midnight for easy comparison
  int get startMinutes => startTime.hour * 60 + startTime.minute;
  int get endMinutes => endTime.hour * 60 + endTime.minute;

  // Format for display
  String get displayTime {
    return '${_formatTime(startTime)} - ${_formatTime(endTime)}';
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  // Firestore serialization
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'startHour': startTime.hour,
      'startMinute': startTime.minute,
      'endHour': endTime.hour,
      'endMinute': endTime.minute,
    };
  }

  factory TimeSlotModel.fromMap(Map<String, dynamic> map) {
    return TimeSlotModel(
      id: map['id'] ?? '',
      startTime: TimeOfDay(
        hour: map['startHour'] ?? 0,
        minute: map['startMinute'] ?? 0,
      ),
      endTime: TimeOfDay(
        hour: map['endHour'] ?? 0,
        minute: map['endMinute'] ?? 0,
      ),
    );
  }

  // Check if this slot overlaps with another
  bool overlapsWith(TimeSlotModel other) {
    return startMinutes < other.endMinutes && endMinutes > other.startMinutes;
  }

  // Validate that end time is after start time
  bool get isValid => endMinutes > startMinutes;

  TimeSlotModel copyWith({
    String? id,
    TimeOfDay? startTime,
    TimeOfDay? endTime,
  }) {
    return TimeSlotModel(
      id: id ?? this.id,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
    );
  }
}

enum RecurringType { none, weekly }

class RecurringRule {
  final RecurringType type;
  final List<int> daysOfWeek; // 1=Monday, 7=Sunday
  final DateTime? endDate;

  RecurringRule({required this.type, required this.daysOfWeek, this.endDate});

  Map<String, dynamic> toMap() {
    return {
      'type': type.toString(),
      'daysOfWeek': daysOfWeek,
      'endDate': endDate != null ? Timestamp.fromDate(endDate!) : null,
    };
  }

  factory RecurringRule.fromMap(Map<String, dynamic> map) {
    return RecurringRule(
      type: RecurringType.values.firstWhere(
        (e) => e.toString() == map['type'],
        orElse: () => RecurringType.none,
      ),
      daysOfWeek: List<int>.from(map['daysOfWeek'] ?? []),
      endDate: map['endDate'] != null
          ? (map['endDate'] as Timestamp).toDate()
          : null,
    );
  }
}

class AvailabilityModel {
  final String id;
  final String doctorId;
  final int dayOfWeek;
  final List<TimeSlotModel> timeSlots;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  final RecurringRule? recurringRule;

  AvailabilityModel({
    required this.id,
    required this.doctorId,
    required this.dayOfWeek,
    required this.timeSlots,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
    this.recurringRule,
  });

  factory AvailabilityModel.fromMap(Map<String, dynamic> map, String id) {
    // Handle both old format (List<String>) and new format (List<TimeSlotModel>)
    List<TimeSlotModel> slots = [];

    if (map['timeSlots'] is List) {
      for (var item in map['timeSlots']) {
        if (item is String) {
          // Old format: "09:00 AM" - convert to TimeSlotModel
          // For migration, create 30-minute slots
          final time = _parseTimeString(item);
          if (time != null) {
            slots.add(
              TimeSlotModel(
                id: DateTime.now().millisecondsSinceEpoch.toString(),
                startTime: time,
                endTime: TimeOfDay(
                  hour: time.hour,
                  minute: time.minute + 30 > 59 ? 0 : time.minute + 30,
                ),
              ),
            );
          }
        } else if (item is Map<String, dynamic>) {
          // New format: TimeSlotModel
          slots.add(TimeSlotModel.fromMap(item));
        }
      }
    }

    return AvailabilityModel(
      id: id,
      doctorId: map['doctorId'] ?? '',
      dayOfWeek: map['dayOfWeek'] ?? 1,
      timeSlots: slots,
      isActive: map['isActive'] ?? true,
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: (map['updatedAt'] as Timestamp).toDate(),
      recurringRule: map['recurringRule'] != null
          ? RecurringRule.fromMap(map['recurringRule'])
          : null,
    );
  }

  static TimeOfDay? _parseTimeString(String timeStr) {
    try {
      // Parse "09:00 AM" format
      final parts = timeStr.split(' ');
      if (parts.length != 2) return null;

      final timeParts = parts[0].split(':');
      if (timeParts.length != 2) return null;

      int hour = int.parse(timeParts[0]);
      final minute = int.parse(timeParts[1]);
      final isPM = parts[1].toUpperCase() == 'PM';

      if (isPM && hour != 12) hour += 12;
      if (!isPM && hour == 12) hour = 0;

      return TimeOfDay(hour: hour, minute: minute);
    } catch (e) {
      return null;
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'doctorId': doctorId,
      'dayOfWeek': dayOfWeek,
      'timeSlots': timeSlots.map((slot) => slot.toMap()).toList(),
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'recurringRule': recurringRule?.toMap(),
    };
  }

  String get dayName {
    const days = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    return days[dayOfWeek - 1];
  }

  AvailabilityModel copyWith({
    String? id,
    String? doctorId,
    int? dayOfWeek,
    List<TimeSlotModel>? timeSlots,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    RecurringRule? recurringRule,
  }) {
    return AvailabilityModel(
      id: id ?? this.id,
      doctorId: doctorId ?? this.doctorId,
      dayOfWeek: dayOfWeek ?? this.dayOfWeek,
      timeSlots: timeSlots ?? this.timeSlots,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      recurringRule: recurringRule ?? this.recurringRule,
    );
  }
}
