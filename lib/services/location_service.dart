import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:kaamfast/common/api_endpoints.dart';
import 'package:kaamfast/common/app_constants.dart';
import 'package:kaamfast/core/network/api_client.dart';
import 'package:kaamfast/models/maps_config.dart';

class LocationService {
  LocationService(this._api);

  final ApiClient _api;
  MapsConfig? _cachedConfig;
  String _placesSession = DateTime.now().microsecondsSinceEpoch.toString();
  final Dio _geo = Dio(BaseOptions(
    connectTimeout: AppConstants.connectTimeout,
    receiveTimeout: AppConstants.receiveTimeout,
    headers: const {
      'User-Agent': 'KaamFast/1.0 (location; https://kaamfast.com)',
    },
  ));

  Future<MapsConfig> config({bool force = false}) async {
    if (!force && _cachedConfig != null) return _cachedConfig!;
    MapsConfig parsed;
    try {
      final data = await _api.get(ApiEndpoints.mapsConfig);
      parsed = MapsConfig.fromJson(Map<String, dynamic>.from(data as Map));
    } catch (_) {
      parsed = MapsConfig(
        enabled: AppConstants.googleMapsApiKey.isNotEmpty,
        provider: 'google',
        apiKey: AppConstants.googleMapsApiKey,
        defaultCity: 'Indore',
        defaultLat: 22.7196,
        defaultLng: 75.8577,
      );
    }

    final key = parsed.apiKey.trim().isNotEmpty
        ? parsed.apiKey.trim()
        : AppConstants.googleMapsApiKey.trim();
    _cachedConfig = MapsConfig(
      enabled: parsed.enabled || key.isNotEmpty,
      provider: parsed.provider.isEmpty ? 'google' : parsed.provider,
      apiKey: key,
      defaultCity: parsed.defaultCity,
      defaultLat: parsed.defaultLat,
      defaultLng: parsed.defaultLng,
    );
    return _cachedConfig!;
  }

  Future<Position> currentPosition() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Location services are disabled. Please turn on GPS.');
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied) {
      throw Exception('Location permission denied.');
    }
    if (permission == LocationPermission.deniedForever) {
      throw Exception('Location permission permanently denied. Enable it in settings.');
    }

    try {
      return await Geolocator.getCurrentPosition(locationSettings: _gpsSettings());
    } catch (_) {
      final last = await Geolocator.getLastKnownPosition();
      if (last != null && last.accuracy > 0 && last.accuracy <= 80) return last;
      rethrow;
    }
  }

  LocationSettings _gpsSettings() {
    const timeout = Duration(seconds: 18);
    if (defaultTargetPlatform == TargetPlatform.android) {
      return AndroidSettings(
        accuracy: LocationAccuracy.best,
        distanceFilter: 0,
        timeLimit: timeout,
      );
    }
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      return AppleSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        distanceFilter: 0,
        timeLimit: timeout,
      );
    }
    return const LocationSettings(
      accuracy: LocationAccuracy.best,
      distanceFilter: 0,
      timeLimit: timeout,
    );
  }

  Future<PlaceResult> reverseGeocode(double lat, double lng) async {
    final maps = await config();
    if (maps.canUseGoogle) {
      try {
        return await _googleReverseGeocode(lat, lng, maps);
      } catch (_) {
        // Fall through to OpenStreetMap so the UI never shows raw coordinates.
      }
    }
    return _nominatimReverseGeocode(lat, lng, maps.defaultCity);
  }

  Future<List<PlaceSuggestion>> autocomplete(String query, {String? sessionToken}) async {
    final q = query.trim();
    if (q.length < 2) return [];
    
    Position? pos;
    try {
      pos = await Geolocator.getLastKnownPosition();
    } catch (_) {}

    final maps = await config();
    if (maps.canUseGoogle) {
      try {
        return await _googleAutocomplete(q, maps.apiKey, sessionToken ?? _placesSession, pos);
      } catch (_) {
        // Nominatim search still lets the user type an address.
      }
    }
    return _nominatimSearch(q, pos);
  }

  Future<PlaceResult> resolveSuggestion(PlaceSuggestion suggestion, {String? sessionToken}) async {
    if (suggestion.placeId != null && suggestion.placeId!.isNotEmpty) {
      final maps = await config();
      final result = await _googlePlaceDetails(
        suggestion.placeId!,
        maps,
        sessionToken ?? _placesSession,
      );
      _refreshPlacesSession();
      return result;
    }
    if (suggestion.latitude != null && suggestion.longitude != null) {
      return reverseGeocode(suggestion.latitude!, suggestion.longitude!);
    }
    throw Exception('Could not resolve this place.');
  }

  void _refreshPlacesSession() {
    _placesSession = DateTime.now().microsecondsSinceEpoch.toString();
  }

  Future<PlaceResult> currentPlace() async {
    final position = await currentPosition();
    return reverseGeocode(position.latitude, position.longitude);
  }

  Future<PlaceResult> _googleReverseGeocode(double lat, double lng, MapsConfig maps) async {
    var results = await _googleGeocodeResults(
      lat,
      lng,
      maps.apiKey,
      resultType: 'street_address|premise|subpremise|establishment|point_of_interest|route',
    );
    if (results.isEmpty) {
      results = await _googleGeocodeResults(lat, lng, maps.apiKey);
    }
    if (results.isEmpty) {
      throw Exception('No address found for this location.');
    }

    final chosen = _mostSpecificGoogleResult(results);
    var parsed = _fromGoogleAddress(chosen, lat, lng, maps.defaultCity);

    if (_isCoarseAddress(parsed, chosen)) {
      final nearby = await _googleNearestPlace(lat, lng, maps.apiKey);
      if (nearby != null) {
        parsed = PlaceResult(
          latitude: parsed.latitude,
          longitude: parsed.longitude,
          line1: nearby,
          city: parsed.city,
          state: parsed.state,
          pincode: parsed.pincode,
          formattedAddress: parsed.formattedAddress == null
              ? nearby
              : '$nearby, ${parsed.formattedAddress}',
        );
      }
    }
    return parsed;
  }

  Future<List<Map<String, dynamic>>> _googleGeocodeResults(
    double lat,
    double lng,
    String apiKey, {
    String? resultType,
  }) async {
    final response = await _geo.get(
      AppConstants.googleGeocodeBaseUrl,
      queryParameters: {
        'latlng': '$lat,$lng',
        'key': apiKey,
        'language': 'en',
        if (resultType != null) 'result_type': resultType,
      },
    );
    final body = response.data;
    if (body is! Map) return [];
    final status = body['status']?.toString();
    if (status != 'OK' && status != 'ZERO_RESULTS') {
      throw Exception('Geocoding failed ($status).');
    }
    final results = body['results'];
    if (results is! List) return [];
    return results.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
  }

  Map<String, dynamic> _mostSpecificGoogleResult(List<Map<String, dynamic>> results) {
    Map<String, dynamic> best = results.first;
    var bestScore = -1;
    for (final result in results) {
      final score = _googleResultScore(result);
      if (score > bestScore) {
        bestScore = score;
        best = result;
      }
    }
    return best;
  }

  int _googleResultScore(Map<String, dynamic> result) {
    final types = (result['types'] as List? ?? []).map((e) => e.toString()).toSet();
    if (types.contains('street_address') || types.contains('subpremise')) return 100;
    if (types.contains('premise')) return 90;
    if (types.contains('establishment') || types.contains('point_of_interest')) return 80;
    if (types.contains('route') || types.contains('intersection')) return 50;
    if (types.contains('neighborhood') || types.contains('sublocality_level_3')) return 40;
    if (types.contains('sublocality_level_2')) return 35;
    if (types.contains('plus_code')) return 20; // Plus code is more precise than sublocality level 1
    if (types.contains('sublocality') || types.contains('sublocality_level_1')) return 15;
    if (types.contains('administrative_area_level_3') || types.contains('political')) return 2;
    return 10;
  }

  bool _isCoarseAddress(PlaceResult parsed, Map<String, dynamic> result) {
    final types = (result['types'] as List? ?? []).map((e) => e.toString()).toSet();
    if (types.contains('street_address') ||
        types.contains('premise') ||
        types.contains('subpremise') ||
        types.contains('establishment') ||
        types.contains('point_of_interest')) {
      return false;
    }
    final text = '${parsed.line1} ${parsed.formattedAddress ?? ''}'.toLowerCase();
    if (text.contains('tahsil') || text.contains('tehsil') || text.contains('district')) {
      return true;
    }
    return parsed.line1.trim().length < 8;
  }

  Future<String?> _googleNearestPlace(double lat, double lng, String apiKey) async {
    try {
      final response = await _geo.get(
        AppConstants.googleNearbySearchUrl,
        queryParameters: {
          'location': '$lat,$lng',
          'rankby': 'distance',
          'key': apiKey,
          'language': 'en',
        },
      );
      final body = response.data;
      if (body is! Map || body['status']?.toString() != 'OK') return null;
      final results = body['results'];
      if (results is! List) return null;
      for (final raw in results) {
        if (raw is! Map) continue;
        final types = (raw['types'] as List? ?? []).map((e) => e.toString()).toSet();
        if (types.contains('locality') ||
            types.contains('political') ||
            types.contains('route') ||
            types.contains('plus_code')) {
          continue;
        }
        final name = raw['name']?.toString().trim() ?? '';
        final vicinity = raw['vicinity']?.toString().trim() ?? '';
        if (name.isEmpty) continue;
        if (vicinity.isNotEmpty && !vicinity.toLowerCase().contains(name.toLowerCase())) {
          return '$name, $vicinity';
        }
        return name;
      }
    } catch (_) {}
    return null;
  }

  Future<List<PlaceSuggestion>> _googleAutocomplete(
    String query,
    String apiKey,
    String sessionToken,
    Position? position,
  ) async {
    final queryParameters = <String, dynamic>{
      'input': query,
      'key': apiKey,
      'components': 'country:in',
      'language': 'en',
      'sessiontoken': sessionToken,
    };

    if (position != null) {
      queryParameters['location'] = '${position.latitude},${position.longitude}';
      queryParameters['radius'] = '50000'; // 50km bias
    }

    final response = await _geo.get(
      AppConstants.googlePlacesAutocompleteUrl,
      queryParameters: queryParameters,
    );
    final body = response.data;
    if (body is! Map) return [];
    final status = body['status']?.toString();
    if (status != 'OK' && status != 'ZERO_RESULTS') {
      throw Exception('Places autocomplete failed ($status).');
    }
    final predictions = body['predictions'];
    if (predictions is! List) return [];
    return predictions.whereType<Map>().map((raw) {
      final item = Map<String, dynamic>.from(raw);
      final structured = item['structured_formatting'] is Map
          ? Map<String, dynamic>.from(item['structured_formatting'] as Map)
          : const <String, dynamic>{};
      return PlaceSuggestion(
        placeId: item['place_id']?.toString(),
        description: item['description']?.toString() ??
            structured['main_text']?.toString() ??
            'Unknown place',
        secondaryText: structured['secondary_text']?.toString(),
      );
    }).toList();
  }

  Future<PlaceResult> _googlePlaceDetails(
    String placeId,
    MapsConfig maps,
    String sessionToken,
  ) async {
    final response = await _geo.get(
      AppConstants.googlePlacesDetailsUrl,
      queryParameters: {
        'place_id': placeId,
        'key': maps.apiKey,
        'language': 'en',
        'sessiontoken': sessionToken,
        'fields': 'geometry,formatted_address,address_component,name',
      },
    );
    final body = response.data;
    if (body is! Map || body['status'] != 'OK') {
      final status = body is Map ? body['status'] : 'UNKNOWN';
      throw Exception('Place details failed ($status).');
    }
    final result = body['result'];
    if (result is! Map) {
      throw Exception('Place details missing.');
    }
    final data = Map<String, dynamic>.from(result);
    final loc = data['geometry'] is Map && (data['geometry'] as Map)['location'] is Map
        ? Map<String, dynamic>.from((data['geometry'] as Map)['location'] as Map)
        : const <String, dynamic>{};
    final lat = (loc['lat'] as num?)?.toDouble() ?? maps.defaultLat;
    final lng = (loc['lng'] as num?)?.toDouble() ?? maps.defaultLng;
    return _fromGoogleAddress(data, lat, lng, maps.defaultCity);
  }

  PlaceResult _fromGoogleAddress(
    Map<String, dynamic> first,
    double lat,
    double lng,
    String defaultCity,
  ) {
    final components = (first['address_components'] as List? ?? [])
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();

    String? component(List<String> types) {
      for (final type in types) {
        for (final c in components) {
          final typeList = c['types'];
          if (typeList is List && typeList.contains(type)) {
            final name = c['long_name']?.toString().trim();
            if (name != null && name.isNotEmpty) return name;
          }
        }
      }
      return null;
    }

    bool noisy(String value) {
      final t = value.toLowerCase();
      // Google plus codes often contain '+'
      if (t.contains('+')) return true;
      return t.contains('tahsil') || t.contains('tehsil') || t == 'india';
    }

    final parts = <String>[];
    void add(String? value) {
      final text = value?.trim() ?? '';
      if (text.isEmpty || noisy(text)) return;
      if (parts.any((p) => p.toLowerCase() == text.toLowerCase())) return;
      parts.add(text);
    }

    add(component(['subpremise']));
    add(component(['premise']));
    add(first['name']?.toString());
    final street = [
      component(['street_number']),
      component(['route']),
    ].whereType<String>().join(' ').trim();
    add(street.isEmpty ? null : street);
    add(component(['neighborhood', 'sublocality_level_3', 'sublocality_level_2']));

    final formatted = first['formatted_address']?.toString();
    if (parts.isEmpty && formatted != null) {
      add(formatted.split(',').where((e) => e.trim().isNotEmpty && !noisy(e)).map((e) => e.trim()).firstOrNull);
    }
    add(component(['sublocality_level_1', 'sublocality']));

    final city = component(['locality', 'administrative_area_level_2']) ?? defaultCity;

    return PlaceResult(
      latitude: lat,
      longitude: lng,
      line1: parts.isNotEmpty ? parts.join(', ') : (formatted ?? 'Selected location'),
      city: city,
      state: component(['administrative_area_level_1']),
      pincode: component(['postal_code']),
      formattedAddress: formatted,
    );
  }

  Future<PlaceResult> _nominatimReverseGeocode(double lat, double lng, String defaultCity) async {
    final response = await _geo.get(
      'https://nominatim.openstreetmap.org/reverse',
      queryParameters: {
        'lat': lat,
        'lon': lng,
        'format': 'jsonv2',
        'addressdetails': 1,
        'zoom': 18,
      },
    );
    return _fromNominatim(response.data, lat, lng, defaultCity);
  }

  Future<List<PlaceSuggestion>> _nominatimSearch(String query, Position? position) async {
    final queryParameters = <String, dynamic>{
      'q': query,
      'format': 'jsonv2',
      'addressdetails': 1,
      'limit': 8,
      'countrycodes': 'in',
    };

    if (position != null) {
      // Create a bounding box around the current location (roughly ~50km radius)
      final lat = position.latitude;
      final lng = position.longitude;
      // 1 degree is ~111km, so 0.5 degrees is ~55km
      queryParameters['viewbox'] = '${lng - 0.5},${lat + 0.5},${lng + 0.5},${lat - 0.5}';
      queryParameters['bounded'] = 1;
    }

    final response = await _geo.get(
      'https://nominatim.openstreetmap.org/search',
      queryParameters: queryParameters,
    );
    final body = response.data;
    if (body is! List) return [];
    return body.whereType<Map>().map((raw) {
      final item = Map<String, dynamic>.from(raw);
      final lat = double.tryParse('${item['lat']}');
      final lng = double.tryParse('${item['lon']}');
      return PlaceSuggestion(
        description: item['display_name']?.toString() ?? query,
        secondaryText: item['type']?.toString(),
        latitude: lat,
        longitude: lng,
      );
    }).toList();
  }

  PlaceResult _fromNominatim(dynamic body, double lat, double lng, String defaultCity) {
    if (body is! Map) {
      return PlaceResult(
        latitude: lat,
        longitude: lng,
        line1: 'Selected location',
        city: defaultCity,
        formattedAddress: defaultCity,
      );
    }
    final address = body['address'] is Map
        ? Map<String, dynamic>.from(body['address'] as Map)
        : const <String, dynamic>{};
    String? pick(List<String> keys) {
      for (final key in keys) {
        final value = address[key]?.toString().trim();
        if (value != null && value.isNotEmpty) return value;
      }
      return null;
    }

    final line1 = [
      pick(['building', 'amenity', 'office', 'shop', 'tourism']),
      pick(['house_number']),
      pick(['road', 'pedestrian', 'residential']),
    ].whereType<String>().join(', ').trim();
    final area = pick(['neighbourhood', 'suburb', 'quarter', 'village', 'hamlet']);
    final city = pick(['city', 'town', 'city_district', 'county']) ?? defaultCity;
    final formatted = body['display_name']?.toString();
    return PlaceResult(
      latitude: lat,
      longitude: lng,
      line1: line1.isNotEmpty
          ? line1
          : (area ?? formatted ?? 'Selected location'),
      city: city,
      state: pick(['state']),
      pincode: pick(['postcode']),
      formattedAddress: formatted,
    );
  }
}
