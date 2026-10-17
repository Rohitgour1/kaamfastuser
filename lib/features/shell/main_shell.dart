import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:kaamfast/core/ads/ad_config.dart';
import 'package:kaamfast/core/theme/app_theme.dart';
import 'package:kaamfast/l10n/l10n_ext.dart';
import 'package:kaamfast/widgets/app_banner_ad.dart';

// NavigationDestination label color is controlled via theme; active icons use navy.

class MainShell extends StatelessWidget {
  const MainShell({super.key, required this.shell});

  final StatefulNavigationShell shell;

  @override
  Widget build(BuildContext context) {
    final router = GoRouter.of(context);

    return ListenableBuilder(
      listenable: router.routerDelegate,
      builder: (context, _) {
        // Prefer shell index — URI path can miss the active tab and then
        // AppBannerAd never mounts (AdMob shows zero requests in production).
        final showBanner = AdConfig.showBannerForShellIndex(shell.currentIndex);
        return _scaffold(context, showBanner);
      },
    );
  }

  Widget _scaffold(BuildContext context, bool showBanner) {
    final l10n = context.l10n;
    return Scaffold(
      body: Column(
        children: [
          Expanded(child: shell),
          if (showBanner) const AppBannerAd(key: ValueKey('shell-banner')),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: AppColors.line)),
        ),
        child: NavigationBar(
          selectedIndex: shell.currentIndex,
          onDestinationSelected: shell.goBranch,
          backgroundColor: Colors.white,
          elevation: 0,
          indicatorColor: Colors.transparent,
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          destinations: [
            _dest(Icons.home_outlined, Icons.home_rounded, l10n.navHome),
            _dest(
              Icons.receipt_long_outlined,
              Icons.receipt_long,
              l10n.navOrders,
            ),
            _dest(
              Icons.local_shipping_outlined,
              Icons.local_shipping,
              l10n.navTracking,
            ),
            _dest(Icons.person_outline, Icons.person, l10n.navProfile),
          ],
        ),
      ),
    );
  }

  NavigationDestination _dest(IconData icon, IconData selected, String label) {
    return NavigationDestination(
      icon: Icon(icon, color: AppColors.muted),
      selectedIcon: Icon(selected, color: AppColors.navy),
      label: label,
    );
  }
}
