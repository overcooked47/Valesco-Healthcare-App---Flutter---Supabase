import '../core/utils/uuid_helper.dart';

/// Allergy model based on class diagram
/// Attributes: allergyID, allergenName, allergyType, reaction, severity, notes
/// Methods: createValid(), isValid(), addAllergy(), removeAllergy(), getAllergyInfo()
enum AllergySeverity {
  mild,
  moderate,
  severe,
  lifeThreatening,
}

extension AllergySeverityExtension on AllergySeverity {
  String get displayName {
    switch (this) {
      case AllergySeverity.mild:
        return 'Mild';
      case AllergySeverity.moderate:
        return 'Moderate';
      case AllergySeverity.severe:
        return 'Severe';
      case AllergySeverity.lifeThreatening:
        return 'Life-Threatening';
    }
  }
}

enum AllergyType {
  drug,
  food,
  environmental,
  insect,
  latex,
  other,
}

extension AllergyTypeExtension on AllergyType {
  String get displayName {
    switch (this) {
      case AllergyType.drug:
        return 'Drug';
      case AllergyType.food:
        return 'Food';
      case AllergyType.environmental:
        return 'Environmental';
      case AllergyType.insect:
        return 'Insect';
      case AllergyType.latex:
        return 'Latex';
      case AllergyType.other:
        return 'Other';
    }
  }
}

class Allergy {
  final String id;
  final String patientId;
  final String allergenName;
  final AllergyType allergyType;
  final String reaction;
  final AllergySeverity severity;
  final String? notes;
  final DateTime createdAt;

  Allergy({
    String? id,
    required this.patientId,
    required this.allergenName,
    required this.allergyType,
    required this.reaction,
    required this.severity,
    this.notes,
    DateTime? createdAt,
  })  : id = id ?? UuidHelper.generateV4(),
        createdAt = createdAt ?? DateTime.now();

  /// Create a valid allergy record
  static Allergy? createValid({
    required String patientId,
    required String allergenName,
    required AllergyType allergyType,
    required String reaction,
    required AllergySeverity severity,
    String? notes,
  }) {
    // Validate required fields
    if (allergenName.trim().isEmpty || reaction.trim().isEmpty) {
      return null;
    }

    return Allergy(
      patientId: patientId,
      allergenName: allergenName.trim(),
      allergyType: allergyType,
      reaction: reaction.trim(),
      severity: severity,
      notes: notes,
    );
  }

  /// Check if allergy data is valid
  bool isValid() {
    return allergenName.trim().isNotEmpty && reaction.trim().isNotEmpty;
  }

  /// Get allergy information as formatted string
  String getAllergyInfo() {
    return '$allergenName (${allergyType.displayName}) - ${severity.displayName}: $reaction';
  }

  /// Check if this is a severe allergy
  bool get isSevere => 
      severity == AllergySeverity.severe || 
      severity == AllergySeverity.lifeThreatening;

  /// Check if this is a drug allergy
  bool get isDrugAllergy => allergyType == AllergyType.drug;

  /// Check if this is a food allergy
  bool get isFoodAllergy => allergyType == AllergyType.food;

  Allergy copyWith({
    String? id,
    String? patientId,
    String? allergenName,
    AllergyType? allergyType,
    String? reaction,
    AllergySeverity? severity,
    String? notes,
    DateTime? createdAt,
  }) {
    return Allergy(
      id: id ?? this.id,
      patientId: patientId ?? this.patientId,
      allergenName: allergenName ?? this.allergenName,
      allergyType: allergyType ?? this.allergyType,
      reaction: reaction ?? this.reaction,
      severity: severity ?? this.severity,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'patientId': patientId,
      'allergenName': allergenName,
      'allergyType': allergyType.name,
      'reaction': reaction,
      'severity': severity.name,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Allergy.fromJson(Map<String, dynamic> json) {
    return Allergy(
      id: json['id'],
      patientId: json['patientId'],
      allergenName: json['allergenName'],
      allergyType: AllergyType.values.byName(json['allergyType']),
      reaction: json['reaction'],
      severity: AllergySeverity.values.byName(json['severity']),
      notes: json['notes'],
      createdAt: DateTime.parse(json['createdAt']),
    );
  }
}
