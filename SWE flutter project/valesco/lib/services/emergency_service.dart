import '../models/emergency_alert_model.dart';
import '../models/emergency_contact_model.dart';
import '../models/location_model.dart';
import '../models/notification_model.dart';

/// EmergencyService based on class diagram
/// Methods: sendOneClickAlert(user, location), notifyEmergencyContacts(alert),
///          requestAmbulance(location), showLocationWithContacts(),
///          sentOneClickAlert(user, location), notifyEmergencyContact(alert),
///          requestNearbyAmbulance(location), shareLocationWithContacts(user)
class EmergencyService {
  static EmergencyService? _instance;
  
  EmergencyService._();
  
  static EmergencyService get instance {
    _instance ??= EmergencyService._();
    return _instance!;
  }

  /// Send a one-click emergency alert
  Future<EmergencyAlertModel> sendOneClickAlert({
    required String userId,
    required LocationModel location,
    AlertType alertType = AlertType.medical,
    String? message,
  }) async {
    // Create the alert
    final alert = EmergencyAlertModel.createAlert(
      userId: userId,
      alertType: alertType,
      location: location,
      message: message,
    );

    // In a real implementation, this would:
    // 1. Save to database
    // 2. Notify emergency contacts
    // 3. Contact emergency services if needed

    return alert.sendAlert();
  }

  /// Notify all emergency contacts about an alert
  Future<bool> notifyEmergencyContacts({
    required EmergencyAlertModel alert,
    required List<EmergencyContactModel> contacts,
  }) async {
    // Sort contacts by priority
    final sortedContacts = List<EmergencyContactModel>.from(contacts)
      ..sort((a, b) => a.priority.compareTo(b.priority));

    final notifiedIds = <String>[];

    for (final contact in sortedContacts) {
      try {
        // In real implementation, would send SMS/push notification
        await _sendNotificationToContact(contact, alert);
        notifiedIds.add(contact.id);
      } catch (e) {
        // Log error but continue notifying other contacts
        print('Failed to notify ${contact.name}: $e');
      }
    }

    return notifiedIds.isNotEmpty;
  }

  Future<void> _sendNotificationToContact(
    EmergencyContactModel contact,
    EmergencyAlertModel alert,
  ) async {
    // Placeholder - would integrate with SMS/notification service
    final notification = NotificationModel.send(
      userId: contact.userId,
      title: 'Emergency Alert',
      message: 'Emergency alert from a family member. Location: ${alert.address}',
      channel: NotificationChannel.sms,
      type: NotificationType.emergency,
    );

    // Send via appropriate channel
    print('Sending emergency notification to ${contact.name}: ${notification.message}');
  }

  /// Request nearest ambulance
  Future<Map<String, dynamic>> requestAmbulance({
    required LocationModel location,
    required String userId,
    String? notes,
  }) async {
    // In real implementation, would:
    // 1. Find nearest available ambulance
    // 2. Send request to ambulance service
    // 3. Return booking confirmation

    return {
      'success': true,
      'estimatedArrival': 10,
      'ambulanceId': 'AMB-001',
      'message': 'Ambulance dispatched to your location',
    };
  }

  /// Share location with emergency contacts
  Future<bool> shareLocationWithContacts({
    required String userId,
    required LocationModel location,
    required List<EmergencyContactModel> contacts,
  }) async {
    for (final contact in contacts) {
      try {
        // In real implementation, would send location sharing link
        await _shareLocationWithContact(contact, location);
      } catch (e) {
        print('Failed to share location with ${contact.name}: $e');
      }
    }
    return true;
  }

  Future<void> _shareLocationWithContact(
    EmergencyContactModel contact,
    LocationModel location,
  ) async {
    // Placeholder - would send actual location link
    final locationUrl = 'https://maps.google.com/?q=${location.latitude},${location.longitude}';
    print('Sharing location with ${contact.name}: $locationUrl');
  }

  /// Get emergency alert history for a user
  Future<List<EmergencyAlertModel>> getAlertHistory(String userId) async {
    // Placeholder - would fetch from database
    return [];
  }

  /// Cancel an active alert
  Future<EmergencyAlertModel> cancelAlert(
    EmergencyAlertModel alert, {
    String? reason,
  }) async {
    return alert.cancel(reason: reason);
  }

  /// Resolve an alert
  Future<EmergencyAlertModel> resolveAlert(
    EmergencyAlertModel alert, {
    String? notes,
  }) async {
    return alert.resolve(notes: notes);
  }
}
