import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../models/project_model.dart';
import '../../services/firestore_service.dart';
import '../../providers/auth_provider.dart';
import '../../providers/client_provider.dart';

class CreateProjectDialog extends ConsumerStatefulWidget {
  final String createdBy;

  const CreateProjectDialog({super.key, required this.createdBy});

  @override
  ConsumerState<CreateProjectDialog> createState() =>
      _CreateProjectDialogState();
}

class _CreateProjectDialogState extends ConsumerState<CreateProjectDialog> {
  final _titleController = TextEditingController();
  String? _selectedClientId;
  String? _selectedClientName;
  DateTime? _deadline;
  ProjectStatus _status = ProjectStatus.active;
  bool _isLoading = false;

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _pickDeadline() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 3)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.accent,
              surface: AppColors.cardBackground,
            ),
          ),
          child: child!,
        );
      },
    );

    if (date != null && mounted) {
      final time = await showTimePicker(
        context: context,
        initialTime: const TimeOfDay(hour: 20, minute: 0),
        builder: (context, child) {
          return Theme(
            data: Theme.of(context).copyWith(
              colorScheme: const ColorScheme.dark(
                primary: AppColors.accent,
                surface: AppColors.cardBackground,
              ),
            ),
            child: child!,
          );
        },
      );

      setState(() {
        _deadline = DateTime(
          date.year,
          date.month,
          date.day,
          time?.hour ?? 20,
          time?.minute ?? 0,
        );
      });
    }
  }

  Future<void> _createProject() async {
    if (_titleController.text.trim().isEmpty) return;

    setState(() => _isLoading = true);
    try {
      final firestoreService = ref.read(firestoreServiceProvider);
      final now = DateTime.now();

      await firestoreService.createProject(
        ProjectModel(
          id: '',
          title: _titleController.text.trim(),
          clientId: _selectedClientId,
          clientName: _selectedClientName ?? '',
          deadline: _deadline,
          status: _status,
          createdBy: widget.createdBy,
          createdAt: now,
          updatedAt: now,
        ),
      );

      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to create project: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.cardBackground,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 480,
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'New Project',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close, color: AppColors.textMuted),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Title
            const Text(
              'Title',
              style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _titleController,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: const InputDecoration(hintText: 'Project title'),
            ),
            const SizedBox(height: 18),

            // Client
            if (_status != ProjectStatus.practice) ...[
              const Text(
                'Client',
                style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 6),
              Consumer(
                builder: (context, ref, child) {
                  final clientsAsync = ref.watch(clientsProvider);
                  return clientsAsync.when(
                    data: (clients) {
                      if (clients.isEmpty) {
                        return const Text(
                          'No clients available. Please add a client first from the dashboard.',
                          style: TextStyle(color: AppColors.textMuted, fontSize: 13),
                        );
                      }
                      // Validate that the selected name still exists in the list
                      final isValidSelection = _selectedClientId != null &&
                          clients.any((c) => c.id == _selectedClientId);
                      
                      return DropdownButtonFormField<String>(
                        value: isValidSelection ? _selectedClientId : null,
                        decoration: const InputDecoration(hintText: 'Select Client'),
                        dropdownColor: AppColors.surfaceElevated,
                        style: const TextStyle(color: AppColors.textPrimary),
                        items: clients.map((client) {
                          return DropdownMenuItem(
                            value: client.id,
                            child: Text(client.name, style: const TextStyle(color: AppColors.textPrimary)),
                          );
                        }).toList(),
                        onChanged: (val) {
                          setState(() {
                            _selectedClientId = val;
                            _selectedClientName = clients.firstWhere((c) => c.id == val).name;
                          });
                        },
                      );
                    },
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (e, _) => Text('Error loading clients: $e', style: const TextStyle(color: AppColors.error)),
                  );
                },
              ),
              const SizedBox(height: 18),
            ],

            // Deadline
            const Text(
              'Deadline',
              style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 6),
            GestureDetector(
              onTap: _pickDeadline,
              child: Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: AppColors.inputBackground,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.border),
                ),
                child: Text(
                  _deadline != null
                      ? DateFormat('d MMM yyyy, h:mm a').format(_deadline!)
                      : 'Pick a deadline',
                  style: TextStyle(
                    color: _deadline != null
                        ? AppColors.textPrimary
                        : AppColors.textMuted,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 18),

            // Status
            const Text(
              'Category',
              style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 6),
            Row(
              children: ProjectStatus.values
                  .where((s) => s != ProjectStatus.completed)
                  .map((status) {
                final isSelected = _status == status;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () => setState(() {
                      _status = status;
                      if (_status == ProjectStatus.practice) {
                        _selectedClientId = null;
                        _selectedClientName = null;
                      }
                    }),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.accent
                              : AppColors.border,
                        ),
                        color: isSelected
                            ? AppColors.accent.withValues(alpha: 0.1)
                            : Colors.transparent,
                      ),
                      child: Text(
                        status.label,
                        style: TextStyle(
                          color: isSelected
                              ? AppColors.accent
                              : AppColors.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 28),

            // Create button
            SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _createProject,
                child: _isLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.white,
                        ),
                      )
                    : const Text('Create Project'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
