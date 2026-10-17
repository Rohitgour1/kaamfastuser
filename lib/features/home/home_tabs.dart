import 'package:flutter/material.dart';

export 'package:kaamfast/features/home/cleaning_home_tab.dart';
export 'package:kaamfast/features/home/delivery_home_tab.dart';
export 'package:kaamfast/features/home/helper_home_tab.dart';
export 'package:kaamfast/features/home/laundry_home_tab.dart';
export 'package:kaamfast/features/home/marketplace_home_tab.dart';

/// Lets a horizontally scrolling bar run edge to edge inside a padded list.
class FullBleedBar extends StatelessWidget {
  const FullBleedBar({super.key, required this.child, this.height = 50, this.inset = 16});

  final Widget child;
  final double height;
  final double inset;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: LayoutBuilder(
        builder: (context, box) => OverflowBox(
          minWidth: box.maxWidth + inset * 2,
          maxWidth: box.maxWidth + inset * 2,
          child: child,
        ),
      ),
    );
  }
}
