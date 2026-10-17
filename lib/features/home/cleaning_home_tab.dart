import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:kaamfast/core/theme/app_theme.dart';
import 'package:kaamfast/features/home/home_tabs.dart';
import 'package:kaamfast/features/home/promo_widgets.dart';
import 'package:kaamfast/models/module.dart';
import 'package:kaamfast/services/api_services.dart';
import 'package:provider/provider.dart';

const _assetDir = 'assets/images/cleaning';

class CleaningHomeTab extends StatefulWidget {
  const CleaningHomeTab({super.key, this.imageUrl, this.categoryBar});

  final String? imageUrl;
  final Widget? categoryBar;

  @override
  State<CleaningHomeTab> createState() => _CleaningHomeTabState();
}

class _CleaningHomeTabState extends State<CleaningHomeTab> {
  static final _fallback = <PhotoCategory>[
    _category('Home Cleaning', null, null, null, 0),
    _category('Bathroom Cleaning', null, null, null, 1),
    _category('Kitchen Cleaning', null, null, null, 2),
    _category('Sofa Cleaning', null, null, null, 3),
  ];

  List<PhotoCategory> _categories = _fallback;
  bool _fromBackend = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    try {
      final module = await context.read<ModuleService>().show('cleaning');
      if (!mounted || module.categories.isEmpty) return;
      setState(() {
        _fromBackend = true;
        _categories = [
          for (var i = 0; i < module.categories.length; i++) _fromCategory(module.categories[i], i),
        ];
      });
    } catch (_) {}
  }

  static PhotoCategory _fromCategory(ServiceCategory c, int index) =>
      _category(c.name, c.startingPrice, c.slug, c.coverUrl, index);

  static PhotoCategory _category(String name, num? price, String? slug, String? imageUrl, int index) {
    final n = name.toLowerCase();
    final (icon, asset) = switch (n) {
      _ when n.contains('bath') || n.contains('toilet') => (Icons.bathtub_outlined, 'bathroom.png'),
      _ when n.contains('kitchen') => (Icons.kitchen_outlined, 'kitchen.png'),
      _ when n.contains('sofa') || n.contains('carpet') || n.contains('upholster') =>
        (Icons.weekend_outlined, 'sofa.png'),
      _ => (Icons.cleaning_services_outlined, 'home.png'),
    };
    final (tint, knob) = categoryPalettes[index % categoryPalettes.length];
    final s = slug?.trim();
    return PhotoCategory(
      title: name,
      subtitle: price == null ? 'Book now' : 'From ₹${price.toStringAsFixed(0)}',
      route: s == null || s.isEmpty ? '/cleaning' : '/cleaning?category=$s',
      icon: icon,
      assetPath: '$_assetDir/$asset',
      imageUrl: imageUrl,
      tint: tint,
      knob: knob,
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 28),
      children: [
        if (widget.categoryBar != null) ...[
          FullBleedBar(child: widget.categoryBar!),
          const SizedBox(height: 12),
        ],
        NavyPanelHero(
          eyebrow: 'SPOTLESS HOMES',
          title: 'CLEANING',
          subtitle: 'Professional cleaning at your doorstep',
          features: const [
            HeroFeature(Icons.verified_user_outlined, 'Trained\nStaff'),
            HeroFeature(Icons.eco_outlined, 'Eco\nProducts'),
            HeroFeature(Icons.shield_outlined, 'Fully\nInsured'),
            HeroFeature(Icons.star_rounded, 'On-Time\nService', highlight: true),
          ],
          cta: 'Book Cleaning',
          tag: 'Chamakta Ghar,\nKhush Parivaar',
          assetPath: '$_assetDir/hero_cleaning.jpg',
          imageUrl: widget.imageUrl,
          onTap: () => context.push('/cleaning'),
        ),
        const SizedBox(height: 22),
        const Text(
          'What needs cleaning?',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.navy),
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _categories.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            mainAxisExtent: 116,
          ),
          itemBuilder: (context, index) {
            final category = _categories[index];
            return PhotoCategoryTile(
              category: category,
              onTap: () => context.push(_fromBackend ? category.route : '/cleaning'),
            );
          },
        ),
        const SizedBox(height: 20),
        SuggestServiceCard(onTap: () => context.push('/service-requests')),
      ],
    );
  }
}
