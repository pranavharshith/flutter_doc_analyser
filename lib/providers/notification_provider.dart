import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/notification_model.dart';

class NotificationProvider extends ChangeNotifier {
  final List<NotificationModel> _notifications = [];
  int _unreadCount = 0;
  bool _isLoading = false;

  List<NotificationModel> get notifications => List.unmodifiable(_notifications);
  int get unreadCount => _unreadCount;
  bool get isLoading => _isLoading;

  Future<void> loadNotifications(String uid) async {
    _isLoading = true;
    notifyListeners();
    try {
      final snap = await FirebaseFirestore.instance
          .collection('notifications')
          .doc(uid)
          .collection('userNotifications')
          .orderBy('timestamp', descending: true)
          .get();
      _notifications
        ..clear()
        ..addAll(snap.docs
            .map((d) => NotificationModel.fromMap(d.data(), d.id)));
      _unreadCount = _notifications.where((n) => !n.isRead).length;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> markAllRead(String uid) async {
    final batch = FirebaseFirestore.instance.batch();
    for (final n in _notifications.where((n) => !n.isRead)) {
      final ref = FirebaseFirestore.instance
          .collection('notifications')
          .doc(uid)
          .collection('userNotifications')
          .doc(n.id);
      batch.update(ref, {'isRead': true});
    }
    await batch.commit();
    for (final n in _notifications) {
      // Mark locally
    }
    await loadNotifications(uid);
  }
}
