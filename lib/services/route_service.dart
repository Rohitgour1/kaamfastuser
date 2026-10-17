import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:kaamfast/common/app_constants.dart';
import 'package:kaamfast/services/location_service.dart';
import 'package:latlong2/latlong.dart';

class RouteService {
  RouteService(this._location);

  final LocationService _location;
  final Dio _http = Dio(BaseOptions(
    connectTimeout: AppConstants.connectTimeout,
    receiveTimeout: AppConstants.receiveTimeout,
  ));

  Future<List<LatLng>> drivingRoute(LatLng from, LatLng to) async {
    try {
      final config = await _location.config();
      final key = config.apiKey.trim().isNotEmpty
          ? config.apiKey.trim()
          : AppConstants.googleMapsApiKey.trim();
      if (key.isEmpty) return [from, to];

      final response = await _http.get<Map<String, dynamic>>(
        'https://maps.googleapis.com/maps/api/directions/json',
        queryParameters: {
          'origin': '${from.latitude},${from.longitude}',
          'destination': '${to.latitude},${to.longitude}',
          'mode': 'driving',
          'key': key,
        },
      );
      final routes = response.data?['routes'];
      if (routes is! List || routes.isEmpty) return [from, to];
      final overview = (routes.first as Map)['overview_polyline'];
      final encoded = overview is Map ? overview['points']?.toString() : null;
      if (encoded == null || encoded.isEmpty) return [from, to];
      final points = decodePolyline(encoded);
      return points.length >= 2 ? points : [from, to];
    } catch (e, st) {
      debugPrint('Directions API Error: $e\n$st');
      return [from, to];
    }
  }
}

List<LatLng> decodePolyline(String encoded) {
  final points = <LatLng>[];
  var index = 0;
  var lat = 0;
  var lng = 0;
  while (index < encoded.length) {
    var shift = 0;
    var result = 0;
    int b;
    do {
      b = encoded.codeUnitAt(index++) - 63;
      result |= (b & 0x1f) << shift;
      shift += 5;
    } while (b >= 0x20);
    lat += (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
    shift = 0;
    result = 0;
    do {
      b = encoded.codeUnitAt(index++) - 63;
      result |= (b & 0x1f) << shift;
      shift += 5;
    } while (b >= 0x20);
    lng += (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
    points.add(LatLng(lat / 1e5, lng / 1e5));
  }
  return points;
}
