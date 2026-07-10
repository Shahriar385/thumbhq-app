import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/constants/app_constants.dart';

class VideoDetails {
  final String title;
  final String goal;
  final List<String> images;

  const VideoDetails({
    this.title = '',
    this.goal = '',
    this.images = const [],
  });

  factory VideoDetails.fromMap(Map<String, dynamic>? data) {
    if (data == null) return const VideoDetails();
    return VideoDetails(
      title: data['title'] ?? '',
      goal: data['goal'] ?? '',
      images: List<String>.from(data['images'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'goal': goal,
      'images': images,
    };
  }

  VideoDetails copyWith({
    String? title,
    String? goal,
    List<String>? images,
  }) {
    return VideoDetails(
      title: title ?? this.title,
      goal: goal ?? this.goal,
      images: images ?? this.images,
    );
  }
}

class Brief {
  final String content;
  final List<String> referenceImages;
  final List<String> conceptImages;

  const Brief({
    this.content = '',
    this.referenceImages = const [],
    this.conceptImages = const [],
  });

  factory Brief.fromMap(Map<String, dynamic>? data) {
    if (data == null) return const Brief();
    return Brief(
      content: data['content'] ?? '',
      referenceImages: List<String>.from(data['referenceImages'] ?? []),
      conceptImages: List<String>.from(data['conceptImages'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'content': content,
      'referenceImages': referenceImages,
      'conceptImages': conceptImages,
    };
  }

  Brief copyWith({
    String? content,
    List<String>? referenceImages,
    List<String>? conceptImages,
  }) {
    return Brief(
      content: content ?? this.content,
      referenceImages: referenceImages ?? this.referenceImages,
      conceptImages: conceptImages ?? this.conceptImages,
    );
  }
}

class FinalDesign {
  final List<String> images;

  const FinalDesign({
    this.images = const [],
  });

  factory FinalDesign.fromMap(Map<String, dynamic>? data) {
    if (data == null) return const FinalDesign();
    return FinalDesign(
      images: List<String>.from(data['images'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'images': images,
    };
  }

  FinalDesign copyWith({List<String>? images}) {
    return FinalDesign(images: images ?? this.images);
  }
}

class ProjectModel {
  final String id;
  final String title;
  final String? clientId;
  final String clientName;
  final DateTime? deadline;
  final ProjectStatus status;
  final VideoDetails videoDetails;
  final Brief brief;
  final FinalDesign finalDesign;
  final String? strategistId;
  final String? designerId;
  final ApprovalStatus approvalStatus;
  final AssignmentStatus strategistStatus;
  final AssignmentStatus designerStatus;
  final String? strategistRevisionNote;
  final List<String> strategistRevisionImages;
  final String? designerRevisionNote;
  final List<String> designerRevisionImages;
  final bool commissionsPaid;
  final String createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ProjectModel({
    required this.id,
    required this.title,
    this.clientId,
    this.clientName = '',
    this.deadline,
    this.status = ProjectStatus.active,
    this.videoDetails = const VideoDetails(),
    this.brief = const Brief(),
    this.finalDesign = const FinalDesign(),
    this.strategistId,
    this.designerId,
    this.approvalStatus = ApprovalStatus.ongoing,
    this.strategistStatus = AssignmentStatus.assigned,
    this.designerStatus = AssignmentStatus.assigned,
    this.strategistRevisionNote,
    this.strategistRevisionImages = const [],
    this.designerRevisionNote,
    this.designerRevisionImages = const [],
    this.commissionsPaid = false,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ProjectModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    // No more designerStatuses parsing needed here

    return ProjectModel(
      id: doc.id,
      title: data['title'] ?? '',
      clientId: data['clientId'],
      clientName: data['clientName'] ?? '',
      deadline: (data['deadline'] as Timestamp?)?.toDate(),
      status: ProjectStatus.fromValue(data['status'] ?? 'active'),
      videoDetails:
          VideoDetails.fromMap(data['videoDetails'] as Map<String, dynamic>?),
      brief: Brief.fromMap(data['brief'] as Map<String, dynamic>?),
      finalDesign:
          FinalDesign.fromMap(data['finalDesign'] as Map<String, dynamic>?),
      strategistId: data['strategistId'],
      designerId: data['designerId'],
      approvalStatus:
          ApprovalStatus.fromValue(data['approvalStatus'] ?? 'ongoing'),
      strategistStatus:
          AssignmentStatus.fromValue(data['strategistStatus'] ?? 'assigned'),
      designerStatus:
          AssignmentStatus.fromValue(data['designerStatus'] ?? 'assigned'),
      strategistRevisionNote: data['strategistRevisionNote'],
      strategistRevisionImages: List<String>.from(data['strategistRevisionImages'] ?? []),
      designerRevisionNote: data['designerRevisionNote'],
      designerRevisionImages:
          List<String>.from(data['designerRevisionImages'] ?? []),
      commissionsPaid: data['commissionsPaid'] ?? false,
      createdBy: data['createdBy'] ?? '',
      createdAt:
          (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt:
          (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      if (clientId != null) 'clientId': clientId,
      'clientName': clientName,
      'deadline': deadline != null ? Timestamp.fromDate(deadline!) : null,
      'status': status.value,
      'videoDetails': videoDetails.toMap(),
      'brief': brief.toMap(),
      'finalDesign': finalDesign.toMap(),
      'strategistId': strategistId,
      'designerId': designerId,
      'approvalStatus': approvalStatus.value,
      'strategistStatus': strategistStatus.value,
      'designerStatus': designerStatus.value,
      'strategistRevisionNote': strategistRevisionNote,
      'strategistRevisionImages': strategistRevisionImages,
      'designerRevisionNote': designerRevisionNote,
      'designerRevisionImages': designerRevisionImages,
      'commissionsPaid': commissionsPaid,
      'createdBy': createdBy,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  ProjectModel copyWith({
    String? id,
    String? title,
    String? clientId,
    String? clientName,
    DateTime? deadline,
    ProjectStatus? status,
    VideoDetails? videoDetails,
    Brief? brief,
    FinalDesign? finalDesign,
    String? strategistId,
    String? designerId,
    ApprovalStatus? approvalStatus,
    AssignmentStatus? strategistStatus,
    AssignmentStatus? designerStatus,
    String? strategistRevisionNote,
    List<String>? strategistRevisionImages,
    String? designerRevisionNote,
    List<String>? designerRevisionImages,
    bool? commissionsPaid,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ProjectModel(
      id: id ?? this.id,
      title: title ?? this.title,
      clientId: clientId ?? this.clientId,
      clientName: clientName ?? this.clientName,
      deadline: deadline ?? this.deadline,
      status: status ?? this.status,
      videoDetails: videoDetails ?? this.videoDetails,
      brief: brief ?? this.brief,
      finalDesign: finalDesign ?? this.finalDesign,
      strategistId: strategistId ?? this.strategistId,
      designerId: designerId ?? this.designerId,
      approvalStatus: approvalStatus ?? this.approvalStatus,
      strategistStatus: strategistStatus ?? this.strategistStatus,
      designerStatus: designerStatus ?? this.designerStatus,
      strategistRevisionNote: strategistRevisionNote ?? this.strategistRevisionNote,
      strategistRevisionImages: strategistRevisionImages ?? this.strategistRevisionImages,
      designerRevisionNote: designerRevisionNote ?? this.designerRevisionNote,
      designerRevisionImages:
          designerRevisionImages ?? this.designerRevisionImages,
      commissionsPaid: commissionsPaid ?? this.commissionsPaid,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
