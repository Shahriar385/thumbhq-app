import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/user_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/client_provider.dart';
import '../../../providers/project_provider.dart';
import '../../../providers/user_provider.dart';

class DashboardFilterBar extends ConsumerWidget {
  const DashboardFilterBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider).value;
    if (currentUser == null) return const SizedBox.shrink();

    final isManager = currentUser.isManager;
    final isDesktop = MediaQuery.of(context).size.width > 900;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(8),
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: isDesktop
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(child: _buildSearchField(ref)),
                if (isManager) ...[
                  const SizedBox(width: 16),
                  _buildStrategistDropdown(ref),
                  const SizedBox(width: 8),
                  _buildDesignerDropdown(ref),
                  const SizedBox(width: 8),
                  _buildClientDropdown(ref),
                  const SizedBox(width: 8),
                  if (ref.watch(selectedTabProvider) != ProjectStatus.practice) ...[
                    _buildStatusDropdown(ref),
                    const SizedBox(width: 8),
                  ],
                  if (_hasActiveFilters(ref)) _buildClearButton(ref),
                ],
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSearchField(ref),
                if (isManager) ...[
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      _buildStrategistDropdown(ref),
                      _buildDesignerDropdown(ref),
                      _buildClientDropdown(ref),
                      if (ref.watch(selectedTabProvider) != ProjectStatus.practice)
                        _buildStatusDropdown(ref),
                      if (_hasActiveFilters(ref)) _buildClearButton(ref),
                    ],
                  ),
                ],
              ],
            ),
    );
  }

  Widget _buildSearchField(WidgetRef ref) {
    return SizedBox(
      height: 40,
      child: TextField(
        style: const TextStyle(color: AppColors.textPrimary, fontSize: 12),
        decoration: InputDecoration(
          hintText: 'Search by title...',
          hintStyle: const TextStyle(color: AppColors.textMuted),
          prefixIcon: const Icon(Icons.search, color: AppColors.textMuted, size: 20,),
          filled: true,
          fillColor: AppColors.inputBackground,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide.none,
          ),
        ),
        onChanged: (value) {
          ref.read(searchQueryProvider.notifier).state = value;
        },
      ),
    );
  }

  Widget _buildClearButton(WidgetRef ref) {
    return SizedBox(
      height: 40,
      child: TextButton.icon(
        onPressed: () {
          ref.read(searchQueryProvider.notifier).state = '';
          ref.read(selectedStrategistFilterProvider.notifier).state = null;
          ref.read(selectedDesignerFilterProvider.notifier).state = null;
          ref.read(selectedClientFilterProvider.notifier).state = null;
          ref.read(selectedStatusFilterProvider.notifier).state = null;
        },
        label: const Text('Clear', style: TextStyle(fontSize: 12),),
        style: TextButton.styleFrom(
          foregroundColor: AppColors.error,
        ),
      ),
    );
  }

  bool _hasActiveFilters(WidgetRef ref) {
    return ref.watch(selectedStrategistFilterProvider) != null ||
           ref.watch(selectedDesignerFilterProvider) != null ||
           ref.watch(selectedClientFilterProvider) != null ||
           ref.watch(selectedStatusFilterProvider) != null;
  }

  Widget _buildStrategistDropdown(WidgetRef ref) {
    final membersAsync = ref.watch(activeMembersProvider);
    final selectedValue = ref.watch(selectedStrategistFilterProvider);

    return Container(
      width: 105,
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.inputBackground,
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String?>(
          value: selectedValue,
          hint: const Text('Strategist', style: TextStyle(color: AppColors.textMuted)),
          dropdownColor: AppColors.surfaceElevated,
          isExpanded: true,
          icon: const Icon(Icons.arrow_drop_down, color: AppColors.textMuted),
          items: [
            const DropdownMenuItem(
              value: null,
              child: Text('Strategist', style: TextStyle(color: AppColors.textPrimary, fontSize: 12)),
            ),
            ...membersAsync.when(
              data: (users) => users.map((u) => DropdownMenuItem(
                value: u.uid,
                child: Text(u.displayName, style: const TextStyle(color: AppColors.textPrimary, fontSize: 12)),
              )).toList(),
              loading: () => [],
              error: (_, __) => [],
            ),
          ],
          onChanged: (val) {
            ref.read(selectedStrategistFilterProvider.notifier).state = val;
          },
        ),
      ),
    );
  }

  Widget _buildDesignerDropdown(WidgetRef ref) {
    final membersAsync = ref.watch(activeMembersProvider);
    final selectedValue = ref.watch(selectedDesignerFilterProvider);

    return Container(
      width: 105,
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.inputBackground,
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String?>(
          value: selectedValue,
          hint: const Text('Designer', style: TextStyle(color: AppColors.textMuted)),
          dropdownColor: AppColors.surfaceElevated,
          isExpanded: true,
          icon: const Icon(Icons.arrow_drop_down, color: AppColors.textMuted),
          items: [
            const DropdownMenuItem(
              value: null,
              child: Text('Designer', style: TextStyle(color: AppColors.textPrimary, fontSize: 12)),
            ),
            ...membersAsync.when(
              data: (users) => users.map((u) => DropdownMenuItem(
                value: u.uid,
                child: Text(u.displayName, style: const TextStyle(color: AppColors.textPrimary, fontSize: 12)),
              )).toList(),
              loading: () => [],
              error: (_, __) => [],
            ),
          ],
          onChanged: (val) {
            ref.read(selectedDesignerFilterProvider.notifier).state = val;
          },
        ),
      ),
    );
  }

  Widget _buildClientDropdown(WidgetRef ref) {
    final clientsAsync = ref.watch(clientsProvider);
    final selectedValue = ref.watch(selectedClientFilterProvider);

    return Container(
      width: 110,
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.inputBackground,
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String?>(
          value: selectedValue,
          hint: const Text('All Clients', style: TextStyle(color: AppColors.textMuted)),
          dropdownColor: AppColors.surfaceElevated,
          isExpanded: true,
          icon: const Icon(Icons.arrow_drop_down, color: AppColors.textMuted),
          items: [
            const DropdownMenuItem(
              value: null,
              child: Text('All Clients', style: TextStyle(color: AppColors.textPrimary, fontSize: 12)),
            ),
            ...clientsAsync.when(
              data: (clients) => clients.map((c) => DropdownMenuItem(
                value: c.id,
                child: Text(c.name, style: const TextStyle(color: AppColors.textPrimary, fontSize: 12)),
              )).toList(),
              loading: () => [],
              error: (_, __) => [],
            ),
          ],
          onChanged: (val) {
            ref.read(selectedClientFilterProvider.notifier).state = val;
          },
        ),
      ),
    );
  }

  Widget _buildStatusDropdown(WidgetRef ref) {
    final selectedTab = ref.watch(selectedTabProvider);
    final isCompleted = selectedTab == ProjectStatus.completed;
    
    final statuses = isCompleted
        ? ['All', 'Practice', 'Paid']
        : ['All Statuses', 'Queue', 'In Revision', 'Submitted', 'Needs Approval'];

    final selectedStatus = ref.watch(selectedStatusFilterProvider);
    final value = selectedStatus != null && statuses.contains(selectedStatus)
        ? selectedStatus
        : statuses.first;

    return Container(
      width: 120,
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.inputBackground,
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String?>(
          value: value,
          icon: const Icon(Icons.arrow_drop_down, color: AppColors.textMuted),
          dropdownColor: AppColors.surfaceElevated,
          isExpanded: true,
          onChanged: (String? newValue) {
            ref.read(selectedStatusFilterProvider.notifier).state = newValue;
          },
          items: statuses.map((status) {
            return DropdownMenuItem<String?>(
              value: status,
              child: Text(status, style: const TextStyle(color: AppColors.textPrimary, fontSize: 12)),
            );
          }).toList(),
        ),
      ),
    );
  }
}
