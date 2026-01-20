import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../models/location_model.dart';

/// LocationService - Handles GPS location retrieval and permissions
/// Uses the geolocator package to get the device's current location
class LocationService {
  static LocationService? _instance;
  
  LocationService._();
  
  static LocationService get instance {
    _instance ??= LocationService._();
    return _instance!;
  }

  Position? _lastKnownPosition;
  
  /// Get the last known position (cached)
  Position? get lastKnownPosition => _lastKnownPosition;

  /// Check if location services are enabled
  Future<bool> isLocationServiceEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  /// Check and request location permission
  /// Returns true if permission is granted
  Future<bool> checkAndRequestPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();
    
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        debugPrint('Location permission denied');
        return false;
      }
    }
    
    if (permission == LocationPermission.deniedForever) {
      debugPrint('Location permission permanently denied');
      return false;
    }
    
    return true;
  }

  /// Get the current location of the device
  /// Returns null if location cannot be obtained
  Future<Position?> getCurrentLocation({
    LocationAccuracy accuracy = LocationAccuracy.high,
    Duration timeout = const Duration(seconds: 10),
  }) async {
    try {
      // Check if location services are enabled
      final serviceEnabled = await isLocationServiceEnabled();
      if (!serviceEnabled) {
        debugPrint('Location services are disabled');
        return null;
      }

      // Check and request permission
      final hasPermission = await checkAndRequestPermission();
      if (!hasPermission) {
        return null;
      }

      // Get current position
      final position = await Geolocator.getCurrentPosition(
        locationSettings: LocationSettings(
          accuracy: accuracy,
          timeLimit: timeout,
        ),
      );
      
      _lastKnownPosition = position;
      debugPrint('Got location: ${position.latitude}, ${position.longitude}');
      return position;
    } catch (e) {
      debugPrint('Error getting location: $e');
      return null;
    }
  }

  /// Get location as LocationModel
  Future<LocationModel?> getCurrentLocationModel() async {
    final position = await getCurrentLocation();
    if (position == null) return null;
    
    return LocationModel(
      latitude: position.latitude,
      longitude: position.longitude,
    );
  }

  /// Calculate distance between two points in kilometers
  double calculateDistanceKm(
    double startLatitude,
    double startLongitude,
    double endLatitude,
    double endLongitude,
  ) {
    // Geolocator.distanceBetween returns meters
    final distanceMeters = Geolocator.distanceBetween(
      startLatitude,
      startLongitude,
      endLatitude,
      endLongitude,
    );
    return distanceMeters / 1000; // Convert to km
  }

  /// Open location settings (if permission denied)
  Future<bool> openLocationSettings() async {
    return await Geolocator.openLocationSettings();
  }

  /// Open app settings (if permission permanently denied)
  Future<bool> openAppSettings() async {
    return await Geolocator.openAppSettings();
  }

  /// Stream of position updates for real-time tracking
  Stream<Position> getPositionStream({
    LocationAccuracy accuracy = LocationAccuracy.high,
    int distanceFilter = 10, // minimum distance (meters) to trigger update
  }) {
    return Geolocator.getPositionStream(
      locationSettings: LocationSettings(
        accuracy: accuracy,
        distanceFilter: distanceFilter,
      ),
    );
  }
}
