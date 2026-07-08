import 'package:cloud_firestore/cloud_firestore.dart';

class RevenueModel {
  final String id;
  final String clientId;
  final double amount;
  final DateTime date;
  final String note;
  final DateTime createdAt;

  const RevenueModel({
    required this.id,
    required this.clientId,
    required this.amount,
    required this.date,
    this.note = '',
    required this.createdAt,
  });

  factory RevenueModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return RevenueModel(
      id: doc.id,
      clientId: data['clientId'] ?? '',
      amount: (data['amount'] ?? 0.0).toDouble(),
      date: (data['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      note: data['note'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'clientId': clientId,
      'amount': amount,
      'date': Timestamp.fromDate(date),
      'note': note,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
