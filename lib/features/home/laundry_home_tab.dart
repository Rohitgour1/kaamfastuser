import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kaamfast/core/theme/app_theme.dart';
import 'package:kaamfast/features/home/home_tabs.dart';
import 'package:kaamfast/features/home/promo_widgets.dart';
import 'package:kaamfast/models/module.dart';
import 'package:kaamfast/services/api_services.dart';
import 'package:provider/provider.dart';

const _assetDir = 'assets/images/laundry';

class LaundryHomeTab extends StatefulWidget {
  const LaundryHomeTab({super.key, this.imageUrl, this.categoryBar});

  final String? imageUrl;
  final Widget? categoryBar;

  @override
  State<LaundryHomeTab> createState() => _LaundryHomeTabState();
}

class _LaundryHomeTabState extends State<LaundryHomeTab> {
  String _laundryPath({String? service, String? coupon}) {
    return Uri(
      path: '/laundry/pickup',
      queryParameters: {
        'service': ?service,
        if (coupon != null && coupon.isNotEmpty) 'coupon': coupon,
      },
    ).toString();
  }

  static const _palettes = [
    (Color(0xFFFFF5E3), Color(0xFFFCE3BC)),
    (Color(0xFFFDECF0), Color(0xFFF8D2DC)),
    (Color(0xFFEAF1FC), Color(0xFFD3E1F7)),
    (Color(0xFFE6F6F0), Color(0xFFCBEBDF)),
    (Color(0xFFEAF0FB), Color(0xFFD3DFF5)),
    (Color(0xFFF1ECFC), Color(0xFFDFD5F7)),
  ];

  List<_LaundryService> _services = const [];
  bool _loadingServices = true;

  @override
  void initState() {
    super.initState();
    _loadServices();
  }

  Future<void> _loadServices() async {
    try {
      final module = await context.read<ModuleService>().show('laundry');
      if (!mounted) return;
      setState(() {
        _services = [
          for (var i = 0; i < module.categories.length; i++) _fromCategory(module.categories[i], i),
        ];
        _loadingServices = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loadingServices = false);
    }
  }

  static String? _assetFor(String name) {
    final n = name.toLowerCase();
    if (n.contains('dry')) return 'dry_cleaning.png';
    if (n.contains('shoe') || n.contains('sneaker')) return 'shoe_cleaning.png';
    if (n.contains('blanket') || n.contains('curtain') || n.contains('quilt')) return 'blanket_care.png';
    if (n.contains('fold')) return 'wash_fold.png';
    if (n.contains('iron') || n.contains('press') || n.contains('steam')) return 'steam_ironing.png';
    if (n.contains('wash') || n.contains('laundry')) return 'regular_laundry.png';
    return null;
  }

  static String _unitSuffix(String? unit) {
    final u = (unit ?? '').trim().toLowerCase();
    if (u.isEmpty) return '';
    if (u.startsWith('kg') || u.startsWith('kilo')) return '/KG';
    if (u.startsWith('p')) return '/PC';
    return '/${u.toUpperCase()}';
  }

  _LaundryService _fromCategory(ServiceCategory category, int index) {
    ServiceItem? cheapest;
    for (final s in category.services) {
      if (s.basePrice == null) continue;
      if (cheapest == null || s.basePrice! < cheapest.basePrice!) cheapest = s;
    }
    final price = cheapest == null
        ? null
        : '₹${cheapest.basePrice!.toStringAsFixed(cheapest.basePrice! == cheapest.basePrice!.roundToDouble() ? 0 : 2)}'
            '${_unitSuffix(cheapest.unit)}';
    final asset = _assetFor(category.name);
    final (tint, knob) = _palettes[index % _palettes.length];
    return _LaundryService(
      category.name,
      price,
      asset,
      tint,
      knob,
      imageUrl: category.coverUrl,
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
        _LaundryHeroCarousel(
          imageUrl: widget.imageUrl,
          onTap: () => context.push(_laundryPath()),
        ),
        const SizedBox(height: 22),
        Row(
          children: [
            const Expanded(
              child: Text(
                'What do you need?',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.navy),
              ),
            ),
            InkWell(
              onTap: () => context.push(_laundryPath()),
              borderRadius: BorderRadius.circular(8),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'View All',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.accentOrange),
                    ),
                    SizedBox(width: 4),
                    Icon(Icons.arrow_forward_rounded, size: 16, color: AppColors.accentOrange),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_loadingServices)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(child: CircularProgressIndicator()),
          )
        else
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _services.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              mainAxisExtent: 136,
            ),
            itemBuilder: (context, index) {
              final service = _services[index];
              return _LaundryServiceTile(
                service: service,
                onTap: () => context.push(_laundryPath(service: service.title)),
              );
            },
          ),
        const SizedBox(height: 14),
        _WelcomeOffers(onApply: (code) => context.push(_laundryPath(coupon: code))),
        const SizedBox(height: 4),
        SuggestServiceCard(onTap: () => context.push('/service-requests')),
      ],
    );
  }
}

class _LaundryService {
  const _LaundryService(this.title, this.price, this.asset, this.tint, this.knob, {this.imageUrl});

  final String title;
  final String? price;
  final String? asset;
  final String? imageUrl;
  final Color tint;
  final Color knob;
}

class _HeroSlide {
  const _HeroSlide(this.eyebrow, this.line1, this.line2);

  final String eyebrow;
  final String line1;
  final String line2;
}

class _LaundryHeroCarousel extends StatefulWidget {
  const _LaundryHeroCarousel({required this.onTap, this.imageUrl});

  final String? imageUrl;
  final VoidCallback onTap;

  @override
  State<_LaundryHeroCarousel> createState() => _LaundryHeroCarouselState();
}

class _LaundryHeroCarouselState extends State<_LaundryHeroCarousel> {
  static const _slides = [
    _HeroSlide('PREMIUM LAUNDRY SERVICE', 'Fresh Clothes', 'Happier Days'),
    _HeroSlide('EXPRESS STEAM IRONING', 'Crisp Clothes', 'Every Day'),
    _HeroSlide('FREE DOORSTEP PICKUP', 'We Pick & Wash', 'You Relax'),
  ];

  final _controller = PageController();
  Timer? _timer;
  int _page = 0;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted || !_controller.hasClients) return;
      final next = (_page + 1) % _slides.length;
      _controller.animateToPage(next, duration: const Duration(milliseconds: 450), curve: Curves.easeOut);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 2.3,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            Positioned.fill(child: _HeroImage(url: widget.imageUrl)),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    stops: const [0, 0.42, 0.62],
                    colors: [
                      const Color(0xFFF1F5FB),
                      const Color(0xFFF1F5FB).withValues(alpha: 0.85),
                      const Color(0xFFF1F5FB).withValues(alpha: 0),
                    ],
                  ),
                ),
              ),
            ),
            PageView.builder(
              controller: _controller,
              itemCount: _slides.length,
              onPageChanged: (i) => setState(() => _page = i),
              itemBuilder: (context, i) => GestureDetector(
                onTap: widget.onTap,
                behavior: HitTestBehavior.opaque,
                child: _HeroCopy(slide: _slides[i]),
              ),
            ),
            const Positioned(right: 10, bottom: 18, child: _ComfortTag()),
            Positioned(
              left: 16,
              bottom: 10,
              child: Row(
                children: [
                  for (var i = 0; i < _slides.length; i++)
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.only(right: 5),
                      width: i == _page ? 14 : 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: i == _page ? AppColors.accentOrange : const Color(0xFFCBD2DC),
                        borderRadius: BorderRadius.circular(3),
                      ),
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

class _HeroImage extends StatelessWidget {
  const _HeroImage({this.url});

  final String? url;

  @override
  Widget build(BuildContext context) {
    const local = Image(
      image: AssetImage('$_assetDir/hero_laundry.jpg'),
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
  const _HeroCopy({required this.slide});

  final _HeroSlide slide;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 8, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            slide.eyebrow,
            style: const TextStyle(
              fontSize: 8.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.4,
              color: AppColors.navy,
            ),
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  slide.line1,
                  style: const TextStyle(
                    fontSize: 26,
                    height: 1.05,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.6,
                    color: AppColors.navy,
                  ),
                ),
                Text(
                  slide.line2,
                  style: const TextStyle(
                    fontSize: 26,
                    height: 1.1,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.6,
                    color: AppColors.accentOrange,
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          const Row(
            children: [
              _HeroFeature(Icons.verified_user_outlined, 'Hygienic\nCleaning'),
              SizedBox(width: 14),
              _HeroFeature(Icons.bolt_rounded, 'Quick\nPickup'),
              SizedBox(width: 14),
              _HeroFeature(Icons.eco_outlined, 'Safe &\nEco Friendly'),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroFeature extends StatelessWidget {
  const _HeroFeature(this.icon, this.label);

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: AppColors.navy),
        const SizedBox(height: 3),
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 8,
            height: 1.2,
            fontWeight: FontWeight.w600,
            color: AppColors.navy,
          ),
        ),
      ],
    );
  }
}

class _ComfortTag extends StatelessWidget {
  const _ComfortTag();

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: 0.14,
      child: Container(
        width: 68,
        padding: const EdgeInsets.fromLTRB(8, 8, 8, 6),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.95),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.10), blurRadius: 8, offset: const Offset(0, 3)),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Fresh\nClean\nComfort',
              textAlign: TextAlign.center,
              style: GoogleFonts.caveat(
                fontSize: 14,
                height: 1.0,
                fontWeight: FontWeight.w700,
                color: AppColors.navy,
              ),
            ),
            const SizedBox(height: 2),
            const Icon(Icons.sentiment_satisfied_alt_rounded, size: 14, color: AppColors.accentOrange),
          ],
        ),
      ),
    );
  }
}

class _LaundryServiceTile extends StatelessWidget {
  const _LaundryServiceTile({required this.service, required this.onTap});

  final _LaundryService service;
  final VoidCallback onTap;

  Widget _image() {
    final local = Image.asset(
      '$_assetDir/${service.asset ?? 'regular_laundry.png'}',
      fit: BoxFit.contain,
      filterQuality: FilterQuality.medium,
    );
    final url = service.imageUrl?.trim();
    if (url == null || url.isEmpty) return local;
    return Image.network(url, fit: BoxFit.contain, errorBuilder: (_, _, _) => local);
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: service.tint,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 10, 8, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: Center(child: _image())),
              const SizedBox(height: 6),
              Text(
                service.title,
                maxLines: 2,
                style: const TextStyle(
                  fontSize: 12,
                  height: 1.2,
                  fontWeight: FontWeight.w800,
                  color: AppColors.navy,
                ),
              ),
              const SizedBox(height: 3),
              Row(
                children: [
                  Expanded(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        service.price == null ? 'Book now' : 'From ${service.price}',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: AppColors.muted,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(color: service.knob, shape: BoxShape.circle),
                    child: const Icon(Icons.chevron_right_rounded, size: 16, color: AppColors.navy),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WelcomeOffers extends StatefulWidget {
  const _WelcomeOffers({required this.onApply});

  final ValueChanged<String> onApply;

  @override
  State<_WelcomeOffers> createState() => _WelcomeOffersState();
}

class _WelcomeOffersState extends State<_WelcomeOffers> {
  List<Map<String, dynamic>> _offers = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final offers = await context.read<BookingApi>().coupons(moduleSlug: 'laundry');
      if (!mounted) return;
      setState(() => _offers = offers);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    if (_offers.isEmpty) return const SizedBox.shrink();
    return Column(
      children: [
        for (final offer in _offers) ...[
          _OfferCard(offer: offer, onApply: widget.onApply),
          const SizedBox(height: 12),
        ],
      ],
    );
  }
}

class _OfferCard extends StatelessWidget {
  const _OfferCard({required this.offer, required this.onApply});

  final Map<String, dynamic> offer;
  final ValueChanged<String> onApply;

  static const _yellow = Color(0xFFFFD84D);

  num? _num(Object? v) => v is num ? v : num.tryParse('${v ?? ''}');

  String _money(num v) => v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(2);

  /// Splits "Welcome 10%" into white "Welcome " and yellow "10%".
  (String, String) _title() {
    final name = (offer['name']?.toString() ?? '').trim();
    final type = offer['discount_type']?.toString();
    final value = _num(offer['discount_value']);
    final percent = RegExp(r'\d+(\.\d+)?\s*%').firstMatch(name);
    if (percent != null) {
      return (name.substring(0, percent.start), name.substring(percent.start));
    }
    if (value != null && value > 0) {
      final highlight = type == 'percent' ? '${_money(value)}%' : '₹${_money(value)}';
      return (name.isEmpty ? 'Save ' : '$name ', highlight);
    }
    return (name.isEmpty ? 'Special offer' : name, '');
  }

  String _subtitle() {
    final description = (offer['description']?.toString() ?? '').trim();
    if (description.isNotEmpty) return description;
    final type = offer['discount_type']?.toString();
    final value = _num(offer['discount_value']);
    final max = _num(offer['max_discount']);
    if (value == null || value <= 0) return 'Tap to apply this code on your order.';
    final off = type == 'percent' ? '${_money(value)}% off' : '₹${_money(value)} off';
    final cap = max != null && max > 0 ? ' (max ₹${_money(max)})' : '';
    return '$off your booking$cap';
  }

  @override
  Widget build(BuildContext context) {
    final code = offer['code']?.toString() ?? '';
    final (lead, highlight) = _title();
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => onApply(code),
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          height: 118,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFFF8A1F), Color(0xFFFF5E01)],
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.accentOrange.withValues(alpha: 0.25),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Stack(
            children: [
              Positioned(
                right: 6,
                top: 6,
                bottom: 6,
                child: Image.asset('$_assetDir/offer_gift.png', fit: BoxFit.contain),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 14, 120, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'SPECIAL OFFER',
                      style: TextStyle(
                        fontSize: 9,
                        letterSpacing: 1.6,
                        fontWeight: FontWeight.w700,
                        color: Colors.white.withValues(alpha: 0.85),
                      ),
                    ),
                    const SizedBox(height: 2),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: RichText(
                        text: TextSpan(
                          style: const TextStyle(
                            fontSize: 26,
                            height: 1.1,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.4,
                          ),
                          children: [
                            TextSpan(text: lead, style: const TextStyle(color: Colors.white)),
                            if (highlight.isNotEmpty)
                              TextSpan(text: highlight, style: const TextStyle(color: _yellow)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _subtitle(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.92)),
                    ),
                    const Spacer(),
                    if (code.isNotEmpty) _CodeChip(code: code),
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

class _CodeChip extends StatelessWidget {
  const _CodeChip({required this.code});

  final String code;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        await Clipboard.setData(ClipboardData(text: code));
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$code copied')),
        );
      },
      child: CustomPaint(
        painter: _DashedBorderPainter(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                code,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  letterSpacing: 0.6,
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.copy_rounded, size: 14, color: Colors.white),
            ],
          ),
        ),
      ),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.9)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;
    final path = Path()
      ..addRRect(RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(8)));
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        canvas.drawPath(metric.extractPath(distance, distance + 5), paint);
        distance += 9;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
