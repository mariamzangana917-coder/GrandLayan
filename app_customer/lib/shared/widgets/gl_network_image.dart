import 'package:flutter/material.dart';

class GlNetworkImage extends StatelessWidget {
  const GlNetworkImage({
    super.key,
    required this.imageUrl,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.height,
    this.width,
  });

  final String? imageUrl;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final double? height;
  final double? width;

  @override
  Widget build(BuildContext context) {
    final child = imageUrl == null || imageUrl!.trim().isEmpty
        ? _placeholder()
        : Image.network(
            imageUrl!,
            fit: fit,
            height: height,
            width: width,
            errorBuilder:
                (BuildContext context, Object error, StackTrace? stackTrace) {
                  return _placeholder();
                },
            loadingBuilder: (context, child, progress) {
              if (progress == null) {
                return child;
              }

              return Container(
                height: height,
                width: width,
                alignment: Alignment.center,
                child: const CircularProgressIndicator(),
              );
            },
          );

    if (borderRadius == null) {
      return child;
    }

    return ClipRRect(borderRadius: borderRadius!, child: child);
  }

  Widget _placeholder() {
    return Container(
      height: height,
      width: width,
      color: const Color(0xFFF4F0E8),
      alignment: Alignment.center,
      child: const Icon(
        Icons.image_outlined,
        size: 36,
        color: Color(0xFFC9A227),
      ),
    );
  }
}
