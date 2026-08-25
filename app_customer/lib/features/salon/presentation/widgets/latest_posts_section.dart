import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../posts/data/models/post_model.dart';

class LatestPostsSection extends StatelessWidget {
  const LatestPostsSection({
    required this.posts,
    required this.onPostTap,
    super.key,
  });

  final List<PostModel> posts;
  final ValueChanged<PostModel> onPostTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 205,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: posts.length,
        separatorBuilder: (_, index) => const SizedBox(width: 14),
        itemBuilder: (BuildContext context, int index) {
          final PostModel post = posts[index];

          return SizedBox(
            width: 220,
            child: _PostCard(post: post, onTap: () => onPostTap(post)),
          );
        },
      ),
    );
  }
}

class _PostCard extends StatelessWidget {
  const _PostCard({required this.post, required this.onTap});

  final PostModel post;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;

    final Color surfaceColor = isDark ? const Color(0xFF191919) : Colors.white;

    final String description = post.description?.trim() ?? '';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.zero,
        splashColor: AppColors.gold.withValues(alpha: 0.06),
        highlightColor: AppColors.gold.withValues(alpha: 0.025),
        child: Ink(
          decoration: BoxDecoration(
            color: surfaceColor,
            borderRadius: BorderRadius.zero,
            border: Border.all(
              color: AppColors.gold.withValues(alpha: isDark ? 0.38 : 0.28),
              width: 0.7,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.gold.withValues(alpha: isDark ? 0.045 : 0.025),
                blurRadius: 14,
                spreadRadius: 0,
                offset: const Offset(0, 4),
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.10 : 0.025),
                blurRadius: 12,
                spreadRadius: 0,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _PostImage(imageUrl: post.imageUrl, isDark: isDark),
              ),

              if (description.isNotEmpty)
                Container(
                  width: double.infinity,
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.035)
                      : Colors.black.withValues(alpha: 0.025),
                  padding: const EdgeInsets.fromLTRB(12, 9, 12, 10),
                  child: Text(
                    description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textDirection: TextDirection.rtl,
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      fontSize: 12.5,
                      height: 1.5,
                      fontWeight: FontWeight.w300,
                      letterSpacing: 0.15,
                      color: isDark
                          ? const Color(0xFFE5E5E5)
                          : const Color(0xFF444444),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PostImage extends StatelessWidget {
  const _PostImage({required this.imageUrl, required this.isDark});

  final String? imageUrl;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    if (imageUrl == null || imageUrl!.trim().isEmpty) {
      return ColoredBox(
        color: AppColors.gold.withValues(alpha: isDark ? 0.14 : 0.09),
        child: const Center(
          child: Icon(Icons.image_outlined, color: AppColors.gold, size: 30),
        ),
      );
    }

    return Image.network(
      imageUrl!,
      fit: BoxFit.cover,
      filterQuality: FilterQuality.high,
      loadingBuilder:
          (
            BuildContext context,
            Widget child,
            ImageChunkEvent? loadingProgress,
          ) {
            if (loadingProgress == null) {
              return child;
            }

            return const Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 1.5),
              ),
            );
          },
      errorBuilder:
          (BuildContext context, Object error, StackTrace? stackTrace) {
            return ColoredBox(
              color: AppColors.gold.withValues(alpha: isDark ? 0.14 : 0.09),
              child: const Center(
                child: Icon(
                  Icons.broken_image_outlined,
                  color: AppColors.gold,
                  size: 30,
                ),
              ),
            );
          },
    );
  }
}
