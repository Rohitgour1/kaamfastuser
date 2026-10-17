import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:kaamfast/core/theme/app_theme.dart';
import 'package:kaamfast/l10n/l10n_ext.dart';
import 'package:kaamfast/models/marketplace.dart';
import 'package:kaamfast/services/api_services.dart';
import 'package:provider/provider.dart';

class MarketplacePostDetailScreen extends StatefulWidget {
  const MarketplacePostDetailScreen({super.key, required this.postId});

  final int postId;

  @override
  State<MarketplacePostDetailScreen> createState() =>
      _MarketplacePostDetailScreenState();
}

class _MarketplacePostDetailScreenState
    extends State<MarketplacePostDetailScreen> {
  MarketplacePost? _post;
  MarketplaceConfig? _config;
  bool _loading = true;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final api = context.read<MarketplaceApi>();
      final results = await Future.wait([
        api.show(widget.postId),
        api.config(),
      ]);
      if (!mounted) return;
      setState(() {
        _post = results[0] as MarketplacePost;
        _config = results[1] as MarketplaceConfig;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = '$e';
      });
    }
  }

  Future<void> _startChat() async {
    final post = _post;
    if (post == null) return;
    setState(() => _busy = true);
    try {
      final chat = await context.read<MarketplaceApi>().startChat(post.id);
      if (!mounted) return;
      context.push('/marketplace/chats/${chat.id}');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _changeStatus(String status) async {
    final post = _post;
    if (post == null) return;
    setState(() => _busy = true);
    try {
      final updated =
          await context.read<MarketplaceApi>().updateStatus(post.id, status);
      if (!mounted) return;
      setState(() => _post = updated);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Marked as $status')),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _deleteImage(MarketplaceImage image) async {
    final post = _post;
    if (post == null) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete image?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    setState(() => _busy = true);
    try {
      await context.read<MarketplaceApi>().deleteImage(post.id, image.id);
      await _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final post = _post;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          post?.isRequest == true
              ? context.l10n.wanted
              : context.l10n.forSale,
        ),
        actions: [
          if (post?.isMine == true)
            IconButton(
              onPressed: () async {
                await context.push('/marketplace/posts/${post!.id}/edit');
                if (mounted) _load();
              },
              icon: const Icon(Icons.edit_outlined),
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null || post == null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_error ?? 'Post not found'),
                      TextButton(onPressed: _load, child: const Text('Retry')),
                    ],
                  ),
                )
              : Column(
                  children: [
                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: _load,
                        child: ListView(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                          children: [
                            _Gallery(
                              post: post,
                              onDelete: post.isMine ? _deleteImage : null,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              post.title,
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                color: AppColors.navy,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              post.priceLabel,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: AppColors.accentOrange,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                if (post.category != null)
                                  _InfoChip(post.category!),
                                if (post.condition != null)
                                  _InfoChip(post.condition!),
                                if (post.locationLabel.isNotEmpty)
                                  _InfoChip(post.locationLabel),
                                _InfoChip(post.status),
                              ],
                            ),
                            if (post.description != null &&
                                post.description!.trim().isNotEmpty) ...[
                              const SizedBox(height: 16),
                              const Text(
                                'Description',
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 15,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                post.description!,
                                style: const TextStyle(
                                  color: AppColors.ink,
                                  height: 1.45,
                                ),
                              ),
                            ],
                            if (post.user != null) ...[
                              const SizedBox(height: 18),
                              ListTile(
                                contentPadding: EdgeInsets.zero,
                                leading: CircleAvatar(
                                  backgroundColor: AppColors.mist,
                                  child: Text(
                                    post.user!.displayName.isNotEmpty
                                        ? post.user!.displayName[0]
                                            .toUpperCase()
                                        : '?',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.navy,
                                    ),
                                  ),
                                ),
                                title: Text(
                                  post.user!.displayName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                subtitle: Text(
                                  post.isMine ? 'Your post' : 'Posted by',
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    SafeArea(
                      top: false,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                        child: _bottomActions(post),
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _bottomActions(MarketplacePost post) {
    if (_busy) {
      return const Center(child: CircularProgressIndicator());
    }
    if (post.isMine) {
      final options = post.isSale
          ? (_config?.saleStatuses ?? const [])
          : (_config?.requestStatuses ?? const []);
      return Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () async {
                await context.push('/marketplace/posts/${post.id}/edit');
                if (mounted) _load();
              },
              child: Text(context.l10n.edit),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: FilledButton(
              onPressed: () async {
                final statuses = options
                    .where((e) => e['value'] != post.status)
                    .toList();
                if (statuses.isEmpty) return;
                final picked = await showModalBottomSheet<String>(
                  context: context,
                  builder: (ctx) => SafeArea(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ListTile(
                          title: Text(
                            context.l10n.status,
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                        ),
                        ...statuses.map(
                          (s) => ListTile(
                            title: Text(s['label'] ?? s['value'] ?? ''),
                            onTap: () => Navigator.pop(ctx, s['value']),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
                if (picked != null) _changeStatus(picked);
              },
              child: Text(context.l10n.status),
            ),
          ),
        ],
      );
    }
    if (!post.isActive) {
      return const Text(
        'This post is no longer active.',
        textAlign: TextAlign.center,
        style: TextStyle(color: AppColors.muted),
      );
    }
    return FilledButton(
      onPressed: _startChat,
      child: Text(
        post.isRequest
            ? context.l10n.iHaveThis
            : context.l10n.chatWithSeller,
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.mist,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppColors.ink,
        ),
      ),
    );
  }
}

class _Gallery extends StatelessWidget {
  const _Gallery({required this.post, this.onDelete});

  final MarketplacePost post;
  final ValueChanged<MarketplaceImage>? onDelete;

  @override
  Widget build(BuildContext context) {
    final images = post.images;
    final urls = images.isNotEmpty
        ? images.map((e) => e.url).toList()
        : [
            if (post.coverUrl != null && post.coverUrl!.isNotEmpty)
              post.coverUrl!,
          ];
    if (urls.isEmpty) {
      return Container(
        height: 220,
        decoration: BoxDecoration(
          color: AppColors.mist,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(
          child: Icon(Icons.image_outlined, size: 48, color: AppColors.muted),
        ),
      );
    }
    return SizedBox(
      height: 240,
      child: PageView.builder(
        itemCount: urls.length,
        itemBuilder: (context, index) {
          final url = urls[index];
          final image = index < images.length ? images[index] : null;
          return Stack(
            children: [
              Positioned.fill(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: CachedNetworkImage(
                    imageUrl: url,
                    fit: BoxFit.cover,
                    errorWidget: (_, _, _) => Container(
                      color: AppColors.mist,
                      child: const Icon(Icons.broken_image_outlined),
                    ),
                  ),
                ),
              ),
              if (onDelete != null && image != null)
                Positioned(
                  top: 8,
                  right: 8,
                  child: IconButton.filled(
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.black54,
                    ),
                    onPressed: () => onDelete!(image),
                    icon: const Icon(Icons.delete_outline, color: Colors.white),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
