import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/health_profile_model.dart';

class HealthProfileProvider extends ChangeNotifier {
  HealthProfileModel? _healthProfile;
  List<EmergencyContact> _emergencyContacts = [];
  bool _isLoading = false;
  String? _error;

  final SupabaseClient _supabase = Supabase.instance.client;

  HealthProfileModel? get healthProfile => _healthProfile;
  HealthProfileModel? get profile => _healthProfile; // Alias for healthProfile
  List<EmergencyContact> get emergencyContacts =>
      _healthProfile?.emergencyContacts ?? _emergencyContacts;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasProfile => _healthProfile != null;

  /// Load profile from Supabase for the current user
  Future<void> loadProfile() async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      debugPrint('loadProfile: No authenticated user');
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      debugPrint('loadProfile: Loading profile for user ${user.id}');

      final data = await _supabase
          .from('health_profiles')
          .select()
          .eq('user_id', user.id)
          .maybeSingle();

      if (data != null) {
        _healthProfile = _profileFromSupabase(data);
        debugPrint('loadProfile: Profile loaded successfully');
      } else {
        debugPrint('loadProfile: No profile found for user');
      }

      // Load emergency contacts (even if no profile yet, we can still have contacts)
      try {
        final contacts = await _supabase
            .from('emergency_contacts')
            .select()
            .eq('user_id', user.id);

        final contactsList = (contacts as List)
            .map(
              (c) => EmergencyContact(
                id: c['id'],
                name: c['name'] ?? '',
                relationship: c['relationship'] ?? '',
                phoneNumber: c['phone_number'] ?? '',
                isPrimary: c['is_primary'] ?? false,
              ),
            )
            .toList();

        // Store in both places
        _emergencyContacts = contactsList;
        if (_healthProfile != null) {
          _healthProfile = _healthProfile!.copyWith(
            emergencyContacts: contactsList,
          );
        }
        debugPrint(
          'loadProfile: Loaded ${contactsList.length} emergency contacts',
        );
      } catch (contactError) {
        debugPrint('loadProfile: Failed to load contacts: $contactError');
        // Don't fail the whole operation if contacts fail to load
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to load profile: $e';
      debugPrint('loadProfile error: $e');
      _isLoading = false;
      notifyListeners();
    }
  }

  HealthProfileModel _profileFromSupabase(Map<String, dynamic> data) {
    return HealthProfileModel(
      id: data['id'],
      userId: data['user_id'],
      name: data['name'] ?? '',
      age: data['age'] ?? 0,
      gender: Gender.values.firstWhere(
        (g) => g.name == data['gender'],
        orElse: () => Gender.other,
      ),
      bloodGroup: BloodGroup.values.firstWhere(
        (b) => b.name == data['blood_group'],
        orElse: () => BloodGroup.oPositive,
      ),
      height: (data['height'] ?? 0).toDouble(),
      weight: (data['weight'] ?? 0).toDouble(),
      chronicConditions: List<String>.from(data['chronic_conditions'] ?? []),
      pastSurgeries: List<String>.from(data['past_surgeries'] ?? []),
      currentMedications: List<String>.from(data['current_medications'] ?? []),
      drugAllergies: List<String>.from(data['drug_allergies'] ?? []),
      foodAllergies: List<String>.from(data['food_allergies'] ?? []),
      createdAt: data['created_at'] != null
          ? DateTime.parse(data['created_at'])
          : DateTime.now(),
      updatedAt: data['updated_at'] != null
          ? DateTime.parse(data['updated_at'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> _profileToSupabase(HealthProfileModel profile) {
    return {
      'user_id': profile.userId,
      'name': profile.name,
      'age': profile.age,
      'gender': profile.gender.name,
      'blood_group': profile.bloodGroup.name,
      'height': profile.height,
      'weight': profile.weight,
      'chronic_conditions': profile.chronicConditions,
      'past_surgeries': profile.pastSurgeries,
      'current_medications': profile.currentMedications,
      'drug_allergies': profile.drugAllergies,
      'food_allergies': profile.foodAllergies,
      'updated_at': DateTime.now().toIso8601String(),
    };
  }

  Future<void> createProfile(HealthProfileModel profile) async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      _error = 'You must be logged in to create a profile';
      notifyListeners();
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Override userId with authenticated user
      final profileWithUserId = profile.copyWith(userId: user.id);
      final data = _profileToSupabase(profileWithUserId);
      data['created_at'] = DateTime.now().toIso8601String();

      final response = await _supabase
          .from('health_profiles')
          .insert(data)
          .select()
          .single();

      _healthProfile = _profileFromSupabase(response);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to create profile: $e';
      debugPrint('Create profile error: $e');
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateProfile(HealthProfileModel profile) async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      _error = 'You must be logged in to update profile';
      notifyListeners();
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final data = _profileToSupabase(profile);

      // Update using user_id instead of profile id for better reliability
      await _supabase
          .from('health_profiles')
          .update(data)
          .eq('user_id', user.id);

      _healthProfile = profile.copyWith(updatedAt: DateTime.now());
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to update profile: $e';
      debugPrint('Update profile error: $e');
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addEmergencyContact(EmergencyContact contact) async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      _error = 'You must be logged in to add emergency contacts';
      notifyListeners();
      return;
    }

    try {
      final response = await _supabase
          .from('emergency_contacts')
          .insert({
            'user_id': user.id,
            'name': contact.name,
            'relationship': contact.relationship,
            'phone_number': contact.phoneNumber,
            'is_primary': contact.isPrimary,
          })
          .select()
          .single();

      final newContact = EmergencyContact(
        id: response['id'],
        name: response['name'],
        relationship: response['relationship'],
        phoneNumber: response['phone_number'],
        isPrimary: response['is_primary'] ?? false,
      );

      // Update the separate contacts list
      _emergencyContacts = [..._emergencyContacts, newContact];

      // Also update health profile if it exists
      if (_healthProfile != null) {
        _healthProfile = _healthProfile!.copyWith(
          emergencyContacts: _emergencyContacts,
        );
      }
      debugPrint('addEmergencyContact: Contact added successfully');
      notifyListeners();
    } catch (e) {
      _error = 'Failed to add emergency contact: $e';
      debugPrint('addEmergencyContact error: $e');
      notifyListeners();
    }
  }

  Future<void> removeEmergencyContact(String contactId) async {
    try {
      await _supabase.from('emergency_contacts').delete().eq('id', contactId);

      // Update the separate contacts list
      _emergencyContacts = _emergencyContacts
          .where((c) => c.id != contactId)
          .toList();

      // Also update health profile if it exists
      if (_healthProfile != null) {
        _healthProfile = _healthProfile!.copyWith(
          emergencyContacts: _emergencyContacts,
        );
      }
      debugPrint('removeEmergencyContact: Contact removed successfully');
      notifyListeners();
    } catch (e) {
      _error = 'Failed to remove emergency contact: $e';
      debugPrint('removeEmergencyContact error: $e');
      notifyListeners();
    }
  }

  Future<void> updateEmergencyContact(EmergencyContact contact) async {
    try {
      await _supabase
          .from('emergency_contacts')
          .update({
            'name': contact.name,
            'relationship': contact.relationship,
            'phone_number': contact.phoneNumber,
            'is_primary': contact.isPrimary,
          })
          .eq('id', contact.id);

      // Update the separate contacts list
      _emergencyContacts = _emergencyContacts.map((c) {
        if (c.id == contact.id) return contact;
        return c;
      }).toList();

      // Also update health profile if it exists
      if (_healthProfile != null) {
        _healthProfile = _healthProfile!.copyWith(
          emergencyContacts: _emergencyContacts,
        );
      }
      debugPrint('updateEmergencyContact: Contact updated successfully');
      notifyListeners();
    } catch (e) {
      _error = 'Failed to update emergency contact: $e';
      debugPrint('updateEmergencyContact error: $e');
      notifyListeners();
    }
  }

  Future<void> addMedicalDocument(MedicalDocument document) async {
    if (_healthProfile == null) return;

    // For documents, we'll store metadata in Supabase
    // Actual files would go to Supabase Storage
    final updatedDocuments = [..._healthProfile!.medicalDocuments, document];
    _healthProfile = _healthProfile!.copyWith(
      medicalDocuments: updatedDocuments,
    );
    notifyListeners();
  }

  Future<void> removeMedicalDocument(String documentId) async {
    if (_healthProfile == null) return;

    final updatedDocuments = _healthProfile!.medicalDocuments
        .where((d) => d.id != documentId)
        .toList();
    _healthProfile = _healthProfile!.copyWith(
      medicalDocuments: updatedDocuments,
    );
    notifyListeners();
  }

  void clearProfile() {
    _healthProfile = null;
    _error = null;
    notifyListeners();
  }

  // Initialize with mock data (for offline/demo mode)
  void initMockProfile(String userId) {
    _healthProfile = HealthProfileModel(
      userId: userId,
      name: 'Demo User',
      age: 35,
      gender: Gender.male,
      bloodGroup: BloodGroup.oPositive,
      height: 175,
      weight: 72,
      chronicConditions: ['Type 2 Diabetes', 'Hypertension'],
      pastSurgeries: ['Appendectomy (2015)'],
      currentMedications: ['Metformin 500mg', 'Lisinopril 10mg'],
      drugAllergies: ['Penicillin', 'Sulfa drugs'],
      foodAllergies: ['Peanuts'],
      emergencyContacts: [
        EmergencyContact(
          name: 'Jane Doe',
          relationship: 'Spouse',
          phoneNumber: '01712345679',
          isPrimary: true,
        ),
        EmergencyContact(
          name: 'John Doe Sr.',
          relationship: 'Father',
          phoneNumber: '01712345680',
        ),
      ],
    );
    notifyListeners();
  }
}
