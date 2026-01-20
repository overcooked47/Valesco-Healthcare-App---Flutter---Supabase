import '../core/utils/uuid_helper.dart';

enum Gender { male, female, other }

enum BloodGroup { aPositive, aNegative, bPositive, bNegative, abPositive, abNegative, oPositive, oNegative }

extension BloodGroupExtension on BloodGroup {
  String get displayName {
    switch (this) {
      case BloodGroup.aPositive:
        return 'A+';
      case BloodGroup.aNegative:
        return 'A-';
      case BloodGroup.bPositive:
        return 'B+';
      case BloodGroup.bNegative:
        return 'B-';
      case BloodGroup.abPositive:
        return 'AB+';
      case BloodGroup.abNegative:
        return 'AB-';
      case BloodGroup.oPositive:
        return 'O+';
      case BloodGroup.oNegative:
        return 'O-';
    }
  }
}

class HealthProfileModel {
  final String id;
  final String userId;
  final String name;
  final int age;
  final Gender gender;
  final BloodGroup bloodGroup;
  final double height; // in cm
  final double weight; // in kg
  final List<String> chronicConditions;
  final List<String> pastSurgeries;
  final List<String> currentMedications;
  final List<String> drugAllergies;
  final List<String> foodAllergies;
  final List<EmergencyContact> emergencyContacts;
  final List<MedicalDocument> medicalDocuments;
  final DateTime createdAt;
  final DateTime updatedAt;

  HealthProfileModel({
    String? id,
    required this.userId,
    required this.name,
    required this.age,
    required this.gender,
    required this.bloodGroup,
    required this.height,
    required this.weight,
    this.chronicConditions = const [],
    this.pastSurgeries = const [],
    this.currentMedications = const [],
    this.drugAllergies = const [],
    this.foodAllergies = const [],
    this.emergencyContacts = const [],
    this.medicalDocuments = const [],
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : id = id ?? UuidHelper.generateV4(),
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  double get bmi => weight / ((height / 100) * (height / 100));

  String get bmiCategory {
    if (bmi < 18.5) return 'Underweight';
    if (bmi < 25) return 'Normal';
    if (bmi < 30) return 'Overweight';
    return 'Obese';
  }

  HealthProfileModel copyWith({
    String? id,
    String? userId,
    String? name,
    int? age,
    Gender? gender,
    BloodGroup? bloodGroup,
    double? height,
    double? weight,
    List<String>? chronicConditions,
    List<String>? pastSurgeries,
    List<String>? currentMedications,
    List<String>? drugAllergies,
    List<String>? foodAllergies,
    List<EmergencyContact>? emergencyContacts,
    List<MedicalDocument>? medicalDocuments,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return HealthProfileModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      age: age ?? this.age,
      gender: gender ?? this.gender,
      bloodGroup: bloodGroup ?? this.bloodGroup,
      height: height ?? this.height,
      weight: weight ?? this.weight,
      chronicConditions: chronicConditions ?? this.chronicConditions,
      pastSurgeries: pastSurgeries ?? this.pastSurgeries,
      currentMedications: currentMedications ?? this.currentMedications,
      drugAllergies: drugAllergies ?? this.drugAllergies,
      foodAllergies: foodAllergies ?? this.foodAllergies,
      emergencyContacts: emergencyContacts ?? this.emergencyContacts,
      medicalDocuments: medicalDocuments ?? this.medicalDocuments,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'name': name,
      'age': age,
      'gender': gender.name,
      'bloodGroup': bloodGroup.name,
      'height': height,
      'weight': weight,
      'chronicConditions': chronicConditions,
      'pastSurgeries': pastSurgeries,
      'currentMedications': currentMedications,
      'drugAllergies': drugAllergies,
      'foodAllergies': foodAllergies,
      'emergencyContacts': emergencyContacts.map((e) => e.toJson()).toList(),
      'medicalDocuments': medicalDocuments.map((e) => e.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory HealthProfileModel.fromJson(Map<String, dynamic> json) {
    return HealthProfileModel(
      id: json['id'],
      userId: json['userId'],
      name: json['name'],
      age: json['age'],
      gender: Gender.values.byName(json['gender']),
      bloodGroup: BloodGroup.values.byName(json['bloodGroup']),
      height: json['height'].toDouble(),
      weight: json['weight'].toDouble(),
      chronicConditions: List<String>.from(json['chronicConditions'] ?? []),
      pastSurgeries: List<String>.from(json['pastSurgeries'] ?? []),
      currentMedications: List<String>.from(json['currentMedications'] ?? []),
      drugAllergies: List<String>.from(json['drugAllergies'] ?? []),
      foodAllergies: List<String>.from(json['foodAllergies'] ?? []),
      emergencyContacts: (json['emergencyContacts'] as List?)
              ?.map((e) => EmergencyContact.fromJson(e))
              .toList() ??
          [],
      medicalDocuments: (json['medicalDocuments'] as List?)
              ?.map((e) => MedicalDocument.fromJson(e))
              .toList() ??
          [],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }
}

class EmergencyContact {
  final String id;
  final String name;
  final String relationship;
  final String phoneNumber;
  final bool isPrimary;

  EmergencyContact({
    String? id,
    required this.name,
    required this.relationship,
    required this.phoneNumber,
    this.isPrimary = false,
  }) : id = id ?? UuidHelper.generateV4();

  EmergencyContact copyWith({
    String? id,
    String? name,
    String? relationship,
    String? phoneNumber,
    bool? isPrimary,
  }) {
    return EmergencyContact(
      id: id ?? this.id,
      name: name ?? this.name,
      relationship: relationship ?? this.relationship,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      isPrimary: isPrimary ?? this.isPrimary,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'relationship': relationship,
      'phoneNumber': phoneNumber,
      'isPrimary': isPrimary,
    };
  }

  factory EmergencyContact.fromJson(Map<String, dynamic> json) {
    return EmergencyContact(
      id: json['id'],
      name: json['name'],
      relationship: json['relationship'],
      phoneNumber: json['phoneNumber'],
      isPrimary: json['isPrimary'] ?? false,
    );
  }
}

class MedicalDocument {
  final String id;
  final String name;
  final String type; // prescription, test_report, scan, etc.
  final String filePath;
  final DateTime uploadedAt;
  final String? notes;

  MedicalDocument({
    String? id,
    required this.name,
    required this.type,
    required this.filePath,
    DateTime? uploadedAt,
    this.notes,
  })  : id = id ?? UuidHelper.generateV4(),
        uploadedAt = uploadedAt ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'filePath': filePath,
      'uploadedAt': uploadedAt.toIso8601String(),
      'notes': notes,
    };
  }

  factory MedicalDocument.fromJson(Map<String, dynamic> json) {
    return MedicalDocument(
      id: json['id'],
      name: json['name'],
      type: json['type'],
      filePath: json['filePath'],
      uploadedAt: DateTime.parse(json['uploadedAt']),
      notes: json['notes'],
    );
  }
}
