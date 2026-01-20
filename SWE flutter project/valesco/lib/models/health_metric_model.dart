import '../core/utils/uuid_helper.dart';

/// HealthMetric model based on class diagram
/// Attributes: metricID, metricType, value, unit, recordedAt
/// Methods: recordMetric(), getMetrics(), calculateTrend()
class HealthMetric {
  final String id;
  final String patientId;
  final String metricType; // e.g., 'blood_pressure', 'heart_rate', 'temperature', 'weight'
  final double value;
  final double? secondaryValue; // For metrics like blood pressure (diastolic)
  final String unit;
  final DateTime recordedAt;
  final String? notes;

  HealthMetric({
    String? id,
    required this.patientId,
    required this.metricType,
    required this.value,
    this.secondaryValue,
    required this.unit,
    DateTime? recordedAt,
    this.notes,
  })  : id = id ?? UuidHelper.generateV4(),
        recordedAt = recordedAt ?? DateTime.now();

  /// Record a new metric
  static HealthMetric recordMetric({
    required String patientId,
    required String metricType,
    required double value,
    double? secondaryValue,
    required String unit,
    String? notes,
  }) {
    return HealthMetric(
      patientId: patientId,
      metricType: metricType,
      value: value,
      secondaryValue: secondaryValue,
      unit: unit,
      notes: notes,
    );
  }

  /// Check if the metric value is within normal range
  bool isNormal() {
    switch (metricType.toLowerCase()) {
      case 'blood_pressure':
      case 'bloodpressure':
        // Systolic: 90-120, Diastolic: 60-80
        return value >= 90 && value <= 120 && 
               (secondaryValue == null || (secondaryValue! >= 60 && secondaryValue! <= 80));
      case 'heart_rate':
      case 'heartrate':
        return value >= 60 && value <= 100;
      case 'temperature':
        return value >= 36.1 && value <= 37.2;
      case 'blood_glucose':
      case 'bloodglucose':
        return value >= 70 && value <= 100;
      case 'oxygen_level':
      case 'oxygenlevel':
        return value >= 95 && value <= 100;
      default:
        return true;
    }
  }

  /// Get status of the reading
  String getStatus() {
    if (isNormal()) return 'Normal';
    
    switch (metricType.toLowerCase()) {
      case 'blood_pressure':
      case 'bloodpressure':
        if (value > 140 || (secondaryValue != null && secondaryValue! > 90)) {
          return 'High';
        }
        return 'Low';
      case 'heart_rate':
      case 'heartrate':
        return value > 100 ? 'High' : 'Low';
      case 'temperature':
        return value > 37.2 ? 'Fever' : 'Low';
      case 'blood_glucose':
      case 'bloodglucose':
        return value > 100 ? 'High' : 'Low';
      case 'oxygen_level':
      case 'oxygenlevel':
        return 'Low';
      default:
        return 'Unknown';
    }
  }

  /// Get display name for metric type
  String get displayName {
    switch (metricType.toLowerCase()) {
      case 'blood_pressure':
      case 'bloodpressure':
        return 'Blood Pressure';
      case 'heart_rate':
      case 'heartrate':
        return 'Heart Rate';
      case 'temperature':
        return 'Temperature';
      case 'blood_glucose':
      case 'bloodglucose':
        return 'Blood Glucose';
      case 'oxygen_level':
      case 'oxygenlevel':
        return 'Oxygen Level';
      case 'weight':
        return 'Weight';
      default:
        return metricType;
    }
  }

  /// Get formatted value with unit
  String get formattedValue {
    if (secondaryValue != null) {
      return '${value.toStringAsFixed(0)}/${secondaryValue!.toStringAsFixed(0)} $unit';
    }
    return '${value.toStringAsFixed(1)} $unit';
  }

  HealthMetric copyWith({
    String? id,
    String? patientId,
    String? metricType,
    double? value,
    double? secondaryValue,
    String? unit,
    DateTime? recordedAt,
    String? notes,
  }) {
    return HealthMetric(
      id: id ?? this.id,
      patientId: patientId ?? this.patientId,
      metricType: metricType ?? this.metricType,
      value: value ?? this.value,
      secondaryValue: secondaryValue ?? this.secondaryValue,
      unit: unit ?? this.unit,
      recordedAt: recordedAt ?? this.recordedAt,
      notes: notes ?? this.notes,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'patientId': patientId,
      'metricType': metricType,
      'value': value,
      'secondaryValue': secondaryValue,
      'unit': unit,
      'recordedAt': recordedAt.toIso8601String(),
      'notes': notes,
    };
  }

  factory HealthMetric.fromJson(Map<String, dynamic> json) {
    return HealthMetric(
      id: json['id'],
      patientId: json['patientId'],
      metricType: json['metricType'],
      value: (json['value'] as num).toDouble(),
      secondaryValue: json['secondaryValue'] != null 
          ? (json['secondaryValue'] as num).toDouble() 
          : null,
      unit: json['unit'],
      recordedAt: DateTime.parse(json['recordedAt']),
      notes: json['notes'],
    );
  }
}
