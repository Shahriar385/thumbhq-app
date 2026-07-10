import 'dart:typed_data';
import 'package:flutter/rendering.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/role_badge.dart';
import '../../core/widgets/status_badge.dart';
import '../../core/widgets/user_avatar.dart';
import '../../models/project_model.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/project_provider.dart';
import '../../providers/user_provider.dart';
import '../../services/firestore_service.dart';
import '../../services/storage_service.dart';
import '../../core/widgets/full_screen_image.dart';
import 'widgets/section_editor.dart';
import 'widgets/image_grid.dart';
import 'widgets/project_chat_sheet.dart';

import 'dart:async';
import 'package:image_picker/image_picker.dart';

class ProjectDetailScreen extends ConsumerStatefulWidget {
  final String projectId;

  const ProjectDetailScreen({super.key, required this.projectId});

  @override
  ConsumerState<ProjectDetailScreen> createState() =>
      _ProjectDetailScreenState();
}

class _ProjectDetailScreenState extends ConsumerState<ProjectDetailScreen> {
  // Video details controllers
  final _videoTitleController = TextEditingController();
  final _videoGoalController = TextEditingController();
  List<String> _videoImageUrls = [];
  List<MapEntry<String, Uint8List>> _videoPendingUploads = [];

  // Brief controllers
  final _briefContentController = TextEditingController();
  List<String> _briefRefImageUrls = [];
  List<String> _briefConceptImageUrls = [];
  List<MapEntry<String, Uint8List>> _briefPendingUploads = [];

  // Final design
  List<String> _finalDesignUrls = [];
  List<MapEntry<String, Uint8List>> _finalDesignPendingUploads = [];

  bool _initialized = false;
  bool _isSaving = false;

  final ScrollController _scrollController = ScrollController();
  bool _isFabVisible = true;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      if (_scrollController.position.userScrollDirection == ScrollDirection.reverse) {
        if (_isFabVisible) setState(() => _isFabVisible = false);
      } else if (_scrollController.position.userScrollDirection == ScrollDirection.forward) {
        if (!_isFabVisible) setState(() => _isFabVisible = true);
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _videoTitleController.dispose();
    _videoGoalController.dispose();
    _briefContentController.dispose();
    super.dispose();
  }

  void _initializeFromProject(ProjectModel project) {
    if (_initialized) return;
    _initialized = true;

    _videoTitleController.text = project.videoDetails.title;
    _videoGoalController.text = project.videoDetails.goal;
    _videoImageUrls = List.from(project.videoDetails.images);

    _briefContentController.text = project.brief.content;
    _briefRefImageUrls = List.from(project.brief.referenceImages);
    _briefConceptImageUrls = List.from(project.brief.conceptImages);

    _finalDesignUrls = List.from(project.finalDesign.images);
  }

  Future<void> _pickImages(
      void Function(List<MapEntry<String, Uint8List>>) onPicked) async {
    final picker = ImagePicker();
    final files = await picker.pickMultiImage();
    if (files.isEmpty) return;
    
    final entries = <MapEntry<String, Uint8List>>[];
    for (final file in files) {
      final bytes = await file.readAsBytes();
      entries.add(MapEntry(file.name, bytes));
    }
    onPicked(entries);
  }

  Future<List<String>> _uploadPendingImages(
    List<MapEntry<String, Uint8List>> pending,
    String subPath,
    ValueNotifier<double>? progressNotifier,
  ) async {
    if (pending.isEmpty) {
      progressNotifier?.value = 1.0;
      return [];
    }
    final storageService = StorageService();
    final path = 'projects/${widget.projectId}/$subPath';
    return await storageService.uploadImages(
      path: path,
      files: pending,
      onProgress: (p) {
        if (progressNotifier != null) progressNotifier.value = p;
      },
    );
  }

  void _showProgressDialog(ValueNotifier<double> progressNotifier) {
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
                      const Text(
                        'Uploading...',
                        style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 24),
                      LinearProgressIndicator(
                        value: value,
                        backgroundColor: AppColors.border,
                        color: AppColors.accent,
                        minHeight: 8,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '${(value * 100).toInt()}%',
                        style: const TextStyle(
                            color: AppColors.textMuted, fontSize: 14),
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

  Future<void> _saveVideoDetails() async {
    setState(() => _isSaving = true);
    final progressNotifier = ValueNotifier<double>(0.0);
    _showProgressDialog(progressNotifier);
    try {
      final newUrls = await _uploadPendingImages(
          _videoPendingUploads, 'video_details', progressNotifier);
      _videoImageUrls.addAll(newUrls);
      _videoPendingUploads.clear();

      final firestoreService = ref.read(firestoreServiceProvider);
      await firestoreService.updateVideoDetails(
        widget.projectId,
        VideoDetails(
          title: _videoTitleController.text.trim(),
          goal: _videoGoalController.text.trim(),
          images: _videoImageUrls,
        ),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Video details saved')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        Navigator.pop(context);
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _saveBrief(ProjectModel project, UserModel currentUser) async {
    setState(() => _isSaving = true);
    final progressNotifier = ValueNotifier<double>(0.0);
    _showProgressDialog(progressNotifier);
    try {
      final newUrls = await _uploadPendingImages(
          _briefPendingUploads, 'brief', progressNotifier);
      _briefRefImageUrls.addAll(newUrls);
      _briefPendingUploads.clear();

      final firestoreService = ref.read(firestoreServiceProvider);
      await firestoreService.updateBrief(
        widget.projectId,
        Brief(
          content: _briefContentController.text.trim(),
          referenceImages: _briefRefImageUrls,
          conceptImages: _briefConceptImageUrls,
        ),
      );
      
      final isStrategist = project.strategistId == currentUser.uid;
      if (isStrategist && project.strategistStatus != AssignmentStatus.submitted) {
        await firestoreService.updateStrategistStatus(project.id, AssignmentStatus.submitted);
        _checkForApproval(project.copyWith(strategistStatus: AssignmentStatus.submitted));
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Brief saved and submitted')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        Navigator.pop(context);
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _saveFinalDesign(ProjectModel project, UserModel currentUser) async {
    setState(() => _isSaving = true);
    final progressNotifier = ValueNotifier<double>(0.0);
    _showProgressDialog(progressNotifier);
    try {
      final newUrls = await _uploadPendingImages(
          _finalDesignPendingUploads, 'final_design', progressNotifier);
      _finalDesignUrls.addAll(newUrls);
      _finalDesignPendingUploads.clear();

      final firestoreService = ref.read(firestoreServiceProvider);
      await firestoreService.updateFinalDesign(
        widget.projectId,
        FinalDesign(images: _finalDesignUrls),
      );


      final isDesigner = project.designerId == currentUser.uid;
      if (isDesigner && project.designerStatus != AssignmentStatus.submitted) {
        await firestoreService.updateDesignerStatus(project.id, currentUser.uid, AssignmentStatus.submitted);
        _checkForApproval(project.copyWith(designerStatus: AssignmentStatus.submitted));
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Final design saved and submitted')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        Navigator.pop(context);
        setState(() => _isSaving = false);
      }
    }
  }

  bool _canViewChat(ProjectModel project, UserModel user) {
    return user.isManager ||
        project.strategistId == user.uid ||
        project.designerId == user.uid;
  }

  @override
  Widget build(BuildContext context) {
    final projectAsync = ref.watch(projectProvider(widget.projectId));
    final currentUser = ref.watch(currentUserProvider).value;
    final allUsersAsync = ref.watch(allUsersProvider);

    return Scaffold(
      floatingActionButton: projectAsync.value != null && currentUser != null && _canViewChat(projectAsync.value!, currentUser)
          ? AnimatedSlide(
              duration: const Duration(milliseconds: 250),
              offset: _isFabVisible ? Offset.zero : const Offset(0, 2),
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 250),
                opacity: _isFabVisible ? 1 : 0,
                child: FloatingActionButton(
                  onPressed: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (_) => ProjectChatSheet(
                        project: projectAsync.value!,
                        currentUser: currentUser,
                      ),
                    );
                  },
                  backgroundColor: AppColors.accent,
                  child: const Icon(Icons.chat_bubble_outline, color: AppColors.white),
                ),
              ),
            )
          : null,
      body: projectAsync.when(
        data: (project) {
          if (project == null || currentUser == null) {
            return const Center(child: Text('Project not found'));
          }
          _initializeFromProject(project);
          return _buildContent(context, project, currentUser, allUsersAsync);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    ProjectModel project,
    UserModel currentUser,
    AsyncValue<List<UserModel>> allUsersAsync,
  ) {
    final isManager = currentUser.isManager;
    final isStrategist = project.strategistId == currentUser.uid;
    final isDesigner = project.designerId == currentUser.uid;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Column(
        children: [
          // ─── Top bar ─────────────────────────────────
          Row(
            children: [
              IconButton(
                onPressed: () => context.pop(),
                icon: const Icon(Icons.arrow_back_rounded),
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  project.title,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              if (project.clientName.isNotEmpty)
                Text(
                  project.clientName,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                  ),
                ),
              if (project.deadline != null) ...[
                const SizedBox(width: 16),
                Text(
                  'Deadline: ${DateFormat('d MMM h:mma').format(project.deadline!)}',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 24),

          // ─── Body ────────────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              controller: _scrollController,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Video Details (Manager can edit, Strategist can view)
                  if (isManager || isStrategist) ...[
                    SectionEditor(
                      title: 'Video details',
                      canEdit: isManager,
                      titleController: _videoTitleController,
                      titleHint: 'Video title',
                      contentController: _videoGoalController,
                      contentHint: 'Goal / description...',
                      imageUrls: _videoImageUrls,
                      pendingUploads: _videoPendingUploads,
                      onAddImages: () => _pickImages((files) {
                        setState(() => _videoPendingUploads.addAll(files));
                      }),
                      onRemoveUrl: (i) =>
                          setState(() => _videoImageUrls.removeAt(i)),
                      onRemovePending: (i) =>
                          setState(() => _videoPendingUploads.removeAt(i)),
                    ),
                    if (isManager) ...[
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: _isSaving ? null : _saveVideoDetails,
                          child: const Text('Save Video Details'),
                        ),
                      ),
                    ],
                    const SizedBox(height: 28),
                  ],

                  // Brief (Strategist can edit, Manager can view)
                  if ((isStrategist || isManager) && project.strategistStatus == AssignmentStatus.revision && project.strategistRevisionNote != null)
                    _buildRevisionNote(project.strategistRevisionNote!, images: project.strategistRevisionImages),
                  SectionEditor(
                    title: 'Brief',
                    canEdit: isStrategist || isManager,
                    contentController: _briefContentController,
                    contentHint: 'Format, references, notes...',
                    contentMaxLines: 8,
                    imageUrls: _briefRefImageUrls,
                    pendingUploads: _briefPendingUploads,
                    onAddImages: () => _pickImages((files) {
                      setState(() => _briefPendingUploads.addAll(files));
                    }),
                    onRemoveUrl: (i) =>
                        setState(() => _briefRefImageUrls.removeAt(i)),
                    onRemovePending: (i) =>
                        setState(() => _briefPendingUploads.removeAt(i)),
                  ),
                  if (isStrategist || isManager) ...[
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: _isSaving ? null : () => _saveBrief(project, currentUser),
                        child: const Text('Save Brief'),
                      ),
                    ),
                  ],
                  const SizedBox(height: 28),

                  // Final Design (Designer can edit)
                  _buildFinalDesignSection(isDesigner || isManager, project, currentUser),
                  if (isDesigner || isManager) ...[
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: _isSaving ? null : () => _saveFinalDesign(project, currentUser),
                        child: const Text('Save Final Design'),
                      ),
                    ),
                  ],
                  const SizedBox(height: 28),

                  // ─── Assignment Panel (Manager) ──────
                  if (isManager)
                    _buildAssignmentPanel(project, allUsersAsync),

                  const SizedBox(height: 28),

                  // ─── Action Buttons ──────────────────
                  _buildActionButtons(
                      project, currentUser, isManager, isStrategist, isDesigner),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFinalDesignSection(bool canEdit, ProjectModel project, UserModel currentUser) {
    final isManager = currentUser.isManager;
    final isDesigner = project.designerId == currentUser.uid;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if ((isDesigner || isManager) && project.designerStatus == AssignmentStatus.revision && project.designerRevisionNote != null)
          _buildRevisionNote(project.designerRevisionNote!, images: project.designerRevisionImages),
        const Text(
          'Final design',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          constraints: const BoxConstraints(minHeight: 100),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.inputBackground,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            children: [
              if (_finalDesignUrls.isEmpty && _finalDesignPendingUploads.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Text(
                    'No final designs uploaded yet.',
                    style: TextStyle(color: AppColors.textMuted, fontSize: 13),
                  ),
                ),
              if (_finalDesignUrls.isNotEmpty ||
                  _finalDesignPendingUploads.isNotEmpty)
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ..._finalDesignUrls.asMap().entries.map((entry) {
                      return GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => FullScreenImage(imageUrl: entry.value),
                            ),
                          );
                        },
                        child: _imageTile(
                          child: CachedNetworkImage(
                            imageUrl: entry.value,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Shimmer.fromColors(
                              baseColor: AppColors.surfaceElevated,
                              highlightColor: AppColors.border,
                              child: Container(color: Colors.white),
                            ),
                            errorWidget: (context, url, error) => const Icon(
                              Icons.broken_image,
                              color: AppColors.textMuted,
                            ),
                          ),
                          onRemove: canEdit
                              ? () => setState(
                                  () => _finalDesignUrls.removeAt(entry.key))
                              : null,
                        ),
                      );
                    }),
                    ..._finalDesignPendingUploads.asMap().entries.map((entry) {
                      return GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => FullScreenImage(imageBytes: entry.value.value),
                            ),
                          );
                        },
                        child: _imageTile(
                          child:
                              Image.memory(entry.value.value, fit: BoxFit.cover),
                          onRemove: () => setState(
                              () => _finalDesignPendingUploads.removeAt(entry.key)),
                          isPending: true,
                        ),
                      );
                    }),
                  ],
                ),
              if (canEdit) ...[
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: () => _pickImages((files) {
                    setState(() => _finalDesignPendingUploads.addAll(files));
                  }),
                  child: Container(
                    width: 100,
                    height: 80,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceElevated,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_photo_alternate_outlined,
                            color: AppColors.textMuted, size: 22),
                        SizedBox(height: 4),
                        Text('Add',
                            style: TextStyle(
                                color: AppColors.textMuted, fontSize: 11)),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _imageTile({
    required Widget child,
    VoidCallback? onRemove,
    bool isPending = false,
  }) {
    return Stack(
      children: [
        Container(
          width: 120,
          height: 90,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.border),
          ),
          clipBehavior: Clip.antiAlias,
          child: child,
        ),
        if (onRemove != null)
          Positioned(
            top: 4,
            right: 4,
            child: GestureDetector(
              onTap: onRemove,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: const BoxDecoration(
                  color: AppColors.error,
                  shape: BoxShape.circle,
                ),
                child:
                    const Icon(Icons.close, size: 12, color: AppColors.white),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildAssignmentPanel(
      ProjectModel project, AsyncValue<List<UserModel>> allUsersAsync) {
    return allUsersAsync.when(
      data: (allUsers) {
        // Show all members except pending to avoid assigning unapproved users.
        // If the user meant literally everyone, we could just use `allUsers`.
        // Let's use all assignable users.
        final assignableUsers = allUsers.where((u) => !u.isPending).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Assignment',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),

            // Strategist assignment
            const Text('Strategist',
                style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            _buildStrategistDropdown(project, assignableUsers),
            const SizedBox(height: 20),

            // Designer assignment
            const Text('Designer',
                style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            _buildDesignerDropdown(project, assignableUsers),
          ],
        );
      },
      loading: () => const CircularProgressIndicator(),
      error: (_, __) => const Text('Error loading users'),
    );
  }

  Widget _buildStrategistDropdown(ProjectModel project, List<UserModel> users) {
    // If current strategist is no longer in users (e.g. deleted), we still want to show them?
    // Let's ensure the dropdown value is valid.
    final isValidValue = users.any((u) => u.uid == project.strategistId);
    final value = isValidValue ? project.strategistId : null;

    final isCompleted = project.status == ProjectStatus.completed;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      decoration: BoxDecoration(
        border: Border.all(color: isCompleted ? AppColors.border.withAlpha(100) : AppColors.border),
        borderRadius: BorderRadius.circular(8),
        color: isCompleted ? AppColors.background : AppColors.surfaceElevated,
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          hint: const Text('Select a Strategist',
              style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
          value: value,
          dropdownColor: AppColors.surfaceElevated,
          icon: const Icon(Icons.arrow_drop_down, color: AppColors.textMuted),
          items: [
            const DropdownMenuItem<String>(
              value: null,
              child: Text('Unassigned',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
            ),
            ...users.map((u) => DropdownMenuItem(
                  value: u.uid,
                  child: Row(
                    children: [
                      UserAvatar(
                          photoURL: u.photoURL,
                          displayName: u.displayName,
                          radius: 12),
                      const SizedBox(width: 8),
                      Text(u.displayName,
                          style: TextStyle(
                              color: isCompleted ? AppColors.textMuted : AppColors.textPrimary, 
                              fontSize: 13)),
                      const SizedBox(width: 8),
                      RoleBadge(role: u.role),
                    ],
                  ),
                )),
          ],
          onChanged: project.status == ProjectStatus.completed
              ? null
              : (uid) async {
                  final firestoreService = ref.read(firestoreServiceProvider);
                  if (uid == null) {
                    // Unassign strategist (we can set to empty string or handle logic)
                    await firestoreService.assignStrategist(project.id, '');
                  } else {
                    await firestoreService.assignStrategist(project.id, uid);
                  }
                },
        ),
      ),
    );
  }

  Widget _buildDesignerDropdown(ProjectModel project, List<UserModel> users) {
    final isValidValue = users.any((u) => u.uid == project.designerId);
    final value = isValidValue ? project.designerId : null;

    final isCompleted = project.status == ProjectStatus.completed;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      decoration: BoxDecoration(
        border: Border.all(color: isCompleted ? AppColors.border.withAlpha(100) : AppColors.border),
        borderRadius: BorderRadius.circular(8),
        color: isCompleted ? AppColors.background : AppColors.surfaceElevated,
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          hint: const Text('Select a Designer',
              style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
          value: value,
          dropdownColor: AppColors.surfaceElevated,
          icon: const Icon(Icons.arrow_drop_down, color: AppColors.textMuted),
          items: [
            const DropdownMenuItem<String>(
              value: null,
              child: Text('Unassigned',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
            ),
            ...users.map((u) => DropdownMenuItem(
                  value: u.uid,
                  child: Row(
                    children: [
                      UserAvatar(
                          photoURL: u.photoURL,
                          displayName: u.displayName,
                          radius: 12),
                      const SizedBox(width: 8),
                      Text(u.displayName,
                          style: TextStyle(
                              color: isCompleted ? AppColors.textMuted : AppColors.textPrimary, 
                              fontSize: 13)),
                      const SizedBox(width: 8),
                      RoleBadge(role: u.role),
                    ],
                  ),
                )),
          ],
          onChanged: project.status == ProjectStatus.completed
              ? null
              : (uid) async {
                  final firestoreService = ref.read(firestoreServiceProvider);
                  if (uid == null) {
                    await firestoreService.assignDesigner(project.id, '');
                  } else {
                    await firestoreService.assignDesigner(project.id, uid);
                  }
                },
        ),
      ),
    );
  }

  Widget _buildActionButtons(
    ProjectModel project,
    UserModel currentUser,
    bool isManager,
    bool isStrategist,
    bool isDesigner,
  ) {
    return Row(
      children: [
        if (isStrategist && project.strategistStatus == AssignmentStatus.submitted)
          const Padding(
            padding: EdgeInsets.only(right: 12),
            child: StatusBadge(label: 'Brief Submitted', color: AppColors.submitted),
          ),

        if (isDesigner && project.designerStatus == AssignmentStatus.submitted)
          const Padding(
            padding: EdgeInsets.only(right: 12),
            child: StatusBadge(label: 'Design Submitted', color: AppColors.submitted),
          ),

        // Manager Revision (Brief)
        if (isManager && project.strategistStatus == AssignmentStatus.submitted)
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: OutlinedButton(
              onPressed: () => _showRevisionDialog('Strategist', project.id),
              child: const Text('Revise Brief'),
            ),
          ),

        // Manager Revision (Design)
        if (isManager && project.designerStatus == AssignmentStatus.submitted)
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: OutlinedButton(
              onPressed: () => _showRevisionDialog('Designer', project.id),
              child: const Text('Revise Design'),
            ),
          ),

        const Spacer(),

        // Manager Approve
        if (isManager &&
            project.approvalStatus != ApprovalStatus.approved) ...[
          (() {
            final hasFinalDesign = project.finalDesign.images.isNotEmpty;
            return ElevatedButton(
              onPressed: hasFinalDesign
                  ? () async {
                      final firestoreService = ref.read(firestoreServiceProvider);
                      await firestoreService.updateApprovalStatus(
                          project.id, ApprovalStatus.approved);
                      await firestoreService.updateProject(
                          project.id, {'status': ProjectStatus.completed.value});
                    }
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: hasFinalDesign
                    ? AppColors.approved
                    : AppColors.textMuted.withOpacity(0.3),
                disabledForegroundColor: AppColors.textSecondary,
              ),
              child: const Text('Approve'),
            );
          })(),
        ],
        if (isManager && project.approvalStatus == ApprovalStatus.approved)
          StatusBadge.approved(),
      ],
    );
  }

  Future<void> _checkForApproval(ProjectModel project) async {
    // If all assigned members have submitted, move to needs_approval
    final firestoreService = ref.read(firestoreServiceProvider);

    bool allSubmitted = true;
    if (project.strategistId != null &&
        project.strategistStatus != AssignmentStatus.submitted) {
      allSubmitted = false;
    }
    if (project.designerId != null &&
        project.designerStatus != AssignmentStatus.submitted) {
      allSubmitted = false;
    }

    if (allSubmitted &&
        project.approvalStatus == ApprovalStatus.ongoing) {
      await firestoreService.updateApprovalStatus(
          project.id, ApprovalStatus.needsApproval);
    }
  }

  Widget _buildRevisionNote(String note, {List<String> images = const []}) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.info.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.info.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.feedback_outlined, color: AppColors.info, size: 20),
              SizedBox(width: 8),
              Text('Revision Requested',
                  style: TextStyle(
                      color: AppColors.info,
                      fontWeight: FontWeight.bold,
                      fontSize: 14)),
            ],
          ),
          const SizedBox(height: 8),
          Text(note,
              style: const TextStyle(
                  color: AppColors.textPrimary, fontSize: 14, height: 1.4)),
          if (images.isNotEmpty) ...[
            const SizedBox(height: 16),
            ImageGrid(
              imageUrls: images,
              canEdit: false,
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _showRevisionDialog(String role, String projectId) async {
    final controller = TextEditingController();
    final firestoreService = ref.read(firestoreServiceProvider);
    
    List<MapEntry<String, Uint8List>> pendingImages = [];
    bool isUploading = false;

    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: AppColors.surfaceElevated,
              title: Text('Request $role Revision',
                  style: const TextStyle(color: AppColors.textPrimary, fontSize: 18)),
              content: SizedBox(
                width: 500,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        controller: controller,
                        maxLines: 4,
                        style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
                        decoration: const InputDecoration(
                          hintText: 'Enter instructions for the revision...',
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text('Attach Images', style: TextStyle(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w500)),
                      const SizedBox(height: 8),
                      ImageGrid(
                        imageUrls: const [],
                        pendingUploads: pendingImages,
                        canEdit: true,
                        onAddImages: () async {
                          await _pickImages((newItems) {
                            setState(() {
                              pendingImages.addAll(newItems);
                            });
                          });
                        },
                        onRemovePending: (index) {
                          setState(() {
                            pendingImages.removeAt(index);
                          });
                        },
                      ),
                      if (isUploading)
                        const Padding(
                          padding: EdgeInsets.only(top: 16),
                          child: LinearProgressIndicator(color: AppColors.accent),
                        ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isUploading ? null : () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: isUploading ? null : () async {
                    if (controller.text.trim().isEmpty) return;
                    setState(() => isUploading = true);
                    
                    try {
                      final progressNotifier = ValueNotifier<double>(0.0);
                      final uploadedUrls = await _uploadPendingImages(
                        pendingImages, 
                        'revisions/${role.toLowerCase()}', 
                        progressNotifier,
                      );
                      
                      if (role == 'Strategist') {
                        await firestoreService.requestStrategistRevision(
                            projectId, controller.text.trim(), images: uploadedUrls);
                      } else if (role == 'Designer') {
                        await firestoreService.requestDesignerRevision(
                            projectId, controller.text.trim(), images: uploadedUrls);
                      }
                      if (context.mounted) Navigator.pop(context);
                    } catch(e) {
                      setState(() => isUploading = false);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                      }
                    }
                  },
                  child: const Text('Send Request'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
