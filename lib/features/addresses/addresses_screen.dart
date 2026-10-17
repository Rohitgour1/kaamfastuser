import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:kaamfast/core/theme/app_theme.dart';
import 'package:kaamfast/models/address.dart';
import 'package:kaamfast/models/maps_config.dart';
import 'package:kaamfast/providers/location_provider.dart';
import 'package:kaamfast/services/api_services.dart';
import 'package:kaamfast/services/location_service.dart';
import 'package:provider/provider.dart';

class AddressesScreen extends StatefulWidget {
  const AddressesScreen({super.key});

  @override
  State<AddressesScreen> createState() => _AddressesScreenState();
}

class _AddressesScreenState extends State<AddressesScreen> {
  List<AddressModel> _items = [];
  bool _loading = true;
  bool _locating = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final raw = await context.read<AddressApi>().list();
      final items = raw.whereType<Map>().map((e) => AddressModel.fromJson(Map<String, dynamic>.from(e))).toList();
      if (!mounted) return;
      setState(() {
        _items = items;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  Future<void> _savePlace(PlaceResult place, {String label = 'Home'}) async {
    await context.read<AddressApi>().create(place.toAddressBody(
          label: label,
          isDefault: _items.isEmpty,
        ));
    await _load();
  }

  Future<void> _useCurrentLocation() async {
    setState(() => _locating = true);
    try {
      final place = await context.read<LocationService>().currentPlace();
      if (!mounted) return;
      await context.read<LocationProvider>().setPlace(place);
      await _confirmAndSave(place);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  Future<void> _openMapPicker() async {
    final place = await context.push<PlaceResult>('/location-picker');
    if (place == null || !mounted) return;
    await _confirmAndSave(place);
  }

  Future<void> _confirmAndSave(PlaceResult place) async {
    final label = TextEditingController(text: 'Home');
    final flat = TextEditingController();
    final line1 = TextEditingController(text: place.storageLine1);
    final city = TextEditingController(text: place.city);
    final pincode = TextEditingController(text: place.pincode ?? '');

    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: MediaQuery.of(context).viewInsets.bottom + 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Confirm address', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
              const SizedBox(height: 4),
              Text(
                place.formattedAddress ?? place.shortLabel,
                style: const TextStyle(color: AppColors.muted, fontSize: 12),
              ),
              const SizedBox(height: 12),
              TextField(controller: label, decoration: const InputDecoration(labelText: 'Label')),
              const SizedBox(height: 8),
              TextField(controller: flat, decoration: const InputDecoration(labelText: 'Flat / House No. / Building')),
              const SizedBox(height: 8),
              TextField(controller: line1, decoration: const InputDecoration(labelText: 'Area / Street')),
              const SizedBox(height: 8),
              TextField(controller: city, decoration: const InputDecoration(labelText: 'City')),
              const SizedBox(height: 8),
              TextField(controller: pincode, decoration: const InputDecoration(labelText: 'Pincode'), keyboardType: TextInputType.number),
              const SizedBox(height: 12),
              FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Save address')),
            ],
          ),
        );
      },
    );

    if (ok != true || !mounted) return;

    try {
      final combinedLine1 = flat.text.trim().isNotEmpty 
          ? '${flat.text.trim()}, ${line1.text.trim()}'
          : line1.text.trim();

      await _savePlace(
        PlaceResult(
          latitude: place.latitude,
          longitude: place.longitude,
          line1: combinedLine1,
          city: city.text.trim(),
          state: place.state,
          pincode: pincode.text.trim().isEmpty ? null : pincode.text.trim(),
          formattedAddress: place.formattedAddress,
        ),
        label: label.text.trim().isEmpty ? 'Home' : label.text.trim(),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  Future<void> _addManual() async {
    final label = TextEditingController(text: 'Home');
    final flat = TextEditingController();
    final line1 = TextEditingController();
    final city = TextEditingController(text: 'Indore');
    final pincode = TextEditingController();

    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: MediaQuery.of(context).viewInsets.bottom + 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Add address', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
              const SizedBox(height: 12),
              TextField(controller: label, decoration: const InputDecoration(labelText: 'Label')),
              const SizedBox(height: 8),
              TextField(controller: flat, decoration: const InputDecoration(labelText: 'Flat / House No. / Building')),
              const SizedBox(height: 8),
              TextField(controller: line1, decoration: const InputDecoration(labelText: 'Area / Street')),
              const SizedBox(height: 8),
              TextField(controller: city, decoration: const InputDecoration(labelText: 'City')),
              const SizedBox(height: 8),
              TextField(controller: pincode, decoration: const InputDecoration(labelText: 'Pincode'), keyboardType: TextInputType.number),
              const SizedBox(height: 12),
              FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Save')),
            ],
          ),
        );
      },
    );

    if (ok != true || !mounted) return;
    try {
      final combinedLine1 = flat.text.trim().isNotEmpty 
          ? '${flat.text.trim()}, ${line1.text.trim()}'
          : line1.text.trim();
          
      await context.read<AddressApi>().create({
        'label': label.text.trim(),
        'line1': combinedLine1,
        'city': city.text.trim(),
        'pincode': pincode.text.trim(),
        'is_default': _items.isEmpty,
      });
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Addresses')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        children: [
                          ListTile(
                            leading: const Icon(Icons.search_rounded, color: AppColors.teal),
                            title: const Text('Search address'),
                            subtitle: const Text('Google autocomplete + map pin'),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: _openMapPicker,
                          ),
                          const Divider(height: 1),
                          ListTile(
                            leading: const Icon(Icons.my_location, color: AppColors.teal),
                            title: const Text('Use current location'),
                            subtitle: const Text('GPS + reverse geocode'),
                            trailing: _locating
                                ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2))
                                : const Icon(Icons.chevron_right),
                            onTap: _locating ? null : _useCurrentLocation,
                          ),
                          const Divider(height: 1),
                          ListTile(
                            leading: const Icon(Icons.map_outlined, color: AppColors.teal),
                            title: const Text('Pick on map'),
                            subtitle: const Text('Search, drag pin, or tap map'),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: _openMapPicker,
                          ),
                          const Divider(height: 1),
                          ListTile(
                            leading: const Icon(Icons.edit_location_alt_outlined),
                            title: const Text('Enter manually'),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: _addManual,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('Saved addresses', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                  const SizedBox(height: 8),
                  if (_items.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 40),
                      child: Center(child: Text('No saved addresses')),
                    )
                  else
                    ..._items.map(
                      (a) => Card(
                        child: ListTile(
                          title: Text('${a.label ?? 'Address'}${a.isDefault ? ' · Default' : ''}'),
                          subtitle: Text(a.shortLine),
                          onTap: () async {
                            if (a.latitude == null || a.longitude == null) return;
                            await context.read<LocationProvider>().setPlace(
                              PlaceResult(
                                latitude: a.latitude!,
                                longitude: a.longitude!,
                                line1: a.line1,
                                city: a.city,
                                state: a.state,
                                pincode: a.pincode,
                                formattedAddress: a.shortLine,
                              ),
                            );
                            if (context.mounted) context.pop();
                          },
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline, color: AppColors.danger),
                            onPressed: () async {
                              await context.read<AddressApi>().delete(a.id);
                              await _load();
                            },
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
    );
  }
}
