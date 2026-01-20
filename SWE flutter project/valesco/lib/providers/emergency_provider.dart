import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/emergency_alert_model.dart';
import '../models/health_profile_model.dart';
import '../models/location_model.dart';

class EmergencyProvider extends ChangeNotifier {
  EmergencyAlertModel? _activeAlert;
  List<EmergencyAlertModel> _alertHistory = [];
  bool _isLoading = false;
  String? _error;
  int _countdown = 5;
  bool _isCancellable = true;

  final SupabaseClient _supabase = Supabase.instance.client;

  EmergencyAlertModel? get activeAlert => _activeAlert;
  List<EmergencyAlertModel> get alertHistory => _alertHistory;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get countdown => _countdown;
  int get countdownSeconds => _countdown; // Alias
  bool get isCancellable => _isCancellable;
  bool get hasActiveAlert =>
      _activeAlert != null &&
      _activeAlert!.status != EmergencyAlertStatus.cancelled &&
      _activeAlert!.status != EmergencyAlertStatus.resolved;
  bool get isAlertActive => hasActiveAlert; // Alias

  /// Load alert history from Supabase
  Future<void> loadAlertHistory() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    try {
      final data = await _supabase
          .from('emergency_alerts')
          .select()
          .eq('user_id', user.id)
          .order('created_at', ascending: false)
          .limit(20);

      _alertHistory = (data as List).map((a) => _alertFromSupabase(a)).toList();
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to load alert history: $e');
    }
  }

  EmergencyAlertModel _alertFromSupabase(Map<String, dynamic> data) {
    return EmergencyAlertModel(
      id: data['id'],
      userId: data['user_id'],
      location: LocationModel(
        latitude: (data['latitude'] ?? 0).toDouble(),
        longitude: (data['longitude'] ?? 0).toDouble(),
        address: data['address'] ?? '',
      ),
      status: EmergencyAlertStatus.values.firstWhere(
        (s) => s.name == data['status'],
        orElse: () => EmergencyAlertStatus.initiated,
      ),
      contactsNotified: List<String>.from(data['contacts_notified'] ?? []),
      ambulanceId: data['ambulance_id'],
      notes: data['notes'],
      createdAt: DateTime.parse(data['created_at']),
      resolvedAt: data['resolved_at'] != null
          ? DateTime.parse(data['resolved_at'])
          : null,
    );
  }

  Future<bool> initiateEmergencyAlert({
    required String userId,
    required double latitude,
    required double longitude,
    String address = '',
    List<EmergencyContact>? contacts,
  }) async {
    _isLoading = true;
    _countdown = 5;
    _isCancellable = true;
    notifyListeners();

    _activeAlert = EmergencyAlertModel(
      userId: userId,
      location: LocationModel(
        latitude: latitude,
        longitude: longitude,
        address: address,
      ),
      status: EmergencyAlertStatus.initiated,
    );
    notifyListeners();

    // Countdown before sending
    for (int i = 5; i > 0; i--) {
      if (_activeAlert?.status == EmergencyAlertStatus.cancelled) {
        return false;
      }
      _countdown = i;
      notifyListeners();
      await Future.delayed(const Duration(seconds: 1));
    }

    _isCancellable = false;

    // Send alert to contacts
    await _sendAlertToContacts(contacts ?? []);

    _activeAlert = _activeAlert?.copyWith(
      status: EmergencyAlertStatus.sent,
      contactsNotified: contacts?.map((c) => c.id).toList() ?? [],
    );

    // Save to Supabase
    try {
      await _supabase.from('emergency_alerts').insert({
        'user_id': userId,
        'latitude': latitude,
        'longitude': longitude,
        'address': address,
        'status': _activeAlert!.status.name,
        'contacts_notified': _activeAlert!.contactsNotified,
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('Failed to save alert: $e');
    }

    _isLoading = false;
    notifyListeners();
    return true;
  }

  Future<void> _sendAlertToContacts(List<EmergencyContact> contacts) async {
    // Simulate sending SMS/calls to emergency contacts
    await Future.delayed(const Duration(seconds: 2));

    // In real app, this would:
    // 1. Send SMS to all contacts with location and emergency info
    // 2. Initiate calls to primary contacts
    // 3. Share health profile with emergency services
  }

  void cancelAlert() {
    if (_activeAlert != null && _isCancellable) {
      _activeAlert = _activeAlert!.copyWith(
        status: EmergencyAlertStatus.cancelled,
        resolvedAt: DateTime.now(),
      );
      _alertHistory.insert(0, _activeAlert!);
      _activeAlert = null;
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> resolveAlert({String? notes}) async {
    if (_activeAlert != null) {
      _activeAlert = _activeAlert!.copyWith(
        status: EmergencyAlertStatus.resolved,
        resolvedAt: DateTime.now(),
        notes: notes,
      );

      // Update in Supabase
      try {
        await _supabase
            .from('emergency_alerts')
            .update({
              'status': EmergencyAlertStatus.resolved.name,
              'resolved_at': DateTime.now().toIso8601String(),
              'notes': notes,
            })
            .eq('id', _activeAlert!.id);
      } catch (e) {
        debugPrint('Failed to update alert: $e');
      }

      _alertHistory.insert(0, _activeAlert!);
      _activeAlert = null;
      notifyListeners();
    }
  }

  Future<void> bookAmbulance(String ambulanceId) async {
    if (_activeAlert != null) {
      _activeAlert = _activeAlert!.copyWith(
        ambulanceId: ambulanceId,
        status: EmergencyAlertStatus.acknowledged,
      );

      // Update in Supabase
      try {
        await _supabase
            .from('emergency_alerts')
            .update({
              'ambulance_id': ambulanceId,
              'status': EmergencyAlertStatus.acknowledged.name,
            })
            .eq('id', _activeAlert!.id);
      } catch (e) {
        debugPrint('Failed to book ambulance: $e');
      }

      notifyListeners();
    }
  }

  void clearHistory() {
    _alertHistory = [];
    notifyListeners();
  }

  Future<void> initiateAlert({
    required String userId,
    required double latitude,
    required double longitude,
    String address = '',
    List<EmergencyContact>? contacts,
  }) async {
    await initiateEmergencyAlert(
      userId: userId,
      latitude: latitude,
      longitude: longitude,
      address: address,
      contacts: contacts,
    );
  }

  Future<void> callEmergencyNumber(String number) async {
    // In a real app, this would use url_launcher to make a phone call
    // For now, it's a mock implementation
    await Future.delayed(const Duration(milliseconds: 500));
  }
}
