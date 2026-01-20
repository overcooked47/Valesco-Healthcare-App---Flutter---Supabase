import '../core/utils/uuid_helper.dart';
import 'health_metric_model.dart';
import 'allergy_model.dart';
import 'health_condition_model.dart';

/// PatientProfile model based on class diagram
/// Attributes: patientID, dateOfBirth, gender, bloodType, height, weight, address
/// Methods: createProfile(), updateProfile(), getAge(), calculateBMI()
/// Relationships: has 0..* HealthMetric, has 0..* Allergy, has 0..* HealthCondition
class PatientProfile {
  final String id;
  final String userId;
  final DateTime dateOfBirth;
  final String gender;
  final String bloodType;
  final double height; // in cm
  final double weight; // in kg
  final String address;
  final List<HealthMetric> healthMetrics;
  final List<Allergy> allergies;
  final List<HealthCondition> healthConditions;
  final DateTime createdAt;
  final DateTime updatedAt;

  PatientProfile({
    String? id,
    required this.userId,
    required this.dateOfBirth,
    required this.gender,
    required this.bloodType,
    required this.height,
    required this.weight,
    this.address = '',
    this.healthMetrics = const [],
    this.allergies = const [],
    this.healthConditions = const [],
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : id = id ?? UuidHelper.generateV4(),
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  /// Create a new patient profile
  static PatientProfile createProfile({
    required String userId,
    required DateTime dateOfBirth,
    required String gender,
    required String bloodType,
    required double height,
    required double weight,
    String? address,
  }) {
    return PatientProfile(
      userId: userId,
      dateOfBirth: dateOfBirth,
      gender: gender,
      bloodType: bloodType,
      height: height,
      weight: weight,
      address: address ?? '',
    );
  }

  /// Update profile with new values
  PatientProfile updateProfile({
    DateTime? dateOfBirth,
    String? gender,
    String? bloodType,
    double? height,
    double? weight,
    String? address,
    List<HealthMetric>? healthMetrics,
    List<Allergy>? allergies,
    List<HealthCondition>? healthConditions,
  }) {
    return copyWith(
      dateOfBirth: dateOfBirth,
      gender: gender,
      bloodType: bloodType,
      height: height,
      weight: weight,
      address: address,
      healthMetrics: healthMetrics,
      allergies: allergies,
      healthConditions: healthConditions,
      updatedAt: DateTime.now(),
    );
  }

  /// Get age in years
  int getAge() {
    final now = DateTime.now();
    int age = now.year - dateOfBirth.year;
    if (now.month < dateOfBirth.month ||
        (now.month == dateOfBirth.month && now.day < dateOfBirth.day)) {
      age--;
    }
    return age;
  }

  /// Calculate BMI
  double calculateBMI() {
    if (height <= 0) return 0;
    final heightInMeters = height / 100;
    return weight / (heightInMeters * heightInMeters);
  }

  /// Get BMI category
  String get bmiCategory {
    final bmi = calculateBMI();
    if (bmi < 18.5) return 'Underweight';
    if (bmi < 25) return 'Normal';
    if (bmi < 30) return 'Overweight';
    return 'Obese';
  }

  /// Add a health metric
  PatientProfile addHealthMetric(HealthMetric metric) {
    return copyWith(
      healthMetrics: [...healthMetrics, metric],
      updatedAt: DateTime.now(),
    );
  }

  /// Add an allergy
  PatientProfile addAllergy(Allergy allergy) {
    return copyWith(
      allergies: [...allergies, allergy],
      updatedAt: DateTime.now(),
    );
  }

  /// Add a health condition
  PatientProfile addHealthCondition(HealthCondition condition) {
    return copyWith(
      healthConditions: [...healthConditions, condition],
      updatedAt: DateTime.now(),
    );
  }

  /// Get health metrics by type
  List<HealthMetric> getMetrics() {
    return healthMetrics;
  }

  /// Calculate trend for a specific metric type
  String calculateTrend(String metricType) {
    final metrics = healthMetrics
        .where((m) => m.metricType == metricType)
        .toList()
      ..sort((a, b) => a.recordedAt.compareTo(b.recordedAt));

    if (metrics.length < 2) return 'Insufficient data';

    final recent = metrics.last.value;
    final previous = metrics[metrics.length - 2].value;

    if (recent > previous) return 'Increasing';
    if (recent < previous) return 'Decreasing';
    return 'Stable';
  }

  PatientProfile copyWith({
    String? id,
    String? userId,
    DateTime? dateOfBirth,
    String? gender,
    String? bloodType,
    double? height,
    double? weight,
    String? address,
    List<HealthMetric>? healthMetrics,
    List<Allergy>? allergies,
    List<HealthCondition>? healthConditions,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PatientProfile(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      gender: gender ?? this.gender,
      bloodType: bloodType ?? this.bloodType,
      height: height ?? this.height,
      weight: weight ?? this.weight,
      address: address ?? this.address,
      healthMetrics: healthMetrics ?? this.healthMetrics,
      allergies: allergies ?? this.allergies,
      healthConditions: healthConditions ?? this.healthConditions,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'dateOfBirth': dateOfBirth.toIso8601String(),
      'gender': gender,
      'bloodType': bloodType,
      'height': height,
      'weight': weight,
      'address': address,
      'healthMetrics': healthMetrics.map((m) => m.toJson()).toList(),
      'allergies': allergies.map((a) => a.toJson()).toList(),
      'healthConditions': healthConditions.map((c) => c.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory PatientProfile.fromJson(Map<String, dynamic> json) {
    return PatientProfile(
      id: json['id'],
      userId: json['userId'],
      dateOfBirth: DateTime.parse(json['dateOfBirth']),
      gender: json['gender'],
      bloodType: json['bloodType'],
      height: (json['height'] as num).toDouble(),
      weight: (json['weight'] as num).toDouble(),
      address: json['address'] ?? '',
      healthMetrics: (json['healthMetrics'] as List?)
              ?.map((m) => HealthMetric.fromJson(m))
              .toList() ??
          [],
      allergies: (json['allergies'] as List?)
              ?.map((a) => Allergy.fromJson(a))
              .toList() ??
          [],
      healthConditions: (json['healthConditions'] as List?)
              ?.map((c) => HealthCondition.fromJson(c))
              .toList() ??
          [],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }
}
