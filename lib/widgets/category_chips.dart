import 'package:flutter/material.dart';
import 'package:kaamfast/core/theme/app_theme.dart';
import 'package:kaamfast/l10n/l10n_ext.dart';

enum HomeCategory { laundry, delivery, cleaning, helper, marketplace }

class CategoryChips extends StatelessWidget {
  const CategoryChips({
    super.key,
    required this.selected,
    required this.onSelected,
    this.iconUrls = const {},
    this.showMarketplace = true,
  });

  final HomeCategory selected;
  final ValueChanged<HomeCategory> onSelected;
  final Map<HomeCategory, String?> iconUrls;
  final bool showMarketplace;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final items = <(HomeCategory, String, IconData)>[
      (HomeCategory.laundry, 'Laundry', Icons.local_laundry_service_rounded),
      (HomeCategory.delivery, 'Delivery', Icons.inventory_2_outlined),
      (HomeCategory.cleaning, 'Cleaning', Icons.sanitizer_outlined),
      (HomeCategory.helper, 'Helper', Icons.person_rounded),
      // Always last in the service scroller.
      if (showMarketplace)
        (
          HomeCategory.marketplace,
          l10n.marketplaceChip,
          Icons.storefront_outlined,
        ),
    ];

    return SizedBox(
      height: 50,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: items.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final item = items[index];
          final active = selected == item.$1;
          return GestureDetector(
            onTap: () => onSelected(item.$1),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: EdgeInsets.fromLTRB(active ? 9 : 14, 8, 18, 8),
              decoration: BoxDecoration(
                color: active ? AppColors.navy : _inactiveFill,
                borderRadius: BorderRadius.circular(14),
                boxShadow: active
                    ? [
                        BoxShadow(
                          color: AppColors.navy.withValues(alpha: 0.22),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : null,
              ),
              child: Row(
                children: [
                  _ChipIcon(
                    icon: item.$3,
                    imageUrl: iconUrls[item.$1],
                    active: active,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    item.$2,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: active ? Colors.white : AppColors.navy,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  static const _inactiveFill = Color(0xFFFFE9DA);
}

class _ChipIcon extends StatelessWidget {
  const _ChipIcon({required this.icon, required this.active, this.imageUrl});

  final IconData icon;
  final bool active;
  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    final url = imageUrl?.trim();
    final color = active ? AppColors.navy : AppColors.accentOrange;
    final glyph = url == null || url.isEmpty
        ? Icon(icon, size: 20, color: color)
        : ClipRRect(
            borderRadius: BorderRadius.circular(5),
            child: Image.network(
              url,
              width: 20,
              height: 20,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => Icon(icon, size: 20, color: color),
            ),
          );
    if (!active) return glyph;
    return Container(
      width: 32,
      height: 32,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(9),
      ),
      child: glyph,
    );
  }
}
