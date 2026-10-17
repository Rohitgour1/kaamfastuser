import 'package:flutter/material.dart';
import 'package:kaamfast/common/app_constants.dart';
import 'package:kaamfast/core/theme/app_theme.dart';

class KaamFastLogoMark extends StatelessWidget {
  const KaamFastLogoMark({
    super.key,
    this.size = 36,
    this.withBackground = false,
    this.borderRadius,
  });

  static const assetPath = AppConstants.logoAsset;

  final double size;
  final bool withBackground;
  final double? borderRadius;

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? size * 0.22;
    final image = Image.asset(
      assetPath,
      width: size,
      height: size,
      fit: BoxFit.cover,
      filterQuality: FilterQuality.high,
    );

    if (!withBackground) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: image,
      );
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.navyDeep,
        borderRadius: BorderRadius.circular(radius),
        boxShadow: [
          BoxShadow(
            color: AppColors.navy.withValues(alpha: 0.12),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: image,
    );
  }
}

class KaamFastBrandRow extends StatelessWidget {
  const KaamFastBrandRow({super.key, this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        KaamFastLogoMark(size: compact ? 28 : 34, withBackground: true),
        SizedBox(width: compact ? 6 : 8),
        Text(
          'Kaam Fast',
          style: TextStyle(
            fontSize: compact ? 13 : 15,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.6,
            color: AppColors.navy,
          ),
        ),
      ],
    );
  }
}
