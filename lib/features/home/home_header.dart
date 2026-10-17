import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:kaamfast/core/theme/app_theme.dart';
import 'package:kaamfast/providers/location_provider.dart';
import 'package:provider/provider.dart';

/// Home-only header: KaamFast wordmark, bell and a location pill.
class HomeHeader extends StatelessWidget {
  const HomeHeader({super.key, this.hasUnread = true, this.bellFirst = true});

  final bool hasUnread;
  final bool bellFirst;

  @override
  Widget build(BuildContext context) {
    final location = context.watch<LocationProvider>();
    final place = location.place;
    final full = location.displayLabel;
    final area = full.split(',').first.trim();
    final cityLine = place == null
        ? ''
        : [
            place.city.trim(),
            (place.pincode ?? '').trim(),
          ].where((e) => e.isNotEmpty).join(', ');

    final bell = _BellButton(
      hasUnread: hasUnread,
      onTap: () => context.push('/notifications'),
    );
    final pill = Flexible(
      child: _LocationPill(
        area: area.isEmpty ? full : area,
        cityLine: cityLine,
        onTap: () => context.push('/location-picker'),
      ),
    );
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
      child: Row(
        children: [
          const _Wordmark(),
          const Spacer(),
          if (bellFirst) bell else pill,
          const SizedBox(width: 8),
          if (bellFirst) pill else bell,
        ],
      ),
    );
  }
}

class _Wordmark extends StatelessWidget {
  const _Wordmark();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Image.asset(
          'assets/images/laundry/k_mark.png',
          height: 34,
          filterQuality: FilterQuality.high,
        ),
        const SizedBox(width: 2),
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            RichText(
              text: const TextSpan(
                style: TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.w800,
                  fontStyle: FontStyle.italic,
                  letterSpacing: -0.4,
                  height: 1.0,
                ),
                children: [
                  TextSpan(text: 'Kaam', style: TextStyle(color: AppColors.navy)),
                  TextSpan(text: 'Fast', style: TextStyle(color: AppColors.accentOrange)),
                ],
              ),
            ),
            const SizedBox(height: 3),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(width: 8, height: 1, color: AppColors.navy),
                const SizedBox(width: 3),
                const Text(
                  'Har Kaam, Fast & Easy',
                  style: TextStyle(
                    fontSize: 7.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.navy,
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(width: 3),
                Container(width: 8, height: 1, color: AppColors.navy),
              ],
            ),
          ],
        ),
      ],
    );
  }
}

class _BellButton extends StatelessWidget {
  const _BellButton({required this.onTap, required this.hasUnread});

  final VoidCallback onTap;
  final bool hasUnread;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: const CircleBorder(),
      elevation: 0,
      shadowColor: Colors.black12,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppColors.navy.withValues(alpha: 0.08),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              const Icon(Icons.notifications_rounded, color: AppColors.navy, size: 22),
              if (hasUnread)
                Positioned(
                  top: 9,
                  right: 10,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: AppColors.accentOrange,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 1.5),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LocationPill extends StatelessWidget {
  const _LocationPill({
    required this.area,
    required this.cityLine,
    required this.onTap,
  });

  final String area;
  final String cityLine;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 160),
          padding: const EdgeInsets.fromLTRB(10, 7, 8, 7),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: AppColors.navy.withValues(alpha: 0.08),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.location_on_rounded, color: AppColors.navy, size: 22),
              const SizedBox(width: 6),
              Flexible(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      area,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: AppColors.navy,
                        height: 1.2,
                      ),
                    ),
                    if (cityLine.isNotEmpty)
                      Text(
                        cityLine,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: AppColors.muted,
                          height: 1.2,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 2),
              const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.navy, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}
