import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../models/revenue_model.dart';
import '../../../../providers/client_provider.dart';
import '../../../../providers/auth_provider.dart';

class AddRevenueDialog extends ConsumerStatefulWidget {
  const AddRevenueDialog({super.key});

  @override
  ConsumerState<AddRevenueDialog> createState() => _AddRevenueDialogState();
}

class _AddRevenueDialogState extends ConsumerState<AddRevenueDialog> {
  String? _selectedClientId;
  DateTime _selectedDate = DateTime.now();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  bool _isSaving = false;

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
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

    if (date != null && mounted) {
      setState(() => _selectedDate = date);
    }
  }

  Future<void> _save() async {
    if (_selectedClientId == null) return;
    final amount = double.tryParse(_amountController.text.trim());
    if (amount == null || amount <= 0) return;

    setState(() => _isSaving = true);
    try {
      final firestoreService = ref.read(firestoreServiceProvider);
      
      final revenue = RevenueModel(
        id: '',
        clientId: _selectedClientId!,
        amount: amount,
        date: _selectedDate,
        note: _noteController.text.trim(),
        createdAt: DateTime.now(),
      );

      await firestoreService.addRevenue(revenue);

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.cardBackground,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 400,
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Add Revenue',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, color: AppColors.textMuted),
                ),
              ],
            ),
            const SizedBox(height: 24),
            
            // Client Dropdown
            const Text(
              'Client',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 6),
            Consumer(
              builder: (context, ref, child) {
                final clientsAsync = ref.watch(clientsProvider);
                return clientsAsync.when(
                  data: (clients) {
                    if (clients.isEmpty) {
                      return const Text('No clients available.', style: TextStyle(color: AppColors.textMuted));
                    }
                    return DropdownButtonFormField<String>(
                      value: _selectedClientId,
                      decoration: const InputDecoration(hintText: 'Select Client'),
                      dropdownColor: AppColors.surfaceElevated,
                      items: clients.map((client) {
                        return DropdownMenuItem(
                          value: client.id,
                          child: Text(client.name, style: const TextStyle(color: AppColors.textPrimary)),
                        );
                      }).toList(),
                      onChanged: (val) => setState(() => _selectedClientId = val),
                    );
                  },
                  loading: () => const CircularProgressIndicator(),
                  error: (_, __) => const Text('Error loading clients'),
                );
              },
            ),
            const SizedBox(height: 16),

            // Date Picker
            const Text(
              'Date',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 6),
            InkWell(
              onTap: _pickDate,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: BoxDecoration(
                  color: AppColors.inputBackground,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      DateFormat.yMMMd().format(_selectedDate),
                      style: const TextStyle(color: AppColors.textPrimary, fontSize: 16),
                    ),
                    const Icon(Icons.calendar_today, color: AppColors.textMuted, size: 20),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Amount
            const Text(
              'Amount (\$)',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: const InputDecoration(hintText: 'e.g. 1500.00'),
            ),
            const SizedBox(height: 16),

            // Note
            const Text(
              'Note (Optional)',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _noteController,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: const InputDecoration(hintText: 'Brief description'),
            ),
            const SizedBox(height: 32),

            // Save Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.approved,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.white,
                        ),
                      )
                    : const Text(
                        'Add Revenue',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.white,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
