import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kaamfast/features/home/home_header.dart';
import 'package:kaamfast/features/home/home_tabs.dart';
import 'package:kaamfast/models/module.dart';
import 'package:kaamfast/providers/location_provider.dart';
import 'package:kaamfast/services/api_services.dart';
import 'package:kaamfast/widgets/category_chips.dart';
import 'package:provider/provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  HomeCategory _category = HomeCategory.laundry;
  List<ServiceModule> _modules = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LocationProvider>().detectCurrent();
      _loadModules();
    });
  }

  Future<void> _loadModules() async {
    try {
      final modules = await context.read<ModuleService>().list();
      if (!mounted) return;
      setState(() => _modules = modules);
    } catch (_) {}
  }

  ServiceModule? _moduleFor(HomeCategory category) {
    final slugs = switch (category) {
      HomeCategory.laundry => ['laundry'],
      HomeCategory.delivery => ['parcel', 'delivery'],
      HomeCategory.cleaning => ['cleaning'],
      HomeCategory.helper => ['helper'],
      HomeCategory.marketplace => const <String>[],
    };
    for (final slug in slugs) {
      for (final module in _modules) {
        if (module.slug == slug) return module;
      }
    }
    return null;
  }

  String? _iconFor(HomeCategory category) {
    final icon = _moduleFor(category)?.iconUrl?.trim();
    if (icon == null || icon.isEmpty) return null;
    return icon;
  }

  String? _bannerFor(HomeCategory category) {
    final url = _moduleFor(category)?.bannerUrl?.trim();
    if (url == null || url.isEmpty) return _backgroundFor(category);
    return url;
  }

  String? _backgroundFor(HomeCategory category) {
    if (category == HomeCategory.marketplace) return null;
    final url = _moduleFor(category)?.backgroundUrl?.trim();
    if (url == null || url.isEmpty) return null;
    return url;
  }

  void _onCategorySelected(HomeCategory category) {
    setState(() => _category = category);
  }

  @override
  Widget build(BuildContext context) {
    final backgroundUrl = _backgroundFor(_category);
    final chips = CategoryChips(
      selected: _category,
      showMarketplace: true,
      iconUrls: {
        for (final category in HomeCategory.values)
          if (category != HomeCategory.marketplace)
            category: _iconFor(category),
      },
      onSelected: _onCategorySelected,
    );
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: Colors.white,
        body: DecoratedBox(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              stops: [0, 0.35, 0.6],
              colors: [Color(0xFFEAF1FB), Color(0xFFF6F8FC), Colors.white],
            ),
          ),
          child: Stack(
            children: [
              if (backgroundUrl != null)
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  height: 220,
                  child: ShaderMask(
                    shaderCallback: (rect) => const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.white, Colors.transparent],
                    ).createShader(rect),
                    blendMode: BlendMode.dstIn,
                    child: Image.network(
                      backgroundUrl,
                      fit: BoxFit.cover,
                      alignment: Alignment.topCenter,
                      errorBuilder: (_, _, _) => const SizedBox.shrink(),
                    ),
                  ),
                ),
              SafeArea(
                bottom: false,
                child: Column(
                  children: [
                    HomeHeader(bellFirst: _category == HomeCategory.laundry),
                    Expanded(
                      child: switch (_category) {
                        HomeCategory.laundry => LaundryHomeTab(
                            imageUrl: _bannerFor(HomeCategory.laundry),
                            categoryBar: chips,
                          ),
                        HomeCategory.delivery => DeliveryHomeTab(
                            imageUrl: _bannerFor(HomeCategory.delivery),
                            categoryBar: chips,
                          ),
                        HomeCategory.cleaning => CleaningHomeTab(
                            imageUrl: _bannerFor(HomeCategory.cleaning),
                            categoryBar: chips,
                          ),
                        HomeCategory.helper => HelperHomeTab(
                            imageUrl: _bannerFor(HomeCategory.helper),
                            categoryBar: chips,
                          ),
                        HomeCategory.marketplace => MarketplaceHomeTab(categoryBar: chips),
                      },
                    ),
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
