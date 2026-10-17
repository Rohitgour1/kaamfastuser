import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:kaamfast/core/theme/app_theme.dart';
import 'package:kaamfast/features/home/home_tabs.dart';
import 'package:kaamfast/features/home/promo_widgets.dart';
import 'package:kaamfast/features/marketplace/widgets/marketplace_post_card.dart';
import 'package:kaamfast/l10n/l10n_ext.dart';
import 'package:kaamfast/models/marketplace.dart';
import 'package:kaamfast/services/api_services.dart';
import 'package:kaamfast/widgets/filter_pill.dart';
import 'package:provider/provider.dart';

const _assetDir = 'assets/images/market';

class MarketplaceHomeTab extends StatefulWidget {
  const MarketplaceHomeTab({super.key, this.categoryBar});

  final Widget? categoryBar;

  @override
  State<MarketplaceHomeTab> createState() => _MarketplaceHomeTabState();
}

class _MarketplaceHomeTabState extends State<MarketplaceHomeTab> {
  List<String> _categories = const [];
  String? _category;
  List<MarketplacePost> _sales = const [];
  List<MarketplacePost> _requests = const [];
  int _unreadChats = 0;
  bool _loadingSales = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _refresh());
  }

  Future<void> _refresh() async {
    final api = context.read<MarketplaceApi>();
    await Future.wait([
      _loadSales(),
      api.config().then((c) {
        if (mounted) setState(() => _categories = c.categories);
      }).catchError((_) {}),
      api.posts(type: 'request', perPage: 10).then((p) {
        if (mounted) setState(() => _requests = p.items);
      }).catchError((_) {}),
      api.chats(perPage: 1).then((p) {
        if (mounted) setState(() => _unreadChats = p.unreadChats);
      }).catchError((_) {}),
    ]);
  }

  Future<void> _loadSales() async {
    setState(() => _loadingSales = true);
    try {
      final page = await context.read<MarketplaceApi>().posts(type: 'sale', category: _category, perPage: 6);
      if (!mounted) return;
      setState(() => _sales = page.items);
    } catch (_) {
      if (mounted) setState(() => _sales = const []);
    } finally {
      if (mounted) setState(() => _loadingSales = false);
    }
  }

  void _selectCategory(String? category) {
    if (_category == category) return;
    setState(() => _category = category);
    _loadSales();
  }

  List<PhotoCategory> _actions(BuildContext context) {
    final l10n = context.l10n;
    PhotoCategory tile(int i, String title, String subtitle, String route, IconData icon, String asset) {
      final (tint, knob) = categoryPalettes[i];
      return PhotoCategory(
        title: title,
        subtitle: subtitle,
        route: route,
        icon: icon,
        assetPath: '$_assetDir/$asset',
        tint: tint,
        knob: knob,
      );
    }

    return [
      tile(0, l10n.forSale, 'Browse items', '/marketplace/sale', Icons.sell_outlined, 'sale.png'),
      tile(1, l10n.wanted, 'See requests', '/marketplace/wanted', Icons.search_rounded, 'wanted.png'),
      tile(2, l10n.myPosts, 'Manage listings', '/marketplace/mine', Icons.inventory_2_outlined, 'mine.png'),
      tile(
        3,
        l10n.chats,
        _unreadChats > 0 ? '$_unreadChats unread' : 'Talk to buyers',
        '/marketplace/chats',
        Icons.chat_bubble_outline_rounded,
        'chats.png',
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final actions = _actions(context);
    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 28),
        children: [
          if (widget.categoryBar != null) ...[
            FullBleedBar(child: widget.categoryBar!),
            const SizedBox(height: 12),
          ],
          NavyPanelHero(
            eyebrow: 'BUY • SELL • LOCAL',
            title: 'MARKET',
            subtitle: 'Buy & sell pre-loved items near you',
            features: const [
              HeroFeature(Icons.location_on_outlined, 'Local\nBuyers'),
              HeroFeature(Icons.sell_outlined, 'Free\nListing'),
              HeroFeature(Icons.chat_bubble_outline_rounded, 'Direct\nChat'),
              HeroFeature(Icons.star_rounded, 'Safe\nDeals', highlight: true),
            ],
            cta: l10n.sellItem,
            tag: 'Purana Saaman,\nNaya Daam',
            assetPath: '$_assetDir/hero_market.jpg',
            onTap: () => context.push('/marketplace/posts/new?type=sale'),
          ),
          const SizedBox(height: 16),
          _SearchPill(onTap: () => context.push('/marketplace/sale')),
          const SizedBox(height: 18),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: actions.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              mainAxisExtent: 100,
            ),
            itemBuilder: (context, index) => PhotoCategoryTile(
              category: actions[index],
              onTap: () => context.push(actions[index].route),
            ),
          ),
          const SizedBox(height: 22),
          _SectionHeader('Fresh for sale', action: l10n.seeAll, onAction: () => context.push('/marketplace/sale')),
          if (_categories.isNotEmpty) ...[
            const SizedBox(height: 10),
            FullBleedBar(
              height: 38,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _categories.length + 1,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final value = index == 0 ? null : _categories[index - 1];
                  return FilterPill(
                    label: value ?? 'All',
                    selected: _category == value,
                    onTap: () => _selectCategory(value),
                  );
                },
              ),
            ),
          ],
          const SizedBox(height: 12),
          if (_loadingSales)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_sales.isEmpty)
            _EmptySales(onSell: () => context.push('/marketplace/posts/new?type=sale'))
          else
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _sales.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 0.72,
              ),
              itemBuilder: (context, index) {
                final post = _sales[index];
                return MarketplacePostCard(
                  post: post,
                  onTap: () => context.push('/marketplace/posts/${post.id}'),
                );
              },
            ),
          if (_requests.isNotEmpty) ...[
            const SizedBox(height: 22),
            _SectionHeader(
              'People are looking for',
              action: l10n.seeAll,
              onAction: () => context.push('/marketplace/wanted'),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 220,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                clipBehavior: Clip.none,
                itemCount: _requests.length,
                separatorBuilder: (_, _) => const SizedBox(width: 10),
                itemBuilder: (context, index) {
                  final post = _requests[index];
                  return MarketplacePostCard(
                    post: post,
                    compact: true,
                    onTap: () => context.push('/marketplace/posts/${post.id}'),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.title, {required this.action, required this.onAction});

  final String title;
  final String action;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.navy),
          ),
        ),
        InkWell(
          onTap: onAction,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.all(4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  action,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.accentOrange),
                ),
                const Icon(Icons.chevron_right_rounded, size: 20, color: AppColors.accentOrange),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _SearchPill extends StatelessWidget {
  const _SearchPill({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.line),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8, offset: const Offset(0, 3)),
            ],
          ),
          child: Row(
            children: [
              const Icon(Icons.search_rounded, color: AppColors.navy),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  context.l10n.searchItems,
                  style: const TextStyle(fontSize: 14, color: AppColors.muted),
                ),
              ),
              Container(
                width: 30,
                height: 30,
                decoration: const BoxDecoration(color: AppColors.accentOrange, shape: BoxShape.circle),
                child: const Icon(Icons.arrow_forward_rounded, size: 18, color: Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptySales extends StatelessWidget {
  const _EmptySales({required this.onSell});

  final VoidCallback onSell;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F8FD),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFDDE6F3)),
      ),
      child: Column(
        children: [
          const Icon(Icons.storefront_outlined, size: 36, color: AppColors.navy),
          const SizedBox(height: 8),
          Text(
            context.l10n.noItemsForSale,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.navy),
          ),
          const SizedBox(height: 4),
          const Text(
            'Be the first to list something in your area.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: AppColors.muted),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: onSell,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.accentOrange,
              foregroundColor: Colors.white,
              shape: const StadiumBorder(),
            ),
            icon: const Icon(Icons.add_rounded, size: 18),
            label: Text(context.l10n.sellItem),
          ),
        ],
      ),
    );
  }
}
