import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class UserAvatar extends StatefulWidget {
  final String photoURL;
  final String displayName;
  final double radius;

  const UserAvatar({
    super.key,
    required this.photoURL,
    required this.displayName,
    this.radius = 20.0,
  });

  @override
  State<UserAvatar> createState() => _UserAvatarState();
}

class _UserAvatarState extends State<UserAvatar> {
  bool _hasError = false;

  @override
  Widget build(BuildContext context) {
    final hasValidUrl = widget.photoURL.isNotEmpty && !_hasError;

    return CircleAvatar(
      radius: widget.radius,
      backgroundColor: AppColors.surfaceElevated,
      backgroundImage: hasValidUrl ? NetworkImage(widget.photoURL) : null,
      onBackgroundImageError: hasValidUrl
          ? (exception, stackTrace) {
              if (mounted) {
                setState(() => _hasError = true);
              }
            }
          : null,
      child: !hasValidUrl
          ? Text(
              widget.displayName.isNotEmpty
                  ? widget.displayName[0].toUpperCase()
                  : '?',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: widget.radius * 0.8,
                fontWeight: FontWeight.w600,
              ),
            )
          : null,
    );
  }
}
