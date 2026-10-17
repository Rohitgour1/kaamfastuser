import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kaamfast/core/theme/app_theme.dart';
import 'package:kaamfast/features/home/home_tabs.dart';
import 'package:kaamfast/providers/location_provider.dart';
import 'package:provider/provider.dart';

const _assetDir = 'assets/images/delivery';

class DeliveryHomeTab extends StatelessWidget {
  const DeliveryHomeTab({super.key, this.imageUrl, this.categoryBar});

  final String? imageUrl;
  final Widget? categoryBar;

  static const _parcels = <_ParcelOption>[
    _ParcelOption('Documents', 'Light', 'parcel_documents.png', Color(0xFFEAF1FC), Color(0xFFD3E1F7)),
    _ParcelOption('Small box', 'Up to 2kg', 'parcel_small.png', Color(0xFFFFF5E3), Color(0xFFFCE3BC)),
    _ParcelOption('Medium', 'Up to 5kg', 'parcel_medium.png', Color(0xFFFDECF0), Color(0xFFF8D2DC)),
    _ParcelOption('Large', 'Up to 10kg', 'parcel_large.png', Color(0xFFE6F6F0), Color(0xFFCBEBDF)),
  ];

  @override
  Widget build(BuildContext context) {
    final city = context.watch<LocationProvider>().place?.city.trim() ?? '';
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 28),
      children: [
        if (categoryBar != null) ...[
          FullBleedBar(child: categoryBar!),
          const SizedBox(height: 12),
        ],
        _DeliveryHero(
          imageUrl: imageUrl,
          city: city.isEmpty ? 'Town' : city,
          onTap: () => context.push('/delivery'),
        ),
        const SizedBox(height: 22),
        const _SectionTitle('What are you sending?'),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _parcels.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            mainAxisExtent: 90,
          ),
          itemBuilder: (context, index) => _ParcelTile(
            option: _parcels[index],
            onTap: () => context.push('/delivery?size=$index'),
          ),
        ),
        const SizedBox(height: 16),
        const _PriceNote(),
      ],
    );
  }
}

class _ParcelOption {
  const _ParcelOption(this.title, this.subtitle, this.asset, this.tint, this.knob);

  final String title;
  final String subtitle;
  final String asset;
  final Color tint;
  final Color knob;
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.navy),
    );
  }
}

class _DeliveryHero extends StatelessWidget {
  const _DeliveryHero({required this.city, required this.onTap, this.imageUrl});

  final String? imageUrl;
  final String city;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1.55,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: LayoutBuilder(
          builder: (context, box) {
            final w = box.maxWidth;
            final h = box.maxHeight;
            return GestureDetector(
              onTap: onTap,
              child: Stack(
                children: [
                  Positioned.fill(child: _HeroImage(url: imageUrl)),
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                          stops: const [0, 0.42, 0.62],
                          colors: [
                            const Color(0xFFF1F5FB),
                            const Color(0xFFF1F5FB).withValues(alpha: 0.82),
                            const Color(0xFFF1F5FB).withValues(alpha: 0),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _RoutePainter(
                        from: Offset(w * 0.40, h * 0.56),
                        pin: Offset(w * 0.505, h * 0.40),
                        to: Offset(w * 0.56, h * 0.47),
                      ),
                    ),
                  ),
                  Positioned(
                    left: w * 0.505 - 13,
                    top: h * 0.40 - 30,
                    child: const Icon(Icons.location_on_rounded, size: 28, color: AppColors.accentOrange),
                  ),
                  Positioned(
                    left: w * 0.535,
                    top: h * 0.42,
                    child: _AcrossBubble(city: city),
                  ),
                  Positioned(
                    right: 10,
                    top: 8,
                    child: _HandwrittenTag(),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 12, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child: Align(
                            alignment: Alignment.topLeft,
                            child: SizedBox(
                              width: w * 0.5,
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.topLeft,
                                child: _HeroCopy(onTap: onTap),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Row(
                          children: [
                            Expanded(child: _HeroChip(Icons.verified_user_rounded, 'Verified Partners')),
                            SizedBox(width: 8),
                            Expanded(child: _HeroChip(Icons.bolt_rounded, 'Quick Pickup')),
                            SizedBox(width: 8),
                            Expanded(child: _HeroChip(Icons.location_on_rounded, 'Live Tracking')),
                          ],
                        ),
                      ],
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

class _HeroImage extends StatelessWidget {
  const _HeroImage({this.url});

  final String? url;

  @override
  Widget build(BuildContext context) {
    const local = Image(
      image: AssetImage('$_assetDir/hero_delivery.jpg'),
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
    const headline = TextStyle(
      fontSize: 34,
      height: 1.0,
      fontWeight: FontWeight.w800,
      letterSpacing: -1,
    );
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'KAAMFAST DELIVERY',
          style: TextStyle(fontSize: 10, letterSpacing: 1.8, fontWeight: FontWeight.w600, color: AppColors.navy),
        ),
        const SizedBox(height: 6),
        Text('Send parcels,', style: headline.copyWith(color: AppColors.navy)),
        Text('simply.', style: headline.copyWith(color: AppColors.accentOrange)),
        const SizedBox(height: 6),
        const Text(
          'Safe • Fast • Reliable\nPickup from your door,\ndelivery across town.',
          style: TextStyle(fontSize: 12, height: 1.3, fontWeight: FontWeight.w500, color: AppColors.muted),
        ),
        const SizedBox(height: 12),
        Material(
          color: AppColors.accentOrange,
          shape: const StadiumBorder(),
          elevation: 3,
          shadowColor: AppColors.accentOrange.withValues(alpha: 0.4),
          child: InkWell(
            onTap: onTap,
            customBorder: const StadiumBorder(),
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 22, vertical: 12),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Send a Parcel',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white),
                  ),
                  SizedBox(width: 8),
                  Icon(Icons.arrow_forward_rounded, size: 20, color: Colors.white),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _HeroChip extends StatelessWidget {
  const _HeroChip(this.icon, this.label);

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 32,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 6, offset: const Offset(0, 2)),
        ],
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: AppColors.navy),
            const SizedBox(width: 5),
            Text(
              label,
              style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: AppColors.navy),
            ),
          ],
        ),
      ),
    );
  }
}

class _AcrossBubble extends StatelessWidget {
  const _AcrossBubble({required this.city});

  final String city;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        'Across\n$city',
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 9, height: 1.2, fontWeight: FontWeight.w600, color: AppColors.navy),
      ),
    );
  }
}

class _HandwrittenTag extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: -0.12,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Har Parcel\nSafe Haathon\nMein',
            textAlign: TextAlign.center,
            style: GoogleFonts.caveat(
              fontSize: 17,
              height: 0.95,
              fontWeight: FontWeight.w700,
              color: AppColors.navy,
            ),
          ),
          CustomPaint(size: const Size(62, 10), painter: _SwooshPainter()),
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
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final path = Path()
      ..moveTo(0, size.height * 0.9)
      ..quadraticBezierTo(size.width * 0.5, size.height * 0.1, size.width, 0);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _RoutePainter extends CustomPainter {
  _RoutePainter({required this.from, required this.pin, required this.to});

  final Offset from;
  final Offset pin;
  final Offset to;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.navy.withValues(alpha: 0.55)
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final path = Path()
      ..moveTo(from.dx, from.dy)
      ..quadraticBezierTo(from.dx + 4, pin.dy + 6, pin.dx - 2, pin.dy + 2)
      ..moveTo(pin.dx + 4, pin.dy + 2)
      ..quadraticBezierTo(to.dx - 6, pin.dy - 2, to.dx, to.dy);
    for (final metric in path.computeMetrics()) {
      var d = 0.0;
      while (d < metric.length) {
        canvas.drawPath(metric.extractPath(d, d + 3), paint);
        d += 6;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _RoutePainter oldDelegate) =>
      oldDelegate.from != from || oldDelegate.pin != pin || oldDelegate.to != to;
}

class _ParcelTile extends StatelessWidget {
  const _ParcelTile({required this.option, required this.onTap});

  final _ParcelOption option;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: option.tint,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
          child: Row(
            children: [
              SizedBox(
                width: 72,
                child: Image.asset(
                  '$_assetDir/${option.asset}',
                  fit: BoxFit.contain,
                  filterQuality: FilterQuality.medium,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 6),
                    Text(
                      option.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.navy),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      option.subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12, color: AppColors.muted),
                    ),
                    const Spacer(),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(color: option.knob, shape: BoxShape.circle),
                        child: const Icon(Icons.chevron_right_rounded, size: 20, color: AppColors.navy),
                      ),
                    ),
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

class _PriceNote extends StatelessWidget {
  const _PriceNote();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F8FD),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFDDE6F3)),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: const BoxDecoration(color: Color(0xFFFFF1D6), shape: BoxShape.circle),
            child: const Icon(Icons.currency_rupee_rounded, size: 18, color: Color(0xFFF29A00)),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Final price will be shown after pickup & drop location and parcel size are selected.',
              style: TextStyle(fontSize: 11.5, height: 1.4, color: AppColors.muted),
            ),
          ),
          const SizedBox(width: 8),
          Image.asset('$_assetDir/price_calculator.png', height: 56, filterQuality: FilterQuality.medium),
        ],
      ),
    );
  }
}
