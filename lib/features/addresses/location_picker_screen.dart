import 'dart:async';

import 'package:flutter/material.dart';
import 'package:kaamfast/core/theme/app_theme.dart';
import 'package:kaamfast/models/maps_config.dart';
import 'package:kaamfast/providers/location_provider.dart';
import 'package:kaamfast/services/location_service.dart';
import 'package:kaamfast/widgets/app_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

class LocationPickerScreen extends StatefulWidget {
  const LocationPickerScreen({super.key});

  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  final _search = TextEditingController();
  final _searchFocus = FocusNode();
  MapsConfig? _config;
  LatLng? _pin;
  PlaceResult? _place;
  List<PlaceSuggestion> _suggestions = [];
  Timer? _debounce;
  bool _loading = true;
  bool _busy = false;
  bool _searching = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    final location = context.read<LocationService>();
    try {
      final config = await location.config();
      final existing = context.read<LocationProvider>().place;
      setState(() {
        _config = config;
        _pin = existing != null
            ? LatLng(existing.latitude, existing.longitude)
            : LatLng(config.defaultLat, config.defaultLng);
        _place = existing;
      });
      if (existing == null) {
        await _useCurrent();
      } else {
        setState(() => _loading = false);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = '$e';
        _loading = false;
      });
    }
  }

  Future<void> _useCurrent() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final place = await context.read<LocationService>().currentPlace();
      if (!mounted) return;
      _applyPlace(place);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = '$e';
        _loading = false;
        _busy = false;
      });
    }
  }

  void _applyPlace(PlaceResult place) {
    setState(() {
      _pin = LatLng(place.latitude, place.longitude);
      _place = place;
      _loading = false;
      _busy = false;
      _suggestions = [];
    });
  }

  Future<void> _onPinChanged(LatLng value) async {
    setState(() {
      _pin = value;
      _busy = true;
      _suggestions = [];
    });
    try {
      final place = await context.read<LocationService>().reverseGeocode(
            value.latitude,
            value.longitude,
          );
      if (!mounted) return;
      setState(() {
        _place = place;
        _busy = false;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = '$e';
        _busy = false;
      });
    }
  }

  void _onQueryChanged(String value) {
    _debounce?.cancel();
    if (value.trim().length < 2) {
      setState(() {
        _suggestions = [];
        _searching = false;
      });
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 320), () => _runSearch(value));
  }

  Future<void> _runSearch(String value) async {
    setState(() => _searching = true);
    try {
      final results = await context.read<LocationService>().autocomplete(value);
      if (!mounted || _search.text.trim() != value.trim()) return;
      setState(() {
        _suggestions = results;
        _searching = false;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _searching = false;
        _error = '$e';
      });
    }
  }

  Future<void> _selectSuggestion(PlaceSuggestion suggestion) async {
    _searchFocus.unfocus();
    setState(() {
      _busy = true;
      _suggestions = [];
      _search.text = suggestion.description;
    });
    try {
      final place = await context.read<LocationService>().resolveSuggestion(suggestion);
      if (!mounted) return;
      _applyPlace(place);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = '$e';
      });
    }
  }

  Future<void> _confirm() async {
    if (_place == null) return;
    await context.read<LocationProvider>().setPlace(_place!);
    if (!mounted) return;
    Navigator.of(context).pop(_place);
  }

  @override
  Widget build(BuildContext context) {
    final pin = _pin ?? LatLng(_config?.defaultLat ?? 22.7196, _config?.defaultLng ?? 75.8577);

    return Scaffold(
      appBar: AppBar(title: const Text('Select location')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  child: TextField(
                    controller: _search,
                    focusNode: _searchFocus,
                    textInputAction: TextInputAction.search,
                    onChanged: _onQueryChanged,
                    decoration: InputDecoration(
                      hintText: 'Search area, street, landmark...',
                      prefixIcon: const Icon(Icons.search_rounded),
                      suffixIcon: _searching
                          ? const Padding(
                              padding: EdgeInsets.all(12),
                              child: SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                            )
                          : (_search.text.isEmpty
                              ? null
                              : IconButton(
                                  icon: const Icon(Icons.close_rounded),
                                  onPressed: () {
                                    _search.clear();
                                    setState(() => _suggestions = []);
                                  },
                                )),
                    ),
                  ),
                ),
                if (_error != null)
                  Material(
                    color: const Color(0xFFFFE8E8),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Text(_error!, style: const TextStyle(color: AppColors.danger)),
                    ),
                  ),
                Expanded(
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: AppMap(
                          center: pin,
                          zoom: 16,
                          onTap: (point) {
                            _searchFocus.unfocus();
                            _onPinChanged(point);
                          },
                          markers: [
                            AppMapMarker(point: pin, color: AppColors.accentOrange),
                          ],
                        ),
                      ),
                      if (_suggestions.isNotEmpty)
                        Positioned(
                          top: 0,
                          left: 12,
                          right: 12,
                          child: Material(
                            elevation: 8,
                            borderRadius: BorderRadius.circular(12),
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxHeight: 280),
                              child: ListView.separated(
                                shrinkWrap: true,
                                padding: EdgeInsets.zero,
                                itemCount: _suggestions.length,
                                separatorBuilder: (_, _) => const Divider(height: 1),
                                itemBuilder: (context, index) {
                                  final item = _suggestions[index];
                                  return ListTile(
                                    dense: true,
                                    leading: const Icon(Icons.place_outlined, color: AppColors.navy),
                                    title: Text(
                                      item.description,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    subtitle: item.secondaryText == null
                                        ? null
                                        : Text(item.secondaryText!, maxLines: 1, overflow: TextOverflow.ellipsis),
                                    onTap: () => _selectSuggestion(item),
                                  );
                                },
                              ),
                            ),
                          ),
                        ),
                      Positioned(
                        right: 12,
                        bottom: 28,
                        child: FloatingActionButton.small(
                          onPressed: _busy ? null : _useCurrent,
                          backgroundColor: Colors.white,
                          foregroundColor: AppColors.navy,
                          child: const Icon(Icons.my_location_rounded),
                        ),
                      ),
                    ],
                  ),
                ),
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          _place?.formattedAddress ??
                              _place?.shortLabel ??
                              'Search or tap a point on the map',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          [
                            if (_place != null && _place!.city.isNotEmpty) _place!.city,
                            if (_place?.pincode != null && _place!.pincode!.isNotEmpty) _place!.pincode,
                          ].join(' · '),
                          style: const TextStyle(color: AppColors.muted),
                        ),
                        const SizedBox(height: 12),
                        FilledButton(
                          onPressed: (_place == null || _busy) ? null : _confirm,
                          child: _busy
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : const Text('Use this location'),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
