import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kaamfast/core/theme/app_theme.dart';
import 'package:kaamfast/features/home/home_tabs.dart';
import 'package:kaamfast/models/module.dart';
import 'package:kaamfast/services/api_services.dart';
import 'package:provider/provider.dart';

const _assetDir = 'assets/images/helper';

class HelperHomeTab extends StatefulWidget {
  const HelperHomeTab({super.key, this.imageUrl, this.categoryBar});

  final String? imageUrl;
  final Widget? categoryBar;

  @override
  State<HelperHomeTab> createState() => _HelperHomeTabState();
}

class _HelperHomeTabState extends State<HelperHomeTab> {
  static const _palettes = [
    (Color(0xFFFFF5E3), Color(0xFFFCE3BC)),
    (Color(0xFFEAF1FC), Color(0xFFD3E1F7)),
    (Color(0xFFFDECF0), Color(0xFFF8D2DC)),
    (Color(0xFFE6F6F0), Color(0xFFCBEBDF)),
  ];

  static const _fallback = <_HelperCategory>[
    _HelperCategory('Electrician', '₹249/hr', '/helper?service=electrician', Icons.electrical_services_rounded, 'electrician.png', Color(0xFFFFF5E3), Color(0xFFFCE3BC)),
    _HelperCategory('Labour', '₹179/hr', '/helper?service=labour', Icons.hardware_rounded, 'labour.png', Color(0xFFEAF1FC), Color(0xFFD3E1F7)),
    _HelperCategory('Assistant', '₹149/hr', '/helper?service=assistant', Icons.handshake_outlined, 'assistant.png', Color(0xFFFDECF0), Color(0xFFF8D2DC)),
    _HelperCategory('Moving help', '₹199/hr', '/helper?service=moving', Icons.local_shipping_outlined, 'moving.png', Color(0xFFE6F6F0), Color(0xFFCBEBDF)),
  ];

  List<_HelperCategory> _categories = _fallback;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final services = await context.read<ModuleService>().services('helper');
      if (!mounted || services.isEmpty) return;
      setState(() {
        _categories = [
          for (var i = 0; i < services.length; i++) _fromService(services[i], i),
        ];
      });
    } catch (_) {}
  }

  _HelperCategory _fromService(ServiceItem s, int index) {
    final n = s.name.toLowerCase();
    final (icon, asset) = switch (n) {
      _ when n.contains('electric') => (Icons.electrical_services_rounded, 'electrician.png'),
      _ when n.contains('moving') => (Icons.local_shipping_outlined, 'moving.png'),
      _ when n.contains('labour') || n.contains('labor') => (Icons.hardware_rounded, 'labour.png'),
      _ when n.contains('shop') => (Icons.shopping_bag_outlined, 'assistant.png'),
      _ when n.contains('household') => (Icons.home_outlined, 'assistant.png'),
      _ when n.contains('assistant') => (Icons.handshake_outlined, 'assistant.png'),
      _ => (Icons.handyman_outlined, 'labour.png'),
    };
    final (tint, knob) = _palettes[index % _palettes.length];
    return _HelperCategory(
      s.name,
      '₹${(s.basePrice ?? 0).toStringAsFixed(0)}/hr',
      '/helper?service_id=${s.id}',
      icon,
      asset,
      tint,
      knob,
      imageUrl: s.imageUrl,
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
        _HelperHero(
          imageUrl: widget.imageUrl,
          onTap: () => context.push(_categories.first.route),
        ),
        const SizedBox(height: 22),
        const Text(
          'Popular categories',
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
            mainAxisExtent: 100,
          ),
          itemBuilder: (context, index) {
            final category = _categories[index];
            return _CategoryTile(
              category: category,
              onTap: () => context.push(category.route),
            );
          },
        ),
      ],
    );
  }
}

class _HelperCategory {
  const _HelperCategory(
    this.title,
    this.price,
    this.route,
    this.icon,
    this.asset,
    this.tint,
    this.knob, {
    this.imageUrl,
  });

  final String title;
  final String price;
  final String route;
  final String? imageUrl;
  final IconData icon;
  final String asset;
  final Color tint;
  final Color knob;
}

class _HelperHero extends StatelessWidget {
  const _HelperHero({required this.onTap, this.imageUrl});

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
                  Positioned.fill(child: _HeroImage(url: imageUrl)),
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
                  const Positioned(right: 10, top: 12, child: _HandwrittenTag()),
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
                        child: SizedBox(
                          width: 190,
                          child: _HeroCopy(onTap: onTap),
                        ),
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

class _HeroImage extends StatelessWidget {
  const _HeroImage({this.url});

  final String? url;

  @override
  Widget build(BuildContext context) {
    const local = Image(
      image: AssetImage('$_assetDir/hero_helper.jpg'),
      fit: BoxFit.cover,
      alignment: Alignment.centerRight,
    );
    final remote = url?.trim();
    if (remote == null || remote.isEmpty) return local;
    return Image.network(
      remote,
      fit: BoxFit.cover,
      alignment: Alignment.centerRight,
      errorBuilder: (_, _, _) => local,
    );
  }
}

class _HeroCopy extends StatelessWidget {
  const _HeroCopy({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'ON DEMAND',
          style: TextStyle(
            fontSize: 10,
            letterSpacing: 1.8,
            fontWeight: FontWeight.w700,
            color: Colors.white.withValues(alpha: 0.85),
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'HELPER',
          style: TextStyle(
            fontSize: 42,
            height: 1.0,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.5,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Skilled professionals\nfor your everyday needs.',
          style: TextStyle(
            fontSize: 13,
            height: 1.3,
            fontWeight: FontWeight.w500,
            color: Colors.white.withValues(alpha: 0.9),
          ),
        ),
        const SizedBox(height: 12),
        const IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: _HeroFeature(Icons.verified_user_outlined, 'Verified\nPartners', Colors.white)),
              _FeatureDivider(),
              Expanded(child: _HeroFeature(Icons.bolt_rounded, 'Quick\nBooking', Color(0xFFFFC83D))),
              _FeatureDivider(),
              Expanded(child: _HeroFeature(Icons.currency_rupee_rounded, 'Transparent\nPricing', Color(0xFFFFC83D))),
              _FeatureDivider(),
              Expanded(child: _HeroFeature(Icons.schedule_rounded, 'On-Time\nService', Colors.white)),
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
            child: const SizedBox(
              height: 40,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Hire Helper',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white),
                  ),
                  SizedBox(width: 8),
                  Icon(Icons.arrow_forward_rounded, size: 18, color: Colors.white),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _HeroFeature extends StatelessWidget {
  const _HeroFeature(this.icon, this.label, this.iconColor);

  final IconData icon;
  final String label;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 17, color: iconColor),
        const SizedBox(height: 4),
        Text(
          label,
          textAlign: TextAlign.center,
          maxLines: 2,
          style: const TextStyle(fontSize: 7, height: 1.2, fontWeight: FontWeight.w600, color: Colors.white),
        ),
      ],
    );
  }
}

class _FeatureDivider extends StatelessWidget {
  const _FeatureDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      margin: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
      color: Colors.white.withValues(alpha: 0.2),
    );
  }
}

class _HandwrittenTag extends StatelessWidget {
  const _HandwrittenTag();

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: -0.14,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Ghar ke\nhar kaam\nka Saathi',
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

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({required this.category, required this.onTap});

  final _HelperCategory category;
  final VoidCallback onTap;

  Widget _tileImage() {
    final local = Image.asset(
      '$_assetDir/${category.asset}',
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
            Positioned(
              right: 0,
              top: 6,
              bottom: 0,
              child: _tileImage(),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 0, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(color: category.knob, shape: BoxShape.circle),
                    child: Icon(category.icon, size: 20, color: AppColors.navy),
                  ),
                  const Spacer(),
                  Text(
                    category.title,
                    maxLines: 1,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.navy),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'From ${category.price}',
                        style: const TextStyle(fontSize: 11.5, color: AppColors.muted),
                      ),
                      const SizedBox(width: 8),
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
          ],
        ),
      ),
    );
  }
}
