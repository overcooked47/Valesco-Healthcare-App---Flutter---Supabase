import 'package:flutter/material.dart';
import '../core/utils/uuid_helper.dart';

enum MedicationFrequency {
  daily,
  twiceDaily,
  threeTimesDaily,
  weekly,
  custom,
}

extension MedicationFrequencyExtension on MedicationFrequency {
  String get displayName {
    switch (this) {
      case MedicationFrequency.daily:
        return 'Once Daily';
      case MedicationFrequency.twiceDaily:
        return 'Twice Daily';
      case MedicationFrequency.threeTimesDaily:
        return '3 Times Daily';
      case MedicationFrequency.weekly:
        return 'Weekly';
      case MedicationFrequency.custom:
        return 'Custom';
    }
  }
}

enum MedicationStatus {
  active,
  completed,
  paused,
}

class MedicationModel {
  final String id;
  final String userId;
  final String name;
  final String dosage;
  final MedicationFrequency frequency;
  final List<TimeOfDay> reminderTimes;
  final DateTime startDate;
  final DateTime? endDate;
  final String? notes;
  final int totalPills;
  final int pillsRemaining;
  final int refillReminderThreshold;
  final MedicationStatus status;
  final DateTime createdAt;

  MedicationModel({
    String? id,
    required this.userId,
    required this.name,
    required this.dosage,
    required this.frequency,
    required this.reminderTimes,
    required this.startDate,
    this.endDate,
    this.notes,
    this.totalPills = 30,
    int? pillsRemaining,
    this.refillReminderThreshold = 5,
    this.status = MedicationStatus.active,
    DateTime? createdAt,
  })  : id = id ?? UuidHelper.generateV4(),
        pillsRemaining = pillsRemaining ?? 30,
        createdAt = createdAt ?? DateTime.now();

  bool get needsRefill => pillsRemaining <= refillReminderThreshold;

  MedicationModel copyWith({
    String? id,
    String? userId,
    String? name,
    String? dosage,
    MedicationFrequency? frequency,
    List<TimeOfDay>? reminderTimes,
    DateTime? startDate,
    DateTime? endDate,
    String? notes,
    int? totalPills,
    int? pillsRemaining,
    int? refillReminderThreshold,
    MedicationStatus? status,
    DateTime? createdAt,
  }) {
    return MedicationModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      dosage: dosage ?? this.dosage,
      frequency: frequency ?? this.frequency,
      reminderTimes: reminderTimes ?? this.reminderTimes,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      notes: notes ?? this.notes,
      totalPills: totalPills ?? this.totalPills,
      pillsRemaining: pillsRemaining ?? this.pillsRemaining,
      refillReminderThreshold: refillReminderThreshold ?? this.refillReminderThreshold,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'name': name,
      'dosage': dosage,
      'frequency': frequency.name,
      'reminderTimes': reminderTimes.map((t) => '${t.hour}:${t.minute}').toList(),
      'startDate': startDate.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'notes': notes,
      'totalPills': totalPills,
      'pillsRemaining': pillsRemaining,
      'refillReminderThreshold': refillReminderThreshold,
      'status': status.name,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory MedicationModel.fromJson(Map<String, dynamic> json) {
    return MedicationModel(
      id: json['id'],
      userId: json['userId'],
      name: json['name'],
      dosage: json['dosage'],
      frequency: MedicationFrequency.values.byName(json['frequency']),
      reminderTimes: (json['reminderTimes'] as List).map((t) {
        final parts = t.split(':');
        return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
      }).toList(),
      startDate: DateTime.parse(json['startDate']),
      endDate: json['endDate'] != null ? DateTime.parse(json['endDate']) : null,
      notes: json['notes'],
      totalPills: json['totalPills'],
      pillsRemaining: json['pillsRemaining'],
      refillReminderThreshold: json['refillReminderThreshold'],
      status: MedicationStatus.values.byName(json['status']),
      createdAt: DateTime.parse(json['createdAt']),
    );
  }
}

enum IntakeStatus {
  pending,
  taken,
  skipped,
  snoozed,
}

class MedicationIntakeModel {
  final String id;
  final String medicationId;
  final DateTime scheduledTime;
  final DateTime? actualTime;
  final IntakeStatus status;
  final String? notes;

  MedicationIntakeModel({
    String? id,
    required this.medicationId,
    required this.scheduledTime,
    this.actualTime,
    this.status = IntakeStatus.pending,
    this.notes,
  }) : id = id ?? UuidHelper.generateV4();

  MedicationIntakeModel copyWith({
    String? id,
    String? medicationId,
    DateTime? scheduledTime,
    DateTime? actualTime,
    IntakeStatus? status,
    String? notes,
  }) {
    return MedicationIntakeModel(
      id: id ?? this.id,
      medicationId: medicationId ?? this.medicationId,
      scheduledTime: scheduledTime ?? this.scheduledTime,
      actualTime: actualTime ?? this.actualTime,
      status: status ?? this.status,
      notes: notes ?? this.notes,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'medicationId': medicationId,
      'scheduledTime': scheduledTime.toIso8601String(),
      'actualTime': actualTime?.toIso8601String(),
      'status': status.name,
      'notes': notes,
    };
  }

  factory MedicationIntakeModel.fromJson(Map<String, dynamic> json) {
    return MedicationIntakeModel(
      id: json['id'],
      medicationId: json['medicationId'],
      scheduledTime: DateTime.parse(json['scheduledTime']),
      actualTime: json['actualTime'] != null ? DateTime.parse(json['actualTime']) : null,
      status: IntakeStatus.values.byName(json['status']),
      notes: json['notes'],
    );
  }
}
