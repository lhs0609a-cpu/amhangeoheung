import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../core/theme/hwahae_colors.dart';

/// Real content photos retain a stable layout while loading or unavailable.
class ContentImage extends StatelessWidget {
  /// Uploaded business photos use {url, caption}; older records use strings.
  static String? firstUrl(dynamic images) {
    if (images is! List) return null;
    for (final image in images) {
      final candidate = image is String
          ? image
          : image is Map
              ? image['url']
              : null;
      if (candidate is String && candidate.trim().isNotEmpty) return candidate;
    }
    return null;
  }

  final String? url;
  final String label;
  final double width;
  final double height;
  final IconData icon;

  const ContentImage({
    super.key,
    this.url,
    required this.label,
    this.width = 80,
    this.height = 80,
    this.icon = Icons.storefront_outlined,
  });

  @override
  Widget build(BuildContext context) {
    final placeholder = ColoredBox(
      color: HwahaeColors.primaryContainer,
      child: Center(child: Icon(icon, color: HwahaeColors.primary, size: 28)),
    );
    return Semantics(
      image: true,
      label: label,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          width: width,
          height: height,
          child: url == null || url!.trim().isEmpty
              ? placeholder
              : CachedNetworkImage(
                  imageUrl: url!,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => placeholder,
                  errorWidget: (_, __, ___) => placeholder,
                ),
        ),
      ),
    );
  }
}
