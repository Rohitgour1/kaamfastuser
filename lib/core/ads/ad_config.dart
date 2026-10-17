import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// Single place to turn banner ads on or off.
///
/// A screen shows a banner only when its GoRouter path is in
/// [bannerEnabledRoutes]. New screens stay ad-free until added here.
///
/// Tab paths (`/home`, `/bookings`, `/tracking`, `/profile`) are applied by
/// `MainShell`. Every other path is applied by `RouteBannerSlot` in the router.
class AdConfig {
  AdConfig._();

  /// Master switch. Set to false to hide banners everywhere.
  static const bool enabled = true;

  /// AdMob App ID (Android manifest / iOS Info.plist). Not an ad unit ID.
  static const String appId = 'ca-app-pub-6722925098081210~3290223291';

  /// Production banner ad unit. Used only in release builds.
  static const String productionBannerAdUnitId =
      'ca-app-pub-6722925098081210/7286513906';

  /// Google sample units. Debug/profile only — never ship these in release.
  /// Adaptive unit first; fixed 320x50 is the fallback if adaptive size fails.
  static const String androidTestBannerAdUnitId =
      'ca-app-pub-3940256099942544/9214589741';
  static const String androidTestFixedBannerAdUnitId =
      'ca-app-pub-3940256099942544/6300978111';
  static const String iosTestBannerAdUnitId =
      'ca-app-pub-3940256099942544/2435281174';

  /// Allowlist. Add or remove a path to enable or disable the banner.
  ///
  /// Use the route path, not the widget class name. Match exactly —
  /// `/bookings` does not enable `/bookings/:id`.
  static const Set<String> bannerEnabledRoutes = {
    '/home',
    '/bookings',
    '/tracking',
    '/notifications',
  };

  /// Tabs whose banner is owned by `MainShell`, not [RouteBannerSlot].
  static const Set<String> shellRoutes = {
    '/home',
    '/bookings',
    '/tracking',
    '/profile',
  };

  /// Shell branch index → whether that tab should show a banner.
  /// Prefer this over path matching so ads still load if the URI path is odd.
  static bool showBannerForShellIndex(int index) {
    if (!enabled || !isSupportedPlatform) return false;
    // 0 home, 1 bookings, 2 tracking, 3 profile
    return index == 0 || index == 1 || index == 2;
  }

  static bool get isSupportedPlatform {
    if (kIsWeb) return false;
    return defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;
  }

  /// Release uses the live unit. Debug and profile use Google's test units.
  static String bannerAdUnitId({bool fixedSize = false}) {
    if (kReleaseMode) return productionBannerAdUnitId;
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      return iosTestBannerAdUnitId;
    }
    return fixedSize
        ? androidTestFixedBannerAdUnitId
        : androidTestBannerAdUnitId;
  }

  static bool showBannerFor(String route) {
    if (!enabled || !isSupportedPlatform) return false;
    return bannerEnabledRoutes.contains(route);
  }

  static Future<void>? _initFuture;
  static bool _canRequestAds = false;
  static bool _sdkInitialized = false;

  static bool get canRequestAds => _canRequestAds;

  /// Initializes consent + Mobile Ads SDK once. Safe to call from app startup
  /// after the first frame so a consent form can attach to an Activity.
  static Future<void> initialize() {
    return _initFuture ??= _initialize().catchError((Object error, StackTrace st) {
      _log('initialize failed: $error', st);
      // Allow a later retry instead of locking production at zero requests.
      _initFuture = null;
    });
  }

  static Future<void> _initialize() async {
    if (!enabled || !isSupportedPlatform) return;

    await _gatherConsent();

    final allowed = await _resolveCanRequestAds();
    _canRequestAds = allowed;
    _log(
      'consent done canRequestAds=$allowed '
      'release=$kReleaseMode unit=${bannerAdUnitId()}',
    );

    if (!allowed) {
      _log('blocked by consent — no ad requests will be sent');
      // Let future initialize() calls retry after the user changes privacy options.
      _initFuture = null;
      return;
    }

    if (!_sdkInitialized) {
      try {
        await MobileAds.instance.updateRequestConfiguration(
          RequestConfiguration(
            ageRestrictedTreatment: AgeRestrictedTreatment.unspecified,
          ),
        );
      } catch (error) {
        _log('updateRequestConfiguration failed: $error');
      }
      try {
        final status = await MobileAds.instance.initialize();
        _sdkInitialized = true;
        _log('SDK initialized: ${status.adapterStatuses}');
      } catch (error, st) {
        _log('MobileAds.initialize failed: $error', st);
        // Still allow load attempts — some adapters recover on first request.
        _sdkInitialized = true;
      }
    }

    _canRequestAds = true;
  }

  /// UMP must run before ads (GMA 25+). If consent is still unclear after that
  /// (India / no privacy message / network blip), fall open so AdMob actually
  /// receives requests. Only hard-block when consent is explicitly required
  /// and not obtained.
  static Future<bool> _resolveCanRequestAds() async {
    try {
      if (await ConsentInformation.instance.canRequestAds()) return true;
    } catch (error) {
      _log('canRequestAds() threw: $error');
    }

    ConsentStatus? status;
    try {
      status = await ConsentInformation.instance.getConsentStatus();
      _log('ConsentStatus=$status');
    } catch (error) {
      _log('getConsentStatus failed: $error');
      return true;
    }

    if (status == ConsentStatus.required) {
      return false;
    }
    // notRequired / obtained / unknown → request ads.
    return true;
  }

  /// Google requires [requestConsentInfoUpdate] before any ad request.
  /// Until this runs, `canRequestAds()` is always false and GMA 25+ sends
  /// nothing to AdMob — which looks like "no requests" after Play publish.
  static Future<void> _gatherConsent() async {
    final done = Completer<void>();
    try {
      ConsentInformation.instance.requestConsentInfoUpdate(
        ConsentRequestParameters(),
        () async {
          try {
            await ConsentForm.loadAndShowConsentFormIfRequired((error) {
              if (error != null) {
                _log(
                  'consent form: ${error.errorCode} ${error.message}',
                );
              }
            });
          } catch (error) {
            _log('consent form failed: $error');
          }
          if (!done.isCompleted) done.complete();
        },
        (error) {
          _log(
            'consent update failed: ${error.errorCode} ${error.message}',
          );
          if (!done.isCompleted) done.complete();
        },
      );
    } catch (error) {
      _log('requestConsentInfoUpdate threw: $error');
      if (!done.isCompleted) done.complete();
    }

    await done.future.timeout(
      const Duration(seconds: 12),
      onTimeout: () {
        _log('consent update timed out');
      },
    );
  }

  static void _log(String message, [StackTrace? st]) {
    developer.log(message, name: 'AdMob', stackTrace: st);
    // Keep visible in `adb logcat` for release Play builds.
    // ignore: avoid_print
    print('AdMob: $message');
  }
}
