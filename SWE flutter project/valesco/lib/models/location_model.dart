import '../core/utils/uuid_helper.dart';

/// Location model representing geographical coordinates and address information
/// Based on class diagram: Location class with latitude, longitude, address, timestamp
class LocationModel {
  final String id;
  final double latitude;
  final double longitude;
  final String address;
  final DateTime timestamp;

  LocationModel({
    String? id,
    required this.latitude,
    required this.longitude,
    this.address = '',
    DateTime? timestamp,
  })  : id = id ?? UuidHelper.generateV4(),
        timestamp = timestamp ?? DateTime.now();

  /// Get current location (static factory method)
  /// In a real implementation, this would use geolocator package
  static Future<LocationModel> getCurrentLocation() async {
    // Placeholder - would integrate with geolocator
    return LocationModel(
      latitude: 0.0,
      longitude: 0.0,
      address: 'Current Location',
    );
  }

  /// Update location with new coordinates
  LocationModel updateLocation({
    required double latitude,
    required double longitude,
    String? address,
  }) {
    return LocationModel(
      id: id,
      latitude: latitude,
      longitude: longitude,
      address: address ?? this.address,
    );
  }

  /// Get address from coordinates (reverse geocoding)
  /// In a real implementation, this would use geocoding package
  static Future<String> getAddressFromCoords(double lat, double lng) async {
    // Placeholder - would integrate with geocoding service
    return 'Address at ($lat, $lng)';
  }

  /// Calculate distance to another location in kilometers
  double distanceTo(LocationModel other) {
    // Haversine formula for calculating distance
    const double earthRadius = 6371; // km
    final double dLat = _toRadians(other.latitude - latitude);
    final double dLon = _toRadians(other.longitude - longitude);

    final double a = _sin(dLat / 2) * _sin(dLat / 2) +
        _cos(_toRadians(latitude)) *
            _cos(_toRadians(other.latitude)) *
            _sin(dLon / 2) *
            _sin(dLon / 2);

    final double c = 2 * _atan2(_sqrt(a), _sqrt(1 - a));
    return earthRadius * c;
  }

  // Math helper methods
  double _toRadians(double degrees) => degrees * 3.14159265359 / 180;
  double _sin(double x) => _taylorSin(x);
  double _cos(double x) => _taylorSin(x + 3.14159265359 / 2);
  double _sqrt(double x) => x > 0 ? _newtonSqrt(x) : 0;
  double _atan2(double y, double x) => _taylorAtan2(y, x);

  double _taylorSin(double x) {
    // Normalize to [-pi, pi]
    while (x > 3.14159265359) {
      x -= 2 * 3.14159265359;
    }
    while (x < -3.14159265359) {
      x += 2 * 3.14159265359;
    }
    double result = x;
    double term = x;
    for (int i = 1; i <= 10; i++) {
      term *= -x * x / ((2 * i) * (2 * i + 1));
      result += term;
    }
    return result;
  }

  double _newtonSqrt(double x) {
    double guess = x / 2;
    for (int i = 0; i < 20; i++) {
      guess = (guess + x / guess) / 2;
    }
    return guess;
  }

  double _taylorAtan2(double y, double x) {
    if (x > 0) return _atan(y / x);
    if (x < 0 && y >= 0) return _atan(y / x) + 3.14159265359;
    if (x < 0 && y < 0) return _atan(y / x) - 3.14159265359;
    if (x == 0 && y > 0) return 3.14159265359 / 2;
    if (x == 0 && y < 0) return -3.14159265359 / 2;
    return 0;
  }

  double _atan(double x) {
    double result = 0;
    double term = x;
    for (int i = 0; i < 20; i++) {
      result += (i % 2 == 0 ? 1 : -1) * term / (2 * i + 1);
      term *= x * x;
    }
    return result;
  }

  LocationModel copyWith({
    String? id,
    double? latitude,
    double? longitude,
    String? address,
    DateTime? timestamp,
  }) {
    return LocationModel(
      id: id ?? this.id,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      address: address ?? this.address,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'latitude': latitude,
      'longitude': longitude,
      'address': address,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory LocationModel.fromJson(Map<String, dynamic> json) {
    return LocationModel(
      id: json['id'],
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      address: json['address'] ?? '',
      timestamp: json['timestamp'] != null 
          ? DateTime.parse(json['timestamp']) 
          : DateTime.now(),
    );
  }

  @override
  String toString() {
    return 'LocationModel(lat: $latitude, lng: $longitude, address: $address)';
  }
}
