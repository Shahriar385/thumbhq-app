import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class StatusBadge extends StatelessWidget {
  final String label;
  final Color? color;

  const StatusBadge({
    super.key,
    required this.label,
    this.color,
  });

  factory StatusBadge.submitted() => const StatusBadge(
        label: 'Submitted',
        color: AppColors.submitted,
      );

  factory StatusBadge.assigned() => const StatusBadge(
        label: 'Assigned',
        color: AppColors.assigned,
      );

  factory StatusBadge.approved() => const StatusBadge(
        label: 'Approved',
        color: AppColors.approved,
      );

  factory StatusBadge.ongoing() => const StatusBadge(
        label: 'Ongoing',
        color: AppColors.ongoing,
      );

  factory StatusBadge.needsApproval() => const StatusBadge(
        label: 'Needs Approval',
        color: AppColors.ongoing,
      );

  @override
  Widget build(BuildContext context) {
    final badgeColor = color ?? AppColors.assigned;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: badgeColor, width: 1),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: badgeColor,
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
