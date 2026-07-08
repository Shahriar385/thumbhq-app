import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import 'image_grid.dart';

class SectionEditor extends StatelessWidget {
  final String title;
  final bool canEdit;

  // Text fields
  final TextEditingController? titleController;
  final String? titleHint;
  final TextEditingController? contentController;
  final String? contentHint;
  final int contentMaxLines;

  // Images
  final List<String> imageUrls;
  final List<MapEntry<String, Uint8List>> pendingUploads;
  final VoidCallback? onAddImages;
  final ValueChanged<int>? onRemoveUrl;
  final ValueChanged<int>? onRemovePending;

  const SectionEditor({
    super.key,
    required this.title,
    this.canEdit = false,
    this.titleController,
    this.titleHint,
    this.contentController,
    this.contentHint,
    this.contentMaxLines = 5,
    this.imageUrls = const [],
    this.pendingUploads = const [],
    this.onAddImages,
    this.onRemoveUrl,
    this.onRemovePending,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.inputBackground,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title field
              if (titleController != null) ...[
                TextField(
                  controller: titleController,
                  enabled: canEdit,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                  decoration: InputDecoration(
                    hintText: titleHint ?? 'Title',
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 8),
                    isDense: true,
                    filled: false,
                  ),
                ),
                const SizedBox(height: 8),
              ],

              // Content field
              if (contentController != null) ...[
                TextField(
                  controller: contentController,
                  enabled: canEdit,
                  maxLines: contentMaxLines,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                    height: 1.6,
                  ),
                  decoration: InputDecoration(
                    hintText: contentHint ?? 'Enter details...',
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 8),
                    isDense: true,
                    filled: false,
                  ),
                ),
                const SizedBox(height: 12),
              ],

              // Images
              ImageGrid(
                imageUrls: imageUrls,
                pendingUploads: pendingUploads,
                canEdit: canEdit,
                onAddImages: onAddImages,
                onRemoveUrl: onRemoveUrl,
                onRemovePending: onRemovePending,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
