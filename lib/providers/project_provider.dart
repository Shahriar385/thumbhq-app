import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../core/constants/app_constants.dart';
import '../models/project_model.dart';
import '../services/firestore_service.dart';
import 'auth_provider.dart';

// ─── All Projects Stream ─────────────────────────────────────────

final allProjectsProvider = StreamProvider<List<ProjectModel>>((ref) {
  final firestoreService = ref.read(firestoreServiceProvider);
  return firestoreService.streamProjects();
});

// ─── Projects by Status ──────────────────────────────────────────

final projectsByStatusProvider =
    StreamProvider.family<List<ProjectModel>, ProjectStatus>((ref, status) {
  final firestoreService = ref.read(firestoreServiceProvider);
  return firestoreService.streamProjectsByStatus(status);
});

// ─── Single Project Stream ───────────────────────────────────────

final projectProvider =
    StreamProvider.family<ProjectModel?, String>((ref, projectId) {
  final firestoreService = ref.read(firestoreServiceProvider);
  return firestoreService.streamProject(projectId);
});

// ─── Selected Tab ────────────────────────────────────────────────

final selectedTabProvider = StateProvider<ProjectStatus>((ref) {
  return ProjectStatus.active;
});

// ─── Filtered Projects (for dashboard) ───────────────────────────

// ─── Selected Status Filter ──────────────────────────────────────
final selectedStatusFilterProvider = StateProvider<String?>((ref) => null);

/// Projects filtered by the selected tab, status filter, and the user's role/assignment
final filteredProjectsProvider = Provider<AsyncValue<List<ProjectModel>>>((ref) {
  final selectedTab = ref.watch(selectedTabProvider);
  final selectedStatus = ref.watch(selectedStatusFilterProvider);
  final projectsAsync = ref.watch(projectsByStatusProvider(selectedTab));
  final currentUser = ref.watch(currentUserProvider).value;

  return projectsAsync.whenData((projects) {
    if (currentUser == null) return [];

    var filtered = projects;
    if (selectedStatus != null && selectedStatus != 'All Statuses') {
      filtered = filtered.where((p) {
        if (selectedStatus == 'Needs Approval') {
          return p.approvalStatus == ApprovalStatus.needsApproval;
        } else if (selectedStatus == 'In Revision') {
          return p.strategistStatus == AssignmentStatus.revision ||
                 p.designerStatus == AssignmentStatus.revision;
        } else if (selectedStatus == 'Submitted') {
          return p.strategistStatus == AssignmentStatus.submitted ||
                 p.designerStatus == AssignmentStatus.submitted;
        } else if (selectedStatus == 'Queue') {
          return p.strategistStatus == AssignmentStatus.assigned ||
                 p.designerStatus == AssignmentStatus.assigned;
        }
        return true;
      }).toList();
    }

    // Manager sees all projects
    if (currentUser.isManager) return filtered;

    // Member sees projects they are assigned to
    return filtered
        .where((p) =>
            p.strategistId == currentUser.uid ||
            p.designerId == currentUser.uid)
        .toList();
  });
});
