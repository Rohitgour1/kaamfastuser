import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gmaps;
import 'package:kaamfast/core/theme/app_theme.dart';
import 'package:latlong2/latlong.dart';

enum AppMapMarkerKind { pin, ride }

class AppMapMarker {
  const AppMapMarker({
    required this.point,
    this.color = const Color(0xFFE53935),
    this.icon = Icons.location_on_rounded,
    this.id,
    this.label,
    this.kind = AppMapMarkerKind.pin,
    this.rotation = 0,
  });

  final LatLng point;
  final Color color;
  final IconData icon;
  final String? id;
  final String? label;
  final AppMapMarkerKind kind;
  final double rotation;
}

class AppMapPolyline {
  const AppMapPolyline({
    required this.points,
    this.color = AppColors.navy,
    this.width = 5,
    this.id = 'route',
  });

  final List<LatLng> points;
  final Color color;
  final int width;
  final String id;
}

double? parseMapCoord(dynamic value) {
  if (value is num) return value.toDouble();
  return double.tryParse('$value');
}

/// Google Map used for tracking and location picking.
class AppMap extends StatefulWidget {
  const AppMap({
    super.key,
    required this.center,
    this.zoom = 15,
    this.markers = const [],
    this.polylines = const [],
    this.onTap,
    this.interactive = true,
    this.myLocationEnabled = false,
    this.fitToOverlays = false,
  });

  final LatLng center;
  final double zoom;
  final List<AppMapMarker> markers;
  final List<AppMapPolyline> polylines;
  final void Function(LatLng point)? onTap;
  final bool interactive;
  final bool myLocationEnabled;
  final bool fitToOverlays;

  @override
  State<AppMap> createState() => _AppMapState();
}

class _AppMapState extends State<AppMap> {
  gmaps.GoogleMapController? _controller;
  bool _isMapLoaded = false;
  gmaps.BitmapDescriptor? _rideIcon;
  bool _didInitialFit = false;

  gmaps.LatLng get _center =>
      gmaps.LatLng(widget.center.latitude, widget.center.longitude);

  @override
  void initState() {
    super.initState();
    unawaited(_ensureRideIcon());
  }

  Future<void> _ensureRideIcon() async {
    if (_rideIcon != null) return;
    try {
      final icon = await _buildRideIcon();
      if (!mounted) return;
      setState(() => _rideIcon = icon);
    } catch (_) {}
  }

  Future<gmaps.BitmapDescriptor> _buildRideIcon() async {
    const size = 96.0;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final center = const Offset(size / 2, size / 2);

    final shadow = Paint()
      ..color = Colors.black.withValues(alpha: 0.22)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    canvas.drawCircle(center.translate(0, 2), 28, shadow);

    final fill = Paint()..color = AppColors.navy;
    canvas.drawCircle(center, 28, fill);
    final ring = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5;
    canvas.drawCircle(center, 28, ring);

    final textPainter = TextPainter(textDirection: TextDirection.ltr);
    textPainter.text = TextSpan(
      text: String.fromCharCode(Icons.two_wheeler.codePoint),
      style: TextStyle(
        fontSize: 34,
        fontFamily: Icons.two_wheeler.fontFamily,
        package: Icons.two_wheeler.fontPackage,
        color: Colors.white,
      ),
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(center.dx - textPainter.width / 2, center.dy - textPainter.height / 2),
    );

    final image = await recorder.endRecording().toImage(size.toInt(), size.toInt());
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    return gmaps.BitmapDescriptor.bytes(bytes!.buffer.asUint8List());
  }

  @override
  void didUpdateWidget(AppMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    final centerChanged = oldWidget.center != widget.center || oldWidget.zoom != widget.zoom;
    if (centerChanged && !widget.fitToOverlays) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _controller?.animateCamera(
          gmaps.CameraUpdate.newCameraPosition(
            gmaps.CameraPosition(target: _center, zoom: widget.zoom),
          ),
        );
      });
    }
    if (widget.fitToOverlays) {
      final markerCountChanged = oldWidget.markers.length != widget.markers.length;
      final polylineChanged = oldWidget.polylines.length != widget.polylines.length ||
          (widget.polylines.isNotEmpty &&
              oldWidget.polylines.isNotEmpty &&
              oldWidget.polylines.first.points.length != widget.polylines.first.points.length);
      final gainedRide = !oldWidget.markers.any((m) => m.kind == AppMapMarkerKind.ride) &&
          widget.markers.any((m) => m.kind == AppMapMarkerKind.ride);
      if (!_didInitialFit || markerCountChanged || polylineChanged || gainedRide) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _fitOverlays());
      }
    }
  }

  @override
  void dispose() {
    _controller = null;
    super.dispose();
  }

  Set<gmaps.Polyline> get _polylines {
    return {
      for (final line in widget.polylines)
        if (line.points.length >= 2)
          gmaps.Polyline(
            polylineId: gmaps.PolylineId(line.id),
            points: [
              for (final p in line.points) gmaps.LatLng(p.latitude, p.longitude),
            ],
            color: line.color,
            width: line.width,
            geodesic: true,
          ),
    };
  }

  Future<void> _fitOverlays() async {
    final controller = _controller;
    if (!mounted || controller == null) return;
    final points = <gmaps.LatLng>[
      for (final m in widget.markers) gmaps.LatLng(m.point.latitude, m.point.longitude),
      for (final line in widget.polylines)
        for (final p in line.points) gmaps.LatLng(p.latitude, p.longitude),
    ];
    if (points.isEmpty) return;
    _didInitialFit = true;
    if (points.length == 1) {
      await controller.animateCamera(
        gmaps.CameraUpdate.newLatLngZoom(points.first, widget.zoom),
      );
      return;
    }
    var minLat = points.first.latitude;
    var maxLat = points.first.latitude;
    var minLng = points.first.longitude;
    var maxLng = points.first.longitude;
    for (final p in points.skip(1)) {
      if (p.latitude < minLat) minLat = p.latitude;
      if (p.latitude > maxLat) maxLat = p.latitude;
      if (p.longitude < minLng) minLng = p.longitude;
      if (p.longitude > maxLng) maxLng = p.longitude;
    }
    if ((maxLat - minLat).abs() < 0.0002) {
      minLat -= 0.002;
      maxLat += 0.002;
    }
    if ((maxLng - minLng).abs() < 0.0002) {
      minLng -= 0.002;
      maxLng += 0.002;
    }
    try {
      await controller.animateCamera(
        gmaps.CameraUpdate.newLatLngBounds(
          gmaps.LatLngBounds(
            southwest: gmaps.LatLng(minLat, minLng),
            northeast: gmaps.LatLng(maxLat, maxLng),
          ),
          72,
        ),
      );
    } catch (_) {
      await controller.animateCamera(
        gmaps.CameraUpdate.newLatLngZoom(points.first, widget.zoom),
      );
    }
  }

  Set<gmaps.Marker> get _markers {
    return {
      for (var i = 0; i < widget.markers.length; i++)
        gmaps.Marker(
          markerId: gmaps.MarkerId(widget.markers[i].id ?? 'm$i'),
          position: gmaps.LatLng(
            widget.markers[i].point.latitude,
            widget.markers[i].point.longitude,
          ),
          infoWindow: gmaps.InfoWindow(title: widget.markers[i].label ?? ''),
          rotation: widget.markers[i].rotation,
          flat: widget.markers[i].kind == AppMapMarkerKind.ride,
          anchor: widget.markers[i].kind == AppMapMarkerKind.ride
              ? const Offset(0.5, 0.5)
              : const Offset(0.5, 1.0),
          zIndexInt: widget.markers[i].kind == AppMapMarkerKind.ride ? 3 : 1,
          icon: widget.markers[i].kind == AppMapMarkerKind.ride && _rideIcon != null
              ? _rideIcon!
              : gmaps.BitmapDescriptor.defaultMarkerWithHue(
                  _hueFor(widget.markers[i].color),
                ),
        ),
    };
  }

  double _hueFor(Color color) {
    if (color == AppColors.navy || color == AppColors.navyDeep) {
      return gmaps.BitmapDescriptor.hueAzure;
    }
    if (color == AppColors.accentOrange) {
      return gmaps.BitmapDescriptor.hueOrange;
    }
    if (color == AppColors.success) {
      return gmaps.BitmapDescriptor.hueGreen;
    }
    if (color == const Color(0xFF6A1B9A) || color == Colors.purple) {
      return gmaps.BitmapDescriptor.hueViolet;
    }
    return gmaps.BitmapDescriptor.hueRed;
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: ExcludeSemantics(
        child: SizedBox.expand(
          child: Stack(
            children: [
              gmaps.GoogleMap(
                initialCameraPosition: gmaps.CameraPosition(
                  target: _center,
                  zoom: widget.zoom,
                ),
                markers: _markers,
                polylines: _polylines,
                myLocationEnabled: widget.myLocationEnabled,
                myLocationButtonEnabled: false,
                compassEnabled: widget.interactive,
                zoomControlsEnabled: false,
                scrollGesturesEnabled: widget.interactive,
                zoomGesturesEnabled: widget.interactive,
                rotateGesturesEnabled: widget.interactive,
                tiltGesturesEnabled: false,
                mapToolbarEnabled: false,
                liteModeEnabled: false,
                buildingsEnabled: false,
                indoorViewEnabled: false,
                trafficEnabled: false,
                onMapCreated: (controller) {
                  _controller = controller;
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (!mounted) return;
                    setState(() {
                      _isMapLoaded = true;
                    });
                    if (widget.fitToOverlays) {
                      _fitOverlays();
                    } else {
                      _controller?.moveCamera(
                        gmaps.CameraUpdate.newCameraPosition(
                          gmaps.CameraPosition(target: _center, zoom: widget.zoom),
                        ),
                      );
                    }
                  });
                },
                onTap: widget.onTap == null
                    ? null
                    : (point) => widget.onTap!(LatLng(point.latitude, point.longitude)),
              ),
              if (!_isMapLoaded)
                Container(
                  color: const Color(0xFFF0F0F0),
                  child: const Center(
                    child: CircularProgressIndicator(),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class AppMapPin extends StatelessWidget {
  const AppMapPin({super.key, this.color = AppColors.accentOrange});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Icon(Icons.location_on_rounded, color: color, size: 40);
  }
}
