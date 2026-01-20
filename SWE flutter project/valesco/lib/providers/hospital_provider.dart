import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/hospital_model.dart';
import '../models/location_model.dart';
import '../services/location_service.dart';

class HospitalProvider extends ChangeNotifier {
  List<HospitalModel> _hospitals = [];
  List<HospitalModel> _filteredHospitals = [];
  List<AmbulanceModel> _ambulances = [];
  bool _isLoading = false;
  String? _error;
  double? _userLatitude;
  double? _userLongitude;
  String? _selectedSpecialty;
  bool _locationPermissionDenied = false;
  bool _locationServiceDisabled = false;

  final SupabaseClient _supabase = Supabase.instance.client;
  final LocationService _locationService = LocationService.instance;

  List<HospitalModel> get hospitals => _selectedSpecialty == null ? _hospitals : _filteredHospitals;
  List<AmbulanceModel> get ambulances => _ambulances;
  List<AmbulanceModel> get availableAmbulances => _ambulances.where((a) => a.status == AmbulanceStatus.available).toList();
  bool get isLoading => _isLoading;
  String? get error => _error;
  double? get userLatitude => _userLatitude;
  double? get userLongitude => _userLongitude;
  String? get selectedSpecialty => _selectedSpecialty;
  bool get locationPermissionDenied => _locationPermissionDenied;
  bool get locationServiceDisabled => _locationServiceDisabled;
  bool get hasUserLocation => _userLatitude != null && _userLongitude != null;

  void setUserLocation(double lat, double lng) {
    _userLatitude = lat;
    _userLongitude = lng;
    _locationPermissionDenied = false;
    _locationServiceDisabled = false;
    notifyListeners();
  }

  /// Initialize and get user's current location
  Future<bool> initializeUserLocation() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Check if location service is enabled
      final serviceEnabled = await _locationService.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _locationServiceDisabled = true;
        _error = 'Location services are disabled. Please enable them in settings.';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      // Get current position
      final position = await _locationService.getCurrentLocation();
      if (position == null) {
        _locationPermissionDenied = true;
        _error = 'Location permission denied. Please grant permission to find nearby hospitals.';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      _userLatitude = position.latitude;
      _userLongitude = position.longitude;
      _locationPermissionDenied = false;
      _locationServiceDisabled = false;
      
      debugPrint('User location initialized: $_userLatitude, $_userLongitude');
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error initializing location: $e');
      _error = 'Failed to get your location. Please try again.';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Open device location settings
  Future<void> openLocationSettings() async {
    await _locationService.openLocationSettings();
  }

  /// Open app settings for permissions
  Future<void> openAppSettings() async {
    await _locationService.openAppSettings();
  }

  /// Load hospitals from Supabase
  Future<void> fetchNearbyHospitals({bool refreshLocation = false}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    // Initialize or refresh user location if needed
    if (!hasUserLocation || refreshLocation) {
      final locationSuccess = await initializeUserLocation();
      if (!locationSuccess) {
        // Location failed, but still try to load hospitals
        // Use a default location as fallback
        debugPrint('Using default location as fallback');
      }
    }

    try {
      final data = await _supabase
          .from('hospitals')
          .select()
          .order('name');

      if ((data as List).isNotEmpty) {
        _hospitals = data.map((h) => _hospitalFromSupabase(h)).toList();
        
        // Calculate distances from user location (if available)
        if (hasUserLocation) {
          for (int i = 0; i < _hospitals.length; i++) {
            _hospitals[i] = _hospitals[i].copyWith(
              distance: _locationService.calculateDistanceKm(
                _userLatitude!,
                _userLongitude!,
                _hospitals[i].location.latitude,
                _hospitals[i].location.longitude,
              ),
            );
          }
          
          // Sort by distance
          _hospitals.sort((a, b) => a.distance.compareTo(b.distance));
        }
      } else {
        // Use mock data if no hospitals in database
        initMockData();
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      // Fall back to mock data on error
      debugPrint('Failed to load hospitals: $e');
      initMockData();
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Load ambulances from Supabase
  Future<void> fetchNearbyAmbulances() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final data = await _supabase
          .from('ambulances')
          .select()
          .order('created_at');

      if ((data as List).isNotEmpty) {
        _ambulances = data.map((a) => _ambulanceFromSupabase(a)).toList();
      } else {
        // Use mock data if no ambulances in database
        if (_ambulances.isEmpty) {
          initMockData();
        }
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to load ambulances: $e');
      if (_ambulances.isEmpty) {
        initMockData();
      }
      _isLoading = false;
      notifyListeners();
    }
  }

  HospitalModel _hospitalFromSupabase(Map<String, dynamic> data) {
    return HospitalModel(
      id: data['id'],
      name: data['name'] ?? '',
      address: data['address'] ?? '',
      phoneNumber: data['phone_number'] ?? '',
      location: LocationModel(
        latitude: (data['latitude'] ?? 0).toDouble(),
        longitude: (data['longitude'] ?? 0).toDouble(),
        address: data['address'] ?? '',
      ),
      distance: 0,
      specialties: List<String>.from(data['specialties'] ?? []),
      rating: (data['rating'] ?? 0).toDouble(),
      isEmergencyAvailable: data['is_emergency_available'] ?? false,
    );
  }

  AmbulanceModel _ambulanceFromSupabase(Map<String, dynamic> data) {
    final ambulanceLat = (data['latitude'] ?? 0).toDouble();
    final ambulanceLng = (data['longitude'] ?? 0).toDouble();
    
    return AmbulanceModel(
      id: data['id'],
      providerName: data['provider_name'] ?? '',
      vehicleNumber: data['vehicle_number'] ?? '',
      phoneNumber: data['phone_number'] ?? '',
      currentLocation: LocationModel(
        latitude: ambulanceLat,
        longitude: ambulanceLng,
      ),
      distance: hasUserLocation 
          ? _locationService.calculateDistanceKm(
              _userLatitude!,
              _userLongitude!,
              ambulanceLat,
              ambulanceLng,
            )
          : 0,
      status: AmbulanceStatus.values.firstWhere(
        (s) => s.name == data['status'],
        orElse: () => AmbulanceStatus.available,
      ),
      estimatedArrivalMinutes: data['estimated_arrival_minutes'] ?? 15,
      vehicleType: data['vehicle_type'] ?? 'Basic Life Support',
      hospitalName: data['hospital_name'],
    );
  }

  Future<void> searchNearbyHospitals({double radius = 10.0}) async {
    await fetchNearbyHospitals();
  }

  Future<void> searchNearbyAmbulances() async {
    await fetchNearbyAmbulances();
  }

  List<HospitalModel> filterHospitalsByService(String service) {
    return _hospitals.where(
      (h) => h.services.any((s) => s.toLowerCase().contains(service.toLowerCase())),
    ).toList();
  }

  List<AmbulanceModel> getAvailableAmbulances() {
    return _ambulances.where((a) => a.status == AmbulanceStatus.available).toList();
  }

  HospitalModel? getNearestHospital() {
    if (_hospitals.isEmpty) return null;
    return _hospitals.reduce((a, b) => a.distance < b.distance ? a : b);
  }

  AmbulanceModel? getNearestAvailableAmbulance() {
    final available = getAvailableAmbulances();
    if (available.isEmpty) return null;
    return available.reduce((a, b) => a.distance < b.distance ? a : b);
  }

  void searchHospitals(String query) {
    if (query.isEmpty) {
      _filteredHospitals = _hospitals;
    } else {
      _filteredHospitals = _hospitals.where((h) => 
        h.name.toLowerCase().contains(query.toLowerCase()) ||
        h.address.toLowerCase().contains(query.toLowerCase()) ||
        h.services.any((s) => s.toLowerCase().contains(query.toLowerCase()))
      ).toList();
    }
    notifyListeners();
  }

  void filterBySpecialty(String? specialty) {
    _selectedSpecialty = specialty;
    if (specialty == null) {
      _filteredHospitals = _hospitals;
    } else if (specialty == 'Open Now') {
      _filteredHospitals = _hospitals.where((h) => h.isEmergencyAvailable).toList();
    } else {
      _filteredHospitals = _hospitals.where((h) =>
        h.services.any((s) => s.toLowerCase().contains(specialty.toLowerCase()))
      ).toList();
    }
    notifyListeners();
  }

  // Initialize with mock data (for offline/demo mode)
  void initMockData() {
    // Define mock hospital data with their actual coordinates
    final mockHospitalData = [
      {
        'name': 'Square Hospital',
        'address': '18/F, Bir Uttam Qazi Nuruzzaman Sarak, Dhaka 1205',
        'phone': '+880-2-8159457',
        'lat': 23.7508,
        'lng': 90.3888,
        'specialties': ['Emergency', 'ICU', 'Surgery', 'Cardiology', 'Neurology'],
        'rating': 4.5,
      },
      {
        'name': 'United Hospital',
        'address': 'Plot 15, Road 71, Gulshan, Dhaka 1212',
        'phone': '+880-2-8836000',
        'lat': 23.7934,
        'lng': 90.4145,
        'specialties': ['Emergency', 'ICU', 'Oncology', 'Orthopedics', 'Pediatrics'],
        'rating': 4.3,
      },
      {
        'name': 'Labaid Hospital',
        'address': 'House 1, Road 4, Dhanmondi, Dhaka 1205',
        'phone': '+880-2-9116551',
        'lat': 23.7461,
        'lng': 90.3742,
        'specialties': ['Emergency', 'Diagnostics', 'Surgery', 'Medicine'],
        'rating': 4.0,
      },
      {
        'name': 'Evercare Hospital',
        'address': 'Plot 81, Block E, Bashundhara R/A, Dhaka',
        'phone': '+880-2-8431661',
        'lat': 23.8167,
        'lng': 90.4354,
        'specialties': ['Emergency', 'ICU', 'Cardiology', 'Nephrology', 'Dialysis'],
        'rating': 4.6,
      },
      {
        'name': 'Ibn Sina Hospital',
        'address': 'House 48, Road 9/A, Dhanmondi, Dhaka',
        'phone': '+880-2-9116551',
        'lat': 23.7418,
        'lng': 90.3755,
        'specialties': ['Emergency', 'Surgery', 'Gynecology', 'Pediatrics'],
        'rating': 4.2,
      },
    ];

    // Create hospitals with dynamic distance calculation
    _hospitals = mockHospitalData.map((data) {
      final hospitalLat = data['lat'] as double;
      final hospitalLng = data['lng'] as double;
      
      // Calculate distance from user's current location
      final distance = hasUserLocation
          ? _locationService.calculateDistanceKm(
              _userLatitude!,
              _userLongitude!,
              hospitalLat,
              hospitalLng,
            )
          : 0.0;
      
      return HospitalModel(
        name: data['name'] as String,
        address: data['address'] as String,
        phoneNumber: data['phone'] as String,
        location: LocationModel(
          latitude: hospitalLat,
          longitude: hospitalLng,
          address: data['address'] as String,
        ),
        distance: distance,
        specialties: List<String>.from(data['specialties'] as List),
        rating: data['rating'] as double,
        isEmergencyAvailable: true,
      );
    }).toList();

    // Sort by distance if we have user location
    if (hasUserLocation) {
      _hospitals.sort((a, b) => a.distance.compareTo(b.distance));
    }

    // Mock ambulance data
    final mockAmbulanceData = [
      {'name': 'Ambulance 001', 'vehicle': 'Dhaka Metro 11-2345', 'phone': '+880-1711-123456', 'lat': 23.7550, 'lng': 90.3900, 'type': 'Advanced Life Support', 'hospital': 'Square Hospital', 'status': AmbulanceStatus.available},
      {'name': 'Ambulance 002', 'vehicle': 'Dhaka Metro 11-3456', 'phone': '+880-1711-234567', 'lat': 23.7900, 'lng': 90.4100, 'type': 'Basic Life Support', 'hospital': 'United Hospital', 'status': AmbulanceStatus.available},
      {'name': 'Ambulance 003', 'vehicle': 'Dhaka Metro 11-4567', 'phone': '+880-1711-345678', 'lat': 23.8000, 'lng': 90.4200, 'type': 'ICU Ambulance', 'hospital': 'Evercare Hospital', 'status': AmbulanceStatus.busy},
      {'name': 'Ambulance 004', 'vehicle': 'Dhaka Metro 11-5678', 'phone': '+880-1711-456789', 'lat': 23.7480, 'lng': 90.3780, 'type': 'Advanced Life Support', 'hospital': 'Labaid Hospital', 'status': AmbulanceStatus.available},
    ];

    _ambulances = mockAmbulanceData.map((data) {
      final ambLat = data['lat'] as double;
      final ambLng = data['lng'] as double;
      
      final distance = hasUserLocation
          ? _locationService.calculateDistanceKm(_userLatitude!, _userLongitude!, ambLat, ambLng)
          : 0.0;
      
      // Estimate arrival time based on distance (assume average 30 km/h in city traffic)
      final estimatedMinutes = hasUserLocation ? (distance / 30 * 60).round().clamp(5, 60) : 15;
      
      return AmbulanceModel(
        providerName: data['name'] as String,
        vehicleNumber: data['vehicle'] as String,
        phoneNumber: data['phone'] as String,
        currentLocation: LocationModel(latitude: ambLat, longitude: ambLng),
        distance: distance,
        status: data['status'] as AmbulanceStatus,
        estimatedArrivalMinutes: estimatedMinutes,
        vehicleType: data['type'] as String,
        hospitalName: data['hospital'] as String,
      );
    }).toList();

    // Sort ambulances by distance
    if (hasUserLocation) {
      _ambulances.sort((a, b) => a.distance.compareTo(b.distance));
    }

    notifyListeners();
  }
}
