import '../core/utils/uuid_helper.dart';

/// GlucoseReading model based on class diagram
/// Attributes: readingID, timestamp, valueInMgDl, mealStatus, notes
/// Methods: recordReading(), isHighReading(), getReadingHistory()
enum MealStatus {
  fasting,
  beforeMeal,
  afterMeal,
  bedtime,
  random,
}

extension MealStatusExtension on MealStatus {
  String get displayName {
    switch (this) {
      case MealStatus.fasting:
        return 'Fasting';
      case MealStatus.beforeMeal:
        return 'Before Meal';
      case MealStatus.afterMeal:
        return 'After Meal';
      case MealStatus.bedtime:
        return 'Bedtime';
      case MealStatus.random:
        return 'Random';
    }
  }

  /// Get normal range for this meal status
  (double min, double max) get normalRange {
    switch (this) {
      case MealStatus.fasting:
        return (70, 100);
      case MealStatus.beforeMeal:
        return (70, 130);
      case MealStatus.afterMeal:
        return (70, 180); // 1-2 hours after meal
      case MealStatus.bedtime:
        return (100, 140);
      case MealStatus.random:
        return (70, 140);
    }
  }
}

enum GlucoseLevel {
  low,
  normal,
  elevated,
  high,
  veryHigh,
}

extension GlucoseLevelExtension on GlucoseLevel {
  String get displayName {
    switch (this) {
      case GlucoseLevel.low:
        return 'Low';
      case GlucoseLevel.normal:
        return 'Normal';
      case GlucoseLevel.elevated:
        return 'Elevated';
      case GlucoseLevel.high:
        return 'High';
      case GlucoseLevel.veryHigh:
        return 'Very High';
    }
  }
}

class GlucoseReading {
  final String id;
  final String patientId;
  final DateTime timestamp;
  final double valueInMgDl;
  final MealStatus mealStatus;
  final String? notes;
  final DateTime createdAt;

  GlucoseReading({
    String? id,
    required this.patientId,
    DateTime? timestamp,
    required this.valueInMgDl,
    required this.mealStatus,
    this.notes,
    DateTime? createdAt,
  })  : id = id ?? UuidHelper.generateV4(),
        timestamp = timestamp ?? DateTime.now(),
        createdAt = createdAt ?? DateTime.now();

  /// Record a new glucose reading
  static GlucoseReading recordReading({
    required String patientId,
    required double valueInMgDl,
    required MealStatus mealStatus,
    String? notes,
  }) {
    return GlucoseReading(
      patientId: patientId,
      valueInMgDl: valueInMgDl,
      mealStatus: mealStatus,
      notes: notes,
    );
  }

  /// Check if this is a high reading based on meal status
  bool isHighReading() {
    final range = mealStatus.normalRange;
    return valueInMgDl > range.$2;
  }

  /// Check if this is a low reading
  bool isLowReading() {
    return valueInMgDl < 70;
  }

  /// Check if reading is within normal range
  bool isNormal() {
    final range = mealStatus.normalRange;
    return valueInMgDl >= range.$1 && valueInMgDl <= range.$2;
  }

  /// Get glucose level category
  GlucoseLevel getLevel() {
    if (valueInMgDl < 70) return GlucoseLevel.low;
    if (valueInMgDl <= 100) return GlucoseLevel.normal;
    if (valueInMgDl <= 125) return GlucoseLevel.elevated;
    if (valueInMgDl <= 180) return GlucoseLevel.high;
    return GlucoseLevel.veryHigh;
  }

  /// Get status string based on value
  String get statusString {
    if (isLowReading()) return 'Low - Eat something';
    if (isHighReading()) return 'High - Monitor closely';
    return 'Normal';
  }

  /// Convert to mmol/L
  double get valueInMmolL => valueInMgDl / 18.0;

  /// Get formatted value
  String get formattedValue => '${valueInMgDl.toStringAsFixed(0)} mg/dL';

  /// Get formatted value in mmol/L
  String get formattedValueMmol => '${valueInMmolL.toStringAsFixed(1)} mmol/L';

  GlucoseReading copyWith({
    String? id,
    String? patientId,
    DateTime? timestamp,
    double? valueInMgDl,
    MealStatus? mealStatus,
    String? notes,
    DateTime? createdAt,
  }) {
    return GlucoseReading(
      id: id ?? this.id,
      patientId: patientId ?? this.patientId,
      timestamp: timestamp ?? this.timestamp,
      valueInMgDl: valueInMgDl ?? this.valueInMgDl,
      mealStatus: mealStatus ?? this.mealStatus,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'patientId': patientId,
      'timestamp': timestamp.toIso8601String(),
      'valueInMgDl': valueInMgDl,
      'mealStatus': mealStatus.name,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory GlucoseReading.fromJson(Map<String, dynamic> json) {
    return GlucoseReading(
      id: json['id'],
      patientId: json['patientId'],
      timestamp: DateTime.parse(json['timestamp']),
      valueInMgDl: (json['valueInMgDl'] as num).toDouble(),
      mealStatus: MealStatus.values.byName(json['mealStatus']),
      notes: json['notes'],
      createdAt: DateTime.parse(json['createdAt']),
    );
  }
}
