import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/custom_tab_bar.dart';
import '../../core/widgets/role_badge.dart';
import '../../core/widgets/user_avatar.dart';
import '../../models/project_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/project_provider.dart';
import '../../providers/user_provider.dart';
import '../../services/auth_service.dart';
import 'package:intl/intl.dart';

import '../../providers/router_provider.dart';
import '../project/create_project_dialog.dart';
import '../settings/commission_settings_dialog.dart';
import '../settings/telegram_link_widget.dart';
import 'widgets/dashboard_filter_bar.dart';
import 'widgets/completed_project_card.dart';
import 'widgets/project_card.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> with RouteAware {
  bool _isReady = false;

  void _triggerDelay() {
    setState(() {
      _isReady = false;
    });
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) {
        setState(() {
          _isReady = true;
        });
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _triggerDelay();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final modalRoute = ModalRoute.of(context);
    if (modalRoute != null) {
      routeObserver.subscribe(this, modalRoute);
    }
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  void didPopNext() {
    // Called when the top route is popped off, and this route shows up again.
    _triggerDelay();
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider).value;
    final selectedTab = ref.watch(selectedTabProvider);
    final projectsAsync = ref.watch(filteredProjectsProvider);

    if (currentUser == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─── Header ────────────────────────────────
            _buildHeader(context, ref, currentUser),
            const SizedBox(height: 16),

            // ─── Telegram Link Widget ────────────────
            const TelegramLinkWidget(),
            const SizedBox(height: 16),

            // ─── Title & Tabs ──────────────────────────
            const Text(
              'Projects',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            CustomTabBar(
              tabs: ProjectStatus.values.map((s) => s.label).toList(),
              selectedIndex: selectedTab.index,
              onTap: (index) {
                ref.read(selectedTabProvider.notifier).state =
                    ProjectStatus.values[index];
                // Reset filter when switching tabs
                ref.read(selectedStatusFilterProvider.notifier).state = null;
              },
            ),
            const SizedBox(height: 24),
            // ─── Add Project (Manager only) ────────────
            if (currentUser.isManager) ...[
              _buildAddProjectButton(context, ref, currentUser),
              const SizedBox(height: 16),
            ],

            // ─── Filter Bar ────────────────────────────
            const DashboardFilterBar(),

            // ─── Project List ──────────────────────────
            Expanded(
              child: !_isReady 
                ? _buildShimmerLoading()
                : projectsAsync.when(
                    data: (projects) {
                      if (projects.isEmpty) {
                        return Center(
                          child: Text(
                            currentUser.isManager
                                ? 'No projects yet. Create one!'
                                : 'No projects assigned to you.',
                            style: const TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 14,
                            ),
                          ),
                        );
                      }
                      return _buildProjectList(context, ref, projects, currentUser);
                    },
                    loading: () => _buildShimmerLoading(),
                    error: (e, _) => Center(
                      child: Text(
                        'Error: $e',
                        style: const TextStyle(color: AppColors.error),
                      ),
                    ),
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShimmerLoading() {
    return SingleChildScrollView(
      child: Column(
        children: List.generate(3, (index) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Shimmer.fromColors(
            baseColor: AppColors.surfaceElevated,
            highlightColor: AppColors.border,
            child: Container(
              width: double.infinity,
              height: 140,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        )),
      ),
    );
  }

  Widget _buildHeader(
      BuildContext context, WidgetRef ref, currentUser) {
    final isDesktop = MediaQuery.of(context).size.width > 630;

    return Row(
      children: [
        // User avatar
        UserAvatar(
          photoURL: currentUser.photoURL,
          displayName: currentUser.displayName,
          radius: 18,
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              currentUser.displayName,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 2),
            RoleBadge(role: currentUser.role),
          ],
        ),
        const Spacer(),

        // Actions
        if (isDesktop)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Team management (Manager only)
              if (currentUser.isManager) ...[
                IconButton(
                  onPressed: () => context.push('/analytics'),
                  icon: const Icon(Icons.analytics_outlined, size: 22),
                  color: AppColors.textSecondary,
                  tooltip: 'Analytics',
                ),
                IconButton(
                  onPressed: () => context.push('/clients'),
                  icon: const Icon(Icons.business_center, size: 22),
                  color: AppColors.textSecondary,
                  tooltip: 'Client Management',
                ),
                _buildPendingIndicator(ref, context),
                IconButton(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => const CommissionSettingsDialog(),
                    );
                  },
                  icon: const Icon(Icons.settings_outlined, size: 22),
                  color: AppColors.textSecondary,
                  tooltip: 'Commission Settings',
                ),
              ],
              const SizedBox(width: 8),
              IconButton(
                onPressed: () {
                  ref.read(authServiceProvider).signOut();
                },
                icon: const Icon(Icons.logout_rounded, size: 22),
                color: AppColors.textSecondary,
                tooltip: 'Sign Out',
              ),
            ],
          )
        else
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: AppColors.textSecondary),
            color: AppColors.surfaceElevated,
            onSelected: (value) {
              switch (value) {
                case 'analytics':
                  context.push('/analytics');
                  break;
                case 'clients':
                  context.push('/clients');
                  break;
                case 'team':
                  context.push('/team');
                  break;
                case 'settings':
                  showDialog(
                    context: context,
                    builder: (context) => const CommissionSettingsDialog(),
                  );
                  break;
                case 'logout':
                  ref.read(authServiceProvider).signOut();
                  break;
              }
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              if (currentUser.isManager) ...[
                const PopupMenuItem<String>(
                  value: 'analytics',
                  child: ListTile(
                    leading: Icon(Icons.analytics_outlined, color: AppColors.textSecondary),
                    title: Text('Analytics', style: TextStyle(color: AppColors.textPrimary)),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                const PopupMenuItem<String>(
                  value: 'clients',
                  child: ListTile(
                    leading: Icon(Icons.business_center, color: AppColors.textSecondary),
                    title: Text('Client Management', style: TextStyle(color: AppColors.textPrimary)),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                PopupMenuItem<String>(
                  value: 'team',
                  child: ListTile(
                    leading: _buildPendingIndicator(ref, context, isMenu: true),
                    title: const Text('Team Management', style: TextStyle(color: AppColors.textPrimary)),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                const PopupMenuItem<String>(
                  value: 'settings',
                  child: ListTile(
                    leading: Icon(Icons.settings_outlined, color: AppColors.textSecondary),
                    title: Text('Commission Settings', style: TextStyle(color: AppColors.textPrimary)),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                const PopupMenuDivider(),
              ],
              const PopupMenuItem<String>(
                value: 'logout',
                child: ListTile(
                  leading: Icon(Icons.logout_rounded, color: AppColors.textSecondary),
                  title: Text('Sign Out', style: TextStyle(color: AppColors.textPrimary)),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildPendingIndicator(WidgetRef ref, BuildContext context, {bool isMenu = false}) {
    final pendingAsync = ref.watch(pendingUsersProvider);
    final pendingCount = pendingAsync.value?.length ?? 0;

    final iconWidget = const Icon(Icons.people_alt_rounded, size: 22, color: AppColors.textSecondary);

    return Stack(
      clipBehavior: Clip.none,
      children: [
        if (isMenu)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: iconWidget,
          )
        else
          IconButton(
            onPressed: () => context.push('/team'),
            icon: iconWidget,
            tooltip: 'Team Management',
          ),
        if (pendingCount > 0)
          Positioned(
            right: isMenu ? -6 : 4,
            top: isMenu ? 2 : 4,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: AppColors.error,
                shape: BoxShape.circle,
              ),
              child: Text(
                '$pendingCount',
                style: const TextStyle(
                  color: AppColors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildAddProjectButton(
      BuildContext context, WidgetRef ref, currentUser) {
    return GestureDetector(
      onTap: () => _showCreateProjectDialog(context, ref, currentUser),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(
          child: Text(
            '+ add project',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 15,
            ),
          ),
        ),
      ),
    );
  }

  void _showCreateProjectDialog(
      BuildContext context, WidgetRef ref, currentUser) {
    showDialog(
      context: context,
      builder: (context) => CreateProjectDialog(createdBy: currentUser.uid),
    );
  }

  Future<void> _confirmDeleteProject(BuildContext context, WidgetRef ref, String projectId, String title, {bool showCommissionWarning = false}) async {
    final message = showCommissionWarning
        ? 'Are you sure you want to delete "$title"?\n\nWARNING: This will permanently undo the balances earned by the assigned Strategist and Designer and adjust analytics. This cannot be undone.'
        : 'Are you sure you want to delete "$title"? This action cannot be undone.';

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceElevated,
        title: const Text('Delete Project', style: TextStyle(color: AppColors.textPrimary)),
        content: Text(message, style: const TextStyle(color: AppColors.textPrimary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      if (!context.mounted) return;
      
      final navigator = Navigator.of(context, rootNavigator: true);
      final scaffoldMessenger = ScaffoldMessenger.of(context);
      
      final progressNotifier = ValueNotifier<double>(0.0);
      _showProgressDialog(context, progressNotifier, 'Deleting Project...');

      final firestoreService = ref.read(firestoreServiceProvider);
      await firestoreService.deleteProject(
        projectId,
        onProgress: (p) => progressNotifier.value = p,
      );

      // We use the captured navigator because the original context might be
      // unmounted if the project list rebuilds without this project.
      navigator.pop(); // Close progress dialog
      progressNotifier.dispose();
      
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('Project "$title" deleted.')),
      );
    }
  }

  void _showProgressDialog(BuildContext context, ValueNotifier<double> progressNotifier, String title) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return PopScope(
          canPop: false,
          child: AlertDialog(
            backgroundColor: AppColors.surfaceElevated,
            content: Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: ValueListenableBuilder<double>(
                valueListenable: progressNotifier,
                builder: (context, value, child) {
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 24),
                      LinearProgressIndicator(
                        value: value,
                        backgroundColor: AppColors.border,
                        valueColor:
                            const AlwaysStoppedAnimation<Color>(AppColors.accent),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '${(value * 100).toInt()}%',
                        style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 14,
                            fontWeight: FontWeight.w500),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildProjectList(
      BuildContext context, WidgetRef ref, List<ProjectModel> projects, currentUser) {
    final selectedTab = ref.watch(selectedTabProvider);
    if (selectedTab == ProjectStatus.completed) {
      return _buildCompletedProjectList(context, ref, projects);
    }

    if (currentUser.isManager) {
      return _buildManagerProjectList(context, ref, projects);
    }
    return _buildMemberProjectList(context, projects, currentUser);
  }

  Widget _buildCompletedProjectList(
      BuildContext context, WidgetRef ref, List<ProjectModel> projects) {
    final currentUser = ref.watch(currentUserProvider).value;
    if (currentUser == null) return const SizedBox.shrink();

    // Sort projects by date descending
    final sortedProjects = List<ProjectModel>.from(projects)
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

    // Group by month
    final Map<String, List<ProjectModel>> grouped = {};
    for (var project in sortedProjects) {
      final month = DateFormat('MMMM').format(project.updatedAt);
      if (!grouped.containsKey(month)) {
        grouped[month] = [];
      }
      grouped[month]!.add(project);
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: grouped.entries.map((entry) {
          final month = entry.key;
          final monthProjects = entry.value;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sectionHeader(month),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 400,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 1.6,
                ),
                itemCount: monthProjects.length,
                itemBuilder: (context, index) {
                  final project = monthProjects[index];
                  final isPractice = project.clientId == null || project.clientId!.isEmpty;
                  return CompletedProjectCard(
                    project: project,
                    onLongPress: currentUser.isManager
                        ? () => _confirmDeleteProject(context, ref, project.id, project.title, showCommissionWarning: !isPractice)
                        : null,
                  );
                },
              ),
              const SizedBox(height: 24),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildManagerProjectList(
      BuildContext context, WidgetRef ref, List<ProjectModel> projects) {
    final needsApproval = projects
        .where((p) => p.approvalStatus == ApprovalStatus.needsApproval)
        .toList();
    final ongoing = projects
        .where((p) => p.approvalStatus == ApprovalStatus.ongoing)
        .toList();
    final approved = projects
        .where((p) => p.approvalStatus == ApprovalStatus.approved)
        .toList();

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (needsApproval.isNotEmpty) ...[
            _sectionHeader('Needs Approval'),
            ...needsApproval.map((p) => ProjectCard(project: p, onLongPress: () => _confirmDeleteProject(context, ref, p.id, p.title))),
            const SizedBox(height: 24),
          ],
          if (ongoing.isNotEmpty) ...[
            _sectionHeader('Ongoing'),
            ...ongoing.map((p) => ProjectCard(project: p, onLongPress: () => _confirmDeleteProject(context, ref, p.id, p.title))),
            const SizedBox(height: 24),
          ],
          if (approved.isNotEmpty) ...[
            _sectionHeader('Approved'),
            ...approved.map((p) => ProjectCard(project: p, onLongPress: () => _confirmDeleteProject(context, ref, p.id, p.title))),
          ],
        ],
      ),
    );
  }

  Widget _buildMemberProjectList(
      BuildContext context, List<ProjectModel> projects, currentUser) {
    List<ProjectModel> queue;
    List<ProjectModel> revision;
    List<ProjectModel> submitted;

    // Member (check assignments dynamically, regardless of default role)
    revision = projects.where((p) {
      final isStrategistRevision = p.strategistId == currentUser.uid &&
          p.strategistStatus == AssignmentStatus.revision;
      final isDesignerRevision = p.designerId == currentUser.uid &&
          p.designerStatus == AssignmentStatus.revision;
      return isStrategistRevision || isDesignerRevision;
    }).toList();

    queue = projects.where((p) {
      if (revision.contains(p)) return false;
      final isStrategistAssigned = p.strategistId == currentUser.uid &&
          p.strategistStatus == AssignmentStatus.assigned;
      final isDesignerAssigned = p.designerId == currentUser.uid &&
          p.designerStatus == AssignmentStatus.assigned;
      return isStrategistAssigned || isDesignerAssigned;
    }).toList();

    submitted = projects.where((p) {
      if (queue.contains(p) || revision.contains(p)) return false;
      
      final isStrategistSubmitted = p.strategistId == currentUser.uid &&
          p.strategistStatus == AssignmentStatus.submitted;
      final isDesignerSubmitted = p.designerId == currentUser.uid &&
          p.designerStatus == AssignmentStatus.submitted;
      return isStrategistSubmitted || isDesignerSubmitted;
    }).toList();

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (revision.isNotEmpty) ...[
            _sectionHeader('Revision'),
            ...revision.map((p) => ProjectCard(project: p)),
            const SizedBox(height: 24),
          ],
          if (queue.isNotEmpty) ...[
            _sectionHeader('Queue'),
            ...queue.map((p) => ProjectCard(project: p)),
            const SizedBox(height: 24),
          ],
          if (submitted.isNotEmpty) ...[
            _sectionHeader('Submitted'),
            ...submitted.map((p) => ProjectCard(project: p)),
          ],
          if (queue.isEmpty && submitted.isEmpty && revision.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.only(top: 60),
                child: Text(
                  'No projects in this tab.',
                  style: TextStyle(color: AppColors.textMuted),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
