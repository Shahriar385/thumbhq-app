import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

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
  @override
  Widget build(BuildContext context) {
    final hasValidUrl = widget.photoURL.isNotEmpty;
    final fallbackWidget = Text(
      widget.displayName.isNotEmpty
          ? widget.displayName[0].toUpperCase()
          : '?',
      style: TextStyle(
        color: AppColors.textPrimary,
        fontSize: widget.radius * 0.8,
        fontWeight: FontWeight.w600,
      ),
    );

    return Container(
      width: widget.radius * 2,
      height: widget.radius * 2,
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        shape: BoxShape.circle,
      ),
      child: hasValidUrl
          ? ClipOval(
              child: CachedNetworkImage(
                imageUrl: widget.photoURL,
                fit: BoxFit.cover,
                memCacheWidth: (widget.radius * 3).toInt(), // Optimize memory
                fadeInDuration: const Duration(milliseconds: 200),
                placeholder: (context, url) => Center(child: fallbackWidget),
                errorWidget: (context, url, error) => Center(child: fallbackWidget),
              ),
            )
          : Center(child: fallbackWidget),
    );
  }
}
