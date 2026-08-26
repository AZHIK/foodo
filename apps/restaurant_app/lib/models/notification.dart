import 'package:flutter/material.dart';

enum NotificationType {
  newOrder('New Order', Icons.receipt_long_rounded),
  lowStock('Low Stock', Icons.warning_amber_rounded),
  aiInsight('AI Insight', Icons.auto_awesome_rounded),
  deliveryUpdate('Delivery Update', Icons.two_wheeler_rounded);

  const NotificationType(this.label, this.icon);
  final String label;
  final IconData icon;
}

/// An app notification: order alert, inventory warning, etc.
class AppNotification {
  const AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.createdAt,
    this.relatedEntityId,
    this.isRead = false,
  });

  final String id;
  final NotificationType type;
  final String title;
  final String body;
  final DateTime createdAt;

  /// The id of the order, inventory item, insight, etc. this notification refers to.
  /// Used to navigate to the relevant detail screen when tapped.
  final String? relatedEntityId;

  final bool isRead;

  AppNotification copyWith({
    String? title,
    String? body,
    bool? isRead,
  }) {
    return AppNotification(
      id: id,
      type: type,
      title: title ?? this.title,
      body: body ?? this.body,
      createdAt: createdAt,
      relatedEntityId: relatedEntityId,
      isRead: isRead ?? this.isRead,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AppNotification && other.id == id);

  @override
  int get hashCode => id.hashCode;
}
