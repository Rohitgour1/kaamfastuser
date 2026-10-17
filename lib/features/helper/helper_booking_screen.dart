import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:kaamfast/core/theme/app_theme.dart';
import 'package:kaamfast/models/address.dart';
import 'package:kaamfast/models/module.dart';
import 'package:kaamfast/models/quote.dart';
import 'package:kaamfast/providers/auth_provider.dart';
import 'package:kaamfast/services/api_services.dart';
import 'package:kaamfast/services/checkout_helper.dart';
import 'package:kaamfast/services/location_service.dart';
import 'package:kaamfast/widgets/address_picker_sheet.dart';
import 'package:kaamfast/widgets/coupon_apply_card.dart';
import 'package:kaamfast/widgets/app_header.dart';
import 'package:kaamfast/widgets/payment_method_picker.dart';
import 'package:provider/provider.dart';

class HelperBookingScreen extends StatefulWidget {
  const HelperBookingScreen({super.key, this.initialServiceHint, this.serviceId});

  final String? initialServiceHint;
  final int? serviceId;

  @override
  State<HelperBookingScreen> createState() => _HelperBookingScreenState();
}

class _HelperBookingScreenState extends State<HelperBookingScreen> {
  ServiceItem? _service;
  AddressModel? _address;
  int _hours = 2;
  QuoteResult? _quote;
  int _quoteSeq = 0;
  String _payMethod = BookingPayMethods.gateway;
  String _notes = '';
  String? _couponCode;
  bool _loading = true;
  bool _quoting = false;
  bool _booking = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    final moduleApi = context.read<ModuleService>();
    final addressApi = context.read<AddressApi>();
    try {
      final services = await moduleApi.services('helper');
      final addresses = await addressApi.listRepaired(context.read<LocationService>());
      if (!mounted) return;

      ServiceItem? preferred = services.where((s) => s.id == widget.serviceId).firstOrNull;
      final hint = widget.initialServiceHint?.toLowerCase();
      if (preferred == null && hint != null && hint.isNotEmpty) {
        for (final s in services) {
          if (s.name.toLowerCase().contains(hint)) {
            preferred = s;
            break;
          }
        }
      }

      setState(() {
        _service = preferred ?? (services.isNotEmpty ? services.first : null);
        _address = addresses.where((a) => a.isDefault).firstOrNull ??
            (addresses.isNotEmpty ? addresses.first : null);
        _loading = false;
      });
      await _refreshQuote();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = '$e';
        _loading = false;
      });
    }
  }

  double get _hourlyRate => _service?.basePrice ?? 0;

  QuoteResult _localQuote() {
    final subtotal = _hourlyRate * _hours;
    final previous = _quote;
    final taxRatio = (previous != null && previous.subtotal > 0)
        ? previous.tax / previous.subtotal
        : 0.18;
    final tax = subtotal * taxRatio;
    return QuoteResult(
      subtotal: subtotal,
      tax: tax,
      total: subtotal + tax,
      discount: previous?.discount ?? 0,
      currency: previous?.currency ?? 'INR',
    );
  }

  Future<void> _refreshQuote() async {
    final seq = ++_quoteSeq;
    setState(() {
      _quoting = true;
      _quote = _localQuote();
    });
    try {
      final raw = await context.read<BookingApi>().quote({
        'module_slug': 'helper',
        if (_service != null) 'service_id': _service!.id,
        if (_address != null) 'address_id': _address!.id,
        'hours': _hours,
        'duration_hours': _hours,
        if (_couponCode != null && _couponCode!.isNotEmpty) 'coupon_code': _couponCode,
      });
      if (!mounted || seq != _quoteSeq) return;
      final server = QuoteResult.fromJson(raw);
      final expected = _hourlyRate * _hours;
      final matchesService = _hourlyRate <= 0 || (server.subtotal - expected).abs() < 1;
      setState(() => _quote = matchesService ? server : _localQuote());
    } catch (e) {
      if (!mounted || seq != _quoteSeq) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted && seq == _quoteSeq) setState(() => _quoting = false);
    }
  }

  Future<void> _placeOrder() async {
    if (_address == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Add an address first')));
      final selected = await showAddressPicker(
        context,
        title: 'Select address',
        defaultLabel: 'Home',
        updateHeader: true,
      );
      if (selected != null && mounted) {
        setState(() => _address = selected);
        await _refreshQuote();
      }
      return;
    }
    setState(() => _booking = true);
    try {
      final bookingApi = context.read<BookingApi>();
      final user = context.read<AuthProvider>().user;
      final booking = await placeBookingAndPay(
        bookingApi: bookingApi,
        method: _payMethod,
        customerPhone: user?.phone,
        customerName: user?.name,
        customerEmail: user?.email,
        createBody: {
          'module_slug': 'helper',
          if (_service != null) 'service_id': _service!.id,
          'address_id': _address!.id,
          'hours': _hours,
          'duration_hours': _hours,
          if (_couponCode != null && _couponCode!.isNotEmpty) 'coupon_code': _couponCode,
          'notes': _notes.isEmpty ? '${_service?.name} · $_hours hr' : _notes,
          'meta': {
            'service_name': _service?.name,
            'hours': _hours,
            'category': _service?.name,
          },
        },
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Booked ${booking.bookingNumber}')));
      context.go('/tracking');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _booking = false);
    }
  }

  IconData _iconFor(String name) {
    final n = name.toLowerCase();
    if (n.contains('electric')) return Icons.electrical_services_outlined;
    if (n.contains('labour') || n.contains('labor') || n.contains('moving')) return Icons.fitness_center_outlined;
    if (n.contains('shop')) return Icons.shopping_bag_outlined;
    if (n.contains('assistant') || n.contains('household')) return Icons.handshake_outlined;
    return Icons.handyman_outlined;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(child: Text(_error!))
                    : Column(
                        children: [
                          const AppHeader(),
                          Expanded(
                            child: ListView(
                              padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                          children: [
                            const Text('Hire a Helper', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: AppColors.navy)),
                            const SizedBox(height: 4),
                            const Text('Choose how many hours you need.', style: TextStyle(color: AppColors.muted)),
                            const SizedBox(height: 18),
                            if (_service != null)
                              Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: AppColors.navy,
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Row(
                                  children: [
                                    Icon(_iconFor(_service!.name), color: Colors.white),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        _service!.name,
                                        style: const TextStyle(fontWeight: FontWeight.w700, color: Colors.white),
                                      ),
                                    ),
                                    Text(
                                      '₹${_hourlyRate.toStringAsFixed(0)}/hr',
                                      style: const TextStyle(fontWeight: FontWeight.w800, color: Colors.white),
                                    ),
                                  ],
                                ),
                              ),
                            const SizedBox(height: 18),
                            const Text('Duration', style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.navy)),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                IconButton(
                                  onPressed: _hours <= 1
                                      ? null
                                      : () {
                                          setState(() => _hours -= 1);
                                          _refreshQuote();
                                        },
                                  icon: const Icon(Icons.remove_circle_outline),
                                ),
                                Text('$_hours hour${_hours == 1 ? '' : 's'}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                                IconButton(
                                  onPressed: _hours >= 12
                                      ? null
                                      : () {
                                          setState(() => _hours += 1);
                                          _refreshQuote();
                                        },
                                  icon: const Icon(Icons.add_circle_outline, color: AppColors.navy),
                                ),
                              ],
                            ),
                            ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: const Icon(Icons.place_outlined, color: AppColors.navy),
                              title: const Text('Service address'),
                              subtitle: Text(_address?.shortLine ?? 'Select address'),
                              trailing: const Icon(Icons.chevron_right),
                              onTap: () async {
                                final selected = await showAddressPicker(
                                  context,
                                  title: 'Select address',
                                  defaultLabel: 'Home',
                                  updateHeader: true,
                                );
                                if (selected == null || !mounted) return;
                                setState(() => _address = selected);
                                await _refreshQuote();
                              },
                            ),
                            TextField(
                              maxLines: 2,
                              decoration: const InputDecoration(
                                labelText: 'Describe the task (optional)',
                                hintText: 'Fan repair, packing help…',
                                border: OutlineInputBorder(),
                              ),
                              onChanged: (v) => _notes = v,
                            ),
                            const SizedBox(height: 16),
                            CouponApplyCard(
                              moduleSlug: 'helper',
                              appliedCode: _couponCode,
                              addressId: _address?.id,
                              serviceId: _service?.id,
                              subtotal: _quote?.subtotal,
                              busy: _quoting || _booking,
                              onChanged: (code) async {
                                setState(() => _couponCode = code);
                                await _refreshQuote();
                              },
                            ),
                            const SizedBox(height: 16),
                            if (_quoting) const LinearProgressIndicator(minHeight: 2),
                            Card(
                                child: Padding(
                                  padding: const EdgeInsets.all(14),
                                  child: Column(
                                    children: [
                                      _PayRow('Rate', '₹${_hourlyRate.toStringAsFixed(0)}/hr'),
                                      _PayRow('Hours', '$_hours'),
                                      _PayRow('Subtotal', '₹${(_quote?.subtotal ?? 0).toStringAsFixed(0)}'),
                                      if ((_quote?.discount ?? 0) > 0)
                                        _PayRow('Discount', '-₹${_quote!.discount.toStringAsFixed(0)}'),
                                      _PayRow('Tax', '₹${(_quote?.tax ?? 0).toStringAsFixed(0)}'),
                                      const Divider(),
                                      _PayRow('To pay', '₹${(_quote?.total ?? 0).toStringAsFixed(0)}', bold: true),
                                    ],
                                  ),
                                ),
                              ),
                            const SizedBox(height: 12),
                            PaymentMethodPicker(
                              value: _payMethod,
                              onChanged: (m) => setState(() => _payMethod = m),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        child: FilledButton(
                          style: FilledButton.styleFrom(backgroundColor: AppColors.navy, minimumSize: const Size.fromHeight(52)),
                          onPressed: _booking || _quote == null ? null : _placeOrder,
                          child: Text(_booking ? 'Booking…' : 'Confirm & pay'),
                        ),
                      ),
                    ],
                  ),
            if (_booking)
              Container(
                color: Colors.black45,
                child: const Center(
                  child: CircularProgressIndicator(),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _PayRow extends StatelessWidget {
  const _PayRow(this.label, this.value, {this.bold = false});
  final String label;
  final String value;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(child: Text(label, style: TextStyle(fontWeight: bold ? FontWeight.w800 : FontWeight.w500))),
          Text(value, style: TextStyle(fontWeight: bold ? FontWeight.w800 : FontWeight.w600, color: AppColors.navy)),
        ],
      ),
    );
  }
}
