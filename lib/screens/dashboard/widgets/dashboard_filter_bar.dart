import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Wrap(
        spacing: 16,
        runSpacing: 16,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          // Project Title Search (Available to everyone)
          SizedBox(
            width: double.infinity,
            child: TextField(
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: InputDecoration(
                hintText: 'Search by title...',
                hintStyle: const TextStyle(color: AppColors.textMuted),
                prefixIcon: const Icon(Icons.search, color: AppColors.textMuted),
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
          ),
          
          if (isManager) ...[
            // Strategist Dropdown
            _buildStrategistDropdown(ref),
            
            // Designer Dropdown
            _buildDesignerDropdown(ref),
            
            // Client Dropdown
            _buildClientDropdown(ref),
            
            // Clear Filters Button
            if (_hasActiveFilters(ref))
              TextButton.icon(
                onPressed: () {
                  ref.read(searchQueryProvider.notifier).state = '';
                  ref.read(selectedStrategistFilterProvider.notifier).state = null;
                  ref.read(selectedDesignerFilterProvider.notifier).state = null;
                  ref.read(selectedClientFilterProvider.notifier).state = null;
                  ref.read(selectedStatusFilterProvider.notifier).state = null;
                },
                icon: const Icon(Icons.clear, size: 16),
                label: const Text('Clear Filters'),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.error,
                ),
              ),
          ],
        ],
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
      width: 180,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.inputBackground,
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String?>(
          value: selectedValue,
          hint: const Text('All Strategists', style: TextStyle(color: AppColors.textMuted)),
          dropdownColor: AppColors.surfaceElevated,
          isExpanded: true,
          icon: const Icon(Icons.arrow_drop_down, color: AppColors.textMuted),
          items: [
            const DropdownMenuItem(
              value: null,
              child: Text('All Strategists', style: TextStyle(color: AppColors.textPrimary)),
            ),
            ...membersAsync.when(
              data: (users) => users.map((u) => DropdownMenuItem(
                value: u.uid,
                child: Text(u.displayName, style: const TextStyle(color: AppColors.textPrimary)),
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
      width: 180,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.inputBackground,
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String?>(
          value: selectedValue,
          hint: const Text('All Designers', style: TextStyle(color: AppColors.textMuted)),
          dropdownColor: AppColors.surfaceElevated,
          isExpanded: true,
          icon: const Icon(Icons.arrow_drop_down, color: AppColors.textMuted),
          items: [
            const DropdownMenuItem(
              value: null,
              child: Text('All Designers', style: TextStyle(color: AppColors.textPrimary)),
            ),
            ...membersAsync.when(
              data: (users) => users.map((u) => DropdownMenuItem(
                value: u.uid,
                child: Text(u.displayName, style: const TextStyle(color: AppColors.textPrimary)),
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
      width: 180,
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
              child: Text('All Clients', style: TextStyle(color: AppColors.textPrimary)),
            ),
            ...clientsAsync.when(
              data: (clients) => clients.map((c) => DropdownMenuItem(
                value: c.id,
                child: Text(c.name, style: const TextStyle(color: AppColors.textPrimary)),
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
}
