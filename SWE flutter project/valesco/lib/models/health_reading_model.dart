import '../core/utils/uuid_helper.dart';

enum HealthReadingType {
  bloodGlucose,
  bloodPressure,
  heartRate,
  temperature,
  oxygenLevel,
  weight,
}

// Alias for bloodGlucose
extension HealthReadingTypeAlias on HealthReadingType {
  static const HealthReadingType bloodSugar = HealthReadingType.bloodGlucose;
}

extension HealthReadingTypeExtension on HealthReadingType {
  String get displayName {
    switch (this) {
      case HealthReadingType.bloodGlucose:
        return 'Blood Sugar';
      case HealthReadingType.bloodPressure:
        return 'Blood Pressure';
      case HealthReadingType.heartRate:
        return 'Heart Rate';
      case HealthReadingType.temperature:
        return 'Temperature';
      case HealthReadingType.oxygenLevel:
        return 'Oxygen Level';
      case HealthReadingType.weight:
        return 'Weight';
    }
  }

  String get unit {
    switch (this) {
      case HealthReadingType.bloodGlucose:
        return 'mg/dL';
      case HealthReadingType.bloodPressure:
        return 'mmHg';
      case HealthReadingType.heartRate:
        return 'BPM';
      case HealthReadingType.temperature:
        return '°C';
      case HealthReadingType.oxygenLevel:
        return '%';
      case HealthReadingType.weight:
        return 'kg';
    }
  }

  String get icon {
    switch (this) {
      case HealthReadingType.bloodGlucose:
        return '🩸';
      case HealthReadingType.bloodPressure:
        return '❤️';
      case HealthReadingType.heartRate:
        return '💓';
      case HealthReadingType.temperature:
        return '🌡️';
      case HealthReadingType.oxygenLevel:
        return '💨';
      case HealthReadingType.weight:
        return '⚖️';
    }
  }
}

enum ReadingStatus {
  normal,
  low,
  high,
  critical,
  elevated, // Alias for high
}

extension ReadingStatusExtension on ReadingStatus {
  String get displayName {
    switch (this) {
      case ReadingStatus.normal:
        return 'Normal';
      case ReadingStatus.low:
        return 'Low';
      case ReadingStatus.high:
      case ReadingStatus.elevated:
        return 'Elevated';
      case ReadingStatus.critical:
        return 'Critical';
    }
  }
}

class HealthReadingModel {
  final String id;
  final String userId;
  final HealthReadingType type;
  final double value;
  final double? secondaryValue; // For blood pressure (diastolic)
  final DateTime timestamp;
  final String? context; // "Before meal", "After exercise", etc.
  final String? notes;
  final ReadingStatus status;

  HealthReadingModel({
    String? id,
    required this.userId,
    required this.type,
    required this.value,
    this.secondaryValue,
    DateTime? timestamp,
    this.context,
    this.notes,
    ReadingStatus? status,
  })  : id = id ?? UuidHelper.generateV4(),
        timestamp = timestamp ?? DateTime.now(),
        status = status ?? _calculateStatus(type, value, secondaryValue);

  // Get unit from type extension
  String get unit => type.unit;

  static ReadingStatus _calculateStatus(
    HealthReadingType type,
    double value,
    double? secondaryValue,
  ) {
    switch (type) {
      case HealthReadingType.bloodGlucose:
        if (value < 54) return ReadingStatus.critical;
        if (value < 70) return ReadingStatus.low;
        if (value > 250) return ReadingStatus.critical;
        if (value > 180) return ReadingStatus.high;
        return ReadingStatus.normal;
      case HealthReadingType.bloodPressure:
        if (value > 180 || (secondaryValue != null && secondaryValue > 120)) {
          return ReadingStatus.critical;
        }
        if (value > 140 || (secondaryValue != null && secondaryValue > 90)) {
          return ReadingStatus.high;
        }
        if (value < 90 || (secondaryValue != null && secondaryValue < 60)) {
          return ReadingStatus.low;
        }
        return ReadingStatus.normal;
      case HealthReadingType.heartRate:
        if (value < 40 || value > 150) return ReadingStatus.critical;
        if (value < 60) return ReadingStatus.low;
        if (value > 100) return ReadingStatus.high;
        return ReadingStatus.normal;
      case HealthReadingType.temperature:
        if (value > 39.4 || value < 35) return ReadingStatus.critical;
        if (value > 37.8) return ReadingStatus.high;
        if (value < 36.1) return ReadingStatus.low;
        return ReadingStatus.normal;
      case HealthReadingType.oxygenLevel:
        if (value < 90) return ReadingStatus.critical;
        if (value < 94) return ReadingStatus.low;
        return ReadingStatus.normal;
      case HealthReadingType.weight:
        return ReadingStatus.normal;
    }
  }

  String get displayValue {
    if (type == HealthReadingType.bloodPressure && secondaryValue != null) {
      return '${value.toInt()}/${secondaryValue!.toInt()}';
    }
    if (type == HealthReadingType.temperature) {
      return value.toStringAsFixed(1);
    }
    return value.toInt().toString();
  }

  HealthReadingModel copyWith({
    String? id,
    String? userId,
    HealthReadingType? type,
    double? value,
    double? secondaryValue,
    DateTime? timestamp,
    String? context,
    String? notes,
    ReadingStatus? status,
  }) {
    return HealthReadingModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      value: value ?? this.value,
      secondaryValue: secondaryValue ?? this.secondaryValue,
      timestamp: timestamp ?? this.timestamp,
      context: context ?? this.context,
      notes: notes ?? this.notes,
      status: status ?? this.status,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'type': type.name,
      'value': value,
      'secondaryValue': secondaryValue,
      'timestamp': timestamp.toIso8601String(),
      'context': context,
      'notes': notes,
      'status': status.name,
    };
  }

  factory HealthReadingModel.fromJson(Map<String, dynamic> json) {
    return HealthReadingModel(
      id: json['id'],
      userId: json['userId'],
      type: HealthReadingType.values.byName(json['type']),
      value: json['value'].toDouble(),
      secondaryValue: json['secondaryValue']?.toDouble(),
      timestamp: DateTime.parse(json['timestamp']),
      context: json['context'],
      notes: json['notes'],
      status: ReadingStatus.values.byName(json['status']),
    );
  }
}
