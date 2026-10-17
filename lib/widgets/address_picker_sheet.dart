import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:kaamfast/core/theme/app_theme.dart';
import 'package:kaamfast/models/address.dart';
import 'package:kaamfast/models/maps_config.dart';
import 'package:kaamfast/providers/location_provider.dart';
import 'package:kaamfast/services/api_services.dart';
import 'package:kaamfast/services/location_service.dart';
import 'package:provider/provider.dart';

Future<AddressModel?> showAddressPicker(
  BuildContext context, {
  required String title,
  String defaultLabel = 'Home',
  bool updateHeader = false,
}) {
  return showModalBottomSheet<AddressModel>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (ctx) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(ctx).bottom),
      child: AddressPickerSheet(
        title: title,
        defaultLabel: defaultLabel,
        updateHeader: updateHeader,
      ),
    ),
  );
}

class AddressPickerSheet extends StatefulWidget {
  const AddressPickerSheet({
    super.key,
    required this.title,
    this.defaultLabel = 'Home',
    this.updateHeader = false,
  });

  final String title;
  final String defaultLabel;
  final bool updateHeader;

  @override
  State<AddressPickerSheet> createState() => _AddressPickerSheetState();
}

class _AddressPickerSheetState extends State<AddressPickerSheet> {
  final _search = TextEditingController();
  List<AddressModel> _saved = [];
  List<PlaceSuggestion> _suggestions = [];
  Timer? _debounce;
  bool _loading = true;
  bool _searching = false;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadSaved();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    super.dispose();
  }

  Future<void> _loadSaved() async {
    setState(() => _loading = true);
    try {
      final items = await context.read<AddressApi>().listRepaired(
            context.read<LocationService>(),
          );
      if (!mounted) return;
      setState(() {
        _saved = items;
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
    setState(() => _busy = true);
    try {
      final place = await context.read<LocationService>().resolveSuggestion(suggestion);
      await _commitPlace(place);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = '$e';
      });
    }
  }

  Future<void> _useCurrent() async {
    setState(() => _busy = true);
    try {
      final place = await context.read<LocationService>().currentPlace();
      await _commitPlace(place, label: 'Current');
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = '$e';
      });
    }
  }

  Future<void> _openMap() async {
    final place = await context.push<PlaceResult>('/location-picker');
    if (place == null || !mounted) return;
    setState(() => _busy = true);
    await _commitPlace(place);
  }

  Future<void> _commitPlace(PlaceResult place, {String? label}) async {
    final saved = await context.read<AddressApi>().savePlace(
          place,
          label: label ?? widget.defaultLabel,
          isDefault: _saved.isEmpty,
        );
    if (widget.updateHeader && mounted) {
      await context.read<LocationProvider>().setPlace(place);
    }
    if (!mounted) return;
    Navigator.pop(context, saved);
  }

  void _selectSaved(AddressModel address) {
    Navigator.pop(context, address);
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.sizeOf(context).height * 0.82;
    return SizedBox(
      height: height,
      child: Column(
        children: [
          const SizedBox(height: 8),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(color: AppColors.line, borderRadius: BorderRadius.circular(99)),
          ),
          ListTile(
            title: Text(widget.title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
            trailing: TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: TextField(
              controller: _search,
              autofocus: true,
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
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(_error!, style: const TextStyle(color: AppColors.danger, fontSize: 12)),
            ),
          if (_busy) const LinearProgressIndicator(minHeight: 2),
          Expanded(
            child: _suggestions.isNotEmpty
                ? ListView.separated(
                    itemCount: _suggestions.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final item = _suggestions[index];
                      return ListTile(
                        leading: const Icon(Icons.place_outlined, color: AppColors.navy),
                        title: Text(item.description, maxLines: 2, overflow: TextOverflow.ellipsis),
                        subtitle: item.secondaryText == null
                            ? null
                            : Text(item.secondaryText!, maxLines: 1, overflow: TextOverflow.ellipsis),
                        onTap: _busy ? null : () => _selectSuggestion(item),
                      );
                    },
                  )
                : _loading
                    ? const Center(child: CircularProgressIndicator())
                    : ListView(
                        children: [
                          ListTile(
                            leading: const Icon(Icons.my_location, color: AppColors.teal),
                            title: const Text('Use current location'),
                            onTap: _busy ? null : _useCurrent,
                          ),
                          ListTile(
                            leading: const Icon(Icons.map_outlined, color: AppColors.teal),
                            title: const Text('Pick on map'),
                            onTap: _busy ? null : _openMap,
                          ),
                          const Divider(),
                          const Padding(
                            padding: EdgeInsets.fromLTRB(16, 8, 16, 4),
                            child: Text('Saved addresses', style: TextStyle(fontWeight: FontWeight.w800)),
                          ),
                          if (_saved.isEmpty)
                            const ListTile(title: Text('No saved addresses yet. Search above.'))
                          else
                            ..._saved.map(
                              (a) => ListTile(
                                leading: const Icon(Icons.bookmark_border_rounded),
                                title: Text(a.label ?? 'Address'),
                                subtitle: Text(a.shortLine, maxLines: 2, overflow: TextOverflow.ellipsis),
                                onTap: _busy ? null : () => _selectSaved(a),
                              ),
                            ),
                        ],
                      ),
          ),
        ],
      ),
    );
  }
}
