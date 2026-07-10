import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/role_badge.dart';
import '../../core/widgets/user_avatar.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/user_provider.dart';
import '../../services/firestore_service.dart';

class TeamScreen extends ConsumerWidget {
  const TeamScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allUsersAsync = ref.watch(allUsersProvider);

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                IconButton(
                  onPressed: () => context.pop(),
                  icon: const Icon(Icons.arrow_back_rounded),
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Team Management',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // User list
            Expanded(
              child: allUsersAsync.when(
                data: (users) => _buildUserList(context, ref, users),
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('Error: $e')),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserList(
      BuildContext context, WidgetRef ref, List<UserModel> users) {
    // Sort: pending first, then by name
    final sorted = List<UserModel>.from(users)
      ..sort((a, b) {
        if (a.isPending && !b.isPending) return -1;
        if (!a.isPending && b.isPending) return 1;
        return a.displayName.compareTo(b.displayName);
      });

    return ListView.builder(
      itemCount: sorted.length,
      itemBuilder: (context, index) {
        final user = sorted[index];
        return _buildUserTile(context, ref, user);
      },
    );
  }

  Widget _buildUserTile(BuildContext context, WidgetRef ref, UserModel user) {
    final currentUser = ref.watch(currentUserProvider).value;
    final isSelf = currentUser?.uid == user.uid;
    final isDesktop = MediaQuery.of(context).size.width > 600;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: user.isPending
            ? AppColors.ongoing.withValues(alpha: 0.05)
            : AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: user.isPending ? AppColors.ongoing.withValues(alpha: 0.3) : AppColors.border,
        ),
      ),
      child: isDesktop
          ? Row(
              children: [
                // Avatar
                UserAvatar(
                  photoURL: user.photoURL,
                  displayName: user.displayName,
                  radius: 20,
                ),
                const SizedBox(width: 16),

                // Name & email
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              user.displayName,
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (isSelf) ...[
                            const SizedBox(width: 8),
                            const Text(
                              '(you)',
                              style: TextStyle(
                                color: AppColors.textMuted,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        user.email,
                        style: const TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 12,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),

                // Current role badge
                RoleBadge(role: user.role),
                const SizedBox(width: 16),

                // Role dropdown (disabled for self)
                if (!isSelf)
                  _buildRoleDropdown(context, ref, user)
                else
                  const SizedBox(width: 140),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    UserAvatar(
                      photoURL: user.photoURL,
                      displayName: user.displayName,
                      radius: 20,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  user.displayName,
                                  style: const TextStyle(
                                    color: AppColors.textPrimary,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (isSelf) ...[
                                const SizedBox(width: 8),
                                const Text(
                                  '(you)',
                                  style: TextStyle(
                                    color: AppColors.textMuted,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            user.email,
                            style: const TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 12,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    RoleBadge(role: user.role),
                    if (!isSelf) _buildRoleDropdown(context, ref, user),
                  ],
                ),
              ],
            ),
    );
  }

  Widget _buildRoleDropdown(
      BuildContext context, WidgetRef ref, UserModel user) {
    final assignableRoles = UserRole.values.where((r) => r != UserRole.pending).toList();

    return PopupMenuButton<UserRole>(
      tooltip: 'Change role',
      offset: const Offset(0, 40),
      color: AppColors.surfaceElevated,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: AppColors.border),
      ),
      itemBuilder: (context) => assignableRoles.map((role) {
        return PopupMenuItem<UserRole>(
          value: role,
          child: Row(
            children: [
              if (user.role == role)
                const Icon(Icons.check, size: 16, color: AppColors.accent)
              else
                const SizedBox(width: 16),
              const SizedBox(width: 8),
              Text(
                role.label,
                style: TextStyle(
                  color: user.role == role
                      ? AppColors.accent
                      : AppColors.textPrimary,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        );
      }).toList(),
      onSelected: (role) async {
        final firestoreService = ref.read(firestoreServiceProvider);
        await firestoreService.updateUserRole(user.uid, role);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${user.displayName} → ${role.label}'),
            ),
          );
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: AppColors.border),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Change Role',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
            ),
            SizedBox(width: 4),
            Icon(Icons.arrow_drop_down,
                color: AppColors.textSecondary, size: 18),
          ],
        ),
      ),
    );
  }
}
