import 'package:flutter/material.dart';
import 'package:flutter_native_contact_picker/flutter_native_contact_picker.dart';
import 'package:flutter_native_contact_picker/model/contact.dart';
import 'package:geolocator/geolocator.dart';
import 'package:kaamfast/core/theme/app_theme.dart';
import 'package:kaamfast/features/tracking/searching_delivery_screen.dart';
import 'package:kaamfast/models/address.dart';
import 'package:kaamfast/models/module.dart';
import 'package:kaamfast/models/quote.dart';
import 'package:kaamfast/models/vehicle.dart';
import 'package:kaamfast/providers/auth_provider.dart';
import 'package:kaamfast/providers/location_provider.dart';
import 'package:kaamfast/services/api_services.dart';
import 'package:kaamfast/services/checkout_helper.dart';
import 'package:kaamfast/services/location_service.dart';
import 'package:kaamfast/widgets/address_picker_sheet.dart';
import 'package:kaamfast/widgets/coupon_apply_card.dart';
import 'package:kaamfast/widgets/app_header.dart';
import 'package:kaamfast/widgets/payment_method_picker.dart';
import 'package:kaamfast/widgets/photo_upload_box.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

class DeliveryBookingScreen extends StatefulWidget {
  const DeliveryBookingScreen({super.key, this.initialTypeIndex});

  /// 0 documents, 1 small, 2 medium, 3 large.
  final int? initialTypeIndex;

  @override
  State<DeliveryBookingScreen> createState() => _DeliveryBookingScreenState();
}

class _ParcelType {
  const _ParcelType(this.label, this.icon, this.weightKg, this.weightLabel);
  final String label;
  final IconData icon;
  final double weightKg;
  final String weightLabel;
}

class _DeliveryBookingScreenState extends State<DeliveryBookingScreen> {
  static const _types = [
    _ParcelType('Documents', Icons.description_outlined, 0.5, '0-0.5'),
    _ParcelType('Small', Icons.inventory_2_outlined, 2, '0.5-2'),
    _ParcelType('Medium', Icons.shopping_bag_outlined, 5, '2-5'),
    _ParcelType('Large', Icons.luggage_outlined, 8, '5-8'),
  ];

  List<AddressModel> _addresses = [];
  List<Vehicle> _vehicles = [];
  Vehicle? _selectedVehicle;
  ServiceItem? _service;
  AddressModel? _pickup;
  AddressModel? _drop;
  late int _typeIndex = (widget.initialTypeIndex ?? 0).clamp(0, _types.length - 1);
  String _notes = '';
  XFile? _parcelPhoto;
  bool _photoMissing = false;
  QuoteResult? _quote;
  /// send | receive
  String _direction = 'send';
  bool _myself = true;
  final _otherName = TextEditingController();
  final _otherPhone = TextEditingController();
  /// sender | receiver — who pays
  String _paidBy = 'sender';
  String _payMethod = BookingPayMethods.gateway;
  String? _couponCode;
  bool _loading = true;
  bool _quoting = false;
  bool _booking = false;
  String? _error;

  double get _weightKg => _types[_typeIndex].weightKg;

  double get _distanceKm {
    final p = _pickup;
    final d = _drop;
    if (p?.latitude == null || p?.longitude == null || d?.latitude == null || d?.longitude == null) {
      return 3;
    }
    final meters = Geolocator.distanceBetween(
      p!.latitude!,
      p.longitude!,
      d!.latitude!,
      d.longitude!,
    );
    return (meters / 1000).clamp(0.5, 80);
  }

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  @override
  void dispose() {
    _otherName.dispose();
    _otherPhone.dispose();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    try {
      final moduleApi = context.read<ModuleService>();
      final addressApi = context.read<AddressApi>();
      final vehicleApi = context.read<VehicleApi>();
      final services = await moduleApi.services('parcel');
      final addresses = await addressApi.listRepaired(context.read<LocationService>());
      final rawVehicles = await vehicleApi.list();
      if (!mounted) return;
      final defaultAddr = addresses.where((a) => a.isDefault).firstOrNull ??
          (addresses.isNotEmpty ? addresses.first : null);
      final parsedVehicles = rawVehicles.map((v) => Vehicle.fromJson(v)).toList();
      setState(() {
        _service = services.isNotEmpty ? services.first : null;
        _addresses = addresses;
        _pickup ??= defaultAddr;
        _vehicles = parsedVehicles;
        if (_vehicles.isNotEmpty) _selectedVehicle = _vehicles.first;
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

  Future<void> _refreshQuote() async {
    if (_pickup == null || _drop == null) {
      setState(() => _quote = null);
      return;
    }
    setState(() => _quoting = true);
    try {
      final raw = await context.read<BookingApi>().quote({
        'module_slug': 'parcel',
        if (_service != null) 'service_id': _service!.id,
        'address_id': _pickup!.id,
        'distance_km': double.parse(_distanceKm.toStringAsFixed(2)),
        'weight_kg': _weightKg,
        if (_selectedVehicle != null) 'vehicle_id': _selectedVehicle!.id,
        if (_couponCode != null && _couponCode!.isNotEmpty) 'coupon_code': _couponCode,
      });
      if (!mounted) return;
      setState(() {
        _quote = QuoteResult.fromJson(raw);
        _quoting = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _quoting = false);
    }
  }

  Future<void> _pickAddress({required bool pickup}) async {
    final selected = await showAddressPicker(
      context,
      title: pickup ? 'Pickup address' : 'Drop address',
      defaultLabel: pickup ? 'Pickup' : 'Drop',
    );
    if (selected == null || !mounted) return;
    setState(() {
      if (pickup) {
        _pickup = selected;
      } else {
        _drop = selected;
      }
    });
    await _refreshQuote();
  }

  Future<void> _useCurrentAsPickup() async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final place = await context.read<LocationService>().currentPlace();
      if (!mounted) return;
      final addr = await context.read<AddressApi>().savePlace(
        place,
        label: 'Current',
        isDefault: true,
      );
      if (!mounted) return;
      await context.read<LocationProvider>().setPlace(place);
      setState(() {
        _pickup = addr;
        if (!_addresses.any((a) => a.id == addr.id)) {
          _addresses = [addr, ..._addresses];
        }
      });
      await _refreshQuote();
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  Map<String, String> _partyDetails() {
    final user = context.read<AuthProvider>().user;
    final selfName = (user?.name ?? '').trim();
    final selfPhone = (user?.phone ?? '').trim();
    final otherName = _otherName.text.trim();
    final otherPhone = _otherPhone.text.trim();

    if (_direction == 'send') {
      return {
        'sender_name': selfName,
        'sender_phone': selfPhone,
        'receiver_name': _myself ? selfName : otherName,
        'receiver_phone': _myself ? selfPhone : otherPhone,
      };
    }
    return {
      'sender_name': _myself ? selfName : otherName,
      'sender_phone': _myself ? selfPhone : otherPhone,
      'receiver_name': selfName,
      'receiver_phone': selfPhone,
    };
  }

  Future<void> _placeOrder() async {
    if (_pickup == null || _drop == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select pickup and drop addresses')),
      );
      return;
    }
    if (_pickup!.id == _drop!.id) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pickup and drop must be different')),
      );
      return;
    }
    if (!_myself) {
      if (_otherName.text.trim().isEmpty || _otherPhone.text.trim().length < 10) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _direction == 'send'
                  ? 'Enter receiver name and phone'
                  : 'Enter sender name and phone',
            ),
          ),
        );
        return;
      }
    }

    if (_direction == 'send' && _parcelPhoto == null) {
      setState(() => _photoMissing = true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add a photo of the parcel you are sending')),
      );
      return;
    }

    setState(() => _booking = true);
    try {
      final bookingApi = context.read<BookingApi>();
      final contacts = _partyDetails();
      final user = context.read<AuthProvider>().user;
      final method = _paidBy == 'receiver' ? 'cash' : _payMethod;

      final booking = await placeBookingAndPay(
        bookingApi: bookingApi,
        method: method,
        photoPath: _parcelPhoto?.path,
        customerPhone: user?.phone,
        customerName: user?.name,
        customerEmail: user?.email,
        createBody: {
          'module_slug': 'parcel',
          if (_service != null) 'service_id': _service!.id,
          'address_id': _pickup!.id,
          'drop_address_id': _drop!.id,
          'distance_km': double.parse(_distanceKm.toStringAsFixed(2)),
          'weight_kg': _weightKg,
          if (_selectedVehicle != null) 'vehicle_id': _selectedVehicle!.id,
          if (_couponCode != null && _couponCode!.isNotEmpty) 'coupon_code': _couponCode,
          'notes': _notes.isEmpty ? 'Parcel: ${_types[_typeIndex].label}' : _notes,
          'meta': {
            'parcel_type': _types[_typeIndex].label,
            'direction': _direction,
            'paid_by': _paidBy,
            ...contacts,
            'drop_address_id': _drop!.id,
            'drop_address': {
              'id': _drop!.id,
              'label': _drop!.label,
              'line1': _drop!.line1,
              'city': _drop!.city,
              'state': _drop!.state,
              'pincode': _drop!.pincode,
              'latitude': _drop!.latitude,
              'longitude': _drop!.longitude,
            },
            'distance_km': double.parse(_distanceKm.toStringAsFixed(2)),
            'weight_kg': _weightKg,
          },
        },
      );
      if (!mounted) return;
      await Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => SearchingDeliveryScreen(
            bookingId: booking.id,
            phase: 'single',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _booking = false);
    }
  }

  String get _otherLabel => _direction == 'send' ? 'Receiver' : 'Sender';

  Future<void> _pickOtherFromContacts() async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final picker = FlutterNativeContactPicker();
      Contact? contact;
      try {
        contact = await picker.selectPhoneNumber();
      } catch (_) {
        contact = await picker.selectContact();
      }
      if (contact == null || !mounted) return;

      final name = (contact.fullName ?? '').trim();
      final phoneRaw = (contact.selectedPhoneNumber ??
              (contact.phoneNumbers != null && contact.phoneNumbers!.isNotEmpty
                  ? contact.phoneNumbers!.first
                  : ''))
          .toString();
      final phone = phoneRaw.replaceAll(RegExp(r'[^\d+]'), '');

      setState(() {
        if (name.isNotEmpty) _otherName.text = name;
        if (phone.isNotEmpty) _otherPhone.text = phone;
        _myself = false;
      });
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Could not open contacts: $e')),
      );
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
                                const Text(
                                  'Parcel delivery',
                                  style: TextStyle(
                                    fontSize: 26,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.navy,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  'Send or receive with live partner search.',
                                  style: TextStyle(color: AppColors.muted),
                                ),
                                const SizedBox(height: 18),
                                const Text(
                                  'Goods type',
                                  style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.navy),
                                ),
                                const SizedBox(height: 10),
                                Wrap(
                                  spacing: 10,
                                  runSpacing: 10,
                                  children: [
                                    for (var i = 0; i < _types.length; i++)
                                      ChoiceChip(
                                        label: Text('${_types[i].label} (${_types[i].weightLabel}kg)'),
                                        selected: _typeIndex == i,
                                        onSelected: (_) {
                                          setState(() => _typeIndex = i);
                                          _refreshQuote();
                                        },
                                        avatar: Icon(_types[i].icon, size: 18),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 18),
                                const Text(
                                  'I want to',
                                  style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.navy),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Expanded(
                                      child: ChoiceChip(
                                        label: const Text('Send parcel'),
                                        selected: _direction == 'send',
                                        onSelected: (_) => setState(() {
                                          _direction = 'send';
                                          _myself = true;
                                        }),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: ChoiceChip(
                                        label: const Text('Receive parcel'),
                                        selected: _direction == 'receive',
                                        onSelected: (_) => setState(() {
                                          _direction = 'receive';
                                          _myself = true;
                                        }),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 14),
                                CheckboxListTile(
                                  contentPadding: EdgeInsets.zero,
                                  value: _myself,
                                  onChanged: (v) => setState(() => _myself = v ?? true),
                                  title: Text('Myself (${_otherLabel.toLowerCase()} is me)'),
                                  controlAffinity: ListTileControlAffinity.leading,
                                ),
                                if (!_myself) ...[
                                  TextField(
                                    controller: _otherName,
                                    decoration: InputDecoration(
                                      labelText: '$_otherLabel name',
                                      border: const OutlineInputBorder(),
                                      suffixIcon: IconButton(
                                        tooltip: 'Pick from contacts',
                                        onPressed: _pickOtherFromContacts,
                                        icon: const Icon(Icons.contacts_outlined),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  TextField(
                                    controller: _otherPhone,
                                    keyboardType: TextInputType.phone,
                                    decoration: InputDecoration(
                                      labelText: '$_otherLabel phone',
                                      border: const OutlineInputBorder(),
                                      suffixIcon: IconButton(
                                        tooltip: 'Pick from contacts',
                                        onPressed: _pickOtherFromContacts,
                                        icon: const Icon(Icons.contact_phone_outlined),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                ],
                                _AddrCard(
                                  title: 'Pickup',
                                  subtitle: _pickup?.shortLine ?? 'Select pickup address',
                                  onTap: () => _pickAddress(pickup: true),
                                  trailing: TextButton(
                                    onPressed: _useCurrentAsPickup,
                                    child: const Text('Current'),
                                  ),
                                ),
                                const SizedBox(height: 10),
                                _AddrCard(
                                  title: 'Drop',
                                  subtitle: _drop?.shortLine ?? 'Select drop address',
                                  onTap: () => _pickAddress(pickup: false),
                                ),
                                const SizedBox(height: 18),
                                if (_vehicles.isNotEmpty) ...[
                                  const Text(
                                    'Vehicle',
                                    style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.navy),
                                  ),
                                  const SizedBox(height: 10),
                                  Wrap(
                                    spacing: 10,
                                    runSpacing: 10,
                                    children: [
                                      for (final v in _vehicles)
                                        ChoiceChip(
                                          label: Text(v.name),
                                          selected: _selectedVehicle?.id == v.id,
                                          onSelected: (_) {
                                            setState(() => _selectedVehicle = v);
                                            _refreshQuote();
                                          },
                                          avatar: const Icon(Icons.two_wheeler_outlined, size: 18),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                ],
                                Text(
                                  _direction == 'send' ? 'Parcel photo *' : 'Parcel photo',
                                  style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.navy),
                                ),
                                const SizedBox(height: 8),
                                PhotoUploadBox(
                                  photo: _parcelPhoto,
                                  title: 'Upload parcel photo',
                                  subtitle: _direction == 'send'
                                      ? 'Required · The delivery partner sees this with your request'
                                      : 'Optional · Helps the partner identify the parcel',
                                  highlightError: _photoMissing && _parcelPhoto == null,
                                  onPick: () async {
                                    final file = await pickPhotoWithSource(context);
                                    if (file == null || !mounted) return;
                                    setState(() {
                                      _parcelPhoto = file;
                                      _photoMissing = false;
                                    });
                                  },
                                  onRemove: () => setState(() => _parcelPhoto = null),
                                ),
                                const SizedBox(height: 16),
                                TextField(
                                  maxLines: 2,
                                  decoration: const InputDecoration(
                                    labelText: 'Notes (optional)',
                                    hintText: 'Fragile, call on arrival…',
                                    border: OutlineInputBorder(),
                                  ),
                                  onChanged: (v) => _notes = v,
                                ),
                                const SizedBox(height: 18),
                                const Text(
                                  'Collect payment from',
                                  style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.navy),
                                ),
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 8,
                                  children: [
                                    ChoiceChip(
                                      label: const Text('Sender'),
                                      selected: _paidBy == 'sender',
                                      onSelected: (_) => setState(() {
                                        _paidBy = 'sender';
                                        if (_payMethod == 'cash') _payMethod = BookingPayMethods.gateway;
                                      }),
                                    ),
                                    ChoiceChip(
                                      label: const Text('Receiver (cash on delivery)'),
                                      selected: _paidBy == 'receiver',
                                      onSelected: (_) => setState(() {
                                        _paidBy = 'receiver';
                                        _payMethod = 'cash';
                                      }),
                                    ),
                                  ],
                                ),
                                if (_paidBy == 'sender') ...[
                                  const SizedBox(height: 12),
                                  PaymentMethodPicker(
                                    value: _payMethod,
                                    onChanged: (m) => setState(() => _payMethod = m),
                                  ),
                                ],
                                const SizedBox(height: 16),
                                CouponApplyCard(
                                  moduleSlug: 'parcel',
                                  appliedCode: _couponCode,
                                  addressId: _pickup?.id,
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
                                  _SoftCard(
                                    child: Column(
                                      children: [
                                        _Row('Distance', '~${_distanceKm.toStringAsFixed(1)} km'),
                                        if (_quote?.meta['eta_minutes'] != null)
                                          _Row('Est. Time', '~${_quote!.meta['eta_minutes']} mins'),
                                        _Row('Weight', '${_weightKg.toStringAsFixed(1)} kg'),
                                        _Row('Subtotal', '₹${(_quote?.subtotal ?? 0).toStringAsFixed(0)}'),
                                        if ((_quote?.discount ?? 0) > 0)
                                          _Row('Discount', '-₹${_quote!.discount.toStringAsFixed(0)}'),
                                        _Row('Tax', '₹${(_quote?.tax ?? 0).toStringAsFixed(0)}'),
                                        const Divider(),
                                        _Row(
                                          'To pay',
                                          '₹${(_quote?.total ?? 0).toStringAsFixed(0)}',
                                          bold: true,
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                            child: FilledButton(
                              style: FilledButton.styleFrom(
                                backgroundColor: AppColors.navy,
                                minimumSize: const Size.fromHeight(52),
                              ),
                              onPressed: _booking || _quote == null ? null : _placeOrder,
                              child: Text(_booking ? 'Booking…' : 'Book now'),
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

class _AddrCard extends StatelessWidget {
  const _AddrCard({
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.trailing,
  });

  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.mist,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              const Icon(Icons.place_outlined, color: AppColors.navy),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
                    Text(subtitle, style: const TextStyle(color: AppColors.muted, fontSize: 13)),
                  ],
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
        ),
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
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.mist,
        borderRadius: BorderRadius.circular(14),
      ),
      child: child,
    );
  }
}

class _Row extends StatelessWidget {
  const _Row(this.label, this.value, {this.bold = false});
  final String label;
  final String value;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Expanded(child: Text(label, style: TextStyle(fontWeight: bold ? FontWeight.w800 : FontWeight.w500))),
          Text(value, style: TextStyle(fontWeight: bold ? FontWeight.w800 : FontWeight.w600)),
        ],
      ),
    );
  }
}
