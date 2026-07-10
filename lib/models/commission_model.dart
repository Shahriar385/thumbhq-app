import 'package:cloud_firestore/cloud_firestore.dart';

class CommissionModel {
  final String id;
  final String projectId;
  final String userId;
  final String role; // 'strategist' or 'designer'
  final double amount;
  final DateTime createdAt;

  const CommissionModel({
    required this.id,
    required this.projectId,
    required this.userId,
    required this.role,
    required this.amount,
    required this.createdAt,
  });

  factory CommissionModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CommissionModel(
      id: doc.id,
      projectId: data['projectId'] ?? '',
      userId: data['userId'] ?? '',
      role: data['role'] ?? '',
      amount: (data['amount'] as num?)?.toDouble() ?? 0.0,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'projectId': projectId,
      'userId': userId,
      'role': role,
      'amount': amount,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
