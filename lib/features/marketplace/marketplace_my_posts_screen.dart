import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:kaamfast/core/theme/app_theme.dart';
import 'package:kaamfast/features/marketplace/widgets/marketplace_post_card.dart';
import 'package:kaamfast/l10n/l10n_ext.dart';
import 'package:kaamfast/models/marketplace.dart';
import 'package:kaamfast/providers/locale_provider.dart';
import 'package:kaamfast/services/api_services.dart';
import 'package:provider/provider.dart';

class MarketplaceMyPostsScreen extends StatefulWidget {
  const MarketplaceMyPostsScreen({super.key});

  @override
  State<MarketplaceMyPostsScreen> createState() =>
      _MarketplaceMyPostsScreenState();
}

class _MarketplaceMyPostsScreenState extends State<MarketplaceMyPostsScreen> {
  String? _typeFilter;
  final _posts = <MarketplacePost>[];
  bool _loading = true;
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
      final page = await context.read<MarketplaceApi>().posts(
        mine: true,
        type: _typeFilter,
      );
      if (!mounted) return;
      setState(() {
        _posts
          ..clear()
          ..addAll(page.items);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.myPosts)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/marketplace/posts/new'),
        backgroundColor: AppColors.navy,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: Text(context.l10n.sellItem),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: SegmentedButton<String?>(
              segments: [
                ButtonSegment(
                  value: null,
                  label: Text(
                    context.watch<LocaleProvider>().isHindi ? 'सभी' : 'All',
                  ),
                ),
                ButtonSegment(value: 'sale', label: Text(context.l10n.forSale)),
                ButtonSegment(
                  value: 'request',
                  label: Text(context.l10n.wanted),
                ),
              ],
              selected: {_typeFilter},
              onSelectionChanged: (v) {
                setState(() => _typeFilter = v.first);
                _load();
              },
            ),
          ),
          Expanded(
            child: _loading
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
                        : _posts.isEmpty
                            ? ListView(
                                physics: const AlwaysScrollableScrollPhysics(),
                                children: const [
                                  SizedBox(height: 120),
                                  Center(
                                    child: Text(
                                      'You have no posts yet',
                                      style: TextStyle(color: AppColors.muted),
                                    ),
                                  ),
                                ],
                              )
                            : ListView.separated(
                                padding: const EdgeInsets.fromLTRB(
                                  16,
                                  12,
                                  16,
                                  100,
                                ),
                                itemCount: _posts.length,
                                separatorBuilder: (_, _) =>
                                    const SizedBox(height: 12),
                                itemBuilder: (context, index) {
                                  final post = _posts[index];
                                  return MarketplacePostCard(
                                    post: post,
                                    onTap: () => context.push(
                                      '/marketplace/posts/${post.id}',
                                    ),
                                  );
                                },
                              ),
                  ),
          ),
        ],
      ),
    );
  }
}
