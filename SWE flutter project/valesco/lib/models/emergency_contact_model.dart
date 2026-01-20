import '../core/utils/uuid_helper.dart';

/// EmergencyContact model based on class diagram
/// Attributes: contactID, name, email, phone, relationship, priority
/// Methods: addContact(), updateContact(), removeContact()
class EmergencyContactModel {
  final String id;
  final String userId;
  final String name;
  final String email;
  final String phone;
  final String relationship;
  final int priority; // 1 = highest priority
  final bool isPrimary;
  final DateTime createdAt;
  final DateTime updatedAt;

  EmergencyContactModel({
    String? id,
    required this.userId,
    required this.name,
    this.email = '',
    required this.phone,
    required this.relationship,
    this.priority = 1,
    this.isPrimary = false,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : id = id ?? UuidHelper.generateV4(),
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  /// Add a new contact - factory method
  static EmergencyContactModel addContact({
    required String userId,
    required String name,
    String? email,
    required String phone,
    required String relationship,
    int? priority,
    bool isPrimary = false,
  }) {
    return EmergencyContactModel(
      userId: userId,
      name: name,
      email: email ?? '',
      phone: phone,
      relationship: relationship,
      priority: priority ?? 1,
      isPrimary: isPrimary,
    );
  }

  /// Update contact information
  EmergencyContactModel updateContact({
    String? name,
    String? email,
    String? phone,
    String? relationship,
    int? priority,
    bool? isPrimary,
  }) {
    return copyWith(
      name: name,
      email: email,
      phone: phone,
      relationship: relationship,
      priority: priority,
      isPrimary: isPrimary,
      updatedAt: DateTime.now(),
    );
  }

  /// Validate contact data
  bool isValid() {
    return name.trim().isNotEmpty && 
           phone.trim().isNotEmpty && 
           relationship.trim().isNotEmpty;
  }

  /// Get formatted phone number
  String get formattedPhone {
    // Simple formatting - can be enhanced based on locale
    final cleaned = phone.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleaned.length == 10) {
      return '(${cleaned.substring(0, 3)}) ${cleaned.substring(3, 6)}-${cleaned.substring(6)}';
    }
    return phone;
  }

  /// Get display string for contact
  String get displayString => '$name ($relationship)';

  EmergencyContactModel copyWith({
    String? id,
    String? userId,
    String? name,
    String? email,
    String? phone,
    String? relationship,
    int? priority,
    bool? isPrimary,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return EmergencyContactModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      relationship: relationship ?? this.relationship,
      priority: priority ?? this.priority,
      isPrimary: isPrimary ?? this.isPrimary,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'name': name,
      'email': email,
      'phone': phone,
      'relationship': relationship,
      'priority': priority,
      'isPrimary': isPrimary,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory EmergencyContactModel.fromJson(Map<String, dynamic> json) {
    return EmergencyContactModel(
      id: json['id'],
      userId: json['userId'],
      name: json['name'],
      email: json['email'] ?? '',
      phone: json['phone'],
      relationship: json['relationship'],
      priority: json['priority'] ?? 1,
      isPrimary: json['isPrimary'] ?? false,
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }
}
