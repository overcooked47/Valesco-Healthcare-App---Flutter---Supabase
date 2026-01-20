import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import '../models/medication_plan_model.dart';
import '../models/reminder_model.dart';
import '../models/notification_model.dart';

/// MedicationReminderService based on class diagram
/// Methods: scheduleReminders(), sendReminderNotification(),
///          confirmReminderAcknowledged(), getReminderHistory()
class MedicationReminderService {
  // FIXED: Use non-nullable singleton pattern
  static final MedicationReminderService _singleton = MedicationReminderService._internal();
  
  factory MedicationReminderService() => _singleton;
  
  MedicationReminderService._internal();
  
  static MedicationReminderService get instance => _singleton;

  final List<Reminder> _activeReminders = [];
  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();
  
  bool _initialized = false;

  /// Initialize notification plugin
  Future<void> initialize() async {
    if (_initialized) return;

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notificationsPlugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Request permissions for Android 13+
    await _requestPermissions();

    _initialized = true;
    debugPrint('✅ MedicationReminderService initialized successfully');
  }

  Future<void> _requestPermissions() async {
    // Fix: Put everything on one line or use proper line continuation
    final androidPlugin = _notificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    
    if (androidPlugin != null) {
      await androidPlugin.requestNotificationsPermission();
      await androidPlugin.requestExactAlarmsPermission();
    }

    final iosPlugin = _notificationsPlugin
        .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
    
    if (iosPlugin != null) {
      await iosPlugin.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
    }
  }

  void _onNotificationTapped(NotificationResponse response) {
    debugPrint('Notification tapped: ${response.payload}');
    // You can handle navigation or actions here
    if (response.payload != null) {
      final reminderId = response.payload;
      confirmReminderAcknowledged(reminderId!);
    }
  }

  /// Schedule reminders for a medication plan
  Future<List<Reminder>> scheduleReminders({
    required MedicationPlan plan,
    required String userId,
  }) async {
    final reminders = <Reminder>[];

    for (final schedule in plan.schedules) {
      for (final time in schedule.timesOfDay) {
        final now = DateTime.now();
        final scheduledTime = DateTime(
          now.year,
          now.month,
          now.day,
          time.hour,
          time.minute,
        );

        // If time has passed today, schedule for tomorrow
        final reminderTime = scheduledTime.isBefore(now)
            ? scheduledTime.add(const Duration(days: 1))
            : scheduledTime;

        final reminder = Reminder.scheduleReminder(
          userId: userId,
          relatedId: schedule.id,
          relatedType: 'medication',
          scheduledTime: reminderTime,
          title: 'Medication Reminder',
          message: 'Time to take ${schedule.medicineName}',
        );

        reminders.add(reminder);
        _activeReminders.add(reminder);

        // Schedule actual device notification
        await _scheduleDeviceNotification(
          id: reminder.id.hashCode,
          title: reminder.title,
          body: reminder.message ?? 'Time to take your medication',
          scheduledTime: reminderTime,
          payload: reminder.id,
        );
      }
    }

    return reminders;
  }

  /// Schedule a single reminder
  Future<Reminder> scheduleSingleReminder({
    required String userId,
    required String medicationName,
    required DateTime scheduledTime,
    String? notes,
  }) async {
    final reminder = Reminder.scheduleReminder(
      userId: userId,
      relatedType: 'medication',
      scheduledTime: scheduledTime,
      title: 'Medication Reminder',
      message: 'Time to take $medicationName${notes != null ? ' - $notes' : ''}',
    );

    _activeReminders.add(reminder);

    // Schedule actual device notification
    await _scheduleDeviceNotification(
      id: reminder.id.hashCode,
      title: reminder.title,
      body: reminder.message ?? 'Time to take your medication',
      scheduledTime: scheduledTime,
      payload: reminder.id,
    );

    return reminder;
  }

  /// Schedule device notification (internal method)
  Future<void> _scheduleDeviceNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
    String? payload,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'medication_reminders',
      'Medication Reminders',
      channelDescription: 'Notifications for medication schedules',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
      enableVibration: true,
      playSound: true,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(scheduledTime, tz.local),
      notificationDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: payload,
    );

    debugPrint('✅ Scheduled notification: $title at $scheduledTime (ID: $id)');
  }

  /// Send reminder notification (for immediate notifications)
  Future<NotificationModel> sendReminderNotification(Reminder reminder) async {
    // Show immediate notification
    await _notificationsPlugin.show(
      reminder.id.hashCode,
      reminder.title,
      reminder.message ?? 'Medication reminder',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'medication_reminders',
          'Medication Reminders',
          channelDescription: 'Notifications for medication schedules',
          importance: Importance.max,
          priority: Priority.high,
          enableVibration: true,
          playSound: true,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: reminder.id,
    );

    final notification = NotificationModel.send(
      userId: reminder.userId,
      title: reminder.title,
      message: reminder.message ?? 'Medication reminder',
      channel: NotificationChannel.push,
      type: NotificationType.reminder,
      data: {
        'reminderId': reminder.id,
        'relatedId': reminder.relatedId,
        'relatedType': reminder.relatedType,
      },
    );

    // Update reminder status
    final index = _activeReminders.indexWhere((r) => r.id == reminder.id);
    if (index != -1) {
      _activeReminders[index] = reminder.markAsSent();
    }

    return notification;
  }

  /// Confirm reminder was acknowledged
  Future<Reminder> confirmReminderAcknowledged(String reminderId) async {
    final index = _activeReminders.indexWhere((r) => r.id == reminderId);
    if (index != -1) {
      final acknowledged = _activeReminders[index].markAcknowledged();
      _activeReminders[index] = acknowledged;
      
      // Cancel the device notification
      await _notificationsPlugin.cancel(reminderId.hashCode);
      
      return acknowledged;
    }
    throw Exception('Reminder not found');
  }

  /// Snooze a reminder
  Future<Reminder> snoozeReminder(String reminderId, {int minutes = 10}) async {
    final index = _activeReminders.indexWhere((r) => r.id == reminderId);
    if (index != -1) {
      final snoozed = _activeReminders[index].snoozeReminder(minutes: minutes);
      _activeReminders[index] = snoozed;
      
      // Cancel current notification
      await _notificationsPlugin.cancel(reminderId.hashCode);
      
      // Schedule new notification for snoozed time
      await _scheduleDeviceNotification(
        id: reminderId.hashCode,
        title: snoozed.title,
        body: snoozed.message ?? 'Time to take your medication',
        scheduledTime: snoozed.scheduledTime,
        payload: reminderId,
      );
      
      return snoozed;
    }
    throw Exception('Reminder not found');
  }

  /// Get reminder history for a user
  Future<List<Reminder>> getReminderHistory(String userId) async {
    // In real implementation, would fetch from database
    return _activeReminders
        .where((r) => r.userId == userId)
        .toList()
      ..sort((a, b) => b.scheduledTime.compareTo(a.scheduledTime));
  }

  /// Get pending reminders
  List<Reminder> getPendingReminders(String userId) {
    return _activeReminders
        .where((r) =>
            r.userId == userId &&
            (r.status == ReminderStatus.pending ||
             r.status == ReminderStatus.snoozed))
        .toList()
      ..sort((a, b) => a.scheduledTime.compareTo(b.scheduledTime));
  }

  /// Get due reminders
  List<Reminder> getDueReminders(String userId) {
    return _activeReminders
        .where((r) => r.userId == userId && r.isDue)
        .toList();
  }

  /// Cancel a reminder
  Future<void> cancelReminder(String reminderId) async {
    final index = _activeReminders.indexWhere((r) => r.id == reminderId);
    if (index != -1) {
      _activeReminders[index] = _activeReminders[index].cancel();
      
      // Cancel device notification
      await _notificationsPlugin.cancel(reminderId.hashCode);
    }
  }

  /// Cancel all reminders for a medication plan
  Future<void> cancelPlanReminders(String planId) async {
    for (int i = 0; i < _activeReminders.length; i++) {
      if (_activeReminders[i].relatedId == planId) {
        _activeReminders[i] = _activeReminders[i].cancel();
        
        // Cancel device notification
        await _notificationsPlugin.cancel(_activeReminders[i].id.hashCode);
      }
    }
  }

  /// Cancel all reminders
  Future<void> cancelAllReminders() async {
    await _notificationsPlugin.cancelAll();
    for (int i = 0; i < _activeReminders.length; i++) {
      _activeReminders[i] = _activeReminders[i].cancel();
    }
  }

  /// Get pending device notifications
  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    return await _notificationsPlugin.pendingNotificationRequests();
  }

  /// Get today's medication schedule
  List<Map<String, dynamic>> getTodaySchedule(String userId) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));

    return _activeReminders
        .where((r) =>
            r.userId == userId &&
            r.scheduledTime.isAfter(today) &&
            r.scheduledTime.isBefore(tomorrow) &&
            r.relatedType == 'medication')
        .map((r) => {
              'reminder': r,
              'time': TimeOfDay(
                hour: r.scheduledTime.hour,
                minute: r.scheduledTime.minute,
              ),
              'status': r.status.displayName,
            })
        .toList()
      ..sort((a, b) => (a['reminder'] as Reminder)
          .scheduledTime
          .compareTo((b['reminder'] as Reminder).scheduledTime));
  }
}