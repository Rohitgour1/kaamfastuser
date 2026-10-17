import 'package:flutter/material.dart';
import 'package:kaamfast/core/theme/app_theme.dart';
import 'package:kaamfast/models/booking.dart';
import 'package:kaamfast/providers/auth_provider.dart';
import 'package:kaamfast/services/api_services.dart';
import 'package:kaamfast/services/checkout_helper.dart';
import 'package:kaamfast/services/live_sync.dart';
import 'package:kaamfast/widgets/payment_method_picker.dart';
import 'package:provider/provider.dart';

class BookingDetailScreen extends StatefulWidget {
  const BookingDetailScreen({super.key, required this.bookingId});

  final int bookingId;

  @override
  State<BookingDetailScreen> createState() => _BookingDetailScreenState();
}

class _BookingDetailScreenState extends State<BookingDetailScreen> {
  BookingModel? _booking;
  bool _loading = true;
  bool _paying = false;
  String? _error;
  int _rating = 5;
  final _comment = TextEditingController();
  LiveSync? _live;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final live = context.read<LiveSync>();
    if (_live != live) {
      _live?.removeListener(_onLive);
      _live = live;
      _live!.addListener(_onLive);
    }
  }

  void _onLive() {
    _load(silent: true);
  }

  @override
  void dispose() {
    _live?.removeListener(_onLive);
    _comment.dispose();
    super.dispose();
  }

  Future<void> _load({bool silent = false}) async {
    if (!silent) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final wasPending = _booking?.status == 'pending';
      final booking = await context.read<BookingApi>().show(widget.bookingId);
      if (!mounted) return;

      final isNowCancelled = booking.status == 'cancelled';
      if (wasPending && isNowCancelled && booking.cancelReason == 'auto_cancelled_no_partner') {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Booking Cancelled'),
            content: const Text('No partner available now try again after some time'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }

      setState(() {
        _booking = booking;
        if (!silent) _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      if (!silent) {
        setState(() {
          _error = '$e';
          _loading = false;
        });
      }
    }
  }

  Future<void> _payNow() async {
    final booking = _booking;
    if (booking == null || _paying) return;

    final selected = await showPaymentMethodSheet(context);
    if (selected == null || !mounted) return;

    setState(() => _paying = true);
    try {
      final api = context.read<BookingApi>();
      final user = context.read<AuthProvider>().user;
      await payBooking(
        bookingApi: api,
        booking: booking,
        method: selected,
        customerPhone: user?.phone,
        customerEmail: user?.email,
      );
      if (booking.status == 'pending') {
        await api.confirm(booking.id);
      }
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _paying = false);
    }
  }

  Future<void> _cancel() async {
    final reason = await showDialog<String>(
      context: context,
      builder: (context) {
        final c = TextEditingController(text: 'Changed plans');
        return AlertDialog(
          title: const Text('Cancel booking'),
          content: TextField(
            controller: c,
            decoration: const InputDecoration(labelText: 'Reason'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Back'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, c.text.trim()),
              child: const Text('Cancel booking'),
            ),
          ],
        );
      },
    );
    if (reason == null || reason.isEmpty || !mounted) return;
    try {
      await context.read<BookingApi>().cancel(
        widget.bookingId,
        reason: reason,
      );
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  Future<void> _review(String target) async {
    try {
      await context.read<BookingApi>().review(
        widget.bookingId,
        rating: _rating,
        comment: _comment.text.trim().isEmpty ? null : _comment.text.trim(),
        targetType: target,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Rated $target')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final booking = _booking;
    return Scaffold(
      appBar: AppBar(title: Text(booking?.bookingNumber ?? 'Booking')),
      body: Stack(
        children: [
          _loading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
              ? Center(child: Text(_error!))
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          booking!.moduleName ?? 'Service',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text('Status: ${booking.status}'),
                        Text('Payment: ${booking.paymentStatus ?? '—'}'),
                        Text(
                          'Total: ₹${(booking.total ?? 0).toStringAsFixed(2)}',
                        ),
                        if (booking.partnerName != null)
                          Text('Partner: ${booking.partnerName}'),
                        if (booking.addressLine != null) ...[
                          const SizedBox(height: 8),
                          Text('Pickup: ${booking.addressLine}'),
                        ],
                        if (booking.dropAddressLine != null)
                          Text('Drop: ${booking.dropAddressLine}'),
                        if (booking.meta['parcel_type'] != null)
                          Text(
                            'Parcel: ${booking.meta['parcel_type']} · ${booking.meta['weight_kg'] ?? ''} kg',
                          ),
                      ],
                    ),
                  ),
                ),
                if (booking.legs.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    booking.moduleSlug == 'laundry'
                        ? 'Laundry flow'
                        : 'Job legs',
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...booking.legs.map(
                    (leg) => Card(
                      child: ListTile(
                        title: Text(leg.label ?? leg.legType ?? 'Leg'),
                        subtitle: Text(leg.partnerName ?? 'Unassigned'),
                        trailing: Text(
                          leg.status ?? '',
                          style: const TextStyle(color: AppColors.muted),
                        ),
                      ),
                    ),
                  ),
                ],
                if (booking.photos.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  const Text(
                    'Photos',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 96,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: booking.photos.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 8),
                      itemBuilder: (context, index) {
                        final photo = booking.photos[index];
                        return ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            photo.url,
                            width: 96,
                            height: 96,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => Container(
                              width: 96,
                              height: 96,
                              color: AppColors.mist,
                              child: const Icon(Icons.broken_image_outlined),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
                if (booking.items.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  const Text(
                    'Items',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                  ),
                  ...booking.items.map(
                    (item) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(item.name),
                      trailing: Text(
                        'x${item.quantity.toStringAsFixed(0)} · ₹${(item.amount ?? 0).toStringAsFixed(0)}',
                      ),
                    ),
                  ),
                ],
                if (booking.status == 'completed') ...[
                  const SizedBox(height: 16),
                  const Text(
                    'Rate service',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                  ),
                  Slider(
                    value: _rating.toDouble(),
                    min: 1,
                    max: 5,
                    divisions: 4,
                    label: '$_rating',
                    onChanged: (v) => setState(() => _rating = v.round()),
                  ),
                  TextField(
                    controller: _comment,
                    decoration: const InputDecoration(
                      labelText: 'Comment (optional)',
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      for (final t
                          in (booking.moduleSlug == 'laundry'
                              ? ['pickup', 'laundry', 'drop']
                              : ['service']))
                        OutlinedButton(
                          onPressed: () => _review(t),
                          child: Text('Rate $t'),
                        ),
                    ],
                  ),
                ],
                if (_needsPayment(booking)) ...[
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: _paying ? null : _payNow,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.navy,
                    ),
                    child: Text(
                      _paying ? 'Opening Razorpay...' : 'Pay now with Razorpay',
                    ),
                  ),
                ],
                if (!['completed', 'cancelled'].contains(booking.status)) ...[
                  const SizedBox(height: 20),
                  OutlinedButton(
                    onPressed: _cancel,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.danger,
                    ),
                    child: const Text('Cancel booking'),
                  ),
                ],
                ],
              ),
          if (_paying)
            Container(
              color: Colors.black45,
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }

  bool _needsPayment(BookingModel booking) {
    final bookingStatus = booking.status.toLowerCase();
    if (['cancelled', 'canceled', 'completed'].contains(bookingStatus)) {
      return false;
    }
    final status = (booking.paymentStatus ?? '').toLowerCase();
    return status.isEmpty ||
        status == 'pending' ||
        status == 'unpaid' ||
        status == 'failed' ||
        status == 'created';
  }
}
