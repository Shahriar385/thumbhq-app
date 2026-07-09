import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';

import '../../../core/theme/app_colors.dart';
import '../../../models/project_model.dart';

class CompletedProjectCard extends StatelessWidget {
  final ProjectModel project;

  const CompletedProjectCard({super.key, required this.project});

  @override
  Widget build(BuildContext context) {
    String? imageUrl;
    if (project.finalDesign.images.isNotEmpty) {
      imageUrl = project.finalDesign.images.first;
    } else if (project.brief.conceptImages.isNotEmpty) {
      imageUrl = project.brief.conceptImages.first;
    } else if (project.brief.referenceImages.isNotEmpty) {
      imageUrl = project.brief.referenceImages.first;
    } else if (project.videoDetails.images.isNotEmpty) {
      imageUrl = project.videoDetails.images.first;
    }

    return GestureDetector(
      onTap: () => context.push('/project/${project.id}'),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    project.title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      project.deadline != null
                          ? DateFormat('M/d/yyyy').format(project.deadline!)
                          : '',
                      style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.w500),
                    ),
                    if (project.clientName.isNotEmpty)
                      Text(
                        project.clientName,
                        style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                            fontWeight: FontWeight.w500),
                      ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: AppColors.surfaceElevated,
                ),
                child: imageUrl != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: CachedNetworkImage(
                          imageUrl: imageUrl,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Shimmer.fromColors(
                            baseColor: AppColors.surfaceElevated,
                            highlightColor: AppColors.border,
                            child: Container(color: Colors.white),
                          ),
                          errorWidget: (context, url, error) => const Center(
                            child: Icon(Icons.image_not_supported,
                                color: AppColors.textMuted),
                          ),
                        ),
                      )
                    : const Center(
                        child: Icon(Icons.image_not_supported,
                            color: AppColors.textMuted),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
