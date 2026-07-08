import 'package:cloud_firestore/cloud_firestore.dart';

class MessageModel {
  final String id;
  final String projectId;
  final String senderId;
  final String senderName;
  final String senderRole;
  final String content;
  final DateTime timestamp;
  
  // Reply fields
  final String? replyToId;
  final String? replyToName;
  final String? replyToContent;

  const MessageModel({
    required this.id,
    required this.projectId,
    required this.senderId,
    required this.senderName,
    required this.senderRole,
    required this.content,
    required this.timestamp,
    this.replyToId,
    this.replyToName,
    this.replyToContent,
  });

  factory MessageModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return MessageModel(
      id: doc.id,
      projectId: data['projectId'] ?? '',
      senderId: data['senderId'] ?? '',
      senderName: data['senderName'] ?? '',
      senderRole: data['senderRole'] ?? '',
      content: data['content'] ?? '',
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      replyToId: data['replyToId'],
      replyToName: data['replyToName'],
      replyToContent: data['replyToContent'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'projectId': projectId,
      'senderId': senderId,
      'senderName': senderName,
      'senderRole': senderRole,
      'content': content,
      'timestamp': Timestamp.fromDate(timestamp),
      if (replyToId != null) 'replyToId': replyToId,
      if (replyToName != null) 'replyToName': replyToName,
      if (replyToContent != null) 'replyToContent': replyToContent,
    };
  }
}
