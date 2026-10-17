import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:kaamfast/core/theme/app_theme.dart';
import 'package:kaamfast/l10n/l10n_ext.dart';
import 'package:kaamfast/models/marketplace.dart';

class MarketplacePostCard extends StatelessWidget {
  const MarketplacePostCard({
    super.key,
    required this.post,
    required this.onTap,
    this.compact = false,
  });

  final MarketplacePost post;
  final VoidCallback onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final cover = post.coverUrl?.trim();
    final width = compact ? 148.0 : double.infinity;
    final category = post.category?.trim();
    final location = post.locationLabel;
    final placeholder = Container(
      color: const Color(0xFFEAF1FC),
      child: Icon(
        post.isRequest ? Icons.search_rounded : Icons.image_outlined,
        color: AppColors.navy.withValues(alpha: 0.35),
        size: 36,
      ),
    );
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Ink(
          width: width,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.line),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8, offset: const Offset(0, 3)),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AspectRatio(
                aspectRatio: compact ? 1.1 : 1.35,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (cover == null || cover.isEmpty)
                      placeholder
                    else
                      CachedNetworkImage(
                        imageUrl: cover,
                        fit: BoxFit.cover,
                        errorWidget: (_, _, _) => placeholder,
                      ),
                    if (category != null && category.isNotEmpty)
                      Positioned(
                        left: 8,
                        top: 8,
                        right: 8,
                        child: Align(
                          alignment: Alignment.topLeft,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.navy.withValues(alpha: 0.85),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              category,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(
                  compact ? 10 : 12,
                  10,
                  compact ? 10 : 12,
                  compact ? 10 : 12,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      post.title,
                      maxLines: compact ? 2 : 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: AppColors.navy,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      post.priceLabel,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        color: AppColors.accentOrange,
                        fontSize: 14,
                      ),
                    ),
                    if (location.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.location_on_outlined, size: 13, color: AppColors.muted),
                          const SizedBox(width: 2),
                          Expanded(
                            child: Text(
                              location,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: AppColors.muted, fontSize: 11.5),
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (!compact && post.status != 'active') ...[
                      const SizedBox(height: 6),
                      _StatusChip(status: post.status),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class MarketplaceHomeStrip extends StatelessWidget {
  const MarketplaceHomeStrip({
    super.key,
    required this.title,
    required this.posts,
    required this.onSeeAll,
    required this.onTapPost,
  });

  final String title;
  final List<MarketplacePost> posts;
  final VoidCallback onSeeAll;
  final ValueChanged<MarketplacePost> onTapPost;

  @override
  Widget build(BuildContext context) {
    if (posts.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: AppColors.navy,
                ),
              ),
            ),
            TextButton(
              onPressed: onSeeAll,
              child: Text(
                context.l10n.seeAll,
                style: const TextStyle(
                  color: AppColors.lavenderText,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 220,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: posts.length,
            separatorBuilder: (_, _) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              final post = posts[index];
              return MarketplacePostCard(
                post: post,
                compact: true,
                onTap: () => onTapPost(post),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.mist,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        status.replaceAll('_', ' ').toUpperCase(),
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: AppColors.muted,
        ),
      ),
    );
  }
}
