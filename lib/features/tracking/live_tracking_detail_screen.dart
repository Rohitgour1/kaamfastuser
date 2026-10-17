import 'dart:async';

import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:kaamfast/common/app_constants.dart';
import 'package:kaamfast/core/theme/app_theme.dart';
import 'package:kaamfast/features/bookings/booking_chat_screen.dart';
import 'package:kaamfast/models/booking.dart';
import 'package:kaamfast/services/api_services.dart';
import 'package:kaamfast/services/live_sync.dart';
import 'package:kaamfast/services/location_service.dart';
import 'package:kaamfast/services/route_service.dart';
import 'package:kaamfast/widgets/app_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:kaamfast/widgets/service_rating_dialog.dart';
import 'package:url_launcher/url_launcher.dart';

class LiveTrackingDetailScreen extends StatefulWidget {
  const LiveTrackingDetailScreen({super.key, required this.bookingId});

  final int bookingId;

  @override
  State<LiveTrackingDetailScreen> createState() => _LiveTrackingDetailScreenState();
}

class _LiveTrackingDetailScreenState extends State<LiveTrackingDetailScreen> {
  BookingModel? _booking;
  Map<String, dynamic>? _tracking;
  bool _loading = true;
  String? _error;
  Timer? _poll;
  LatLng _camera = const LatLng(AppConstants.defaultMapLat, AppConstants.defaultMapLng);
  List<AppMapMarker> _markers = [];
  List<AppMapPolyline> _polylines = [];
  LiveSync? _live;
  RouteService? _routes;
  LatLng? _routeFrom;
  LatLng? _routeTo;
  StreamSubscription<DatabaseEvent>? _partnerLocSub;
  StreamSubscription<DatabaseEvent>? _partnerPresenceSub;
  StreamSubscription<DatabaseEvent>? _bookingPartnerLocSub;
  int? _watchingPartnerId;
  LatLng? _livePartnerPoint;
  LatLng? _pickupPoint;
  LatLng? _dropPoint;
  DateTime? _lastRouteFetchAt;
  bool _refreshing = false;
  bool _ratingPrompted = false;
  bool _rated = false;
  int _savedRating = 0;

  @override
  void initState() {
    super.initState();
    _load();
    _poll = Timer.periodic(const Duration(seconds: 4), (_) => _refreshTracking());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final live = context.read<LiveSync>();
    _routes ??= RouteService(context.read<LocationService>());
    if (_live != live) {
      _live?.removeListener(_onLive);
      _live = live;
      _live!.addListener(_onLive);
    }
  }

  void _onLive() {
    _refreshTracking();
  }

  @override
  void dispose() {
    _poll?.cancel();
    _partnerLocSub?.cancel();
    _partnerPresenceSub?.cancel();
    _bookingPartnerLocSub?.cancel();
    _live?.removeListener(_onLive);
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final api = context.read<BookingApi>();
      final booking = await api.show(widget.bookingId);
      if (!mounted) return;
      context.read<LiveSync>().watchBooking(widget.bookingId);
      setState(() {
        _booking = booking;
        _loading = false;
      });
      _watchBookingPartnerLocation(widget.bookingId);
      await _refreshTracking();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = '$e';
        _loading = false;
      });
    }
  }

  Future<void> _refreshTracking() async {
    if (!mounted || _refreshing) return;
    _refreshing = true;
    try {
      final api = context.read<BookingApi>();
      final data = await api.tracking(widget.bookingId);
      if (!mounted) return;

      final partner = data['partner'];
      if (partner is Map) {
        final pid = (partner['id'] as num?)?.toInt() ?? int.tryParse('${partner['id']}');
        if (pid != null) _watchPartnerLocation(pid);
        _ingestPartnerCoords(partner['latitude'], partner['longitude']);
      }
      _watchBookingPartnerLocation(widget.bookingId);

      _pickupPoint = _coordFromMap(data['pickup']) ?? _pickupPoint;
      _dropPoint = _coordFromMap(data['drop']) ?? _dropPoint;

      final statusNow = (data['status'] ?? '').toString().toLowerCase();
      final previous = (_tracking?['status'] ?? _booking?.status ?? '').toString().toLowerCase();
      await _rebuildMapOverlays(status: statusNow, partnerName: _partnerLabel(partner));

      if (!mounted) return;
      setState(() => _tracking = data);
      if (statusNow == 'completed' && previous != 'completed') {
        final booking = await api.show(widget.bookingId);
        if (!mounted) return;
        setState(() => _booking = booking);
      }
      if (statusNow == 'completed') {
        _promptRating();
      }
    } catch (e, st) {
      debugPrint('Tracking refresh failed: $e\n$st');
    } finally {
      _refreshing = false;
    }
  }

  String _partnerLabel(dynamic partner) {
    if (partner is Map) {
      return partner['name']?.toString() ?? 'Partner';
    }
    return _booking?.partnerName ?? 'Partner';
  }

  LatLng? _coordFromMap(dynamic point) {
    if (point is! Map) return null;
    final lat = parseMapCoord(point['latitude'] ?? point['lat']);
    final lng = parseMapCoord(point['longitude'] ?? point['lng']);
    if (lat == null || lng == null) return null;
    if (lat.abs() < 0.0001 && lng.abs() < 0.0001) return null;
    return LatLng(lat, lng);
  }

  void _ingestPartnerCoords(dynamic latRaw, dynamic lngRaw) {
    final lat = parseMapCoord(latRaw);
    final lng = parseMapCoord(lngRaw);
    if (lat == null || lng == null || lat.abs() < 0.0001) return;
    final next = LatLng(lat, lng);
    final prev = _livePartnerPoint;
    if (prev != null && _distanceMeters(prev, next) < 3) return;
    _livePartnerPoint = next;
  }

  Future<void> _rebuildMapOverlays({required String status, required String partnerName}) async {
    final markers = <AppMapMarker>[];
    final partnerPoint = _livePartnerPoint;
    final pickup = _pickupPoint;
    final drop = _dropPoint;

    if (partnerPoint != null) {
      markers.add(
        AppMapMarker(
          point: partnerPoint,
          color: AppColors.navy,
          id: 'partner',
          label: partnerName,
          kind: AppMapMarkerKind.ride,
        ),
      );
    }
    if (pickup != null) {
      markers.add(AppMapMarker(point: pickup, color: AppColors.success, id: 'pickup', label: 'Pickup'));
    }
    if (drop != null) {
      markers.add(AppMapMarker(point: drop, color: AppColors.accentOrange, id: 'drop', label: 'Drop'));
    }

    final destination = (status == 'in_progress' || status == 'started')
        ? (drop ?? pickup)
        : (status == 'arrived' ? (pickup ?? drop) : (pickup ?? drop));

    LatLng? from;
    LatLng? to;
    if (partnerPoint != null && destination != null) {
      from = partnerPoint;
      to = destination;
    } else if (pickup != null && drop != null) {
      from = pickup;
      to = drop;
    }

    var route = <LatLng>[];
    if (from != null && to != null) {
      final moved = _routeFrom == null ||
          _routeTo == null ||
          _distanceMeters(_routeFrom!, from) > 25 ||
          _distanceMeters(_routeTo!, to) > 15;
      final stale = _lastRouteFetchAt == null ||
          DateTime.now().difference(_lastRouteFetchAt!) > const Duration(seconds: 12);
      if (moved || stale || _polylines.isEmpty) {
        _routeFrom = from;
        _routeTo = to;
        _lastRouteFetchAt = DateTime.now();
        try {
          route = await (_routes?.drivingRoute(from, to) ?? Future.value([from, to]));
        } catch (e) {
          debugPrint('Route fetch failed: $e');
          route = [from, to];
        }
        if (route.length < 2) route = [from, to];
      } else if (_polylines.isNotEmpty && _polylines.first.points.length >= 2) {
        route = List<LatLng>.from(_polylines.first.points);
        if (partnerPoint != null && route.isNotEmpty) {
          route = [partnerPoint, ...route.skip(1)];
        }
      } else {
        route = [from, to];
      }
    }

    final focus = partnerPoint ?? pickup ?? drop;
    if (!mounted) return;
    setState(() {
      _markers = markers;
      _polylines = route.length >= 2
          ? [
              AppMapPolyline(
                points: route,
                color: const Color(0xFF1B8F4A),
                width: 6,
                id: 'route',
              ),
            ]
          : [];
      if (focus != null) _camera = focus;
    });
  }

  void _onPartnerLocationEvent(DatabaseEvent event) {
    final value = event.snapshot.value;
    if (value is! Map) return;
    final map = Map<Object?, Object?>.from(value);
    final lat = parseMapCoord(map['lat'] ?? map['latitude']);
    final lng = parseMapCoord(map['lng'] ?? map['longitude']);
    if (lat == null || lng == null || lat.abs() < 0.0001) return;
    final next = LatLng(lat, lng);
    final prev = _livePartnerPoint;
    if (prev != null && _distanceMeters(prev, next) < 4) return;
    _livePartnerPoint = next;
    final status = (_tracking?['status'] ?? _booking?.status ?? '').toString().toLowerCase();
    final partner = _tracking?['partner'];
    unawaited(_rebuildMapOverlays(status: status, partnerName: _partnerLabel(partner)));
  }

  void _watchPartnerLocation(int partnerId) {
    if (_watchingPartnerId == partnerId && _partnerLocSub != null) return;
    _watchingPartnerId = partnerId;
    _partnerLocSub?.cancel();
    _partnerPresenceSub?.cancel();
    try {
      _partnerLocSub = FirebaseDatabase.instance
          .ref('live/partners/$partnerId/location')
          .onValue
          .listen(_onPartnerLocationEvent, onError: (e) {
        debugPrint('Partner location listen error: $e');
      });
      _partnerPresenceSub = FirebaseDatabase.instance
          .ref('live/partners/$partnerId/presence')
          .onValue
          .listen(_onPartnerLocationEvent, onError: (_) {});
    } catch (e) {
      debugPrint('Partner location listen skipped: $e');
    }
  }

  void _watchBookingPartnerLocation(int bookingId) {
    if (_bookingPartnerLocSub != null) return;
    try {
      _bookingPartnerLocSub = FirebaseDatabase.instance
          .ref('live/bookings/$bookingId/partner_location')
          .onValue
          .listen(_onPartnerLocationEvent, onError: (_) {});
    } catch (e) {
      debugPrint('Booking partner location listen skipped: $e');
    }
  }

  Future<void> _callPartner() async {
    final partner = _tracking?['partner'];
    final raw = partner is Map ? partner['phone']?.toString() ?? '' : '';
    var digits = raw.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Partner phone not available')),
      );
      return;
    }
    if (digits.length == 10) digits = '91$digits';
    final uri = Uri.parse('tel:+$digits');
    if (!await launchUrl(uri) && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open dialer')),
      );
    }
  }

  void _openChat() {
    final partner = _tracking?['partner'];
    final name = partner is Map
        ? (partner['name']?.toString() ?? 'Partner')
        : (_booking?.partnerName ?? 'Partner');
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => BookingChatScreen(
          bookingId: widget.bookingId,
          title: name,
        ),
      ),
    );
  }

  double _distanceMeters(LatLng a, LatLng b) {
    const d = Distance();
    return d.as(LengthUnit.Meter, a, b);
  }

  Future<void> _cancelBooking() async {
    final api = context.read<BookingApi>();
    List<Map<String, dynamic>> reasons = [];
    try {
      reasons = await api.cancelReasons(appliesTo: 'user');
    } catch (_) {}
    if (!mounted) return;

    int? selectedId;
    String? selectedLabel;
    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModal) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Cancel booking', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 8),
                    const Text('Select a reason', style: TextStyle(color: AppColors.muted)),
                    const SizedBox(height: 12),
                    if (reasons.isEmpty)
                      const Text('No configured reasons. You can still cancel.')
                    else
                      ...reasons.map((r) {
                        final id = (r['id'] as num?)?.toInt();
                        final label = r['label']?.toString() ?? 'Reason';
                        final charge = r['charge_compensation'] == true;
                        final amount = r['compensation_amount'];
                        final from = r['charge_from']?.toString();
                        return RadioListTile<int>(
                          value: id ?? -1,
                          groupValue: selectedId,
                          onChanged: id == null
                              ? null
                              : (v) => setModal(() {
                                    selectedId = v;
                                    selectedLabel = label;
                                  }),
                          title: Text(label),
                          subtitle: charge
                              ? Text('Compensation ₹$amount from $from')
                              : null,
                        );
                      }),
                    const SizedBox(height: 8),
                    FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.red.shade700,
                        minimumSize: const Size.fromHeight(48),
                      ),
                      onPressed: () {
                        Navigator.pop(ctx, {
                          'id': selectedId,
                          'label': selectedLabel ?? 'Cancelled',
                        });
                      },
                      child: const Text('Confirm cancel'),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
    if (result == null || !mounted) return;
    try {
      await api.cancel(
        widget.bookingId,
        reason: result['label']?.toString(),
        cancelReasonId: result['id'] is int ? result['id'] as int : null,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Booking cancelled')),
      );
      context.pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  String? get _otp {
    final value = _tracking?['customer_otp']?.toString().trim();
    if (value == null || value.isEmpty) return null;
    return value;
  }

  String get _otpHeadline {
    final label = _tracking?['customer_otp_label']?.toString().trim();
    if (label != null && label.isNotEmpty) return label;
    final purpose = _tracking?['customer_otp_purpose']?.toString();
    return switch (purpose) {
      'service_start' => 'Share this OTP to start the service',
      'service_complete' => 'Share this OTP to end the service',
      _ => 'Share this OTP with the partner',
    };
  }

  String _reviewTarget(BookingModel? booking) {
    final slug = (booking?.moduleSlug ?? '').toLowerCase();
    if (slug.contains('laundry')) return 'laundry';
    return 'service';
  }

  Future<void> _promptRating() async {
    if (_ratingPrompted || _rated || !mounted) return;
    final status = (_tracking?['status'] ?? _booking?.status ?? '').toLowerCase();
    if (status != 'completed') return;
    _ratingPrompted = true;
    try {
      final existing = await context.read<BookingApi>().reviews(widget.bookingId);
      if (existing.isNotEmpty) {
        final raw = existing.first['rating'];
        final stars = raw is num ? raw.toInt() : int.tryParse('$raw') ?? 0;
        if (mounted) {
          setState(() {
            _rated = true;
            _savedRating = stars;
          });
        }
        return;
      }
    } catch (_) {}
    if (!mounted) return;
    final result = await askServiceRating(
      context,
      serviceName: _booking?.moduleName ?? 'the service',
      partnerName: _booking?.partnerName,
    );
    if (result == null || !mounted) return;
    try {
      await context.read<BookingApi>().review(
        widget.bookingId,
        rating: result.rating,
        comment: result.comment,
        targetType: _reviewTarget(_booking),
      );
      if (!mounted) return;
      setState(() {
        _rated = true;
        _savedRating = result.rating;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Thanks for rating')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  String get _otpHint {
    final purpose = _tracking?['customer_otp_purpose']?.toString();
    return switch (purpose) {
      'service_start' => 'Tap to copy · Partner enters this to start',
      'service_complete' => 'Tap to copy · Partner enters this to end & settle payment',
      _ => 'Tap to copy · Partner enters this to complete',
    };
  }

  @override
  Widget build(BuildContext context) {
    final booking = _booking;
    final partner = _tracking?['partner'];
    final status = (_tracking?['status'] ?? booking?.status ?? '').toString();
    final partnerName = partner is Map
        ? (partner['name']?.toString() ?? 'Awaiting partner')
        : (booking?.partnerName ?? 'Awaiting partner');
    final otp = _otp;

    return Scaffold(
      appBar: AppBar(title: Text(booking?.bookingNumber ?? 'Live tracking')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(child: Text(_error!))
          : Column(
              children: [
                SizedBox(
                  height: 260,
                  width: double.infinity,
                  child: AppMap(
                    center: _camera,
                    zoom: 15,
                    markers: _markers,
                    polylines: _polylines,
                    fitToOverlays: true,
                  ),
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
                    children: [
                      Text(
                        status.replaceAll('_', ' ').toUpperCase(),
                        style: const TextStyle(
                          color: AppColors.accentOrange,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.6,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        booking?.moduleName ?? 'Service',
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
                      ),
                      if (partner is Map) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.fromLTRB(12, 12, 10, 12),
                          decoration: BoxDecoration(
                            color: AppColors.mist.withValues(alpha: 0.55),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AppColors.navy.withValues(alpha: 0.12)),
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 24,
                                backgroundColor: AppColors.navy.withValues(alpha: 0.12),
                                backgroundImage: (partner['photo_url']?.toString().isNotEmpty ?? false)
                                    ? NetworkImage(partner['photo_url'].toString())
                                    : null,
                                child: (partner['photo_url']?.toString().isNotEmpty ?? false)
                                    ? null
                                    : const Icon(Icons.person, color: AppColors.navy),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Partner',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.muted,
                                      ),
                                    ),
                                    Text(
                                      partnerName,
                                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                                    ),
                                    if ([
                                      if (partner['vehicle_model'] != null) partner['vehicle_model'],
                                      if (partner['vehicle_color'] != null) partner['vehicle_color'],
                                      if (partner['vehicle_number'] != null) partner['vehicle_number'],
                                    ].whereType<Object>().isNotEmpty)
                                      Text(
                                        [
                                          if (partner['vehicle_model'] != null) partner['vehicle_model'],
                                          if (partner['vehicle_color'] != null) partner['vehicle_color'],
                                          if (partner['vehicle_number'] != null) partner['vehicle_number'],
                                        ].whereType<Object>().join(' · '),
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: AppColors.muted,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              IconButton.filledTonal(
                                tooltip: 'Call',
                                onPressed: _callPartner,
                                icon: const Icon(Icons.call, size: 20),
                                style: IconButton.styleFrom(
                                  backgroundColor: AppColors.navy.withValues(alpha: 0.12),
                                  foregroundColor: AppColors.navy,
                                ),
                              ),
                              const SizedBox(width: 4),
                              IconButton.filledTonal(
                                tooltip: 'Chat',
                                onPressed: _openChat,
                                icon: const Icon(Icons.chat_bubble_outline, size: 20),
                                style: IconButton.styleFrom(
                                  backgroundColor: AppColors.navy.withValues(alpha: 0.12),
                                  foregroundColor: AppColors.navy,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ] else ...[
                        const SizedBox(height: 6),
                        Text(partnerName, style: const TextStyle(fontWeight: FontWeight.w700)),
                      ],
                      if (!['completed', 'cancelled', 'canceled'].contains(status.toLowerCase())) ...[
                        const SizedBox(height: 12),
                        OutlinedButton.icon(
                          onPressed: _cancelBooking,
                          icon: const Icon(Icons.cancel_outlined, color: Colors.red),
                          label: const Text('Cancel booking', style: TextStyle(color: Colors.red)),
                        ),
                      ],
                      if (otp != null) ...[
                        const SizedBox(height: 14),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.navy,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            children: [
                              Text(
                                _otpHeadline,
                                textAlign: TextAlign.center,
                                style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(height: 8),
                              GestureDetector(
                                onTap: () async {
                                  await Clipboard.setData(ClipboardData(text: otp));
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('OTP copied')),
                                    );
                                  }
                                },
                                child: Text(
                                  otp.split('').join(' '),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 32,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 6,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _otpHint,
                                textAlign: TextAlign.center,
                                style: const TextStyle(color: Colors.white70, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      ] else if (!['completed', 'cancelled', 'canceled'].contains(status.toLowerCase())) ...[
                        const SizedBox(height: 12),
                        const Text(
                          'OTP will appear here when the partner is assigned / starts the job.',
                          style: TextStyle(color: AppColors.muted, fontSize: 13),
                        ),
                      ],
                      const SizedBox(height: 16),
                      const Text('Order details', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                      const SizedBox(height: 8),
                      if (booking?.addressLine != null)
                        Text('Pickup: ${booking!.addressLine}'),
                      if (booking?.dropAddressLine != null)
                        Text('Drop: ${booking!.dropAddressLine}'),
                      Text('Payment: ${booking?.paymentStatus ?? '—'}'),
                      Text('Total: ₹${(booking?.total ?? 0).toStringAsFixed(2)}'),
                      if (booking != null && booking.items.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        ...booking.items.map(
                          (item) => Text(
                            '${item.name} × ${item.quantity.toStringAsFixed(0)}  ₹${(item.amount ?? 0).toStringAsFixed(0)}',
                          ),
                        ),
                      ],
                      if (status.toLowerCase() == 'completed') ...[
                        const SizedBox(height: 18),
                        const Text('Rate service', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                        const SizedBox(height: 4),
                        Text(
                          _rated ? 'Thanks for rating' : 'Tap a star to rate',
                          style: const TextStyle(color: AppColors.muted, fontSize: 13),
                        ),
                        StarRatingBar(
                          value: _savedRating,
                          enabled: !_rated,
                          onChanged: _rated
                              ? null
                              : (stars) async {
                                  try {
                                    await context.read<BookingApi>().review(
                                      widget.bookingId,
                                      rating: stars,
                                      targetType: _reviewTarget(booking),
                                    );
                                    if (!mounted) return;
                                    setState(() {
                                      _rated = true;
                                      _savedRating = stars;
                                      _ratingPrompted = true;
                                    });
                                  } catch (e) {
                                    if (!mounted) return;
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('$e')),
                                    );
                                  }
                                },
                        ),
                      ],
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: partner is Map ? _callPartner : null,
                              icon: const Icon(Icons.call, size: 18),
                              label: const Text('Call'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: partner is Map ? _openChat : null,
                              icon: const Icon(Icons.chat_bubble_outline, size: 18),
                              label: const Text('Chat'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
