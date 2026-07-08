import 'package:cloud_firestore/cloud_firestore.dart';

enum ClientStatus {
  onTrack('On track'),
  active('Active'),
  offTrack('Off track');

  final String label;
  const ClientStatus(this.label);

  factory ClientStatus.fromValue(String value) {
    return values.firstWhere(
      (e) => e.name == value || e.label == value,
      orElse: () => ClientStatus.active,
    );
  }
}

class ClientModel {
  final String id;
  final String name;
  final String country;
  final String ytChannelName;
  final double averagePayout;
  final String email;
  final String acquisitionMethod;
  final ClientStatus status;
  final DateTime onboardingDate;
  final DateTime? endDate;
  final double totalPaid;
  final double totalWorked;
  final double monthlyRetainer;
  final String note;
  final DateTime createdAt;
  final DateTime updatedAt;

  ClientModel({
    required this.id,
    required this.name,
    required this.country,
    required this.ytChannelName,
    required this.averagePayout,
    this.email = '',
    this.acquisitionMethod = '',
    this.status = ClientStatus.active,
    required this.onboardingDate,
    this.endDate,
    this.totalPaid = 0.0,
    this.totalWorked = 0.0,
    this.monthlyRetainer = 0.0,
    this.note = '',
    required this.createdAt,
    required this.updatedAt,
  });

  factory ClientModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return ClientModel(
      id: doc.id,
      name: data['name'] ?? '',
      country: data['country'] ?? '',
      ytChannelName: data['ytChannelName'] ?? '',
      averagePayout: (data['averagePayout'] ?? 0.0).toDouble(),
      email: data['email'] ?? '',
      acquisitionMethod: data['acquisitionMethod'] ?? '',
      status: ClientStatus.fromValue(data['status'] ?? 'active'),
      onboardingDate: (data['onboardingDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      endDate: (data['endDate'] as Timestamp?)?.toDate(),
      totalPaid: (data['totalPaid'] ?? 0.0).toDouble(),
      totalWorked: (data['totalWorked'] ?? 0.0).toDouble(),
      monthlyRetainer: (data['monthlyRetainer'] ?? 0.0).toDouble(),
      note: data['note'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'country': country,
      'ytChannelName': ytChannelName,
      'averagePayout': averagePayout,
      'email': email,
      'acquisitionMethod': acquisitionMethod,
      'status': status.name,
      'onboardingDate': Timestamp.fromDate(onboardingDate),
      'endDate': endDate != null ? Timestamp.fromDate(endDate!) : null,
      'totalPaid': totalPaid,
      'totalWorked': totalWorked,
      'monthlyRetainer': monthlyRetainer,
      'note': note,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  ClientModel copyWith({
    String? id,
    String? name,
    String? country,
    String? ytChannelName,
    double? averagePayout,
    String? email,
    String? acquisitionMethod,
    ClientStatus? status,
    DateTime? onboardingDate,
    DateTime? endDate,
    double? totalPaid,
    double? totalWorked,
    double? monthlyRetainer,
    String? note,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ClientModel(
      id: id ?? this.id,
      name: name ?? this.name,
      country: country ?? this.country,
      ytChannelName: ytChannelName ?? this.ytChannelName,
      averagePayout: averagePayout ?? this.averagePayout,
      email: email ?? this.email,
      acquisitionMethod: acquisitionMethod ?? this.acquisitionMethod,
      status: status ?? this.status,
      onboardingDate: onboardingDate ?? this.onboardingDate,
      endDate: endDate ?? this.endDate,
      totalPaid: totalPaid ?? this.totalPaid,
      totalWorked: totalWorked ?? this.totalWorked,
      monthlyRetainer: monthlyRetainer ?? this.monthlyRetainer,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
