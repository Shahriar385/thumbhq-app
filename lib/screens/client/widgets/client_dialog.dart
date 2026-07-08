import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/theme/app_colors.dart';
import '../../../models/client_model.dart';
import '../../../providers/auth_provider.dart';

class ClientDialog extends ConsumerStatefulWidget {
  final ClientModel? client;

  const ClientDialog({super.key, this.client});

  @override
  ConsumerState<ClientDialog> createState() => _ClientDialogState();
}

class _ClientDialogState extends ConsumerState<ClientDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _countryController;
  late final TextEditingController _ytChannelController;
  late final TextEditingController _payoutController;
  late final TextEditingController _emailController;
  late final TextEditingController _retainerController;
  String? _acquisitionMethod;
  late DateTime _onboardingDate;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.client?.name ?? '');
    _countryController = TextEditingController(text: widget.client?.country ?? '');
    _ytChannelController = TextEditingController(text: widget.client?.ytChannelName ?? '');
    _payoutController = TextEditingController(text: widget.client?.averagePayout.toString() ?? '');
    _emailController = TextEditingController(text: widget.client?.email ?? '');
    _retainerController = TextEditingController(text: widget.client?.monthlyRetainer.toString() ?? '');
    
    // Set initial acquisition method if it matches one of the options
    final currentMethod = widget.client?.acquisitionMethod;
    const validMethods = ['X', 'email', 'referral', 'scraping', 'insta', 'ads'];
    _acquisitionMethod = validMethods.contains(currentMethod) ? currentMethod : null;
    
    _onboardingDate = widget.client?.onboardingDate ?? DateTime.now();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _countryController.dispose();
    _ytChannelController.dispose();
    _payoutController.dispose();
    _emailController.dispose();
    _retainerController.dispose();
    super.dispose();
  }

  Future<void> _pickOnboardingDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _onboardingDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
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
      setState(() => _onboardingDate = date);
    }
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    setState(() => _isSaving = true);
    try {
      final firestoreService = ref.read(firestoreServiceProvider);
      
      final clientData = {
        'name': name,
        'country': _countryController.text.trim(),
        'ytChannelName': _ytChannelController.text.trim(),
        'averagePayout': double.tryParse(_payoutController.text.trim()) ?? 0.0,
        'email': _emailController.text.trim(),
        'acquisitionMethod': _acquisitionMethod ?? '',
        'monthlyRetainer': double.tryParse(_retainerController.text.trim()) ?? 0.0,
        'onboardingDate': Timestamp.fromDate(_onboardingDate),
      };

      if (widget.client == null) {
        // Create
        final newClient = ClientModel(
          id: '',
          name: clientData['name'] as String,
          country: clientData['country'] as String,
          ytChannelName: clientData['ytChannelName'] as String,
          averagePayout: clientData['averagePayout'] as double,
          email: clientData['email'] as String,
          acquisitionMethod: clientData['acquisitionMethod'] as String,
          monthlyRetainer: clientData['monthlyRetainer'] as double,
          onboardingDate: _onboardingDate,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        await firestoreService.createClient(newClient);
      } else {
        // Update
        await firestoreService.updateClient(widget.client!.id, clientData);
      }

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
      child: Container(
        width: 400,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.client == null ? 'Add Client' : 'Edit Client',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, color: AppColors.textMuted),
                  splashRadius: 20,
                ),
              ],
            ),
            const SizedBox(height: 24),
            
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Name
                    const Text(
                      'Client Name',
                      style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                          fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _nameController,
                      style: const TextStyle(color: AppColors.textPrimary),
                      decoration: const InputDecoration(hintText: 'e.g. MrBeast'),
                    ),
                    const SizedBox(height: 16),

                    // Country
                    const Text(
                      'Location (Country)',
                      style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                          fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _countryController,
                      style: const TextStyle(color: AppColors.textPrimary),
                      decoration: const InputDecoration(hintText: 'e.g. USA'),
                    ),
                    const SizedBox(height: 16),
                    
                    // Email
                    const Text(
                      'Email',
                      style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                          fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _emailController,
                      style: const TextStyle(color: AppColors.textPrimary),
                      decoration: const InputDecoration(hintText: 'e.g. contact@mrbeast.com'),
                    ),
                    const SizedBox(height: 16),

                    // YT Channel
                    const Text(
                      'YouTube Channel Name',
                      style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                          fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _ytChannelController,
                      style: const TextStyle(color: AppColors.textPrimary),
                      decoration: const InputDecoration(hintText: 'Channel name'),
                    ),
                    const SizedBox(height: 16),
                    
                    // Acquisition Method
                    const Text(
                      'Acquisition Method',
                      style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                          fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      initialValue: _acquisitionMethod,
                      decoration: const InputDecoration(hintText: 'Select Acquisition Method'),
                      dropdownColor: AppColors.surfaceElevated,
                      items: const [
                        DropdownMenuItem(value: 'X', child: Text('X', style: TextStyle(color: AppColors.textPrimary))),
                        DropdownMenuItem(value: 'email', child: Text('Email', style: TextStyle(color: AppColors.textPrimary))),
                        DropdownMenuItem(value: 'referral', child: Text('Referral', style: TextStyle(color: AppColors.textPrimary))),
                        DropdownMenuItem(value: 'scraping', child: Text('Scraping', style: TextStyle(color: AppColors.textPrimary))),
                        DropdownMenuItem(value: 'insta', child: Text('Instagram', style: TextStyle(color: AppColors.textPrimary))),
                        DropdownMenuItem(value: 'ads', child: Text('Ads', style: TextStyle(color: AppColors.textPrimary))),
                      ],
                      onChanged: (val) {
                        setState(() {
                          _acquisitionMethod = val;
                        });
                      },
                    ),
                    const SizedBox(height: 16),

                    Row(
                      children: [
                        // Ticket Size
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Ticket Size',
                                style: TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500),
                              ),
                              const SizedBox(height: 6),
                              TextField(
                                controller: _payoutController,
                                keyboardType: TextInputType.number,
                                style: const TextStyle(color: AppColors.textPrimary),
                                decoration: const InputDecoration(hintText: 'e.g. 500.00'),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        // Monthly Retainer
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Monthly Retainer',
                                style: TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500),
                              ),
                              const SizedBox(height: 6),
                              TextField(
                                controller: _retainerController,
                                keyboardType: TextInputType.number,
                                style: const TextStyle(color: AppColors.textPrimary),
                                decoration: const InputDecoration(hintText: 'e.g. 2000.00'),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Onboarding Date
                    const Text(
                      'Onboarding Date',
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 6),
                    InkWell(
                      onTap: _pickOnboardingDate,
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
                              DateFormat.yMMMd().format(_onboardingDate),
                              style: const TextStyle(color: AppColors.textPrimary, fontSize: 16),
                            ),
                            const Icon(Icons.calendar_today, color: AppColors.textMuted, size: 20),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Save button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
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
                        'Save Client',
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
