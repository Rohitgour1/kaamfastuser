import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kaamfast/core/theme/app_theme.dart';

/// Icon + two-line label shown in the hero's feature row.
class HeroFeature {
  const HeroFeature(this.icon, this.label, {this.highlight = false});

  final IconData icon;
  final String label;
  final bool highlight;
}

/// Home hero with a navy diagonal panel on the left and a photo on the right.
class NavyPanelHero extends StatelessWidget {
  const NavyPanelHero({
    super.key,
    required this.eyebrow,
    required this.title,
    required this.subtitle,
    required this.features,
    required this.cta,
    required this.tag,
    required this.assetPath,
    required this.onTap,
    this.imageUrl,
  });

  final String eyebrow;
  final String title;
  final String subtitle;
  final List<HeroFeature> features;
  final String cta;
  final String tag;
  final String assetPath;
  final String? imageUrl;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1.7,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: LayoutBuilder(
          builder: (context, box) {
            final w = box.maxWidth;
            return GestureDetector(
              onTap: onTap,
              child: Stack(
                children: [
                  Positioned.fill(child: _heroImage()),
                  Positioned(
                    right: -28,
                    bottom: -28,
                    child: Container(
                      width: 64,
                      height: 64,
                      decoration: const BoxDecoration(color: AppColors.accentOrange, shape: BoxShape.circle),
                    ),
                  ),
                  Positioned.fill(
                    child: ClipPath(
                      clipper: const _DiagonalPanelClipper(),
                      child: const DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Color(0xFF0B1F45), Color(0xFF13306A)],
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned(right: 10, top: 12, child: _HandwrittenTag(tag)),
                  Positioned(
                    left: 0,
                    top: 0,
                    bottom: 0,
                    width: w * 0.5,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 4, 14),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.topLeft,
                        child: SizedBox(width: 190, child: _copy()),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _heroImage() {
    final local = Image(
      image: AssetImage(assetPath),
      fit: BoxFit.cover,
      alignment: Alignment.centerRight,
    );
    final remote = imageUrl?.trim();
    if (remote == null || remote.isEmpty) return local;
    return Image.network(
      remote,
      fit: BoxFit.cover,
      alignment: Alignment.centerRight,
      errorBuilder: (_, _, _) => local,
    );
  }

  Widget _copy() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          eyebrow,
          style: TextStyle(
            fontSize: 10,
            letterSpacing: 1.8,
            fontWeight: FontWeight.w700,
            color: Colors.white.withValues(alpha: 0.85),
          ),
        ),
        const SizedBox(height: 4),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 42,
              height: 1.0,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          subtitle,
          style: TextStyle(
            fontSize: 13,
            height: 1.3,
            fontWeight: FontWeight.w500,
            color: Colors.white.withValues(alpha: 0.9),
          ),
        ),
        const SizedBox(height: 12),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < features.length; i++) ...[
                if (i > 0)
                  Container(
                    width: 1,
                    margin: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
                    color: Colors.white.withValues(alpha: 0.2),
                  ),
                Expanded(child: _feature(features[i])),
              ],
            ],
          ),
        ),
        const SizedBox(height: 14),
        Material(
          color: AppColors.accentOrange,
          shape: const StadiumBorder(),
          child: InkWell(
            onTap: onTap,
            customBorder: const StadiumBorder(),
            child: SizedBox(
              height: 40,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    cta,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.arrow_forward_rounded, size: 18, color: Colors.white),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _feature(HeroFeature f) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(f.icon, size: 17, color: f.highlight ? const Color(0xFFFFC83D) : Colors.white),
        const SizedBox(height: 4),
        Text(
          f.label,
          textAlign: TextAlign.center,
          maxLines: 2,
          style: const TextStyle(fontSize: 7, height: 1.2, fontWeight: FontWeight.w600, color: Colors.white),
        ),
      ],
    );
  }
}

class _DiagonalPanelClipper extends CustomClipper<Path> {
  const _DiagonalPanelClipper();

  @override
  Path getClip(Size size) {
    return Path()
      ..moveTo(0, 0)
      ..lineTo(size.width * 0.56, 0)
      ..lineTo(size.width * 0.47, size.height)
      ..lineTo(0, size.height)
      ..close();
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class _HandwrittenTag extends StatelessWidget {
  const _HandwrittenTag(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: -0.14,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            text,
            textAlign: TextAlign.center,
            style: GoogleFonts.caveat(
              fontSize: 16,
              height: 0.95,
              fontWeight: FontWeight.w700,
              color: AppColors.navy,
            ),
          ),
          CustomPaint(size: const Size(56, 8), painter: _SwooshPainter()),
        ],
      ),
    );
  }
}

class _SwooshPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.accentOrange
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    canvas.drawPath(
      Path()
        ..moveTo(0, size.height)
        ..quadraticBezierTo(size.width * 0.5, size.height * 0.1, size.width, 0),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class SuggestServiceCard extends StatelessWidget {
  const SuggestServiceCard({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.line),
          ),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: const BoxDecoration(color: Color(0xFFFFF4D9), shape: BoxShape.circle),
                child: const Icon(Icons.lightbulb_rounded, color: Color(0xFFF5A300), size: 24),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Suggest a service',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.navy),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Need something we don’t offer yet?',
                      style: TextStyle(fontSize: 12, color: AppColors.muted),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: AppColors.navy),
            ],
          ),
        ),
      ),
    );
  }
}

/// Data for a tinted category tile with a person cut-out on the right.
class PhotoCategory {
  const PhotoCategory({
    required this.title,
    required this.subtitle,
    required this.route,
    required this.icon,
    required this.assetPath,
    required this.tint,
    required this.knob,
    this.imageUrl,
  });

  final String title;
  final String subtitle;
  final String route;
  final IconData icon;
  final String assetPath;
  final String? imageUrl;
  final Color tint;
  final Color knob;
}

/// Shared tint / knob colour pairs for category tiles.
const categoryPalettes = <(Color, Color)>[
  (Color(0xFFFFF5E3), Color(0xFFFCE3BC)),
  (Color(0xFFEAF1FC), Color(0xFFD3E1F7)),
  (Color(0xFFFDECF0), Color(0xFFF8D2DC)),
  (Color(0xFFE6F6F0), Color(0xFFCBEBDF)),
];

class PhotoCategoryTile extends StatelessWidget {
  const PhotoCategoryTile({super.key, required this.category, required this.onTap});

  final PhotoCategory category;
  final VoidCallback onTap;

  Widget _tileImage() {
    final local = Image.asset(
      category.assetPath,
      fit: BoxFit.fitHeight,
      alignment: Alignment.bottomRight,
      filterQuality: FilterQuality.medium,
    );
    final url = category.imageUrl?.trim();
    if (url == null || url.isEmpty) return local;
    return Image.network(
      url,
      fit: BoxFit.fitHeight,
      alignment: Alignment.bottomRight,
      errorBuilder: (_, _, _) => local,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: category.tint,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Stack(
          children: [
            Positioned(right: 0, top: 6, bottom: 0, child: _tileImage()),
            FractionallySizedBox(
              widthFactor: 0.62,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 0, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(color: category.knob, shape: BoxShape.circle),
                      child: Icon(category.icon, size: 20, color: AppColors.navy),
                    ),
                    const Spacer(),
                    Text(
                      category.title,
                      maxLines: 2,
                      style: const TextStyle(
                        fontSize: 13.5,
                        height: 1.15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.navy,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Flexible(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              category.subtitle,
                              style: const TextStyle(fontSize: 11.5, color: AppColors.muted),
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(color: category.knob, shape: BoxShape.circle),
                          child: const Icon(Icons.chevron_right_rounded, size: 18, color: AppColors.navy),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
