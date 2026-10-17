import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:kaamfast/core/theme/app_theme.dart';
import 'package:kaamfast/features/marketplace/widgets/marketplace_post_card.dart';
import 'package:kaamfast/l10n/l10n_ext.dart';
import 'package:kaamfast/models/marketplace.dart';
import 'package:kaamfast/services/api_services.dart';
import 'package:kaamfast/widgets/filter_pill.dart';
import 'package:provider/provider.dart';

class MarketplaceListScreen extends StatefulWidget {
  const MarketplaceListScreen({super.key, required this.type});

  /// `sale` or `request`
  final String type;

  @override
  State<MarketplaceListScreen> createState() => _MarketplaceListScreenState();
}

class _MarketplaceListScreenState extends State<MarketplaceListScreen> {
  final _search = TextEditingController();
  final _scroll = ScrollController();
  final _posts = <MarketplacePost>[];
  bool _loading = true;
  bool _loadingMore = false;
  int _page = 1;
  int _lastPage = 1;
  String? _category;
  String? _error;
  List<String> _categories = const [];

  bool get _isSale => widget.type == 'sale';

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadConfig();
      _refresh();
    });
  }

  @override
  void dispose() {
    _search.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _loadConfig() async {
    try {
      final config = await context.read<MarketplaceApi>().config();
      if (!mounted) return;
      setState(() => _categories = config.categories);
    } catch (_) {}
  }

  void _onScroll() {
    if (_loadingMore || _page >= _lastPage) return;
    if (!_scroll.hasClients) return;
    if (_scroll.position.pixels < _scroll.position.maxScrollExtent - 240) {
      return;
    }
    _loadMore();
  }

  Future<void> _refresh() async {
    setState(() {
      _loading = true;
      _error = null;
      _page = 1;
    });
    try {
      final page = await context.read<MarketplaceApi>().posts(
        type: widget.type,
        search: _search.text,
        category: _category,
        page: 1,
      );
      if (!mounted) return;
      setState(() {
        _posts
          ..clear()
          ..addAll(page.items);
        _page = page.currentPage;
        _lastPage = page.lastPage;
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

  Future<void> _loadMore() async {
    setState(() => _loadingMore = true);
    try {
      final next = _page + 1;
      final page = await context.read<MarketplaceApi>().posts(
        type: widget.type,
        search: _search.text,
        category: _category,
        page: next,
      );
      if (!mounted) return;
      setState(() {
        _posts.addAll(page.items);
        _page = page.currentPage;
        _lastPage = page.lastPage;
        _loadingMore = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loadingMore = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FC),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF6F8FC),
        surfaceTintColor: Colors.transparent,
        title: Text(
          _isSale ? l10n.forSale : l10n.wanted,
          style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.navy),
        ),
        actions: [
          IconButton(
            tooltip: l10n.myPosts,
            onPressed: () => context.push('/marketplace/mine'),
            icon: const Icon(Icons.inventory_2_outlined),
          ),
          IconButton(
            tooltip: l10n.chats,
            onPressed: () => context.push('/marketplace/chats'),
            icon: const Icon(Icons.chat_bubble_outline),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(
          '/marketplace/posts/new?type=${widget.type}',
        ),
        backgroundColor: AppColors.accentOrange,
        foregroundColor: Colors.white,
        shape: const StadiumBorder(),
        icon: const Icon(Icons.add_rounded),
        label: Text(_isSale ? l10n.sellItem : l10n.postRequest),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: TextField(
              controller: _search,
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => _refresh(),
              decoration: InputDecoration(
                hintText: _isSale ? l10n.searchItems : l10n.searchRequests,
                filled: true,
                fillColor: Colors.white,
                prefixIcon: const Icon(Icons.search_rounded, color: AppColors.navy),
                suffixIcon: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Material(
                    color: AppColors.accentOrange,
                    shape: const CircleBorder(),
                    child: InkWell(
                      onTap: _refresh,
                      customBorder: const CircleBorder(),
                      child: const Icon(Icons.arrow_forward_rounded, size: 18, color: Colors.white),
                    ),
                  ),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: AppColors.line),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: AppColors.line),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: AppColors.navy, width: 1.4),
                ),
              ),
            ),
          ),
          if (_categories.isNotEmpty)
            SizedBox(
              height: 48,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                children: [
                  FilterPill(
                    label: 'All',
                    selected: _category == null,
                    onTap: () {
                      setState(() => _category = null);
                      _refresh();
                    },
                  ),
                  ..._categories.map(
                    (c) => Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: FilterPill(
                        label: c,
                        selected: _category == c,
                        onTap: () {
                          setState(() => _category = c);
                          _refresh();
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: _refresh,
                    child: _error != null
                        ? ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            children: [
                              const SizedBox(height: 120),
                              Center(child: Text(_error!)),
                              TextButton(
                                onPressed: _refresh,
                                child: const Text('Retry'),
                              ),
                            ],
                          )
                        : _posts.isEmpty
                            ? ListView(
                                physics: const AlwaysScrollableScrollPhysics(),
                                children: [
                                  const SizedBox(height: 120),
                                  Center(
                                    child: Text(
                                      _isSale
                                          ? l10n.noItemsForSale
                                          : l10n.noRequestsYet,
                                      style: const TextStyle(
                                        color: AppColors.muted,
                                      ),
                                    ),
                                  ),
                                ],
                              )
                            : GridView.builder(
                                controller: _scroll,
                                padding: const EdgeInsets.fromLTRB(
                                  16,
                                  12,
                                  16,
                                  100,
                                ),
                                gridDelegate:
                                    const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  mainAxisSpacing: 12,
                                  crossAxisSpacing: 12,
                                  childAspectRatio: 0.72,
                                ),
                                itemCount:
                                    _posts.length + (_loadingMore ? 1 : 0),
                                itemBuilder: (context, index) {
                                  if (index >= _posts.length) {
                                    return const Center(
                                      child: CircularProgressIndicator(),
                                    );
                                  }
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
