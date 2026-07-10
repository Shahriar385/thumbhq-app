import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../models/commission_settings_model.dart';
import '../../../providers/auth_provider.dart';

class CommissionSettingsDialog extends ConsumerStatefulWidget {
  const CommissionSettingsDialog({super.key});

  @override
  ConsumerState<CommissionSettingsDialog> createState() => _CommissionSettingsDialogState();
}

class _CommissionSettingsDialogState extends ConsumerState<CommissionSettingsDialog> {
  final _strategistController = TextEditingController();
  final _managerController = TextEditingController();
  final _leadController = TextEditingController();
  final _coreController = TextEditingController();
  final _juniorController = TextEditingController();
  
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final firestoreService = ref.read(firestoreServiceProvider);
      final settings = await firestoreService.getCommissionSettings();
      _strategistController.text = settings.strategistFee.toString();
      _managerController.text = settings.managerFee.toString();
      _leadController.text = settings.leadDesignerFee.toString();
      _coreController.text = settings.coreDesignerFee.toString();
      _juniorController.text = settings.juniorDesignerFee.toString();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load settings: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _strategistController.dispose();
    _managerController.dispose();
    _leadController.dispose();
    _coreController.dispose();
    _juniorController.dispose();
    super.dispose();
  }

  Future<void> _saveSettings() async {
    setState(() => _isSaving = true);
    try {
      final firestoreService = ref.read(firestoreServiceProvider);
      
      final settings = CommissionSettingsModel(
        strategistFee: double.tryParse(_strategistController.text.trim()) ?? 5.0,
        managerFee: double.tryParse(_managerController.text.trim()) ?? 15.0,
        leadDesignerFee: double.tryParse(_leadController.text.trim()) ?? 15.0,
        coreDesignerFee: double.tryParse(_coreController.text.trim()) ?? 10.0,
        juniorDesignerFee: double.tryParse(_juniorController.text.trim()) ?? 5.0,
      );

      await firestoreService.updateCommissionSettings(settings);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Commission settings saved successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save settings: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Widget _buildField(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: const TextStyle(color: AppColors.textPrimary),
            decoration: const InputDecoration(hintText: 'e.g. 15.00'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.cardBackground,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 400,
        padding: const EdgeInsets.all(28),
        child: _isLoading 
          ? const SizedBox(height: 100, child: Center(child: CircularProgressIndicator()))
          : Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Commission Settings',
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
            
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    _buildField('Strategist Fee (\$)', _strategistController),
                    _buildField('Manager Designer Fee (\$)', _managerController),
                    _buildField('Lead Designer Fee (\$)', _leadController),
                    _buildField('Core Designer Fee (\$)', _coreController),
                    _buildField('Junior Designer Fee (\$)', _juniorController),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _saveSettings,
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
                        'Save Settings',
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
