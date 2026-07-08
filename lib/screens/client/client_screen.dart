import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/custom_tab_bar.dart';
import '../../models/client_model.dart';
import '../../providers/client_provider.dart';
import '../../providers/auth_provider.dart';
import 'widgets/client_dialog.dart';
import 'widgets/add_revenue_dialog.dart';
import 'widgets/client_detail_sheet.dart';

class ClientScreen extends ConsumerWidget {
  const ClientScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final clientsAsync = ref.watch(filteredClientsProvider);
    final allClientsAsync = ref.watch(clientsProvider);
    final selectedTab = ref.watch(selectedClientTabProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
        title: const Text('Client Management'),
      ),
      body: Column(
        children: [
          // ─── Actions ───
          Padding(
            padding: const EdgeInsets.all(24.0).copyWith(bottom: 0),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (_) => const ClientDialog(),
                      );
                    },
                    icon: const Icon(Icons.person_add_rounded, color: AppColors.white),
                    label: const Text('Add Client', style: TextStyle(color: AppColors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (_) => const AddRevenueDialog(),
                      );
                    },
                    icon: const Icon(Icons.attach_money_rounded, color: AppColors.white),
                    label: const Text('Add Revenue', style: TextStyle(color: AppColors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.approved,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // ─── Tabs ───
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24).copyWith(top: 16),
            child: CustomTabBar(
              tabs: ClientStatus.values.map((s) {
                final count = allClientsAsync.value?.where((c) => c.status == s).length ?? 0;
                return '${s.label} ($count)';
              }).toList(),
              selectedIndex: ClientStatus.values.indexOf(selectedTab),
              onTap: (index) {
                ref.read(selectedClientTabProvider.notifier).state = ClientStatus.values[index];
              },
            ),
          ),

          
          // ─── Client List ───
          Expanded(
            child: clientsAsync.when(
        data: (clients) {
          if (clients.isEmpty) {
            return const Center(
              child: Text(
                'No clients found. Add one!',
                style: TextStyle(color: AppColors.textMuted),
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(24),
            itemCount: clients.length,
            itemBuilder: (context, index) {
              final client = clients[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                color: AppColors.surfaceElevated,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (context) => ClientDetailSheet(client: client),
                    );
                  },
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    title: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          client.name,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: _getStatusColor(client.status).withAlpha(30),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: _getStatusColor(client.status).withAlpha(100)),
                          ),
                          child: Text(
                            client.status.label,
                            style: TextStyle(
                              color: _getStatusColor(client.status),
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (client.country.isNotEmpty)
                            Text('Location: ${client.country}',
                                style: const TextStyle(color: AppColors.textSecondary)),
                          Text('Ticket Size: \$${client.averagePayout.toStringAsFixed(2)}',
                              style: const TextStyle(color: AppColors.textSecondary)),
                          const SizedBox(height: 4),
                          Text('Balance: \$${(client.totalPaid - client.totalWorked).toStringAsFixed(2)}',
                              style: TextStyle(
                                color: (client.totalPaid - client.totalWorked) >= 0 ? AppColors.approved : AppColors.error,
                                fontWeight: FontWeight.bold,
                              )),
                        ],
                      ),
                    ),
                    trailing: PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert, color: AppColors.textMuted),
                      color: AppColors.cardBackground,
                      onSelected: (value) {
                        if (value == 'edit') {
                          showDialog(
                            context: context,
                            builder: (_) => ClientDialog(client: client),
                          );
                        } else if (value == 'delete') {
                          _confirmDelete(context, ref, client.id, client.name);
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(Icons.edit, color: AppColors.textMuted, size: 20),
                              SizedBox(width: 8),
                              Text('Edit', style: TextStyle(color: AppColors.textPrimary)),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete, color: AppColors.error, size: 20),
                              SizedBox(width: 8),
                              Text('Delete', style: TextStyle(color: AppColors.error)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(ClientStatus status) {
    switch (status) {
      case ClientStatus.onTrack:
        return AppColors.approved;
      case ClientStatus.active:
        return AppColors.accent;
      case ClientStatus.offTrack:
        return AppColors.error;
    }
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref, String clientId, String name) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceElevated,
        title: const Text('Delete Client', style: TextStyle(color: AppColors.textPrimary)),
        content: Text('Are you sure you want to delete "$name"?', style: const TextStyle(color: AppColors.textPrimary)),
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
      final firestoreService = ref.read(firestoreServiceProvider);
      await firestoreService.deleteClient(clientId);
    }
  }
}
