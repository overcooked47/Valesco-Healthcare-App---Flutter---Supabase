import '../core/utils/uuid_helper.dart';
import 'location_model.dart';

/// Hospital model based on class diagram
/// Attributes: hospitalID, name, address, phone, email, specialties, rating, location
/// Methods: getDetails(), getNearby(), getAvailableServices()
class HospitalModel {
  final String id;
  final String name;
  final String address;
  final String phoneNumber;
  final String? email;
  final List<String> specialties;
  final double rating;
  final LocationModel location;
  final double distance; // in km
  final String? imageUrl;
  final bool isEmergencyAvailable;
  final String operatingHours;
  final String? description;
  final String? website;

  HospitalModel({
    String? id,
    required this.name,
    required this.address,
    required this.phoneNumber,
    this.email,
    this.specialties = const [],
    this.rating = 0.0,
    LocationModel? location,
    required this.distance,
    this.imageUrl,
    this.isEmergencyAvailable = true,
    this.operatingHours = '24/7',
    this.description,
    this.website,
  })  : id = id ?? UuidHelper.generateV4(),
        location = location ?? LocationModel(latitude: 0, longitude: 0, address: address);

  // Convenience getters for location
  double get latitude => location.latitude;
  double get longitude => location.longitude;

  /// Get hospital details
  Map<String, dynamic> getDetails() {
    return {
      'id': id,
      'name': name,
      'address': address,
      'phone': phoneNumber,
      'email': email,
      'specialties': specialties,
      'rating': rating,
      'isEmergencyAvailable': isEmergencyAvailable,
      'operatingHours': operatingHours,
    };
  }

  /// Get nearby hospitals (static method - placeholder)
  static Future<List<HospitalModel>> getNearby(LocationModel currentLocation, {double radiusKm = 10}) async {
    // Placeholder - would integrate with maps/location API
    return [];
  }

  /// Get available services
  List<String> getAvailableServices() {
    return specialties;
  }

  // Aliases for property names used in screens
  String get phone => phoneNumber;
  double get distanceKm => distance;
  bool get hasEmergency => isEmergencyAvailable;
  bool get isOpen24Hours => operatingHours == '24/7';
  List<String> get services => specialties;
  bool get hasAmbulance => isEmergencyAvailable;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'address': address,
      'phoneNumber': phoneNumber,
      'email': email,
      'specialties': specialties,
      'rating': rating,
      'location': location.toJson(),
      'distance': distance,
      'imageUrl': imageUrl,
      'isEmergencyAvailable': isEmergencyAvailable,
      'operatingHours': operatingHours,
      'description': description,
      'website': website,
    };
  }

  factory HospitalModel.fromJson(Map<String, dynamic> json) {
    return HospitalModel(
      id: json['id'],
      name: json['name'],
      address: json['address'],
      phoneNumber: json['phoneNumber'],
      email: json['email'],
      specialties: List<String>.from(json['specialties'] ?? json['services'] ?? []),
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      location: json['location'] != null 
          ? LocationModel.fromJson(json['location'])
          : LocationModel(
              latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
              longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
              address: json['address'] ?? '',
            ),
      distance: (json['distance'] as num?)?.toDouble() ?? 0.0,
      imageUrl: json['imageUrl'],
      isEmergencyAvailable: json['isEmergencyAvailable'] ?? true,
      operatingHours: json['operatingHours'] ?? '24/7',
      description: json['description'],
      website: json['website'],
    );
  }

  HospitalModel copyWith({
    String? id,
    String? name,
    String? address,
    String? phoneNumber,
    String? email,
    List<String>? specialties,
    double? rating,
    LocationModel? location,
    double? distance,
    String? imageUrl,
    bool? isEmergencyAvailable,
    String? operatingHours,
    String? description,
    String? website,
  }) {
    return HospitalModel(
      id: id ?? this.id,
      name: name ?? this.name,
      address: address ?? this.address,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      email: email ?? this.email,
      specialties: specialties ?? this.specialties,
      rating: rating ?? this.rating,
      location: location ?? this.location,
      distance: distance ?? this.distance,
      imageUrl: imageUrl ?? this.imageUrl,
      isEmergencyAvailable: isEmergencyAvailable ?? this.isEmergencyAvailable,
      operatingHours: operatingHours ?? this.operatingHours,
      description: description ?? this.description,
      website: website ?? this.website,
    );
  }
}

/// AmbulanceService model based on class diagram
/// Attributes: serviceID, providerName, phone, isAvailable, vehicleType, currentLocation
/// Methods: requestAmbulance(), getETAToDestination()
enum AmbulanceStatus {
  available,
  busy,
  offline,
  enRoute,
  onScene,
}

extension AmbulanceStatusExtension on AmbulanceStatus {
  String get displayName {
    switch (this) {
      case AmbulanceStatus.available:
        return 'Available';
      case AmbulanceStatus.busy:
        return 'Busy';
      case AmbulanceStatus.offline:
        return 'Offline';
      case AmbulanceStatus.enRoute:
        return 'En Route';
      case AmbulanceStatus.onScene:
        return 'On Scene';
    }
  }
}

class AmbulanceModel {
  final String id;
  final String providerName;
  final String vehicleNumber;
  final String phoneNumber;
  final LocationModel currentLocation;
  final double distance; // in km
  final AmbulanceStatus status;
  final bool isAvailable;
  final int estimatedArrivalMinutes;
  final String vehicleType; // Basic, Advanced, ICU
  final String hospitalName;

  AmbulanceModel({
    String? id,
    required this.providerName,
    required this.vehicleNumber,
    required this.phoneNumber,
    LocationModel? currentLocation,
    required this.distance,
    this.status = AmbulanceStatus.available,
    bool? isAvailable,
    this.estimatedArrivalMinutes = 10,
    this.vehicleType = 'Basic',
    this.hospitalName = '',
  })  : id = id ?? UuidHelper.generateV4(),
        currentLocation = currentLocation ?? LocationModel(latitude: 0, longitude: 0),
        isAvailable = isAvailable ?? (status == AmbulanceStatus.available);

  // Convenience getters for location
  double get latitude => currentLocation.latitude;
  double get longitude => currentLocation.longitude;

  /// Request ambulance - returns true if request accepted
  bool requestAmbulance() {
    return isAvailable && status == AmbulanceStatus.available;
  }

  /// Get ETA to destination
  int getETAToDestination(LocationModel destination) {
    // Simple estimation based on distance
    final distanceToDestination = currentLocation.distanceTo(destination);
    // Assume average speed of 40 km/h in urban areas
    return (distanceToDestination / 40 * 60).ceil();
  }

  /// Cancel request (static method for service integration)
  bool cancelRequest() {
    return status == AmbulanceStatus.enRoute;
  }

  // Aliases for property names used in screens
  String get phone => phoneNumber;
  String get name => providerName;
  double get distanceKm => distance;
  String get driverName => providerName;
  bool get hasACAndOxygen => vehicleType != 'Basic';
  bool get isAdvancedLifeSupport => vehicleType == 'Advanced Life Support' || vehicleType == 'ICU Ambulance';
  String get type => vehicleType;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'providerName': providerName,
      'vehicleNumber': vehicleNumber,
      'phoneNumber': phoneNumber,
      'currentLocation': currentLocation.toJson(),
      'distance': distance,
      'status': status.name,
      'isAvailable': isAvailable,
      'estimatedArrivalMinutes': estimatedArrivalMinutes,
      'vehicleType': vehicleType,
      'hospitalName': hospitalName,
    };
  }

  factory AmbulanceModel.fromJson(Map<String, dynamic> json) {
    return AmbulanceModel(
      id: json['id'],
      providerName: json['providerName'] ?? json['name'] ?? '',
      vehicleNumber: json['vehicleNumber'],
      phoneNumber: json['phoneNumber'],
      currentLocation: json['currentLocation'] != null
          ? LocationModel.fromJson(json['currentLocation'])
          : LocationModel(
              latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
              longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
            ),
      distance: (json['distance'] as num?)?.toDouble() ?? 0.0,
      status: AmbulanceStatus.values.byName(json['status'] ?? 'available'),
      isAvailable: json['isAvailable'],
      estimatedArrivalMinutes: json['estimatedArrivalMinutes'] ?? 10,
      vehicleType: json['vehicleType'] ?? json['type'] ?? 'Basic',
      hospitalName: json['hospitalName'] ?? '',
    );
  }

  AmbulanceModel copyWith({
    String? id,
    String? providerName,
    String? vehicleNumber,
    String? phoneNumber,
    LocationModel? currentLocation,
    double? distance,
    AmbulanceStatus? status,
    bool? isAvailable,
    int? estimatedArrivalMinutes,
    String? vehicleType,
    String? hospitalName,
  }) {
    return AmbulanceModel(
      id: id ?? this.id,
      providerName: providerName ?? this.providerName,
      vehicleNumber: vehicleNumber ?? this.vehicleNumber,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      currentLocation: currentLocation ?? this.currentLocation,
      distance: distance ?? this.distance,
      status: status ?? this.status,
      isAvailable: isAvailable ?? this.isAvailable,
      estimatedArrivalMinutes: estimatedArrivalMinutes ?? this.estimatedArrivalMinutes,
      vehicleType: vehicleType ?? this.vehicleType,
      hospitalName: hospitalName ?? this.hospitalName,
    );
  }
}
