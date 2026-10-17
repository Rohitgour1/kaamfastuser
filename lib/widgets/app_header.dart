import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:kaamfast/core/theme/app_theme.dart';
import 'package:kaamfast/providers/location_provider.dart';
import 'package:kaamfast/widgets/kaamzo_logo.dart';
import 'package:provider/provider.dart';

class AppHeader extends StatelessWidget {
  const AppHeader({
    super.key,
    this.locationLabel,
    this.showLogo = true,
    this.showBack,
    this.onLocationTap,
    this.onImage = false,
  });

  final String? locationLabel;
  final bool showLogo;
  final bool? showBack;
  final VoidCallback? onLocationTap;
  final bool onImage;

  @override
  Widget build(BuildContext context) {
    final liveLabel = context.watch<LocationProvider>().displayLabel;
    final label = (locationLabel != null && locationLabel!.trim().isNotEmpty)
        ? locationLabel!
        : liveLabel;
    final back = showBack ?? context.canPop();
    final ink = onImage ? Colors.white : AppColors.ink;
    final muted = onImage ? Colors.white70 : AppColors.muted;

    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
      child: Row(
        children: [
          if (back)
            IconButton(
              onPressed: () {
                if (context.canPop()) {
                  context.pop();
                } else {
                  context.go('/home');
                }
              },
              icon: Icon(Icons.arrow_back_rounded, color: ink),
            ),
          if (showLogo) ...[
            const KaamFastLogoMark(size: 36, withBackground: true),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: InkWell(
              onTap: onLocationTap ?? () => context.push('/location-picker'),
              borderRadius: BorderRadius.circular(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'LOCATION',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.8,
                      color: muted,
                    ),
                  ),
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: ink,
                          ),
                        ),
                      ),
                      Icon(
                        Icons.keyboard_arrow_down_rounded,
                        size: 18,
                        color: ink,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          IconButton(
            onPressed: () => context.push('/notifications'),
            icon: Icon(
              Icons.notifications_none_rounded,
              color: ink,
            ),
          ),
        ],
      ),
    );
  }
}
