import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

enum NotificationType {
  newReview,
  newApplication,
  applicationUpdate,
  message,
  systemAlert
}

extension NotificationTypeExtension on NotificationType {
  String get displayName {
    switch (this) {
      case NotificationType.newReview:
        return 'New Review';
      case NotificationType.newApplication:
        return 'New Application';
      case NotificationType.applicationUpdate:
        return 'Application Update';
      case NotificationType.message:
        return 'New Message';
      case NotificationType.systemAlert:
        return 'System Alert';
    }
  }

  IconData getIcon() {
    switch (this) {
      case NotificationType.newReview:
        return Icons.star;
      case NotificationType.newApplication:
        return Icons.assignment;
      case NotificationType.applicationUpdate:
        return Icons.update;
      case NotificationType.message:
        return Icons.message;
      case NotificationType.systemAlert:
        return Icons.notifications_active;
    }
  }

  static NotificationType fromString(String value) {
    return NotificationType.values.firstWhere(
          (type) => type.toString().split('.').last == value,
      orElse: () => NotificationType.systemAlert,
    );
  }
}

class Notification {
  final String notificationId;
  final String userId;     // ID of the user who should receive the notification
  final String title;
  final String message;
  final NotificationType type;
  final DateTime createdAt;
  final bool isRead;
  final String? relatedItemId;  // ID of the related property, review, etc.
  final String? relatedItemType; // Type of the related item (property, review, etc.)
  final String? senderId;        // ID of the user who triggered the notification
  final String? senderName;      // Name of the user who triggered the notification
  final String? senderPhotoUrl;  // Photo URL of the user who triggered the notification

  Notification({
    String? notificationId,
    required this.userId,
    required this.title,
    required this.message,
    required this.type,
    DateTime? createdAt,
    this.isRead = false,
    this.relatedItemId,
    this.relatedItemType,
    this.senderId,
    this.senderName,
    this.senderPhotoUrl,
  }) :
        notificationId = notificationId ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'notificationId': notificationId,
      'userId': userId,
      'title': title,
      'message': message,
      'type': type.toString().split('.').last,
      'createdAt': createdAt,
      'isRead': isRead,
      'relatedItemId': relatedItemId,
      'relatedItemType': relatedItemType,
      'senderId': senderId,
      'senderName': senderName,
      'senderPhotoUrl': senderPhotoUrl,
    };
  }

  factory Notification.fromMap(Map<String, dynamic> map) {
    return Notification(
      notificationId: map['notificationId'],
      userId: map['userId'] ?? '',
      title: map['title'] ?? '',
      message: map['message'] ?? '',
      type: NotificationTypeExtension.fromString(map['type'] ?? ''),
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isRead: map['isRead'] ?? false,
      relatedItemId: map['relatedItemId'],
      relatedItemType: map['relatedItemType'],
      senderId: map['senderId'],
      senderName: map['senderName'],
      senderPhotoUrl: map['senderPhotoUrl'],
    );
  }

  Notification copyWith({
    String? notificationId,
    String? userId,
    String? title,
    String? message,
    NotificationType? type,
    DateTime? createdAt,
    bool? isRead,
    String? relatedItemId,
    String? relatedItemType,
    String? senderId,
    String? senderName,
    String? senderPhotoUrl,
  }) {
    return Notification(
      notificationId: notificationId ?? this.notificationId,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      message: message ?? this.message,
      type: type ?? this.type,
      createdAt: createdAt ?? this.createdAt,
      isRead: isRead ?? this.isRead,
      relatedItemId: relatedItemId ?? this.relatedItemId,
      relatedItemType: relatedItemType ?? this.relatedItemType,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      senderPhotoUrl: senderPhotoUrl ?? this.senderPhotoUrl,
    );
  }
}