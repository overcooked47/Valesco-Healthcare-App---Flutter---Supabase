import '../core/utils/uuid_helper.dart';

/// Reminder model based on class diagram
/// Attributes: reminderID, scheduledTime, status, lastReminder, acknowledgedAt
/// Methods: scheduleReminder(), setReminder(), markAcknowledged(), snoozeReminder()
enum ReminderStatus {
  pending,
  sent,
  acknowledged,
  snoozed,
  missed,
  cancelled,
}

extension ReminderStatusExtension on ReminderStatus {
  String get displayName {
    switch (this) {
      case ReminderStatus.pending:
        return 'Pending';
      case ReminderStatus.sent:
        return 'Sent';
      case ReminderStatus.acknowledged:
        return 'Acknowledged';
      case ReminderStatus.snoozed:
        return 'Snoozed';
      case ReminderStatus.missed:
        return 'Missed';
      case ReminderStatus.cancelled:
        return 'Cancelled';
    }
  }
}

class Reminder {
  final String id;
  final String userId;
  final String? relatedId; // Can be medication schedule ID, appointment ID, etc.
  final String relatedType; // 'medication', 'appointment', 'health_check', etc.
  final DateTime scheduledTime;
  final ReminderStatus status;
  final DateTime? lastReminder;
  final DateTime? acknowledgedAt;
  final String title;
  final String? message;
  final int snoozeCount;
  final DateTime createdAt;

  Reminder({
    String? id,
    required this.userId,
    this.relatedId,
    required this.relatedType,
    required this.scheduledTime,
    this.status = ReminderStatus.pending,
    this.lastReminder,
    this.acknowledgedAt,
    required this.title,
    this.message,
    this.snoozeCount = 0,
    DateTime? createdAt,
  })  : id = id ?? UuidHelper.generateV4(),
        createdAt = createdAt ?? DateTime.now();

  /// Schedule a new reminder
  static Reminder scheduleReminder({
    required String userId,
    String? relatedId,
    required String relatedType,
    required DateTime scheduledTime,
    required String title,
    String? message,
  }) {
    return Reminder(
      userId: userId,
      relatedId: relatedId,
      relatedType: relatedType,
      scheduledTime: scheduledTime,
      title: title,
      message: message,
    );
  }

  /// Set/update reminder time
  Reminder setReminder(DateTime newTime) {
    return copyWith(
      scheduledTime: newTime,
      status: ReminderStatus.pending,
    );
  }

  /// Mark reminder as acknowledged
  Reminder markAcknowledged() {
    return copyWith(
      status: ReminderStatus.acknowledged,
      acknowledgedAt: DateTime.now(),
    );
  }

  /// Snooze reminder for specified minutes
  Reminder snoozeReminder({int minutes = 10}) {
    return copyWith(
      scheduledTime: DateTime.now().add(Duration(minutes: minutes)),
      status: ReminderStatus.snoozed,
      lastReminder: DateTime.now(),
      snoozeCount: snoozeCount + 1,
    );
  }

  /// Cancel the reminder
  Reminder cancel() {
    return copyWith(status: ReminderStatus.cancelled);
  }

  /// Mark as sent
  Reminder markAsSent() {
    return copyWith(
      status: ReminderStatus.sent,
      lastReminder: DateTime.now(),
    );
  }

  /// Mark as missed
  Reminder markAsMissed() {
    return copyWith(status: ReminderStatus.missed);
  }

  /// Check if reminder is due
  bool get isDue {
    if (status != ReminderStatus.pending && status != ReminderStatus.snoozed) {
      return false;
    }
    return DateTime.now().isAfter(scheduledTime) ||
        DateTime.now().isAtSameMomentAs(scheduledTime);
  }

  /// Check if reminder is overdue
  bool get isOverdue {
    if (status == ReminderStatus.acknowledged || 
        status == ReminderStatus.cancelled) {
      return false;
    }
    return DateTime.now().isAfter(scheduledTime.add(const Duration(minutes: 30)));
  }

  /// Get time until reminder
  Duration get timeUntil => scheduledTime.difference(DateTime.now());

  Reminder copyWith({
    String? id,
    String? userId,
    String? relatedId,
    String? relatedType,
    DateTime? scheduledTime,
    ReminderStatus? status,
    DateTime? lastReminder,
    DateTime? acknowledgedAt,
    String? title,
    String? message,
    int? snoozeCount,
    DateTime? createdAt,
  }) {
    return Reminder(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      relatedId: relatedId ?? this.relatedId,
      relatedType: relatedType ?? this.relatedType,
      scheduledTime: scheduledTime ?? this.scheduledTime,
      status: status ?? this.status,
      lastReminder: lastReminder ?? this.lastReminder,
      acknowledgedAt: acknowledgedAt ?? this.acknowledgedAt,
      title: title ?? this.title,
      message: message ?? this.message,
      snoozeCount: snoozeCount ?? this.snoozeCount,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'relatedId': relatedId,
      'relatedType': relatedType,
      'scheduledTime': scheduledTime.toIso8601String(),
      'status': status.name,
      'lastReminder': lastReminder?.toIso8601String(),
      'acknowledgedAt': acknowledgedAt?.toIso8601String(),
      'title': title,
      'message': message,
      'snoozeCount': snoozeCount,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Reminder.fromJson(Map<String, dynamic> json) {
    return Reminder(
      id: json['id'],
      userId: json['userId'],
      relatedId: json['relatedId'],
      relatedType: json['relatedType'],
      scheduledTime: DateTime.parse(json['scheduledTime']),
      status: ReminderStatus.values.byName(json['status']),
      lastReminder: json['lastReminder'] != null 
          ? DateTime.parse(json['lastReminder']) 
          : null,
      acknowledgedAt: json['acknowledgedAt'] != null 
          ? DateTime.parse(json['acknowledgedAt']) 
          : null,
      title: json['title'],
      message: json['message'],
      snoozeCount: json['snoozeCount'] ?? 0,
      createdAt: DateTime.parse(json['createdAt']),
    );
  }
}
