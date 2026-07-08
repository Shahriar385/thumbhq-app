import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/constants/app_constants.dart';
import '../models/client_model.dart';
import '../models/message_model.dart';
import '../models/project_model.dart';
import '../models/user_model.dart';
import '../models/revenue_model.dart';
import '../models/commission_settings_model.dart';
import '../models/commission_model.dart';
import 'storage_service.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ─── Users ─────────────────────────────────────────────────────

  CollectionReference get _usersRef => _db.collection('users');

  /// Create user doc on first sign-in. First user becomes manager.
  Future<UserModel> createUserIfNotExists({
    required String uid,
    required String email,
    required String displayName,
    required String photoURL,
  }) async {
    final doc = await _usersRef.doc(uid).get();
    if (doc.exists) {
      return UserModel.fromFirestore(doc);
    }

    // Check if this is the first user → make them manager
    final usersSnapshot = await _usersRef.limit(1).get();
    final isFirstUser = usersSnapshot.docs.isEmpty;

    final user = UserModel(
      uid: uid,
      email: email,
      displayName: displayName,
      photoURL: photoURL,
      role: isFirstUser ? UserRole.manager : UserRole.pending,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await _usersRef.doc(uid).set(user.toFirestore());
    return user;
  }

  /// Stream current user doc
  Stream<UserModel?> streamUser(String uid) {
    return _usersRef.doc(uid).snapshots().map((doc) {
      if (!doc.exists) return null;
      return UserModel.fromFirestore(doc);
    });
  }

  /// Stream all users
  Stream<List<UserModel>> streamAllUsers() {
    return _usersRef.orderBy('createdAt', descending: false).snapshots().map(
          (snapshot) =>
              snapshot.docs.map((doc) => UserModel.fromFirestore(doc)).toList(),
        );
  }

  /// Update user role
  Future<void> updateUserRole(String uid, UserRole role) async {
    await _usersRef.doc(uid).update({
      'role': role.value,
      'updatedAt': Timestamp.now(),
    });
  }

  /// Save or clear a user's Telegram chat ID
  Future<void> updateTelegramChatId(String uid, String? chatId) async {
    if (chatId == null) {
      await _usersRef.doc(uid).update({
        'telegramChatId': FieldValue.delete(),
        'updatedAt': Timestamp.now(),
      });
    } else {
      await _usersRef.doc(uid).update({
        'telegramChatId': chatId,
        'updatedAt': Timestamp.now(),
      });
    }
  }

  /// Fetch user by ID (one-time)
  Future<UserModel?> getUser(String uid) async {
    final doc = await _usersRef.doc(uid).get();
    if (!doc.exists) return null;
    return UserModel.fromFirestore(doc);
  }

  /// Fetch multiple users by IDs
  Future<List<UserModel>> getUsersByIds(List<String> uids) async {
    if (uids.isEmpty) return [];
    final results = await Future.wait(
      uids.map((uid) => _usersRef.doc(uid).get()),
    );
    return results
        .where((doc) => doc.exists)
        .map((doc) => UserModel.fromFirestore(doc))
        .toList();
  }

  // ─── Projects ──────────────────────────────────────────────────

  CollectionReference get _projectsRef => _db.collection('projects');

  /// Create a new project
  Future<String> createProject(ProjectModel project) async {
    final docRef = _projectsRef.doc();
    final data = project.copyWith(id: docRef.id).toFirestore();
    await docRef.set(data);
    return docRef.id;
  }



  /// Update project
  Future<void> updateProject(String id, Map<String, dynamic> data) async {
    data['updatedAt'] = Timestamp.now();
    await _projectsRef.doc(id).update(data);
  }

  /// Stream all projects
  Stream<List<ProjectModel>> streamProjects() {
    return _projectsRef
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ProjectModel.fromFirestore(doc))
            .toList());
  }

  /// Stream projects by status
  Stream<List<ProjectModel>> streamProjectsByStatus(ProjectStatus status) {
    return _projectsRef
        .where('status', isEqualTo: status.value)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ProjectModel.fromFirestore(doc))
            .toList());
  }

  /// Stream a single project
  Stream<ProjectModel?> streamProject(String id) {
    return _projectsRef.doc(id).snapshots().map((doc) {
      if (!doc.exists) return null;
      return ProjectModel.fromFirestore(doc);
    });
  }

  /// Delete project
  Future<void> deleteProject(String id, {void Function(double)? onProgress}) async {
    // 1. Delete all images in Storage
    try {
      final storageService = StorageService();
      await storageService.deleteFolder('projects/$id', onProgress: onProgress);
    } catch (e) {
      onProgress?.call(1.0);
      // It's okay if it fails (e.g., if the project has no images)
    }

    // 2. Delete the Firestore document
    await _projectsRef.doc(id).delete();
  }

  /// Assign strategist to project
  Future<void> assignStrategist(String projectId, String strategistId) async {
    await _projectsRef.doc(projectId).update({
      'strategistId': strategistId.isEmpty ? null : strategistId,
      'strategistStatus': AssignmentStatus.assigned.value,
      'updatedAt': Timestamp.now(),
    });
  }

  /// Assign designer to project
  Future<void> assignDesigner(String projectId, String designerId) async {
    await _projectsRef.doc(projectId).update({
      'designerId': designerId.isEmpty ? null : designerId,
      'designerStatus': AssignmentStatus.assigned.value,
      'updatedAt': Timestamp.now(),
    });
  }

  /// Remove designer from project
  Future<void> removeDesigner(String projectId, String designerId) async {
    await _projectsRef.doc(projectId).update({
      'designerId': null,
      'designerStatus': AssignmentStatus.assigned.value,
      'updatedAt': Timestamp.now(),
    });
  }

  /// Update strategist submission status
  Future<void> updateStrategistStatus(
      String projectId, AssignmentStatus status) async {
    final Map<String, dynamic> data = {
      'strategistStatus': status.value,
      'updatedAt': Timestamp.now(),
    };
    if (status == AssignmentStatus.submitted) {
      data['strategistRevisionNote'] = null;
      data['strategistRevisionImages'] = [];
    }
    await _projectsRef.doc(projectId).update(data);
  }

  /// Update designer submission status
  Future<void> updateDesignerStatus(
      String projectId, String designerId, AssignmentStatus status) async {
    final Map<String, dynamic> data = {
      'designerStatus': status.value,
      'updatedAt': Timestamp.now(),
    };
    if (status == AssignmentStatus.submitted) {
      data['designerRevisionNote'] = null;
      data['designerRevisionImages'] = [];
    }
    await _projectsRef.doc(projectId).update(data);
  }

  /// Request revision for Strategist
  Future<void> requestStrategistRevision(String projectId, String note, {List<String>? images}) async {
    await _projectsRef.doc(projectId).update({
      'strategistStatus': AssignmentStatus.revision.value,
      'strategistRevisionNote': note,
      if (images != null) 'strategistRevisionImages': images,
      'approvalStatus': ApprovalStatus.ongoing.value,
      'updatedAt': Timestamp.now(),
    });
  }

  /// Request revision for Designer
  Future<void> requestDesignerRevision(String projectId, String note, {List<String>? images}) async {
    await _projectsRef.doc(projectId).update({
      'designerStatus': AssignmentStatus.revision.value,
      'designerRevisionNote': note,
      if (images != null) 'designerRevisionImages': images,
      'approvalStatus': ApprovalStatus.ongoing.value,
      'updatedAt': Timestamp.now(),
    });
  }

  /// Update project approval status
  Future<void> updateApprovalStatus(
      String projectId, ApprovalStatus status) async {
    await _projectsRef.doc(projectId).update({
      'approvalStatus': status.value,
      'updatedAt': Timestamp.now(),
    });

    // If approved, add project's ticket size to client's totalWorked and calculate commissions
    if (status == ApprovalStatus.approved) {
      try {
        final projectDoc = await _projectsRef.doc(projectId).get();
        if (projectDoc.exists) {
          final project = ProjectModel.fromFirestore(projectDoc);
          
          if (!project.commissionsPaid) {
            // Add ticket size to client
            if (project.clientId != null && project.clientId!.isNotEmpty) {
              final clientDoc = await _clientsRef.doc(project.clientId).get();
              if (clientDoc.exists) {
                final client = ClientModel.fromFirestore(clientDoc);
                await _clientsRef.doc(project.clientId).update({
                  'totalWorked': FieldValue.increment(client.averagePayout),
                  'updatedAt': Timestamp.now(),
                });
              }
            }
            
            // Calculate and pay commissions
            final settings = await getCommissionSettings();
            final batch = _db.batch();
            
            if (project.strategistId != null && project.strategistId!.isNotEmpty) {
              final strategistDoc = await _usersRef.doc(project.strategistId).get();
              if (strategistDoc.exists) {
                final commissionRef = _commissionsRef.doc();
                batch.set(commissionRef, {
                  'projectId': project.id,
                  'userId': project.strategistId,
                  'role': 'strategist',
                  'amount': settings.strategistFee,
                  'createdAt': Timestamp.now(),
                });
              }
            }
            
            if (project.designerId != null && project.designerId!.isNotEmpty) {
              final designerDoc = await _usersRef.doc(project.designerId).get();
              if (designerDoc.exists) {
                final designer = UserModel.fromFirestore(designerDoc);
                double fee = 0.0;
                switch (designer.role) {
                  case UserRole.manager:
                    fee = settings.managerFee;
                    break;
                  case UserRole.leadDesigner:
                    fee = settings.leadDesignerFee;
                    break;
                  case UserRole.coreDesigner:
                    fee = settings.coreDesignerFee;
                    break;
                  case UserRole.juniorDesigner:
                    fee = settings.juniorDesignerFee;
                    break;
                  default:
                    fee = settings.juniorDesignerFee;
                }
                
                final commissionRef = _commissionsRef.doc();
                batch.set(commissionRef, {
                  'projectId': project.id,
                  'userId': project.designerId,
                  'role': 'designer',
                  'amount': fee,
                  'createdAt': Timestamp.now(),
                });
              }
            }
            
            // Mark project as commissions paid
            batch.update(_projectsRef.doc(projectId), {
              'commissionsPaid': true,
              'updatedAt': Timestamp.now(),
            });
            
            await batch.commit();
          }
        }
      } catch (e) {
        // Handle silently or log error
        print('Error updating approval status and commissions: $e');
      }
    }
  }

  /// Update video details
  Future<void> updateVideoDetails(
      String projectId, VideoDetails details) async {
    await _projectsRef.doc(projectId).update({
      'videoDetails': details.toMap(),
      'updatedAt': Timestamp.now(),
    });
  }

  /// Update brief
  Future<void> updateBrief(String projectId, Brief brief) async {
    await _projectsRef.doc(projectId).update({
      'brief': brief.toMap(),
      'updatedAt': Timestamp.now(),
    });
  }

  /// Update final design
  Future<void> updateFinalDesign(
      String projectId, FinalDesign finalDesign) async {
    await _projectsRef.doc(projectId).update({
      'finalDesign': finalDesign.toMap(),
      'updatedAt': Timestamp.now(),
    });
  }

  // ─── Project Messaging ─────────────────────────────────────────

  CollectionReference _projectMessagesRef(String projectId) =>
      _projectsRef.doc(projectId).collection('messages');

  /// Send a message
  Future<void> sendMessage(String projectId, MessageModel message) async {
    final docRef = _projectMessagesRef(projectId).doc();
    final messageWithId = MessageModel(
      id: docRef.id,
      projectId: projectId,
      senderId: message.senderId,
      senderName: message.senderName,
      senderRole: message.senderRole,
      content: message.content,
      timestamp: message.timestamp,
      replyToId: message.replyToId,
      replyToName: message.replyToName,
      replyToContent: message.replyToContent,
    );
    await docRef.set(messageWithId.toFirestore());
  }

  /// Stream messages for a project
  Stream<List<MessageModel>> streamProjectMessages(String projectId) {
    return _projectMessagesRef(projectId)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => MessageModel.fromFirestore(doc))
            .toList());
  }

  /// Stream revenues for a specific client
  Stream<List<RevenueModel>> streamClientRevenues(String clientId) {
    return _clientRevenuesRef(clientId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => RevenueModel.fromFirestore(doc))
            .toList());
  }

  /// Stream all revenues across all clients
  Stream<List<RevenueModel>> streamAllRevenues() {
    return _db.collectionGroup('revenues')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => RevenueModel.fromFirestore(doc))
            .toList());
  }

  // ─── Commissions & Settings ──────────────────────────────────────

  CollectionReference get _commissionsRef => _db.collection('commissions');
  DocumentReference get _commissionSettingsRef => _db.collection('settings').doc('commissions');

  Future<CommissionSettingsModel> getCommissionSettings() async {
    final doc = await _commissionSettingsRef.get();
    return CommissionSettingsModel.fromFirestore(doc);
  }

  Future<void> updateCommissionSettings(CommissionSettingsModel settings) async {
    await _commissionSettingsRef.set(settings.toFirestore());
  }
  
  Stream<CommissionSettingsModel> streamCommissionSettings() {
    return _commissionSettingsRef.snapshots().map((doc) => CommissionSettingsModel.fromFirestore(doc));
  }

  Stream<List<CommissionModel>> streamCommissions() {
    return _commissionsRef.orderBy('createdAt', descending: true).snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => CommissionModel.fromFirestore(doc)).toList();
    });
  }

  // ─── Clients ───────────────────────────────────────────────────

  CollectionReference get _clientsRef => _db.collection('clients');

  /// Create a new client
  Future<String> createClient(ClientModel client) async {
    final docRef = _clientsRef.doc();
    final data = client.copyWith(id: docRef.id).toFirestore();
    await docRef.set(data);
    return docRef.id;
  }

  /// Update an existing client
  Future<void> updateClient(String id, Map<String, dynamic> data) async {
    data['updatedAt'] = Timestamp.now();
    await _clientsRef.doc(id).update(data);
  }

  /// Delete a client
  Future<void> deleteClient(String id) async {
    await _clientsRef.doc(id).delete();
  }

  /// Stream all clients
  Stream<List<ClientModel>> streamClients() {
    return _clientsRef
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ClientModel.fromFirestore(doc))
            .toList());
  }

  // ─── Revenues ──────────────────────────────────────────────────

  CollectionReference _clientRevenuesRef(String clientId) =>
      _clientsRef.doc(clientId).collection('revenues');

  /// Add revenue to a client
  Future<void> addRevenue(RevenueModel revenue) async {
    // 1. Add revenue record
    final docRef = _clientRevenuesRef(revenue.clientId).doc();
    final newRevenue = RevenueModel(
      id: docRef.id,
      clientId: revenue.clientId,
      amount: revenue.amount,
      date: revenue.date,
      note: revenue.note,
      createdAt: revenue.createdAt,
    );
    await docRef.set(newRevenue.toFirestore());

    // 2. Increment client's totalPaid
    await _clientsRef.doc(revenue.clientId).update({
      'totalPaid': FieldValue.increment(revenue.amount),
      'updatedAt': Timestamp.now(),
    });
  }
}
