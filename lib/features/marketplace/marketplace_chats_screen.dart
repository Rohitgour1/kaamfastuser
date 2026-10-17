import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:kaamfast/core/theme/app_theme.dart';
import 'package:kaamfast/models/marketplace.dart';
import 'package:kaamfast/services/api_services.dart';
import 'package:provider/provider.dart';

class MarketplaceChatsScreen extends StatefulWidget {
  const MarketplaceChatsScreen({super.key});

  @override
  State<MarketplaceChatsScreen> createState() => _MarketplaceChatsScreenState();
}

class _MarketplaceChatsScreenState extends State<MarketplaceChatsScreen> {
  final _chats = <MarketplaceChat>[];
  bool _loading = true;
  String? _error;
  int _unreadChats = 0;

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
      final page = await context.read<MarketplaceApi>().chats();
      if (!mounted) return;
      setState(() {
        _chats
          ..clear()
          ..addAll(page.items);
        _unreadChats = page.unreadChats;
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

  String _timeLabel(String? raw) {
    if (raw == null || raw.isEmpty) return '';
    final dt = DateTime.tryParse(raw)?.toLocal();
    if (dt == null) return '';
    final now = DateTime.now();
    if (dt.year == now.year && dt.month == now.month && dt.day == now.day) {
      final h = dt.hour.toString().padLeft(2, '0');
      final m = dt.minute.toString().padLeft(2, '0');
      return '$h:$m';
    }
    return '${dt.day}/${dt.month}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Marketplace chats'),
        actions: [
          if (_unreadChats > 0)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Center(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.accentOrange,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '$_unreadChats unread',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: _error != null
                  ? ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        const SizedBox(height: 120),
                        Center(child: Text(_error!)),
                      ],
                    )
                  : _chats.isEmpty
                      ? ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: const [
                            SizedBox(height: 120),
                            Center(
                              child: Text(
                                'No marketplace chats yet',
                                style: TextStyle(color: AppColors.muted),
                              ),
                            ),
                          ],
                        )
                      : ListView.separated(
                          itemCount: _chats.length,
                          separatorBuilder: (_, _) =>
                              const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final chat = _chats[index];
                            final cover = chat.post?.coverUrl;
                            final unread = chat.unreadCount;
                            return ListTile(
                              onTap: () async {
                                await context.push(
                                  '/marketplace/chats/${chat.id}',
                                );
                                if (mounted) _load();
                              },
                              leading: ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: cover == null || cover.isEmpty
                                    ? Container(
                                        width: 48,
                                        height: 48,
                                        color: AppColors.mist,
                                        child: const Icon(
                                          Icons.storefront_outlined,
                                        ),
                                      )
                                    : CachedNetworkImage(
                                        imageUrl: cover,
                                        width: 48,
                                        height: 48,
                                        fit: BoxFit.cover,
                                      ),
                              ),
                              title: Text(
                                chat.post?.title ?? 'Marketplace chat',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontWeight: unread > 0
                                      ? FontWeight.w800
                                      : FontWeight.w600,
                                ),
                              ),
                              subtitle: Text(
                                [
                                  chat.otherUser?.displayName,
                                  chat.lastMessage?.body,
                                ]
                                    .whereType<String>()
                                    .where((e) => e.trim().isNotEmpty)
                                    .join(' · '),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              trailing: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    _timeLabel(
                                      chat.lastMessageAt ??
                                          chat.lastMessage?.createdAt,
                                    ),
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: AppColors.muted,
                                    ),
                                  ),
                                  if (unread > 0) ...[
                                    const SizedBox(height: 6),
                                    CircleAvatar(
                                      radius: 10,
                                      backgroundColor: AppColors.accentOrange,
                                      child: Text(
                                        '$unread',
                                        style: const TextStyle(
                                          fontSize: 10,
                                          color: Colors.white,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            );
                          },
                        ),
            ),
    );
  }
}
