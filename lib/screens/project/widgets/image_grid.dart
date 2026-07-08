import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/full_screen_image.dart';

class ImageGrid extends StatelessWidget {
  final List<String> imageUrls;
  final List<MapEntry<String, Uint8List>> pendingUploads;
  final bool canEdit;
  final VoidCallback? onAddImages;
  final ValueChanged<int>? onRemoveUrl;
  final ValueChanged<int>? onRemovePending;

  const ImageGrid({
    super.key,
    required this.imageUrls,
    this.pendingUploads = const [],
    this.canEdit = false,
    this.onAddImages,
    this.onRemoveUrl,
    this.onRemovePending,
  });

  @override
  Widget build(BuildContext context) {
    final totalItems =
        imageUrls.length + pendingUploads.length + (canEdit ? 1 : 0);

    if (totalItems == 0) {
      return const SizedBox.shrink();
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        // Existing uploaded images
        ...List.generate(imageUrls.length, (index) {
          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => FullScreenImage(imageUrl: imageUrls[index]),
                ),
              );
            },
            child: _buildImageTile(
              child: CachedNetworkImage(
                imageUrl: imageUrls[index],
                fit: BoxFit.cover,
                placeholder: (context, url) => Shimmer.fromColors(
                  baseColor: AppColors.surfaceElevated,
                  highlightColor: AppColors.border,
                  child: Container(
                    width: double.infinity,
                    height: double.infinity,
                    color: Colors.white,
                  ),
                ),
                errorWidget: (context, url, error) => const Icon(
                  Icons.broken_image,
                  color: AppColors.textMuted,
                ),
              ),
              onRemove: canEdit ? () => onRemoveUrl?.call(index) : null,
            ),
          );
        }),

        // Pending uploads (local bytes)
        ...List.generate(pendingUploads.length, (index) {
          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => FullScreenImage(imageBytes: pendingUploads[index].value),
                ),
              );
            },
            child: _buildImageTile(
              child: Image.memory(
                pendingUploads[index].value,
                fit: BoxFit.cover,
              ),
              onRemove: () => onRemovePending?.call(index),
              isPending: true,
            ),
          );
        }),

        // Add button
        if (canEdit)
          GestureDetector(
            onTap: onAddImages,
            child: Container(
              width: 100,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.inputBackground,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppColors.border,
                  style: BorderStyle.solid,
                ),
              ),
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_photo_alternate_outlined,
                      color: AppColors.textMuted, size: 22),
                  SizedBox(height: 4),
                  Text(
                    'Add',
                    style:
                        TextStyle(color: AppColors.textMuted, fontSize: 11),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildImageTile({
    required Widget child,
    VoidCallback? onRemove,
    bool isPending = false,
  }) {
    return Stack(
      children: [
        Container(
          width: 100,
          height: 80,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.border),
          ),
          clipBehavior: Clip.antiAlias,
          child: child,
        ),

        if (onRemove != null)
          Positioned(
            top: 4,
            right: 4,
            child: GestureDetector(
              onTap: onRemove,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: const BoxDecoration(
                  color: AppColors.error,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, size: 12, color: AppColors.white),
              ),
            ),
          ),
      ],
    );
  }
}
