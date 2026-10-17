import 'package:flutter/foundation.dart';
import 'package:kaamfast/models/maps_config.dart';
import 'package:kaamfast/services/location_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocationProvider extends ChangeNotifier {
  LocationProvider(this._location);

  static const _latKey = 'current_lat';
  static const _lngKey = 'current_lng';
  static const _lineKey = 'current_line1';
  static const _cityKey = 'current_city';
  static const _stateKey = 'current_state';
  static const _pinKey = 'current_pincode';
  static const _addrKey = 'current_formatted';

  final LocationService _location;

  PlaceResult? place;
  bool detecting = false;
  bool _started = false;
  String? error;

  String get displayLabel {
    final current = place;
    if (current != null && !current.looksLikeCoordinates) {
      return current.shortLabel;
    }
    if (detecting) return 'Detecting location...';
    if (current != null) return current.shortLabel;
    return 'Set your location';
  }

  Future<void> setPlace(PlaceResult result) async {
    place = result;
    error = null;
    detecting = false;
    await _saveCache(result);
    notifyListeners();
  }

  Future<void> detectCurrent({bool force = false}) async {
    if (_started && !force && place != null) {
      final label = place!.shortLabel.toLowerCase();
      if (!label.contains('tahsil') && !label.contains('tehsil')) {
        return;
      }
    }
    _started = true;
    detecting = true;
    error = null;
    notifyListeners();

    await _restoreCache();

    try {
      place = await _location.currentPlace();
      await _saveCache(place!);
      error = null;
    } catch (e) {
      error = e.toString().replaceFirst('Exception: ', '');
    } finally {
      detecting = false;
      notifyListeners();
    }
  }

  Future<void> _restoreCache() async {
    final prefs = await SharedPreferences.getInstance();
    final lat = prefs.getDouble(_latKey);
    final lng = prefs.getDouble(_lngKey);
    if (lat == null || lng == null) return;
    final restored = PlaceResult(
      latitude: lat,
      longitude: lng,
      line1: prefs.getString(_lineKey) ?? '',
      city: prefs.getString(_cityKey) ?? '',
      state: prefs.getString(_stateKey),
      pincode: prefs.getString(_pinKey),
      formattedAddress: prefs.getString(_addrKey),
    );
    if (restored.looksLikeCoordinates) return;
    place = restored;
    notifyListeners();
  }

  Future<void> _saveCache(PlaceResult result) async {
    if (result.looksLikeCoordinates) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_latKey, result.latitude);
    await prefs.setDouble(_lngKey, result.longitude);
    await prefs.setString(_lineKey, result.line1);
    await prefs.setString(_cityKey, result.city);
    await prefs.setString(_stateKey, result.state ?? '');
    await prefs.setString(_pinKey, result.pincode ?? '');
    await prefs.setString(_addrKey, result.formattedAddress ?? '');
  }
}
