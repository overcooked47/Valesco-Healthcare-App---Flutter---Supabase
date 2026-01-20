import '../models/hospital_model.dart';
import '../models/location_model.dart';

/// NearbySearchService based on class diagram
/// Methods: findHospitalsNear(location, radius), findAmbulancesNear(location),
///          findDoctorsNear(location, specialty), notifyDistanceInMiles()
class NearbySearchService {
  static NearbySearchService? _instance;
  
  NearbySearchService._();
  
  static NearbySearchService get instance {
    _instance ??= NearbySearchService._();
    return _instance!;
  }

  /// Find hospitals near a location within given radius
  /// Returns list of hospitals sorted by distance
  Future<List<HospitalModel>> findHospitalsNear(
    LocationModel location, {
    double radiusKm = 10.0,
  }) async {
    // Placeholder - would integrate with maps/location API
    // In real implementation, this would query a backend service
    // or use Google Places API / similar
    
    // Mock data for demonstration
    final mockHospitals = [
      HospitalModel(
        name: 'City General Hospital',
        address: '123 Main Street',
        phoneNumber: '+1234567890',
        specialties: ['Emergency', 'Cardiology', 'Orthopedics'],
        rating: 4.5,
        distance: 2.3,
        location: LocationModel(
          latitude: location.latitude + 0.01,
          longitude: location.longitude + 0.01,
          address: '123 Main Street',
        ),
        isEmergencyAvailable: true,
      ),
      HospitalModel(
        name: 'Regional Medical Center',
        address: '456 Health Avenue',
        phoneNumber: '+1234567891',
        specialties: ['Emergency', 'Neurology', 'Pediatrics'],
        rating: 4.2,
        distance: 5.1,
        location: LocationModel(
          latitude: location.latitude + 0.02,
          longitude: location.longitude - 0.01,
          address: '456 Health Avenue',
        ),
        isEmergencyAvailable: true,
      ),
    ];

    // Filter by radius and sort by distance
    return mockHospitals
        .where((h) => h.distance <= radiusKm)
        .toList()
      ..sort((a, b) => a.distance.compareTo(b.distance));
  }

  /// Find ambulances near a location
  /// Returns list of available ambulances sorted by distance
  Future<List<AmbulanceModel>> findAmbulancesNear(LocationModel location) async {
    // Placeholder - would integrate with ambulance service API
    
    final mockAmbulances = [
      AmbulanceModel(
        providerName: 'City Ambulance Service',
        vehicleNumber: 'AMB-001',
        phoneNumber: '+1234567892',
        distance: 1.5,
        currentLocation: LocationModel(
          latitude: location.latitude + 0.005,
          longitude: location.longitude + 0.005,
        ),
        status: AmbulanceStatus.available,
        vehicleType: 'Advanced Life Support',
        estimatedArrivalMinutes: 8,
      ),
      AmbulanceModel(
        providerName: 'Regional Emergency Services',
        vehicleNumber: 'AMB-002',
        phoneNumber: '+1234567893',
        distance: 3.2,
        currentLocation: LocationModel(
          latitude: location.latitude - 0.01,
          longitude: location.longitude + 0.01,
        ),
        status: AmbulanceStatus.available,
        vehicleType: 'Basic Life Support',
        estimatedArrivalMinutes: 15,
      ),
    ];

    return mockAmbulances
        .where((a) => a.isAvailable)
        .toList()
      ..sort((a, b) => a.distance.compareTo(b.distance));
  }

  /// Find doctors/specialists near a location
  Future<List<Map<String, dynamic>>> findDoctorsNear(
    LocationModel location, {
    String? specialty,
  }) async {
    // Placeholder - would integrate with healthcare provider API
    return [
      {
        'name': 'Dr. John Smith',
        'specialty': specialty ?? 'General Practice',
        'distance': 1.2,
        'rating': 4.8,
        'available': true,
      },
    ];
  }

  /// Convert distance to miles and notify
  double notifyDistanceInMiles(double distanceKm) {
    return distanceKm * 0.621371;
  }

  /// Get nearby emergency services
  Future<Map<String, dynamic>> getNearbyEmergencyServices(
    LocationModel location,
  ) async {
    final hospitals = await findHospitalsNear(location, radiusKm: 15);
    final ambulances = await findAmbulancesNear(location);

    return {
      'hospitals': hospitals,
      'ambulances': ambulances,
      'nearestHospital': hospitals.isNotEmpty ? hospitals.first : null,
      'nearestAmbulance': ambulances.isNotEmpty ? ambulances.first : null,
    };
  }
}
