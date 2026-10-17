import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:kaamfast/core/theme/app_theme.dart';
import 'package:kaamfast/features/laundry/laundry_pickup_screen.dart' show instantPickupLead;
import 'package:kaamfast/models/address.dart';
import 'package:kaamfast/models/module.dart';
import 'package:kaamfast/models/quote.dart';
import 'package:kaamfast/providers/auth_provider.dart';
import 'package:kaamfast/services/api_services.dart';
import 'package:kaamfast/services/checkout_helper.dart';
import 'package:kaamfast/services/location_service.dart';
import 'package:kaamfast/widgets/address_picker_sheet.dart';
import 'package:kaamfast/widgets/coupon_apply_card.dart';
import 'package:kaamfast/widgets/filter_pill.dart';
import 'package:kaamfast/widgets/app_header.dart';
import 'package:kaamfast/widgets/payment_method_picker.dart';
import 'package:kaamfast/widgets/photo_upload_box.dart';
import 'package:kaamfast/widgets/schedule_picker.dart';
import 'package:provider/provider.dart';

class LaundryBookingScreen extends StatefulWidget {
  const LaundryBookingScreen({
    super.key,
    this.serviceName,
    this.scheduledAt,
    this.instant = false,
    this.couponCode,
    this.addressId,
  });

  final String? serviceName;
  final int? addressId;
  final DateTime? scheduledAt;
  final bool instant;
  final String? couponCode;

  @override
  State<LaundryBookingScreen> createState() => _LaundryBookingScreenState();
}

class _CartItem {
  _CartItem({required this.service});
  final ServiceItem service;
  int qty = 1;
}

class _LaundryBookingScreenState extends State<LaundryBookingScreen> {
  static const _otherCategory = 'Other';

  List<ServiceItem> _allServices = [];
  String? _filter;
  final Map<int, _CartItem> _cart = {};
  final _billKey = GlobalKey();
  AddressModel? _address;
  QuoteResult? _quote;
  int _quoteSeq = 0;
  String _payMethod = BookingPayMethods.gateway;
  String? _couponCode;
  bool _loading = true;
  bool _quoting = false;
  bool _booking = false;
  String? _error;
  XFile? _photo;
  late DateTime _scheduledAt =
      widget.scheduledAt ?? DateTime.now().add(const Duration(hours: 24));
  late bool _instant = widget.instant;

  /// Instant pickups are re-anchored to "now" so a long stay on this screen never sends a past time.
  DateTime get _pickupAt => _instant ? DateTime.now().add(instantPickupLead) : _scheduledAt;

  @override
  void initState() {
    super.initState();
    final incoming = widget.couponCode?.trim();
    if (incoming != null && incoming.isNotEmpty) {
      _couponCode = incoming.toUpperCase();
    }
    _bootstrap();
  }

  String get _heading {
    final name = widget.serviceName?.trim();
    if (name != null && name.isNotEmpty) return name;
    return 'Laundry';
  }

  String get _slotLabel {
    if (_instant) return 'Instant · within 60 min';
    final d = _scheduledAt;
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final h = d.hour % 12 == 0 ? 12 : d.hour % 12;
    final m = d.minute.toString().padLeft(2, '0');
    final ampm = d.hour >= 12 ? 'PM' : 'AM';
    return '${months[d.month - 1]} ${d.day} · $h:$m $ampm';
  }

  static String _categoryOf(ServiceItem s) {
    final name = s.categoryName?.trim();
    return name == null || name.isEmpty ? _otherCategory : name;
  }

  List<String> get _categories {
    final seen = <String>{};
    for (final s in _allServices) {
      seen.add(_categoryOf(s));
    }
    if (seen.length == 1 && seen.first == _otherCategory) return const [];
    return seen.toList();
  }

  List<ServiceItem> get _services {
    final filter = _filter;
    if (filter == null) return _allServices;
    return _allServices.where((s) => _categoryOf(s) == filter).toList();
  }

  Future<void> _bootstrap() async {
    try {
      final moduleApi = context.read<ModuleService>();
      final addressApi = context.read<AddressApi>();
      final location = context.read<LocationService>();
      final services = await moduleApi.services('laundry');
      final addresses = await addressApi.listRepaired(location);
      if (!mounted) return;
      final selected = widget.serviceName?.trim();
      final initial = selected == null || selected.isEmpty
          ? null
          : services.where((s) => s.matchesSelectedCategory(selected)).firstOrNull;
      setState(() {
        _allServices = services;
        _filter = initial == null ? null : _categoryOf(initial);
        _address = addresses.where((a) => a.id == widget.addressId).firstOrNull ??
            addresses.where((a) => a.isDefault).firstOrNull ??
            (addresses.isNotEmpty ? addresses.first : null);
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = '$e';
        _loading = false;
      });
    }
  }

  List<Map<String, dynamic>> get _itemPayload => _cart.values.map((c) {
        final price = c.service.basePrice ?? 0;
        return {
          'service_id': c.service.id,
          'name': c.service.name,
          'sku': c.service.sku,
          'quantity': c.qty,
          'qty': c.qty,
          // Send every common key — backend sometimes ignores unit_price only.
          'unit_price': price,
          'price': price,
          'base_price': price,
        };
      }).toList();

  double get _catalogSubtotal => _cart.values.fold<double>(
        0,
        (sum, c) => sum + (c.service.basePrice ?? 0) * c.qty,
      );

  QuoteResult? get _activeQuote => _cart.isEmpty ? null : _quote;

  double get _itemTotal => _activeQuote?.subtotal ?? _catalogSubtotal;
  double get _discount => _activeQuote?.discount ?? 0;

  /// Everything the quote charges beyond the items, before the discount.
  double get _extras {
    final q = _activeQuote;
    if (q == null) return 0;
    final extra = q.total - q.subtotal + q.discount;
    return extra < 0 ? 0 : extra;
  }

  /// Bill rows are derived from the quote total so they always add up to "To Pay".
  double get _deliveryFee => (_activeQuote?.deliveryFee ?? 0).clamp(0, _extras).toDouble();
  double get _taxAndFees => _extras - _deliveryFee;

  double get _toPay => _activeQuote?.total ?? 0;

  QuoteResult _localQuote(QuoteResult? previous) {
    final subtotal = _catalogSubtotal;
    final taxRatio = (previous != null && previous.subtotal > 0)
        ? previous.tax / previous.subtotal
        : 0.0;
    final tax = subtotal * taxRatio;
    // Scale coupon discount if server priced against a wrong subtotal.
    var discount = 0.0;
    if (previous != null && previous.discount > 0 && previous.subtotal > 0) {
      discount = previous.discount * (subtotal / previous.subtotal);
    }
    final delivery = previous?.deliveryFee ?? 0;
    // Flat fees (platform fee etc.) don't scale with the item total.
    var flatFees = 0.0;
    if (previous != null) {
      flatFees = previous.total - previous.subtotal - previous.tax - delivery + previous.discount;
      if (flatFees < 0) flatFees = 0;
    }
    final total = subtotal + delivery + tax + flatFees - discount;
    return QuoteResult(
      subtotal: subtotal,
      tax: tax,
      discount: discount,
      total: total < 0 ? 0 : total,
      currency: previous?.currency ?? 'INR',
      breakdown: previous?.breakdown ?? const [],
      meta: previous?.meta ?? const {},
    );
  }

  Future<void> _refreshQuote() async {
    final seq = ++_quoteSeq;
    if (_cart.isEmpty) {
      setState(() {
        _quote = null;
        _quoting = false;
      });
      return;
    }
    setState(() {
      _quoting = true;
      // Show catalog price immediately so UI never flashes a wrong ₹30.
      _quote = _localQuote(_quote);
    });
    try {
      final raw = await context.read<BookingApi>().quote({
        'module_slug': 'laundry',
        'items': _itemPayload,
        if (_address != null) 'address_id': _address!.id,
        'scheduled_at': _pickupAt.toUtc().toIso8601String(),
        if (_couponCode != null && _couponCode!.isNotEmpty)
          'coupon_code': _couponCode,
      });
      if (!mounted || seq != _quoteSeq) return;
      final server = QuoteResult.fromJson(raw);
      final expected = _catalogSubtotal;
      // Admin piece price wins when quote engine returns a different subtotal.
      final matches =
          expected <= 0 || (server.subtotal - expected).abs() < 1;
      setState(() => _quote = matches ? server : _localQuote(server));
    } catch (e) {
      if (!mounted || seq != _quoteSeq) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted && seq == _quoteSeq) setState(() => _quoting = false);
    }
  }

  void _add(ServiceItem service) {
    setState(() {
      final existing = _cart[service.id];
      if (existing == null) {
        _cart[service.id] = _CartItem(service: service);
      } else {
        existing.qty += 1;
      }
    });
    _refreshQuote();
  }

  void _dec(ServiceItem service) {
    setState(() {
      final existing = _cart[service.id];
      if (existing == null) return;
      if (existing.qty <= 1) {
        _cart.remove(service.id);
      } else {
        existing.qty -= 1;
      }
    });
    _refreshQuote();
  }

  Future<void> _pickPhoto() async {
    final file = await pickPhotoWithSource(context);
    if (file != null && mounted) setState(() => _photo = file);
  }

  Future<void> _useCurrentLocation() async {
    final location = context.read<LocationService>();
    final addresses = context.read<AddressApi>();
    final messenger = ScaffoldMessenger.of(context);
    try {
      final place = await location.currentPlace();
      if (!mounted) return;
      final addr = await addresses.savePlace(place, label: 'Current', isDefault: true);
      if (!mounted) return;
      setState(() => _address = addr);
      await _refreshQuote();
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  Future<void> _placeOrder() async {
    if (_cart.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Add at least one item')));
      return;
    }
    if (_address == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Add an address first')));
      final selected = await showAddressPicker(
        context,
        title: 'Select pickup',
        defaultLabel: 'Pickup',
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
        photoPath: _photo?.path,
        customerPhone: user?.phone,
        customerName: user?.name,
        customerEmail: user?.email,
        createBody: {
          'module_slug': 'laundry',
          'items': _itemPayload,
          'address_id': _address!.id,
          'scheduled_at': _pickupAt.toUtc().toIso8601String(),
          if (_instant) 'is_instant': true,
          if (_couponCode != null && _couponCode!.isNotEmpty) 'coupon_code': _couponCode,
          'notes': () {
            final parts = [
              if (_instant) 'INSTANT PICKUP',
              if (widget.serviceName != null && widget.serviceName!.trim().isNotEmpty)
                widget.serviceName!.trim(),
              if (_photo != null) 'Pickup photo uploaded',
            ];
            return parts.isEmpty ? null : parts.join(' · ');
          }(),
        },
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Booked ${booking.bookingNumber}')),
      );
      context.go('/tracking');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _booking = false);
    }
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
                            Text(_heading, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: AppColors.navy)),
                            const SizedBox(height: 4),
                            const Text('Review details before payment.', style: TextStyle(color: AppColors.muted)),
                            const SizedBox(height: 18),
                            const Text('Select items', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.navy)),
                            if (_categories.isNotEmpty) ...[
                              const SizedBox(height: 10),
                              SizedBox(
                                height: 38,
                                child: ListView.separated(
                                  scrollDirection: Axis.horizontal,
                                  itemCount: _categories.length + 1,
                                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                                  itemBuilder: (context, index) {
                                    final value = index == 0 ? null : _categories[index - 1];
                                    return FilterPill(
                                      label: value ?? 'All',
                                      selected: _filter == value,
                                      onTap: () => setState(() => _filter = value),
                                    );
                                  },
                                ),
                              ),
                            ],
                            const SizedBox(height: 12),
                            if (_services.isEmpty)
                              const Padding(
                                padding: EdgeInsets.only(bottom: 12),
                                child: Text(
                                  'No items in this category yet.',
                                  style: TextStyle(color: AppColors.muted),
                                ),
                              )
                            else
                              ..._services.map(
                                (service) => _ServiceRow(
                                  service: service,
                                  qty: _cart[service.id]?.qty ?? 0,
                                  onAdd: () => _add(service),
                                  onRemove: () => _dec(service),
                                ),
                              ),
                            if (_cart.isNotEmpty) ...[
                              const SizedBox(height: 10),
                              const Text('Items added', style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.navy)),
                              const SizedBox(height: 8),
                            ],
                            ..._cart.values.map((c) {
                              return _SoftCard(
                                child: Row(
                                  children: [
                                    Container(
                                      width: 44,
                                      height: 44,
                                      decoration: BoxDecoration(
                                        color: AppColors.navy,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Icon(Icons.checkroom, color: Colors.white),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(c.service.name, style: const TextStyle(fontWeight: FontWeight.w800)),
                                          Text(
                                            'Qty ${c.qty}${c.service.unit != null ? ' · ${c.service.unit}' : ''}',
                                            style: const TextStyle(color: AppColors.muted, fontSize: 12),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Text(
                                      '₹${((c.service.basePrice ?? 0) * c.qty).toStringAsFixed(0)}',
                                      style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.navy),
                                    ),
                                  ],
                                ),
                              );
                            }),
                            const SizedBox(height: 8),
                            _SoftCard(
                              child: Column(
                                children: [
                                  _EditRow(
                                    icon: Icons.location_on_outlined,
                                    label: 'PICKUP ADDRESS',
                                    value: _address?.shortLine ?? 'Add pickup address',
                                    onEdit: () async {
                                      final selected = await showAddressPicker(
                                        context,
                                        title: 'Select pickup',
                                        defaultLabel: 'Pickup',
                                        updateHeader: true,
                                      );
                                      if (selected == null || !mounted) return;
                                      setState(() => _address = selected);
                                      await _refreshQuote();
                                    },
                                  ),
                                  const Divider(height: 20),
                                  _EditRow(
                                    icon: Icons.schedule_rounded,
                                    label: 'PICKUP TIME',
                                    value: _slotLabel,
                                    onEdit: () async {
                                      final picked = await pickSchedule(
                                        context,
                                        initial: _scheduledAt,
                                      );
                                      if (picked == null || !mounted) return;
                                      setState(() {
                                        _scheduledAt = picked;
                                        _instant = false;
                                      });
                                      await _refreshQuote();
                                    },
                                  ),
                                  TextButton.icon(
                                    onPressed: _useCurrentLocation,
                                    icon: const Icon(Icons.my_location, size: 16),
                                    label: const Text('Use current location'),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 10),
                            CouponApplyCard(
                              moduleSlug: 'laundry',
                              appliedCode: _couponCode,
                              addressId: _address?.id,
                              items: _itemPayload,
                              subtotal: _itemTotal,
                              busy: _quoting || _booking,
                              onChanged: (code) async {
                                setState(() => _couponCode = code);
                                await _refreshQuote();
                              },
                            ),
                            if (_cart.isNotEmpty) ...[
                              const SizedBox(height: 16),
                              Text(
                                'Bill Details',
                                key: _billKey,
                                style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.navy),
                              ),
                              const SizedBox(height: 8),
                              _SoftCard(
                                child: Column(
                                  children: [
                                    if (_quoting) const LinearProgressIndicator(),
                                    _billRow('Item Total', '₹${_itemTotal.toStringAsFixed(2)}'),
                                    if (_deliveryFee > 0)
                                      _billRow(
                                        'Pickup & Delivery',
                                        '₹${_deliveryFee.toStringAsFixed(2)}',
                                        info: true,
                                      ),
                                    if (_taxAndFees > 0)
                                      _billRow('Taxes & Platform Fee', '₹${_taxAndFees.toStringAsFixed(2)}', info: true),
                                    if (_discount > 0)
                                      _billRow(
                                        'Discount',
                                        '-₹${_discount.toStringAsFixed(2)}',
                                        danger: true,
                                      ),
                                    const Divider(height: 20),
                                    _billRow('To Pay', '₹${_toPay.toStringAsFixed(2)}', bold: true),
                                  ],
                                ),
                              ),
                            ],
                            const SizedBox(height: 16),
                            PaymentMethodPicker(
                              value: _payMethod,
                              onChanged: (m) => setState(() => _payMethod = m),
                            ),
                            const SizedBox(height: 8),
                            const SizedBox(height: 8),
                            const Text('Clothes photo', style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.navy)),
                            const SizedBox(height: 8),
                            PhotoUploadBox(
                              title: 'Upload clothes photo',
                              photo: _photo,
                              onPick: _pickPhoto,
                              onRemove: () => setState(() => _photo = null),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          border: Border(top: BorderSide(color: AppColors.line)),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('₹${_toPay.toStringAsFixed(2)}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppColors.navy)),
                                  TextButton(
                                    style: TextButton.styleFrom(
                                      padding: EdgeInsets.zero,
                                      minimumSize: Size.zero,
                                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                    ),
                                    onPressed: () {
                                      final target = _billKey.currentContext;
                                      if (target == null) return;
                                      Scrollable.ensureVisible(
                                        target,
                                        duration: const Duration(milliseconds: 300),
                                        alignment: 0.1,
                                      );
                                    },
                                    child: const Text('VIEW DETAILED BILL', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.navy)),
                                  ),
                                ],
                              ),
                            ),
                            Expanded(
                              child: FilledButton.icon(
                                onPressed: _booking || _quoting || _cart.isEmpty ? null : _placeOrder,
                                icon: _booking
                                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                    : const Icon(Icons.lock_outline, size: 18),
                                label: Text(_booking ? 'Paying...' : 'Pay Securely'),
                                style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
                              ),
                            ),
                          ],
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

  Widget _billRow(String label, String value, {bool bold = false, bool danger = false, bool info = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Expanded(
            child: Row(
              children: [
                Text(label, style: TextStyle(fontWeight: bold ? FontWeight.w800 : FontWeight.w500, color: bold ? AppColors.navy : AppColors.ink)),
                if (info) ...[
                  const SizedBox(width: 4),
                  const Icon(Icons.info_outline, size: 14, color: AppColors.muted),
                ],
              ],
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: bold ? FontWeight.w900 : FontWeight.w700,
              color: danger ? AppColors.danger : AppColors.navy,
            ),
          ),
        ],
      ),
    );
  }
}

class _ServiceRow extends StatelessWidget {
  const _ServiceRow({
    required this.service,
    required this.qty,
    required this.onAdd,
    required this.onRemove,
  });

  final ServiceItem service;
  final int qty;
  final VoidCallback onAdd;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final url = service.imageUrl?.trim();
    final unit = service.unit?.trim();
    final fallback = const Icon(Icons.checkroom_rounded, color: AppColors.navy, size: 22);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: qty > 0 ? AppColors.navy : AppColors.line, width: qty > 0 ? 1.4 : 1),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(color: AppColors.sky, borderRadius: BorderRadius.circular(12)),
            clipBehavior: Clip.antiAlias,
            child: url == null || url.isEmpty
                ? fallback
                : Image.network(url, fit: BoxFit.cover, errorBuilder: (_, _, _) => fallback),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  service.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.navy),
                ),
                const SizedBox(height: 2),
                Text(
                  '₹${(service.basePrice ?? 0).toStringAsFixed(0)}'
                  '${unit != null && unit.isNotEmpty ? ' / $unit' : ''}',
                  style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.accentOrange),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (qty == 0)
            OutlinedButton(
              onPressed: onAdd,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.navy,
                side: const BorderSide(color: AppColors.navy),
                minimumSize: const Size(72, 36),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('ADD', style: TextStyle(fontWeight: FontWeight.w800)),
            )
          else
            Container(
              height: 36,
              decoration: BoxDecoration(color: AppColors.navy, borderRadius: BorderRadius.circular(10)),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    onPressed: onRemove,
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(Icons.remove_rounded, color: Colors.white, size: 18),
                  ),
                  Text('$qty', style: const TextStyle(fontWeight: FontWeight.w800, color: Colors.white)),
                  IconButton(
                    onPressed: onAdd,
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(Icons.add_rounded, color: Colors.white, size: 18),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _SoftCard extends StatelessWidget {
  const _SoftCard({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.sky,
        borderRadius: BorderRadius.circular(14),
      ),
      child: child,
    );
  }
}

class _EditRow extends StatelessWidget {
  const _EditRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.onEdit,
  });

  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppColors.navy, size: 20),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 10, letterSpacing: 0.8, fontWeight: FontWeight.w700, color: AppColors.muted)),
              const SizedBox(height: 2),
              Text(value, style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.ink)),
            ],
          ),
        ),
        TextButton(
          onPressed: onEdit,
          child: const Text('Edit', style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.navy)),
        ),
      ],
    );
  }
}
