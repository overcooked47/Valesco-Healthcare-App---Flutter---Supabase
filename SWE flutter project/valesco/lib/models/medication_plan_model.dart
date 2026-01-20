import '../core/utils/uuid_helper.dart';
import 'medication_schedule_model.dart';

/// MedicationPlan model based on class diagram
/// Attributes: planID, isActive, startDate, instructions, isActive
/// Methods: createPlan(), updatePlan(), addPlan(), generateReport(), setAlert()
class MedicationPlan {
  final String id;
  final String patientId;
  final String medicationId;
  final bool isActive;
  final DateTime startDate;
  final DateTime? endDate;
  final String instructions;
  final String? prescribedBy;
  final String? reason;
  final List<MedicationSchedule> schedules;
  final DateTime createdAt;
  final DateTime updatedAt;

  MedicationPlan({
    String? id,
    required this.patientId,
    required this.medicationId,
    this.isActive = true,
    required this.startDate,
    this.endDate,
    required this.instructions,
    this.prescribedBy,
    this.reason,
    this.schedules = const [],
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : id = id ?? UuidHelper.generateV4(),
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  /// Create a new medication plan
  static MedicationPlan createPlan({
    required String patientId,
    required String medicationId,
    required DateTime startDate,
    DateTime? endDate,
    required String instructions,
    String? prescribedBy,
    String? reason,
    List<MedicationSchedule>? schedules,
  }) {
    return MedicationPlan(
      patientId: patientId,
      medicationId: medicationId,
      startDate: startDate,
      endDate: endDate,
      instructions: instructions,
      prescribedBy: prescribedBy,
      reason: reason,
      schedules: schedules ?? [],
      isActive: true,
    );
  }

  /// Update the medication plan
  MedicationPlan updatePlan({
    bool? isActive,
    DateTime? endDate,
    String? instructions,
    String? prescribedBy,
    String? reason,
    List<MedicationSchedule>? schedules,
  }) {
    return copyWith(
      isActive: isActive,
      endDate: endDate,
      instructions: instructions,
      prescribedBy: prescribedBy,
      reason: reason,
      schedules: schedules,
      updatedAt: DateTime.now(),
    );
  }

  /// Add a schedule to the plan
  MedicationPlan addSchedule(MedicationSchedule schedule) {
    return copyWith(
      schedules: [...schedules, schedule],
      updatedAt: DateTime.now(),
    );
  }

  /// Generate a report of the medication plan
  Map<String, dynamic> generateReport() {
    final now = DateTime.now();
    final daysOnPlan = now.difference(startDate).inDays;
    
    return {
      'planId': id,
      'medicationId': medicationId,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'daysOnPlan': daysOnPlan,
      'isActive': isActive,
      'totalSchedules': schedules.length,
      'instructions': instructions,
      'prescribedBy': prescribedBy,
    };
  }

  /// Set alert for the plan (returns true if alert set successfully)
  bool setAlert() {
    // Placeholder - would integrate with notification service
    return isActive && schedules.isNotEmpty;
  }

  /// Check if plan is currently valid
  bool get isCurrentlyValid {
    final now = DateTime.now();
    if (!isActive) return false;
    if (now.isBefore(startDate)) return false;
    if (endDate != null && now.isAfter(endDate!)) return false;
    return true;
  }

  /// Get remaining days on plan
  int? get remainingDays {
    if (endDate == null) return null;
    final now = DateTime.now();
    return endDate!.difference(now).inDays;
  }

  MedicationPlan copyWith({
    String? id,
    String? patientId,
    String? medicationId,
    bool? isActive,
    DateTime? startDate,
    DateTime? endDate,
    String? instructions,
    String? prescribedBy,
    String? reason,
    List<MedicationSchedule>? schedules,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return MedicationPlan(
      id: id ?? this.id,
      patientId: patientId ?? this.patientId,
      medicationId: medicationId ?? this.medicationId,
      isActive: isActive ?? this.isActive,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      instructions: instructions ?? this.instructions,
      prescribedBy: prescribedBy ?? this.prescribedBy,
      reason: reason ?? this.reason,
      schedules: schedules ?? this.schedules,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'patientId': patientId,
      'medicationId': medicationId,
      'isActive': isActive,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'instructions': instructions,
      'prescribedBy': prescribedBy,
      'reason': reason,
      'schedules': schedules.map((s) => s.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory MedicationPlan.fromJson(Map<String, dynamic> json) {
    return MedicationPlan(
      id: json['id'],
      patientId: json['patientId'],
      medicationId: json['medicationId'],
      isActive: json['isActive'] ?? true,
      startDate: DateTime.parse(json['startDate']),
      endDate: json['endDate'] != null ? DateTime.parse(json['endDate']) : null,
      instructions: json['instructions'],
      prescribedBy: json['prescribedBy'],
      reason: json['reason'],
      schedules: (json['schedules'] as List?)
              ?.map((s) => MedicationSchedule.fromJson(s))
              .toList() ??
          [],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }
}


/// Medication model based on class diagram
/// Attributes: medicationID, name, dosage, sideEffects, type, instructions
/// Methods: getFullMedIngredients(), findAlternativeMed(), getMedsByCondition()
enum MedicationType {
  tablet,
  capsule,
  liquid,
  injection,
  topical,
  inhaler,
  drops,
  patch,
  other,
}

extension MedicationTypeExtension on MedicationType {
  String get displayName {
    switch (this) {
      case MedicationType.tablet:
        return 'Tablet';
      case MedicationType.capsule:
        return 'Capsule';
      case MedicationType.liquid:
        return 'Liquid/Syrup';
      case MedicationType.injection:
        return 'Injection';
      case MedicationType.topical:
        return 'Topical/Cream';
      case MedicationType.inhaler:
        return 'Inhaler';
      case MedicationType.drops:
        return 'Drops';
      case MedicationType.patch:
        return 'Patch';
      case MedicationType.other:
        return 'Other';
    }
  }
}

class Medication {
  final String id;
  final String name;
  final String dosage;
  final List<String> sideEffects;
  final MedicationType type;
  final String instructions;
  final String? manufacturer;
  final String? genericName;
  final List<String>? ingredients;
  final List<String>? contraindications;
  final DateTime createdAt;

  Medication({
    String? id,
    required this.name,
    required this.dosage,
    this.sideEffects = const [],
    required this.type,
    required this.instructions,
    this.manufacturer,
    this.genericName,
    this.ingredients,
    this.contraindications,
    DateTime? createdAt,
  })  : id = id ?? UuidHelper.generateV4(),
        createdAt = createdAt ?? DateTime.now();

  /// Get full medication ingredients
  List<String> getFullMedIngredients() {
    return ingredients ?? [];
  }

  /// Find alternative medication (placeholder - would integrate with drug database)
  List<String> findAlternativeMed() {
    // Placeholder - would return alternatives based on generic name
    if (genericName != null) {
      return ['Alternative 1 for $genericName', 'Alternative 2 for $genericName'];
    }
    return [];
  }

  /// Get medications by condition (static method)
  static List<Medication> getMedsByCondition(String condition, List<Medication> allMeds) {
    // Placeholder - would filter based on condition
    return allMeds;
  }

  /// Get formatted dosage with type
  String get formattedDosage => '$dosage ${type.displayName}';

  /// Check if medication has known side effects
  bool get hasSideEffects => sideEffects.isNotEmpty;

  Medication copyWith({
    String? id,
    String? name,
    String? dosage,
    List<String>? sideEffects,
    MedicationType? type,
    String? instructions,
    String? manufacturer,
    String? genericName,
    List<String>? ingredients,
    List<String>? contraindications,
    DateTime? createdAt,
  }) {
    return Medication(
      id: id ?? this.id,
      name: name ?? this.name,
      dosage: dosage ?? this.dosage,
      sideEffects: sideEffects ?? this.sideEffects,
      type: type ?? this.type,
      instructions: instructions ?? this.instructions,
      manufacturer: manufacturer ?? this.manufacturer,
      genericName: genericName ?? this.genericName,
      ingredients: ingredients ?? this.ingredients,
      contraindications: contraindications ?? this.contraindications,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'dosage': dosage,
      'sideEffects': sideEffects,
      'type': type.name,
      'instructions': instructions,
      'manufacturer': manufacturer,
      'genericName': genericName,
      'ingredients': ingredients,
      'contraindications': contraindications,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Medication.fromJson(Map<String, dynamic> json) {
    return Medication(
      id: json['id'],
      name: json['name'],
      dosage: json['dosage'],
      sideEffects: List<String>.from(json['sideEffects'] ?? []),
      type: MedicationType.values.byName(json['type']),
      instructions: json['instructions'],
      manufacturer: json['manufacturer'],
      genericName: json['genericName'],
      ingredients: json['ingredients'] != null 
          ? List<String>.from(json['ingredients']) 
          : null,
      contraindications: json['contraindications'] != null 
          ? List<String>.from(json['contraindications']) 
          : null,
      createdAt: DateTime.parse(json['createdAt']),
    );
  }
}
