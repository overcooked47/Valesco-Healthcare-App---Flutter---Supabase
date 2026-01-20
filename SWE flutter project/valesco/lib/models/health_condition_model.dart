import '../core/utils/uuid_helper.dart';

/// HealthCondition model based on class diagram
/// Attributes: conditionID, conditionName, diagnosedDate, status, notes
/// Methods: createValid(), isValid(), updateStatus(), getAgeInYears(), calculateBMI()
enum ConditionStatus {
  active,
  managed,
  resolved,
  inRemission,
}

extension ConditionStatusExtension on ConditionStatus {
  String get displayName {
    switch (this) {
      case ConditionStatus.active:
        return 'Active';
      case ConditionStatus.managed:
        return 'Managed';
      case ConditionStatus.resolved:
        return 'Resolved';
      case ConditionStatus.inRemission:
        return 'In Remission';
    }
  }
}

class HealthCondition {
  final String id;
  final String patientId;
  final String conditionName;
  final DateTime diagnosedDate;
  final ConditionStatus status;
  final String? notes;
  final String? treatingPhysician;
  final List<String>? medications;
  final DateTime createdAt;
  final DateTime updatedAt;

  HealthCondition({
    String? id,
    required this.patientId,
    required this.conditionName,
    required this.diagnosedDate,
    this.status = ConditionStatus.active,
    this.notes,
    this.treatingPhysician,
    this.medications,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : id = id ?? UuidHelper.generateV4(),
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  /// Create a valid health condition
  static HealthCondition? createValid({
    required String patientId,
    required String conditionName,
    required DateTime diagnosedDate,
    ConditionStatus status = ConditionStatus.active,
    String? notes,
    String? treatingPhysician,
    List<String>? medications,
  }) {
    if (conditionName.trim().isEmpty) {
      return null;
    }

    if (diagnosedDate.isAfter(DateTime.now())) {
      return null;
    }

    return HealthCondition(
      patientId: patientId,
      conditionName: conditionName.trim(),
      diagnosedDate: diagnosedDate,
      status: status,
      notes: notes,
      treatingPhysician: treatingPhysician,
      medications: medications,
    );
  }

  /// Check if the condition data is valid
  bool isValid() {
    return conditionName.trim().isNotEmpty && 
           !diagnosedDate.isAfter(DateTime.now());
  }

  /// Update the status of the condition
  HealthCondition updateStatus(ConditionStatus newStatus, {String? notes}) {
    return copyWith(
      status: newStatus,
      notes: notes ?? this.notes,
      updatedAt: DateTime.now(),
    );
  }

  /// Get how long the condition has been diagnosed
  int getDurationInYears() {
    final now = DateTime.now();
    int years = now.year - diagnosedDate.year;
    if (now.month < diagnosedDate.month ||
        (now.month == diagnosedDate.month && now.day < diagnosedDate.day)) {
      years--;
    }
    return years;
  }

  /// Get duration in months
  int getDurationInMonths() {
    final now = DateTime.now();
    return (now.year - diagnosedDate.year) * 12 + 
           (now.month - diagnosedDate.month);
  }

  /// Check if condition is chronic (more than 3 months)
  bool get isChronic => getDurationInMonths() > 3;

  /// Check if condition is currently active
  bool get isActive => status == ConditionStatus.active;

  /// Get formatted duration string
  String get durationString {
    final years = getDurationInYears();
    final months = getDurationInMonths() % 12;

    if (years > 0) {
      return '$years year${years > 1 ? 's' : ''} ${months > 0 ? '$months month${months > 1 ? 's' : ''}' : ''}';
    }
    return '$months month${months > 1 ? 's' : ''}';
  }

  HealthCondition copyWith({
    String? id,
    String? patientId,
    String? conditionName,
    DateTime? diagnosedDate,
    ConditionStatus? status,
    String? notes,
    String? treatingPhysician,
    List<String>? medications,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return HealthCondition(
      id: id ?? this.id,
      patientId: patientId ?? this.patientId,
      conditionName: conditionName ?? this.conditionName,
      diagnosedDate: diagnosedDate ?? this.diagnosedDate,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      treatingPhysician: treatingPhysician ?? this.treatingPhysician,
      medications: medications ?? this.medications,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'patientId': patientId,
      'conditionName': conditionName,
      'diagnosedDate': diagnosedDate.toIso8601String(),
      'status': status.name,
      'notes': notes,
      'treatingPhysician': treatingPhysician,
      'medications': medications,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory HealthCondition.fromJson(Map<String, dynamic> json) {
    return HealthCondition(
      id: json['id'],
      patientId: json['patientId'],
      conditionName: json['conditionName'],
      diagnosedDate: DateTime.parse(json['diagnosedDate']),
      status: ConditionStatus.values.byName(json['status']),
      notes: json['notes'],
      treatingPhysician: json['treatingPhysician'],
      medications: json['medications'] != null 
          ? List<String>.from(json['medications']) 
          : null,
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }
}
