import 'package:flutter/material.dart';

import '../../core/constants/app_constants.dart';
import '../theme/app_colors.dart';

class RoleBadge extends StatelessWidget {
  final UserRole role;

  const RoleBadge({super.key, required this.role});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _getColor().withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        role.label,
        style: TextStyle(
          color: _getColor(),
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Color _getColor() {
    switch (role) {
      case UserRole.manager:
        return AppColors.accent;
      case UserRole.strategist:
        return AppColors.ongoing;
      case UserRole.leadDesigner:
        return AppColors.approved;
      case UserRole.coreDesigner:
        return const Color(0xFF5dade2);
      case UserRole.juniorDesigner:
        return const Color(0xFF48c9b0);
      case UserRole.pending:
        return AppColors.textMuted;
      case UserRole.kamla:
        return AppColors.error;
    }
  }
}
