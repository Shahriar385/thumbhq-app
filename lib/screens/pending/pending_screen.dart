import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../services/auth_service.dart';

class PendingScreen extends ConsumerWidget {
  const PendingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider).value;

    return Scaffold(
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 420),
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppColors.ongoing.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  Icons.hourglass_top_rounded,
                  color: AppColors.ongoing,
                  size: 40,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Account Pending',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Hi ${currentUser?.displayName ?? ''}! Your account is pending approval. A manager will assign your role shortly.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 36),
              TextButton.icon(
                onPressed: () {
                  ref.read(authServiceProvider).signOut();
                },
                icon: const Icon(Icons.logout_rounded, size: 18),
                label: const Text('Sign out'),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
