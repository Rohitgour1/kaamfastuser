import 'package:flutter/material.dart';
import 'package:kaamfast/core/ads/ad_config.dart';
import 'package:kaamfast/widgets/app_banner_ad.dart';

/// Puts a footer banner under [child] only when [route] is allowlisted.
///
/// Shell tabs are skipped here so [MainShell] can keep a single banner
/// above the navigation bar.
class RouteBannerSlot extends StatelessWidget {
  const RouteBannerSlot({super.key, required this.route, required this.child});

  final String route;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (AdConfig.shellRoutes.contains(route) ||
        !AdConfig.showBannerFor(route)) {
      return child;
    }

    final keyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0;
    return Column(
      children: [
        Expanded(
          child: MediaQuery.removePadding(
            context: context,
            removeBottom: true,
            child: child,
          ),
        ),
        if (!keyboardOpen) const AppBannerAd(),
      ],
    );
  }
}

Widget routeWithBanner(String route, Widget screen) {
  return RouteBannerSlot(route: route, child: screen);
}
