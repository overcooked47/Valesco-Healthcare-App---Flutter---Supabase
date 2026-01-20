import '../core/utils/uuid_helper.dart';
import 'location_model.dart';

/// EmergencyAlert model based on class diagram
/// Attributes: alertID, createdAt, alertType, status, message, location
/// Methods: createAlert(), sendAlert(), getAlertDetails()
enum EmergencyAlertStatus {
  initiated,
  sent,
  acknowledged,
  cancelled,
  resolved,
}

extension EmergencyAlertStatusExtension on EmergencyAlertStatus {
  String get displayName {
    switch (this) {
      case EmergencyAlertStatus.initiated:
        return 'Initiated';
      case EmergencyAlertStatus.sent:
        return 'Sent';
      case EmergencyAlertStatus.acknowledged:
        return 'Acknowledged';
      case EmergencyAlertStatus.cancelled:
        return 'Cancelled';
      case EmergencyAlertStatus.resolved:
        return 'Resolved';
    }
  }
}

enum AlertType {
  medical,
  accident,
  fire,
  security,
  other,
}

extension AlertTypeExtension on AlertType {
  String get displayName {
    switch (this) {
      case AlertType.medical:
        return 'Medical Emergency';
      case AlertType.accident:
        return 'Accident';
      case AlertType.fire:
        return 'Fire';
      case AlertType.security:
        return 'Security';
      case AlertType.other:
        return 'Other';
    }
  }
}

// Type alias for AlertStatus
typedef AlertStatus = EmergencyAlertStatus;

class EmergencyAlertModel {
  final String id;
  final String userId;
  final AlertType alertType;
  final LocationModel location;
  final String message;
  final DateTime createdAt;
  final EmergencyAlertStatus status;
  final List<String> contactsNotified;
  final String? ambulanceId;
  final String? notes;
  final DateTime? resolvedAt;

  EmergencyAlertModel({
    String? id,
    required this.userId,
    this.alertType = AlertType.medical,
    LocationModel? location,
    this.message = '',
    DateTime? createdAt,
    this.status = EmergencyAlertStatus.initiated,
    this.contactsNotified = const [],
    this.ambulanceId,
    this.notes,
    this.resolvedAt,
  })  : id = id ?? UuidHelper.generateV4(),
        location = location ?? LocationModel(latitude: 0, longitude: 0),
        createdAt = createdAt ?? DateTime.now();

  // Convenience getters for location
  double get latitude => location.latitude;
  double get longitude => location.longitude;
  String get address => location.address;
  DateTime get timestamp => createdAt;

  /// Create a new alert
  static EmergencyAlertModel createAlert({
    required String userId,
    AlertType alertType = AlertType.medical,
    LocationModel? location,
    String? message,
  }) {
    return EmergencyAlertModel(
      userId: userId,
      alertType: alertType,
      location: location,
      message: message ?? '',
    );
  }

  /// Send alert - updates status to sent
  EmergencyAlertModel sendAlert({List<String>? contacts}) {
    return copyWith(
      status: EmergencyAlertStatus.sent,
      contactsNotified: contacts ?? contactsNotified,
    );
  }

  /// Get alert details
  Map<String, dynamic> getAlertDetails() {
    return {
      'id': id,
      'userId': userId,
      'alertType': alertType.displayName,
      'location': {
        'latitude': latitude,
        'longitude': longitude,
        'address': address,
      },
      'message': message,
      'status': status.displayName,
      'createdAt': createdAt.toIso8601String(),
      'contactsNotified': contactsNotified,
      'ambulanceId': ambulanceId,
    };
  }

  /// Acknowledge the alert
  EmergencyAlertModel acknowledge() {
    return copyWith(status: EmergencyAlertStatus.acknowledged);
  }

  /// Resolve the alert
  EmergencyAlertModel resolve({String? notes}) {
    return copyWith(
      status: EmergencyAlertStatus.resolved,
      resolvedAt: DateTime.now(),
      notes: notes,
    );
  }

  /// Cancel the alert
  EmergencyAlertModel cancel({String? reason}) {
    return copyWith(
      status: EmergencyAlertStatus.cancelled,
      notes: reason,
    );
  }

  /// Assign ambulance to alert
  EmergencyAlertModel assignAmbulance(String ambulanceId) {
    return copyWith(ambulanceId: ambulanceId);
  }
  
  // Check if ambulance is booked
  bool get isAmbulanceBooked => ambulanceId != null;

  EmergencyAlertModel copyWith({
    String? id,
    String? userId,
    AlertType? alertType,
    LocationModel? location,
    String? message,
    DateTime? createdAt,
    EmergencyAlertStatus? status,
    List<String>? contactsNotified,
    String? ambulanceId,
    String? notes,
    DateTime? resolvedAt,
  }) {
    return EmergencyAlertModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      alertType: alertType ?? this.alertType,
      location: location ?? this.location,
      message: message ?? this.message,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
      contactsNotified: contactsNotified ?? this.contactsNotified,
      ambulanceId: ambulanceId ?? this.ambulanceId,
      notes: notes ?? this.notes,
      resolvedAt: resolvedAt ?? this.resolvedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'alertType': alertType.name,
      'location': location.toJson(),
      'message': message,
      'createdAt': createdAt.toIso8601String(),
      'status': status.name,
      'contactsNotified': contactsNotified,
      'ambulanceId': ambulanceId,
      'notes': notes,
      'resolvedAt': resolvedAt?.toIso8601String(),
    };
  }

  factory EmergencyAlertModel.fromJson(Map<String, dynamic> json) {
    return EmergencyAlertModel(
      id: json['id'],
      userId: json['userId'],
      alertType: json['alertType'] != null 
          ? AlertType.values.byName(json['alertType']) 
          : AlertType.medical,
      location: json['location'] != null
          ? LocationModel.fromJson(json['location'])
          : LocationModel(
              latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
              longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
              address: json['address'] ?? '',
            ),
      message: json['message'] ?? '',
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt'])
          : (json['timestamp'] != null ? DateTime.parse(json['timestamp']) : DateTime.now()),
      status: EmergencyAlertStatus.values.byName(json['status']),
      contactsNotified: List<String>.from(json['contactsNotified'] ?? []),
      ambulanceId: json['ambulanceId'],
      notes: json['notes'],
      resolvedAt: json['resolvedAt'] != null ? DateTime.parse(json['resolvedAt']) : null,
    );
  }
}
