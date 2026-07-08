import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';

class FullScreenImage extends StatelessWidget {
  final String? imageUrl;
  final Uint8List? imageBytes;

  const FullScreenImage({
    super.key,
    this.imageUrl,
    this.imageBytes,
  });

  Future<void> _downloadImage(BuildContext context) async {
    if (imageUrl != null) {
      final uri = Uri.parse(imageUrl!);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not download image')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          if (imageUrl != null)
            IconButton(
              icon: const Icon(Icons.download_rounded),
              tooltip: 'Download Image',
              onPressed: () => _downloadImage(context),
            ),
        ],
      ),
      extendBodyBehindAppBar: true,
      body: Center(
        child: InteractiveViewer(
          minScale: 0.5,
          maxScale: 4.0,
          child: imageUrl != null
              ? CachedNetworkImage(
                  imageUrl: imageUrl!,
                  placeholder: (context, url) => Shimmer.fromColors(
                    baseColor: Colors.grey[800]!,
                    highlightColor: Colors.grey[700]!,
                    child: Container(color: Colors.black),
                  ),
                  errorWidget: (context, url, error) => const Icon(
                    Icons.broken_image,
                    color: Colors.white54,
                    size: 50,
                  ),
                )
              : imageBytes != null
                  ? Image.memory(imageBytes!)
                  : const SizedBox(),
        ),
      ),
    );
  }
}
