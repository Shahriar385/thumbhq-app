import 'package:cloud_firestore/cloud_firestore.dart';

class CommissionSettingsModel {
  final double strategistFee;
  final double managerFee;
  final double leadDesignerFee;
  final double coreDesignerFee;
  final double juniorDesignerFee;
  
  const CommissionSettingsModel({
    this.strategistFee = 5.0,
    this.managerFee = 15.0,
    this.leadDesignerFee = 15.0,
    this.coreDesignerFee = 10.0,
    this.juniorDesignerFee = 5.0,
  });

  factory CommissionSettingsModel.fromFirestore(DocumentSnapshot doc) {
    if (!doc.exists) return const CommissionSettingsModel();
    final data = doc.data() as Map<String, dynamic>;
    return CommissionSettingsModel(
      strategistFee: (data['strategistFee'] as num?)?.toDouble() ?? 5.0,
      managerFee: (data['managerFee'] as num?)?.toDouble() ?? 15.0,
      leadDesignerFee: (data['leadDesignerFee'] as num?)?.toDouble() ?? 15.0,
      coreDesignerFee: (data['coreDesignerFee'] as num?)?.toDouble() ?? 10.0,
      juniorDesignerFee: (data['juniorDesignerFee'] as num?)?.toDouble() ?? 5.0,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'strategistFee': strategistFee,
      'managerFee': managerFee,
      'leadDesignerFee': leadDesignerFee,
      'coreDesignerFee': coreDesignerFee,
      'juniorDesignerFee': juniorDesignerFee,
    };
  }
}
