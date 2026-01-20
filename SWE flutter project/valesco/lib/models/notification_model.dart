import '../core/utils/uuid_helper.dart';

/// Notification model based on class diagram
/// Attributes: notificationID, title, message, channel, createdAt, isRead
/// Methods: send(), markAsRead()
enum NotificationChannel {
  push,
  sms,
  email,
  inApp,
}

extension NotificationChannelExtension on NotificationChannel {
  String get displayName {
    switch (this) {
      case NotificationChannel.push:
        return 'Push Notification';
      case NotificationChannel.sms:
        return 'SMS';
      case NotificationChannel.email:
        return 'Email';
      case NotificationChannel.inApp:
        return 'In-App';
    }
  }
}

enum NotificationType {
  reminder,
  alert,
  emergency,
  information,
  promotion,
}

extension NotificationTypeExtension on NotificationType {
  String get displayName {
    switch (this) {
      case NotificationType.reminder:
        return 'Reminder';
      case NotificationType.alert:
        return 'Alert';
      case NotificationType.emergency:
        return 'Emergency';
      case NotificationType.information:
        return 'Information';
      case NotificationType.promotion:
        return 'Promotion';
    }
  }
}

class NotificationModel {
  final String id;
  final String userId;
  final String title;
  final String message;
  final NotificationChannel channel;
  final NotificationType type;
  final bool isRead;
  final DateTime createdAt;
  final DateTime? readAt;
  final String? actionUrl;
  final Map<String, dynamic>? data;

  NotificationModel({
    String? id,
    required this.userId,
    required this.title,
    required this.message,
    this.channel = NotificationChannel.push,
    this.type = NotificationType.information,
    this.isRead = false,
    DateTime? createdAt,
    this.readAt,
    this.actionUrl,
    this.data,
  })  : id = id ?? UuidHelper.generateV4(),
        createdAt = createdAt ?? DateTime.now();

  /// Send a notification
  static NotificationModel send({
    required String userId,
    required String title,
    required String message,
    NotificationChannel channel = NotificationChannel.push,
    NotificationType type = NotificationType.information,
    String? actionUrl,
    Map<String, dynamic>? data,
  }) {
    return NotificationModel(
      userId: userId,
      title: title,
      message: message,
      channel: channel,
      type: type,
      actionUrl: actionUrl,
      data: data,
    );
  }

  /// Mark notification as read
  NotificationModel markAsRead() {
    return copyWith(
      isRead: true,
      readAt: DateTime.now(),
    );
  }

  /// Check if notification is recent (within last hour)
  bool get isRecent {
    return DateTime.now().difference(createdAt).inHours < 1;
  }

  /// Check if notification is urgent
  bool get isUrgent {
    return type == NotificationType.emergency || type == NotificationType.alert;
  }

  /// Get time since created
  String get timeSince {
    final diff = DateTime.now().difference(createdAt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${(diff.inDays / 7).floor()}w ago';
  }

  NotificationModel copyWith({
    String? id,
    String? userId,
    String? title,
    String? message,
    NotificationChannel? channel,
    NotificationType? type,
    bool? isRead,
    DateTime? createdAt,
    DateTime? readAt,
    String? actionUrl,
    Map<String, dynamic>? data,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      message: message ?? this.message,
      channel: channel ?? this.channel,
      type: type ?? this.type,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
      readAt: readAt ?? this.readAt,
      actionUrl: actionUrl ?? this.actionUrl,
      data: data ?? this.data,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'title': title,
      'message': message,
      'channel': channel.name,
      'type': type.name,
      'isRead': isRead,
      'createdAt': createdAt.toIso8601String(),
      'readAt': readAt?.toIso8601String(),
      'actionUrl': actionUrl,
      'data': data,
    };
  }

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'],
      userId: json['userId'],
      title: json['title'],
      message: json['message'],
      channel: NotificationChannel.values.byName(json['channel']),
      type: NotificationType.values.byName(json['type']),
      isRead: json['isRead'] ?? false,
      createdAt: DateTime.parse(json['createdAt']),
      readAt: json['readAt'] != null ? DateTime.parse(json['readAt']) : null,
      actionUrl: json['actionUrl'],
      data: json['data'] != null 
          ? Map<String, dynamic>.from(json['data']) 
          : null,
    );
  }
}
