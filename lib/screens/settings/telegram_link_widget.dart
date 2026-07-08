import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/app_colors.dart';
import '../../providers/auth_provider.dart';

/// Bot username (without @)
const _botUsername = 'thumbhq_bot';

class TelegramLinkWidget extends ConsumerWidget {
  const TelegramLinkWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);

    return userAsync.when(
      data: (user) {
        if (user == null) return const SizedBox.shrink();
        final isLinked = user.telegramChatId != null &&
            user.telegramChatId!.isNotEmpty;

        // Hide the widget once linked — no need to show it anymore
        if (isLinked) return const SizedBox.shrink();

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isLinked
                  ? const Color(0xFF27AE60).withValues(alpha: 0.4)
                  : AppColors.border,
            ),
          ),
          child: Row(
            children: [
              // Telegram icon
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFF229ED9).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.telegram,
                  color: Color(0xFF229ED9),
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),

              // Text
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Telegram Notifications',
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isLinked
                          ? '✅ Connected — you\'ll receive notifications'
                          : 'Not linked — tap to connect your Telegram',
                      style: TextStyle(
                        color: isLinked
                            ? const Color(0xFF27AE60)
                            : AppColors.textMuted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),

              // Action button
              if (isLinked)
                TextButton(
                  onPressed: () => _unlink(context, ref, user.uid),
                  child: const Text(
                    'Unlink',
                    style: TextStyle(color: AppColors.error, fontSize: 12),
                  ),
                )
              else
                ElevatedButton.icon(
                  onPressed: () => _openTelegramLink(user.uid),
                  icon: const Icon(Icons.link, size: 16),
                  label: const Text('Link'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF229ED9),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    textStyle: const TextStyle(fontSize: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  /// Opens the Telegram bot with the user's UID as a deep-link parameter.
  Future<void> _openTelegramLink(String uid) async {
    final uri = Uri.parse('https://t.me/$_botUsername?start=$uid');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  /// Removes the telegramChatId from Firestore.
  Future<void> _unlink(
      BuildContext context, WidgetRef ref, String uid) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceElevated,
        title: const Text('Unlink Telegram',
            style: TextStyle(color: AppColors.textPrimary)),
        content: const Text(
          'You will no longer receive Telegram notifications. Are you sure?',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Unlink'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final firestoreService = ref.read(firestoreServiceProvider);
      await firestoreService.updateTelegramChatId(uid, null);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Telegram unlinked.')),
        );
      }
    }
  }
}
