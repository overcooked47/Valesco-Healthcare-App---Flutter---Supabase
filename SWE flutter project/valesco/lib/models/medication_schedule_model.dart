import 'package:flutter/material.dart';
import '../core/utils/uuid_helper.dart';

/// MedicationSchedule model based on class diagram
/// Attributes: medicineName, notes, frequency, timesOfDay
/// Methods: createSchedule(), updateSchedule(), getNextDose()
enum ScheduleFrequency {
  daily,
  twiceDaily,
  threeTimesDaily,
  fourTimesDaily,
  weekly,
  biWeekly,
  monthly,
  asNeeded,
  custom,
}

extension ScheduleFrequencyExtension on ScheduleFrequency {
  String get displayName {
    switch (this) {
      case ScheduleFrequency.daily:
        return 'Once Daily';
      case ScheduleFrequency.twiceDaily:
        return 'Twice Daily';
      case ScheduleFrequency.threeTimesDaily:
        return '3 Times Daily';
      case ScheduleFrequency.fourTimesDaily:
        return '4 Times Daily';
      case ScheduleFrequency.weekly:
        return 'Weekly';
      case ScheduleFrequency.biWeekly:
        return 'Every 2 Weeks';
      case ScheduleFrequency.monthly:
        return 'Monthly';
      case ScheduleFrequency.asNeeded:
        return 'As Needed';
      case ScheduleFrequency.custom:
        return 'Custom';
    }
  }

  int get dosesPerDay {
    switch (this) {
      case ScheduleFrequency.daily:
        return 1;
      case ScheduleFrequency.twiceDaily:
        return 2;
      case ScheduleFrequency.threeTimesDaily:
        return 3;
      case ScheduleFrequency.fourTimesDaily:
        return 4;
      case ScheduleFrequency.weekly:
      case ScheduleFrequency.biWeekly:
      case ScheduleFrequency.monthly:
      case ScheduleFrequency.asNeeded:
      case ScheduleFrequency.custom:
        return 1;
    }
  }
}

class MedicationSchedule {
  final String id;
  final String medicationPlanId;
  final String medicineName;
  final String? notes;
  final ScheduleFrequency frequency;
  final List<TimeOfDay> timesOfDay;
  final List<int>? daysOfWeek; // 1-7 for weekly schedules
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  MedicationSchedule({
    String? id,
    required this.medicationPlanId,
    required this.medicineName,
    this.notes,
    required this.frequency,
    required this.timesOfDay,
    this.daysOfWeek,
    this.isActive = true,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : id = id ?? UuidHelper.generateV4(),
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  /// Create a new medication schedule
  static MedicationSchedule createSchedule({
    required String medicationPlanId,
    required String medicineName,
    String? notes,
    required ScheduleFrequency frequency,
    required List<TimeOfDay> timesOfDay,
    List<int>? daysOfWeek,
  }) {
    return MedicationSchedule(
      medicationPlanId: medicationPlanId,
      medicineName: medicineName,
      notes: notes,
      frequency: frequency,
      timesOfDay: timesOfDay,
      daysOfWeek: daysOfWeek,
    );
  }

  /// Update the schedule
  MedicationSchedule updateSchedule({
    String? medicineName,
    String? notes,
    ScheduleFrequency? frequency,
    List<TimeOfDay>? timesOfDay,
    List<int>? daysOfWeek,
    bool? isActive,
  }) {
    return copyWith(
      medicineName: medicineName,
      notes: notes,
      frequency: frequency,
      timesOfDay: timesOfDay,
      daysOfWeek: daysOfWeek,
      isActive: isActive,
      updatedAt: DateTime.now(),
    );
  }

  /// Get the next dose time
  DateTime? getNextDose() {
    if (!isActive || timesOfDay.isEmpty) return null;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Sort times
    final sortedTimes = List<TimeOfDay>.from(timesOfDay)
      ..sort((a, b) {
        final aMinutes = a.hour * 60 + a.minute;
        final bMinutes = b.hour * 60 + b.minute;
        return aMinutes.compareTo(bMinutes);
      });

    // Find next time today
    for (final time in sortedTimes) {
      final doseTime = DateTime(
        today.year,
        today.month,
        today.day,
        time.hour,
        time.minute,
      );
      if (doseTime.isAfter(now)) {
        // Check if this day is valid for the schedule
        if (_isDayValid(doseTime)) {
          return doseTime;
        }
      }
    }

    // Find next valid day
    var checkDate = today.add(const Duration(days: 1));
    for (int i = 0; i < 30; i++) {
      if (_isDayValid(checkDate)) {
        final firstTime = sortedTimes.first;
        return DateTime(
          checkDate.year,
          checkDate.month,
          checkDate.day,
          firstTime.hour,
          firstTime.minute,
        );
      }
      checkDate = checkDate.add(const Duration(days: 1));
    }

    return null;
  }

  bool _isDayValid(DateTime date) {
    if (frequency == ScheduleFrequency.daily ||
        frequency == ScheduleFrequency.twiceDaily ||
        frequency == ScheduleFrequency.threeTimesDaily ||
        frequency == ScheduleFrequency.fourTimesDaily) {
      return true;
    }

    if (frequency == ScheduleFrequency.weekly && daysOfWeek != null) {
      return daysOfWeek!.contains(date.weekday);
    }

    return true;
  }

  /// Get formatted times string
  String get formattedTimes {
    return timesOfDay
        .map((t) => '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}')
        .join(', ');
  }

  /// Get today's remaining doses
  List<TimeOfDay> getTodaysRemainingDoses() {
    final now = TimeOfDay.now();
    final nowMinutes = now.hour * 60 + now.minute;

    return timesOfDay.where((t) {
      final timeMinutes = t.hour * 60 + t.minute;
      return timeMinutes > nowMinutes;
    }).toList();
  }

  MedicationSchedule copyWith({
    String? id,
    String? medicationPlanId,
    String? medicineName,
    String? notes,
    ScheduleFrequency? frequency,
    List<TimeOfDay>? timesOfDay,
    List<int>? daysOfWeek,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return MedicationSchedule(
      id: id ?? this.id,
      medicationPlanId: medicationPlanId ?? this.medicationPlanId,
      medicineName: medicineName ?? this.medicineName,
      notes: notes ?? this.notes,
      frequency: frequency ?? this.frequency,
      timesOfDay: timesOfDay ?? this.timesOfDay,
      daysOfWeek: daysOfWeek ?? this.daysOfWeek,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'medicationPlanId': medicationPlanId,
      'medicineName': medicineName,
      'notes': notes,
      'frequency': frequency.name,
      'timesOfDay': timesOfDay.map((t) => '${t.hour}:${t.minute}').toList(),
      'daysOfWeek': daysOfWeek,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory MedicationSchedule.fromJson(Map<String, dynamic> json) {
    return MedicationSchedule(
      id: json['id'],
      medicationPlanId: json['medicationPlanId'],
      medicineName: json['medicineName'],
      notes: json['notes'],
      frequency: ScheduleFrequency.values.byName(json['frequency']),
      timesOfDay: (json['timesOfDay'] as List).map((t) {
        final parts = t.toString().split(':');
        return TimeOfDay(
          hour: int.parse(parts[0]),
          minute: int.parse(parts[1]),
        );
      }).toList(),
      daysOfWeek: json['daysOfWeek'] != null 
          ? List<int>.from(json['daysOfWeek']) 
          : null,
      isActive: json['isActive'] ?? true,
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }
}
