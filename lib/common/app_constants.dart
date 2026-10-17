/// Central place to update environment / third‑party config.
/// Prefer `--dart-define=KEY=value` for secrets in CI/release builds.
class AppConstants {
  AppConstants._();

  // ── App ──────────────────────────────────────────────────────────────
  static const String appName = 'Kaam Fast';
  static const String appTagline = 'Har Kaam, Ek App.';
  static const String logoAsset = 'assets/images/logo.png';
  static const String defaultCountryCode = '+91';
  static const String currencySymbol = '₹';

  // ── API / Backend ────────────────────────────────────────────────────
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE',
    defaultValue: 'https://kaamfast.com/api/v1',
  );

  /// Website root (API base without `/api/v1`); legal pages are admin Landing Pages.
  static String get siteUrl => apiBaseUrl.replaceFirst(RegExp(r'/api/v\d+/?$'), '');
  static String get privacyPolicyUrl => '$siteUrl/p/privacy-policy';
  static String get termsUrl => '$siteUrl/p/terms';

  /// Bump when Terms / Privacy text changes so the server can ask for fresh consent.
  static const String legalVersion = '2026-10-11';

  static const Duration connectTimeout = Duration(seconds: 20);
  static const Duration receiveTimeout = Duration(seconds: 30);

  // ── Google Maps ──────────────────────────────────────────────────────
  /// Runtime key can also come from GET /maps/config (preferred).
  /// Android native maps key: set GOOGLE_MAPS_API_KEY in android/local.properties
  static const String googleMapsApiKey = 'AIzaSyA9Q0rnE7ktszKDC-887VpigR7ClEs4zCo';

  static const String googleGeocodeBaseUrl =
      'https://maps.googleapis.com/maps/api/geocode/json';
  static const String googlePlacesAutocompleteUrl =
      'https://maps.googleapis.com/maps/api/place/autocomplete/json';
  static const String googlePlacesDetailsUrl =
      'https://maps.googleapis.com/maps/api/place/details/json';
  static const String googleNearbySearchUrl =
      'https://maps.googleapis.com/maps/api/place/nearbysearch/json';

  static const double defaultMapLat = 22.7196;
  static const double defaultMapLng = 75.8577;
  static const double defaultMapZoom = 12;

  // ── Firebase (fill when you add Firebase) ────────────────────────────
  static const bool firebaseEnabled = true;

  static const String firebaseProjectId = 'kaamfast-c0c75';

  static const String firebaseApiKey = 'AIzaSyCo0Fq7l5uIgNtGl5UtjAni5kEvCABfi5o';

  static const String firebaseAppIdAndroid = 'AIzaSyCo0Fq7l5uIgNtGl5UtjAni5kEvCABfi5o';
  static const String firebaseAppIdIos = String.fromEnvironment(
    'FIREBASE_APP_ID_IOS',
    defaultValue: '',
  );

  static const String firebaseMessagingSenderId = '799114600790';

  static const String firebaseStorageBucket = 'kaamfast-c0c75.firebasestorage.app';

  /// WhatsApp digits with country code, e.g. 9198xxxxxxx.
  /// Override: `--dart-define=SUPPORT_WHATSAPP=9198xxxxxxx`
  static const String supportWhatsApp = String.fromEnvironment(
    'SUPPORT_WHATSAPP',
    defaultValue: '',
  );

  /// Dev OTP hint (backend often returns debug_otp in local).
  static const String debugOtpHint = '123456';
}

/// Backward‑compatible alias used by older imports.
class ApiConfig {
  ApiConfig._();
  static const String baseUrl = AppConstants.apiBaseUrl;
}
