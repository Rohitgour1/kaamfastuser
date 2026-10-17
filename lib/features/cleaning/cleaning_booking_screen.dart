import 'package:cached_network_image/cached_network_image.dart';
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

class CleaningBookingScreen extends StatefulWidget {
  const CleaningBookingScreen({super.key, this.categorySlug});

  /// Optional category slug from home (e.g. deep-cleaning).
  final String? categorySlug;

  @override
  State<CleaningBookingScreen> createState() => _CleaningBookingScreenState();
}

class _CleaningBookingScreenState extends State<CleaningBookingScreen> {
  List<ServiceItem> _services = [];
  ServiceItem? _service;
  AddressModel? _address;

  /// Selected quantities keyed by addon code (from selected service only).
  final Map<String, int> _addonQty = {};

  QuoteResult? _quote;
  String _payMethod = BookingPayMethods.gateway;
  String _notes = '';
  String? _couponCode;
  bool _loading = true;
  bool _quoting = false;
  bool _booking = false;
  String? _error;

  List<ServiceAddon> get _availableAddons => _service?.addons ?? const [];

  List<Map<String, dynamic>> get _addonPayload => _availableAddons
      .where((a) => (_addonQty[a.code] ?? 0) > 0)
      .map(
        (a) => {
          'code': a.code,
          'quantity': _addonQty[a.code] ?? 0,
        },
      )
      .toList();

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  void _selectService(ServiceItem service) {
    setState(() {
      _service = service;
      _addonQty
        ..clear()
        ..addEntries(
          service.addons.map((a) => MapEntry(a.code, 0)),
        );
      _quote = null;
    });
    _refreshQuote();
  }

  Future<void> _bootstrap() async {
    final moduleApi = context.read<ModuleService>();
    final addressApi = context.read<AddressApi>();
    final location = context.read<LocationService>();
    try {
      final services = await moduleApi.services('cleaning');
      final addresses = await addressApi.listRepaired(location);
      if (!mounted) return;

      final cat = widget.categorySlug?.trim().toLowerCase();
      var visible = services;
      if (cat != null && cat.isNotEmpty) {
        final filtered = services.where((s) {
          final slug = s.categorySlug?.toLowerCase();
          final name = s.categoryName?.toLowerCase();
          return slug == cat ||
              (name != null && name.replaceAll(' ', '-') == cat) ||
              s.matchesSelectedCategory(widget.categorySlug);
        }).toList();
        if (filtered.isNotEmpty) visible = filtered;
      }

      setState(() {
        _services = visible;
        _address = addresses.where((a) => a.isDefault).firstOrNull ??
            (addresses.isNotEmpty ? addresses.first : null);
        _loading = false;
      });
      if (visible.isNotEmpty) {
        _selectService(visible.first);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = '$e';
        _loading = false;
      });
    }
  }

  Future<void> _refreshQuote() async {
    if (_service == null) {
      setState(() => _quote = null);
      return;
    }
    setState(() => _quoting = true);
    try {
      final raw = await context.read<BookingApi>().quote({
        'module_slug': 'cleaning',
        'service_id': _service!.id,
        if (_address != null) 'address_id': _address!.id,
        'addons': _addonPayload,
        if (_couponCode != null && _couponCode!.isNotEmpty)
          'coupon_code': _couponCode,
      });
      if (!mounted) return;
      setState(() => _quote = QuoteResult.fromJson(raw));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _quoting = false);
    }
  }

  void _setAddonQty(ServiceAddon addon, int qty) {
    final next = qty < 0 ? 0 : qty;
    if (!addon.isQuantityBased) {
      setState(() => _addonQty[addon.code] = next > 0 ? 1 : 0);
    } else {
      setState(() => _addonQty[addon.code] = next);
    }
    _refreshQuote();
  }

  Future<void> _placeOrder() async {
    if (_service == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select a service first')),
      );
      return;
    }
    if (_address == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add an address first')),
      );
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
          'module_slug': 'cleaning',
          'service_id': _service!.id,
          'address_id': _address!.id,
          'addons': _addonPayload,
          if (_couponCode != null && _couponCode!.isNotEmpty)
            'coupon_code': _couponCode,
          'notes': _notes.isEmpty ? _service?.name : _notes,
          'meta': {
            'service_name': _service?.name,
            'addons': _addonPayload,
          },
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
                              padding:
                                  const EdgeInsets.fromLTRB(16, 4, 16, 24),
                              children: [
                                const Text(
                                  'Book Cleaning',
                                  style: TextStyle(
                                    fontSize: 26,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.navy,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  'Choose service, rooms, and confirm quote.',
                                  style: TextStyle(color: AppColors.muted),
                                ),
                                const SizedBox(height: 18),
                                const Text(
                                  'Service',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.navy,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                GridView.builder(
                                  shrinkWrap: true,
                                  physics:
                                      const NeverScrollableScrollPhysics(),
                                  itemCount: _services.length,
                                  gridDelegate:
                                      const
                                          SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 2,
                                    mainAxisSpacing: 12,
                                    crossAxisSpacing: 12,
                                    childAspectRatio: 0.92,
                                  ),
                                  itemBuilder: (context, index) {
                                    final s = _services[index];
                                    final selected = _service?.id == s.id;
                                    return _ServiceSquareCard(
                                      service: s,
                                      selected: selected,
                                      onTap: () => _selectService(s),
                                    );
                                  },
                                ),
                                const SizedBox(height: 18),
                                const Text(
                                  'Rooms / add-ons',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.navy,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                if (_availableAddons.isEmpty)
                                  const Padding(
                                    padding: EdgeInsets.only(bottom: 8),
                                    child: Text(
                                      'No add-ons for this service.',
                                      style: TextStyle(color: AppColors.muted),
                                    ),
                                  )
                                else
                                  ..._availableAddons.map((addon) {
                                    final qty = _addonQty[addon.code] ?? 0;
                                    return Card(
                                      child: ListTile(
                                        title: Text(addon.name),
                                        subtitle: Text(addon.priceLabel),
                                        trailing: addon.isQuantityBased
                                            ? Row(
                                                mainAxisSize:
                                                    MainAxisSize.min,
                                                children: [
                                                  IconButton(
                                                    onPressed: qty <= 0
                                                        ? null
                                                        : () => _setAddonQty(
                                                              addon,
                                                              qty - 1,
                                                            ),
                                                    icon: const Icon(
                                                      Icons
                                                          .remove_circle_outline,
                                                    ),
                                                  ),
                                                  Text(
                                                    '$qty',
                                                    style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.w800,
                                                    ),
                                                  ),
                                                  IconButton(
                                                    onPressed: () =>
                                                        _setAddonQty(
                                                      addon,
                                                      qty + 1,
                                                    ),
                                                    icon: const Icon(
                                                      Icons
                                                          .add_circle_outline,
                                                      color: AppColors.navy,
                                                    ),
                                                  ),
                                                ],
                                              )
                                            : Switch.adaptive(
                                                value: qty > 0,
                                                activeThumbColor:
                                                    AppColors.navy,
                                                onChanged: (on) =>
                                                    _setAddonQty(
                                                  addon,
                                                  on ? 1 : 0,
                                                ),
                                              ),
                                      ),
                                    );
                                  }),
                                const SizedBox(height: 12),
                                ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  leading: const Icon(
                                    Icons.place_outlined,
                                    color: AppColors.navy,
                                  ),
                                  title: const Text('Service address'),
                                  subtitle: Text(
                                    _address?.shortLine ?? 'Select address',
                                  ),
                                  trailing:
                                      const Icon(Icons.chevron_right),
                                  onTap: () async {
                                    final selected =
                                        await showAddressPicker(
                                      context,
                                      title: 'Select address',
                                      defaultLabel: 'Home',
                                      updateHeader: true,
                                    );
                                    if (selected == null || !mounted) {
                                      return;
                                    }
                                    setState(() => _address = selected);
                                    await _refreshQuote();
                                  },
                                ),
                                TextField(
                                  maxLines: 2,
                                  decoration: const InputDecoration(
                                    labelText: 'Notes (optional)',
                                    border: OutlineInputBorder(),
                                  ),
                                  onChanged: (v) => _notes = v,
                                ),
                                const SizedBox(height: 16),
                                CouponApplyCard(
                                  moduleSlug: 'cleaning',
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
                                if (_quoting)
                                  const LinearProgressIndicator(minHeight: 2)
                                else
                                  Card(
                                    child: Padding(
                                      padding: const EdgeInsets.all(14),
                                      child: Column(
                                        children: [
                                          _PayRow(
                                            'Subtotal',
                                            '₹${(_quote?.subtotal ?? 0).toStringAsFixed(0)}',
                                          ),
                                          if ((_quote?.discount ?? 0) > 0)
                                            _PayRow(
                                              'Discount',
                                              '-₹${_quote!.discount.toStringAsFixed(0)}',
                                            ),
                                          _PayRow(
                                            'Tax',
                                            '₹${(_quote?.tax ?? 0).toStringAsFixed(0)}',
                                          ),
                                          const Divider(),
                                          _PayRow(
                                            'To pay',
                                            '₹${(_quote?.total ?? 0).toStringAsFixed(0)}',
                                            bold: true,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                const SizedBox(height: 12),
                                PaymentMethodPicker(
                                  value: _payMethod,
                                  onChanged: (m) =>
                                      setState(() => _payMethod = m),
                                ),
                              ],
                            ),
                          ),
                          Padding(
                            padding:
                                const EdgeInsets.fromLTRB(16, 0, 16, 16),
                            child: FilledButton(
                              style: FilledButton.styleFrom(
                                backgroundColor: AppColors.navy,
                                minimumSize: const Size.fromHeight(52),
                              ),
                              onPressed: _booking || _quote == null
                                  ? null
                                  : _placeOrder,
                              child: Text(
                                _booking ? 'Booking…' : 'Confirm & pay',
                              ),
                            ),
                          ),
                        ],
                      ),
            if (_booking)
              Container(
                color: Colors.black45,
                child: const Center(child: CircularProgressIndicator()),
              ),
          ],
        ),
      ),
    );
  }
}

class _ServiceSquareCard extends StatelessWidget {
  const _ServiceSquareCard({
    required this.service,
    required this.selected,
    required this.onTap,
  });

  final ServiceItem service;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final image = service.imageUrl?.trim();
    final price = (service.basePrice ?? 0).toStringAsFixed(0);
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? AppColors.navy : AppColors.line,
              width: selected ? 2 : 1,
            ),
            color: selected ? const Color(0xFFF0F5FB) : Colors.white,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(14),
                  ),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (image != null && image.isNotEmpty)
                        CachedNetworkImage(
                          imageUrl: image,
                          fit: BoxFit.cover,
                          errorWidget: (_, _, _) => const ColoredBox(
                            color: AppColors.mist,
                            child: Icon(
                              Icons.cleaning_services_outlined,
                              color: AppColors.muted,
                              size: 36,
                            ),
                          ),
                        )
                      else
                        const ColoredBox(
                          color: AppColors.mist,
                          child: Icon(
                            Icons.cleaning_services_outlined,
                            color: AppColors.muted,
                            size: 36,
                          ),
                        ),
                      if (selected)
                        const Positioned(
                          top: 8,
                          right: 8,
                          child: CircleAvatar(
                            radius: 12,
                            backgroundColor: AppColors.navy,
                            child: Icon(
                              Icons.check,
                              size: 14,
                              color: Colors.white,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      service.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                        color: AppColors.ink,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '₹$price',
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        color: AppColors.accentOrange,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
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
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontWeight: bold ? FontWeight.w800 : FontWeight.w500,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
              color: AppColors.navy,
            ),
          ),
        ],
      ),
    );
  }
}
