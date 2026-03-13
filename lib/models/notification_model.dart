import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationModel {
  final String id;
  final String message;
  final String documentType;
  final String userId;
  final String userName;
  final Timestamp timestamp;
  final String type; // 'user', 'admin', or 'reupload'
  final bool isRead; // FIX: was missing from previous model

  NotificationModel({
    required this.id,
    required this.message,
    required this.documentType,
    required this.userId,
    required this.userName,
    required this.timestamp,
    required this.type,
    this.isRead = false,
  });

  factory NotificationModel.fromMap(Map<String, dynamic> map, String id) {
    return NotificationModel(
      id: id,
      message: map['message'] ?? '',
      documentType: map['documentType'] ?? '',
      userId: map['userId'] ?? '',
      userName: map['userName'] ?? '',
      timestamp: map['timestamp'] ?? Timestamp.now(),
      type: map['type'] ?? 'user',
      isRead: map['isRead'] ?? false, // FIX: now typed
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'message': message,
      'documentType': documentType,
      'userId': userId,
      'userName': userName,
      'timestamp': timestamp,
      'type': type,
      'isRead': isRead,
    };
  }

  NotificationModel copyWith({bool? isRead}) {
    return NotificationModel(
      id: id,
      message: message,
      documentType: documentType,
      userId: userId,
      userName: userName,
      timestamp: timestamp,
      type: type,
      isRead: isRead ?? this.isRead,
    );
  }
}
