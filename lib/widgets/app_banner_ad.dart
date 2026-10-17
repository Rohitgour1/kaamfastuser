import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:kaamfast/core/ads/ad_config.dart';
import 'package:kaamfast/core/theme/app_theme.dart';

/// Footer banner. Loads one [BannerAd], hides itself on failure, and
/// disposes the ad with the widget.
class AppBannerAd extends StatefulWidget {
  const AppBannerAd({super.key});

  @override
  State<AppBannerAd> createState() => _AppBannerAdState();
}

class _AppBannerAdState extends State<AppBannerAd> {
  BannerAd? _ad;
  bool _loaded = false;
  bool _disposed = false;
  int? _loadedWidth;
  Orientation? _loadedOrientation;
  AdSize? _slot;
  int _requestId = 0;
  int _retries = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final media = MediaQuery.of(context);
    final width = media.size.width.truncate();
    final orientation = media.orientation;
    if (width <= 0) return;
    if (width == _loadedWidth && orientation == _loadedOrientation) return;
    _loadedWidth = width;
    _loadedOrientation = orientation;
    _retries = 0;
    // setState during didChangeDependencies aborts the load in debug.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _disposed) return;
      if (width != _loadedWidth || orientation != _loadedOrientation) return;
      _load(width, orientation);
    });
  }

  Future<void> _load(int width, Orientation orientation) async {
    final requestId = ++_requestId;
    final previous = _ad;
    _ad = null;
    _loaded = false;
    if (mounted) setState(() {});
    if (previous != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => previous.dispose());
    }

    if (!AdConfig.enabled || !AdConfig.isSupportedPlatform) return;

    try {
      await AdConfig.initialize();
    } catch (error) {
      debugPrint('Banner ad init failed: $error');
    }
    if (!mounted || requestId != _requestId) return;
    if (!AdConfig.canRequestAds) {
      // ignore: avoid_print
      print('AdMob: banner skipped — consent does not allow requests yet');
      _scheduleRetry(width, orientation, requestId);
      return;
    }

    final size = await _bannerSize(width, orientation);
    if (!mounted || requestId != _requestId) return;
    final fixed = size == AdSize.banner;
    final unitId = AdConfig.bannerAdUnitId(fixedSize: fixed);
    // ignore: avoid_print
    print('AdMob: requesting banner unit=$unitId size=$size');

    final ad = BannerAd(
      adUnitId: unitId,
      size: size,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (loaded) async {
          // ignore: avoid_print
          print('AdMob: banner loaded');
          if (!mounted || _disposed || requestId != _requestId) {
            loaded.dispose();
            return;
          }
          AdSize? platform;
          if (loaded is BannerAd) {
            try {
              platform = await loaded.getPlatformAdSize();
            } catch (_) {}
          }
          if (!mounted || _disposed || requestId != _requestId) return;
          setState(() {
            _slot = platform ?? size;
            _loaded = true;
          });
        },
        onAdFailedToLoad: (failed, error) {
          // ignore: avoid_print
          print('AdMob: banner failed code=${error.code} msg=${error.message}');
          if (_disposed || requestId != _requestId) return;
          if (mounted) {
            setState(() {
              if (identical(_ad, failed)) _ad = null;
              _loaded = false;
            });
          } else if (identical(_ad, failed)) {
            _ad = null;
          }
          failed.dispose();
          _scheduleRetry(width, orientation, requestId);
        },
      ),
    );

    _ad = ad;
    _slot = size;
    try {
      await ad.load();
    } catch (error) {
      // ignore: avoid_print
      print('AdMob: banner load threw: $error');
      if (identical(_ad, ad)) _ad = null;
      ad.dispose();
      _scheduleRetry(width, orientation, requestId);
    }
  }

  /// Screen-width adaptive height. Falls back to 320x50 only if AdMob cannot size the device.
  Future<AdSize> _bannerSize(int width, Orientation orientation) async {
    try {
      final large = await AdSize.getLargeAnchoredAdaptiveBannerAdSizeWithOrientation(
        orientation,
        width,
      );
      if (large != null) return large;
    } catch (error) {
      debugPrint('Large adaptive banner size failed: $error');
    }
    try {
      final anchored =
          await AdSize.getCurrentOrientationAnchoredAdaptiveBannerAdSize(width);
      if (anchored != null) return anchored;
    } catch (error) {
      debugPrint('Adaptive banner size failed: $error');
    }
    return AdSize.banner;
  }

  void _scheduleRetry(int width, Orientation orientation, int requestId) {
    if (_disposed || requestId != _requestId || _retries >= 5) return;
    _retries += 1;
    final delay = Duration(seconds: 4 * _retries);
    Future<void>.delayed(delay, () {
      if (!mounted || _disposed || requestId != _requestId) return;
      _load(width, orientation);
    });
  }

  @override
  void dispose() {
    _disposed = true;
    _requestId++;
    _ad?.dispose();
    _ad = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ad = _ad;
    final slot = _slot;
    final show = _loaded && ad != null && slot != null;
    final height = show ? slot.height.toDouble() : 0.0;
    final width = show ? slot.width.toDouble() : 0.0;

    return AnimatedSize(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      alignment: Alignment.bottomCenter,
      child: show
          ? DecoratedBox(
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: AppColors.line)),
              ),
              child: SafeArea(
                top: false,
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: SizedBox(
                    width: width,
                    height: height,
                    child: AdWidget(ad: ad),
                  ),
                ),
              ),
            )
          : const SizedBox(width: double.infinity, height: 0),
    );
  }
}
