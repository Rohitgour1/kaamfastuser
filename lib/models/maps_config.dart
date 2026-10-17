import 'package:kaamfast/common/address_format.dart';

class MapsConfig {
  MapsConfig({
    required this.enabled,
    required this.provider,
    required this.apiKey,
    required this.defaultCity,
    required this.defaultLat,
    required this.defaultLng,
  });

  factory MapsConfig.fromJson(Map<String, dynamic> json) {
    return MapsConfig(
      enabled: json['enabled'] == true,
      provider: json['provider']?.toString() ?? 'google',
      apiKey: json['api_key']?.toString() ?? '',
      defaultCity: json['default_city']?.toString() ?? 'Indore',
      defaultLat: (json['default_lat'] is num)
          ? (json['default_lat'] as num).toDouble()
          : double.tryParse('${json['default_lat']}') ?? 22.7196,
      defaultLng: (json['default_lng'] is num)
          ? (json['default_lng'] as num).toDouble()
          : double.tryParse('${json['default_lng']}') ?? 75.8577,
    );
  }

  final bool enabled;
  final String provider;
  final String apiKey;
  final String defaultCity;
  final double defaultLat;
  final double defaultLng;

  bool get hasApiKey => apiKey.trim().isNotEmpty;

  /// HTTP Geocoding / Places can run whenever a Google key is present.
  bool get canUseGoogle =>
      hasApiKey && (provider.isEmpty || provider == 'google');
}

class PlaceResult {
  PlaceResult({
    required this.latitude,
    required this.longitude,
    required this.line1,
    required this.city,
    this.state,
    this.pincode,
    this.formattedAddress,
  });

  final double latitude;
  final double longitude;
  final String line1;
  final String city;
  final String? state;
  final String? pincode;
  final String? formattedAddress;

  bool get looksLikeCoordinates {
    return AddressFormat.looksLikeCoordinates(line1) &&
        AddressFormat.looksLikeCoordinates(formattedAddress);
  }

  /// Short human-readable label for header / pickup tile.
  String get shortLabel => AddressFormat.humanLine(
        line1: line1,
        formatted: formattedAddress,
        city: city,
        pincode: pincode,
      );

  /// Never persist raw coordinates as the address line.
  String get storageLine1 => AddressFormat.clampLine(
        AddressFormat.humanLine(
          line1: line1,
          formatted: formattedAddress,
          city: city,
          pincode: pincode,
        ),
      );

  Map<String, dynamic> toAddressBody({
    String label = 'Home',
    bool isDefault = false,
  }) {
    return {
      'label': label,
      'line1': storageLine1,
      'city': city.trim().isNotEmpty ? city.trim() : 'Indore',
      'state': state,
      'pincode': pincode,
      'latitude': latitude,
      'longitude': longitude,
      'is_default': isDefault,
      'meta': {
        'formatted_address': formattedAddress,
        'source': 'places',
      },
    };
  }
}

class PlaceSuggestion {
  PlaceSuggestion({
    required this.description,
    this.secondaryText,
    this.placeId,
    this.latitude,
    this.longitude,
  });

  final String description;
  final String? secondaryText;
  final String? placeId;
  final double? latitude;
  final double? longitude;
}
