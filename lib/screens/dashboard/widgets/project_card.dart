import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../models/project_model.dart';
import '../../../models/user_model.dart';
import '../../../providers/user_provider.dart';
import 'package:intl/intl.dart';

class ProjectCard extends ConsumerWidget {
  final ProjectModel project;
  final VoidCallback? onLongPress;

  const ProjectCard({super.key, required this.project, this.onLongPress});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allUsersAsync = ref.watch(allUsersProvider);
    final isDesktop = MediaQuery.of(context).size.width > 630;

    return GestureDetector(
      onTap: () => context.push('/project/${project.id}'),
      onLongPress: onLongPress,
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: isDesktop
            ? Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ─── Left: Title, Client, Deadline ─────────
                  Expanded(
                    flex: 2,
                    child: _buildProjectInfo(),
                  ),

                  // ─── Right: Assigned Members Thumbnails ────
                  Expanded(
                    flex: 3,
                    child: allUsersAsync.when(
                      data: (users) => _buildAssignedMembers(users, isDesktop: true),
                      loading: () => const SizedBox.shrink(),
                      error: (_, __) => const SizedBox.shrink(),
                    ),
                  ),
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildProjectInfo(),
                  const SizedBox(height: 16),
                  allUsersAsync.when(
                    data: (users) => _buildAssignedMembers(users, isDesktop: false),
                    loading: () => const SizedBox.shrink(),
                    error: (_, __) => const SizedBox.shrink(),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildProjectInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          project.title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        if (project.clientName.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            project.clientName,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
            ),
          ),
        ],
        if (project.deadline != null) ...[
          const SizedBox(height: 2),
          Text(
            'Deadline: ${DateFormat('d MMM h:mma').format(project.deadline!)}',
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
            ),
          ),
        ],
        const SizedBox(height: 12),
        _buildApprovalBadge(),
      ],
    );
  }

  Widget _buildApprovalBadge() {
    switch (project.approvalStatus) {
      case ApprovalStatus.needsApproval:
        return StatusBadge.needsApproval();
      case ApprovalStatus.ongoing:
        return StatusBadge.ongoing();
      case ApprovalStatus.approved:
        return StatusBadge.approved();
    }
  }

  Widget _buildAssignedMembers(List<UserModel> allUsers, {required bool isDesktop}) {
    final widgets = <Widget>[];

    UserModel unknownUser(String id) => UserModel(
        uid: id,
        email: '',
        displayName: 'Unknown',
        photoURL: '',
        role: UserRole.pending,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now());

    if (project.strategistId != null && project.strategistId!.isNotEmpty) {
      final user = allUsers.firstWhere(
        (u) => u.uid == project.strategistId,
        orElse: () => unknownUser(project.strategistId!),
      );
      widgets.add(Padding(
        padding: isDesktop ? const EdgeInsets.only(left: 12) : EdgeInsets.zero,
        child: _buildMemberThumbnail(
            user,
            project.strategistStatus.label,
            'Strategist',
            project.brief.conceptImages.isNotEmpty
                ? project.brief.conceptImages.first
                : (project.brief.referenceImages.isNotEmpty
                    ? project.brief.referenceImages.first
                    : null)),
      ));
    }

    if (project.designerId != null && project.designerId!.isNotEmpty) {
      final user = allUsers.firstWhere(
        (u) => u.uid == project.designerId,
        orElse: () => unknownUser(project.designerId!),
      );
      final customImageUrl = project.finalDesign.images.isNotEmpty
          ? project.finalDesign.images.first
          : null;

      widgets.add(Padding(
        padding: isDesktop ? const EdgeInsets.only(left: 12) : EdgeInsets.zero,
        child: _buildMemberThumbnail(
            user, project.designerStatus.label, 'Designer', customImageUrl),
      ));
    }

    if (widgets.isEmpty) return const SizedBox.shrink();

    if (isDesktop) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: widgets,
      );
    } else {
      return Wrap(
        spacing: 12,
        runSpacing: 12,
        children: widgets,
      );
    }
  }

  Widget _buildMemberThumbnail(
      UserModel user, String status, String roleLabel, String? customImageUrl) {
    final hasImage = customImageUrl != null;

    return Column(
      children: [
        Container(
          width: 144,
          height: 81,
          decoration: BoxDecoration(
            color: AppColors.surfaceElevated,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.border),
          ),
          child: hasImage
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(7),
                  child: CachedNetworkImage(
                    imageUrl: customImageUrl,
                    fit: BoxFit.cover,
                    memCacheWidth: 400, // Resize image in memory to prevent lag
                    fadeInDuration: const Duration(milliseconds: 200),
                    placeholder: (context, url) => Container(
                      width: double.infinity,
                      height: double.infinity,
                      color: AppColors.surfaceElevated,
                    ),
                    errorWidget: (context, url, error) => const SizedBox(),
                  ),
                )
              : null,
        ),
        const SizedBox(height: 6),
        Text(
          '${user.displayName.split(' ').first} ($roleLabel)',
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 4),
        StatusBadge(
          label: status,
          color: status == 'Submitted' ? AppColors.submitted : AppColors.assigned,
        ),
      ],
    );
  }
}
