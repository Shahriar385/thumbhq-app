import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../models/client_model.dart';
import '../../../../providers/auth_provider.dart';

class ClientDetailSheet extends ConsumerStatefulWidget {
  final ClientModel client;

  const ClientDetailSheet({super.key, required this.client});

  @override
  ConsumerState<ClientDetailSheet> createState() => _ClientDetailSheetState();
}

class _ClientDetailSheetState extends ConsumerState<ClientDetailSheet> {
  late ClientStatus _status;
  late DateTime? _endDate;
  late TextEditingController _noteController;

  @override
  void initState() {
    super.initState();
    _status = widget.client.status;
    _endDate = widget.client.endDate;
    _noteController = TextEditingController(text: widget.client.note);
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _updateClient(Map<String, dynamic> updates) async {
    try {
      final firestoreService = ref.read(firestoreServiceProvider);
      await firestoreService.updateClient(widget.client.id, updates);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update: $e')),
        );
      }
    }
  }

  Future<void> _pickEndDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _endDate ?? DateTime.now(),
      firstDate: DateTime(2020),
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

    if (date != null) {
      setState(() => _endDate = date);
      await _updateClient({'endDate': date});
    }
  }

  int _calculateRetentionDays() {
    final end = _endDate ?? DateTime.now();
    return end.difference(widget.client.onboardingDate).inDays;
  }

  @override
  Widget build(BuildContext context) {
    final retentionDays = _calculateRetentionDays();
    final balance = widget.client.totalPaid - widget.client.totalWorked;
    final thumbBalance = widget.client.averagePayout > 0
        ? balance / widget.client.averagePayout
        : 0.0;

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 48,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 24),
          
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                widget.client.name,
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
              DropdownButton<ClientStatus>(
                value: _status,
                dropdownColor: AppColors.surfaceElevated,
                underline: const SizedBox(),
                items: ClientStatus.values.map((status) {
                  return DropdownMenuItem(
                    value: status,
                    child: Text(
                      status.label,
                      style: TextStyle(
                        color: _getStatusColor(status),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) {
                    setState(() => _status = val);
                    _updateClient({'status': val.name});
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 24),

          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Dates section
                  _buildSectionHeader('Timeline'),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildInfoCard(
                          'Onboarding Date',
                          DateFormat.yMMMd().format(widget.client.onboardingDate),
                          Icons.flight_takeoff,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: GestureDetector(
                          onTap: _pickEndDate,
                          child: _buildInfoCard(
                            'End Date',
                            _endDate != null ? DateFormat.yMMMd().format(_endDate!) : 'Set Date',
                            Icons.flight_land,
                            isEditable: true,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildInfoCard(
                    'Client Retention',
                    '$retentionDays Days',
                    Icons.history_toggle_off,
                  ),
                  
                  const SizedBox(height: 32),
                  _buildSectionHeader('Financials'),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildInfoCard(
                          'Total Paid',
                          '\$${widget.client.totalPaid.toStringAsFixed(2)}',
                          Icons.account_balance_wallet,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildInfoCard(
                          'Total Worked',
                          '\$${widget.client.totalWorked.toStringAsFixed(2)}',
                          Icons.work,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildInfoCard(
                          'Balance',
                          '\$${balance.toStringAsFixed(2)}',
                          Icons.compare_arrows,
                          valueColor: balance >= 0 ? AppColors.approved : AppColors.error,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildInfoCard(
                          'Thumbnail Balance',
                          '${thumbBalance.toStringAsFixed(1)} units',
                          Icons.image,
                          valueColor: thumbBalance >= 0 ? AppColors.approved : AppColors.error,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),
                  _buildSectionHeader('Notes'),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _noteController,
                    maxLines: 4,
                    style: const TextStyle(color: AppColors.textPrimary),
                    decoration: InputDecoration(
                      hintText: 'Add a note about this client...',
                      fillColor: AppColors.inputBackground,
                      filled: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onChanged: (val) {
                      // Basic debounce could be added here, or save on unfocus.
                      // For now, save immediately.
                      _updateClient({'note': val});
                    },
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: AppColors.textSecondary,
      ),
    );
  }

  Widget _buildInfoCard(String title, String value, IconData icon, {Color? valueColor, bool isEditable = false}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(16),
        border: isEditable ? Border.all(color: AppColors.accent.withAlpha(50)) : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: AppColors.textMuted),
              const SizedBox(width: 6),
              Text(
                title,
                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: valueColor ?? AppColors.textPrimary,
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
}
