import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:kaamfast/core/theme/app_theme.dart';
import 'package:kaamfast/models/address.dart';
import 'package:kaamfast/models/maps_config.dart';
import 'package:kaamfast/providers/location_provider.dart';
import 'package:kaamfast/services/api_services.dart';
import 'package:kaamfast/services/location_service.dart';
import 'package:kaamfast/widgets/app_header.dart';
import 'package:provider/provider.dart';

/// Step between the laundry home and checkout: search a pickup location,
/// then pick a slot in a popup, then open the booking page.
class LaundryPickupScreen extends StatefulWidget {
  const LaundryPickupScreen({super.key, this.serviceName, this.couponCode});

  final String? serviceName;
  final String? couponCode;

  @override
  State<LaundryPickupScreen> createState() => _LaundryPickupScreenState();
}

class _LaundryPickupScreenState extends State<LaundryPickupScreen> {
  final _search = TextEditingController();
  Timer? _debounce;
  List<AddressModel> _recent = [];
  List<PlaceSuggestion> _suggestions = [];
  bool _loading = true;
  bool _searching = false;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadRecent();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    super.dispose();
  }

  Future<void> _loadRecent() async {
    try {
      final list = await context.read<AddressApi>().listRepaired(context.read<LocationService>());
      if (!mounted) return;
      final sorted = [...list]..sort((a, b) => b.id.compareTo(a.id));
      final seen = <String>{};
      final recent = <AddressModel>[];
      for (final a in sorted) {
        if (seen.add(a.shortLine.trim().toLowerCase())) recent.add(a);
        if (recent.length == 3) break;
      }
      setState(() {
        _recent = recent;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
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

  Future<void> _resolveAndSave(Future<PlaceResult> Function(LocationService) resolve, {String label = 'Pickup'}) async {
    final location = context.read<LocationService>();
    final api = context.read<AddressApi>();
    final header = context.read<LocationProvider>();
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final place = await resolve(location);
      final saved = await api.savePlace(place, label: label, isDefault: _recent.isEmpty);
      await header.setPlace(place);
      if (!mounted) return;
      setState(() => _busy = false);
      await _pickTimeFor(saved);
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
    await _resolveAndSave((_) async => place);
  }

  Future<void> _pickTimeFor(AddressModel address) async {
    FocusScope.of(context).unfocus();
    final choice = await showModalBottomSheet<PickupChoice>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (_) => _PickupTimeSheet(address: address),
    );
    if (choice == null || !mounted) return;
    final coupon = widget.couponCode?.trim();
    context.push(Uri(
      path: '/laundry',
      queryParameters: {
        'service': ?widget.serviceName,
        if (coupon != null && coupon.isNotEmpty) 'coupon': coupon,
        'at': choice.at.toIso8601String(),
        if (choice.instant) 'instant': '1',
        'address_id': '${address.id}',
      },
    ).toString());
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.serviceName?.trim();
    final showingResults = _search.text.trim().length >= 2;
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            const AppHeader(),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title == null || title.isEmpty ? 'Laundry' : title,
                    style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: AppColors.navy),
                  ),
                  const SizedBox(height: 4),
                  const Text('Where should we pick up your clothes?', style: TextStyle(color: AppColors.muted)),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _search,
                    textInputAction: TextInputAction.search,
                    onChanged: _onQueryChanged,
                    decoration: InputDecoration(
                      hintText: 'Search area, street, landmark...',
                      prefixIcon: const Icon(Icons.search_rounded, color: AppColors.navy),
                      filled: true,
                      fillColor: AppColors.mist,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                      suffixIcon: _searching
                          ? const Padding(
                              padding: EdgeInsets.all(12),
                              child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
                            )
                          : _search.text.isEmpty
                              ? null
                              : IconButton(
                                  icon: const Icon(Icons.close_rounded),
                                  onPressed: () {
                                    _search.clear();
                                    setState(() => _suggestions = []);
                                  },
                                ),
                    ),
                  ),
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(_error!, style: const TextStyle(color: AppColors.danger, fontSize: 12)),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            if (_busy) const LinearProgressIndicator(minHeight: 2),
            Expanded(
              child: showingResults ? _buildResults() : _buildIdle(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResults() {
    if (_suggestions.isEmpty) {
      return Center(
        child: Text(
          _searching ? 'Searching…' : 'No places found',
          style: const TextStyle(color: AppColors.muted),
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      itemCount: _suggestions.length,
      separatorBuilder: (_, _) => const Divider(height: 1, indent: 56),
      itemBuilder: (context, i) {
        final item = _suggestions[i];
        return ListTile(
          leading: const Icon(Icons.place_outlined, color: AppColors.navy),
          title: Text(item.description, maxLines: 2, overflow: TextOverflow.ellipsis),
          subtitle: item.secondaryText == null
              ? null
              : Text(item.secondaryText!, maxLines: 1, overflow: TextOverflow.ellipsis),
          onTap: _busy ? null : () => _resolveAndSave((loc) => loc.resolveSuggestion(item)),
        );
      },
    );
  }

  Widget _buildIdle() {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      children: [
        ListTile(
          leading: const Icon(Icons.my_location, color: AppColors.accentOrange),
          title: const Text('Use current location', style: TextStyle(fontWeight: FontWeight.w700)),
          onTap: _busy ? null : () => _resolveAndSave((loc) => loc.currentPlace(), label: 'Current'),
        ),
        ListTile(
          leading: const Icon(Icons.map_outlined, color: AppColors.accentOrange),
          title: const Text('Pick on map', style: TextStyle(fontWeight: FontWeight.w700)),
          onTap: _busy ? null : _openMap,
        ),
        const Divider(),
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 8, 16, 4),
          child: Text(
            'Recent searches',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.navy),
          ),
        ),
        if (_loading)
          const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (_recent.isEmpty)
          const ListTile(
            title: Text('No recent locations yet. Search above.', style: TextStyle(color: AppColors.muted)),
          )
        else
          for (final a in _recent)
            ListTile(
              leading: const Icon(Icons.history_rounded, color: AppColors.navy),
              title: Text(
                a.shortLine,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: a.label == null ? null : Text(a.label!),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: _busy ? null : () => _pickTimeFor(a),
            ),
      ],
    );
  }
}

typedef PickupChoice = ({DateTime at, bool instant});

/// Instant pickups are only offered while partners are on shift.
const instantPickupStartHour = 7;
const instantPickupEndHour = 21;
const instantPickupLead = Duration(minutes: 15);

bool get instantPickupOpen {
  final hour = DateTime.now().hour;
  return hour >= instantPickupStartHour && hour < instantPickupEndHour;
}

class _PickupTimeSheet extends StatefulWidget {
  const _PickupTimeSheet({required this.address});

  final AddressModel address;

  @override
  State<_PickupTimeSheet> createState() => _PickupTimeSheetState();
}

class _PickupTimeSheetState extends State<_PickupTimeSheet> {
  static const _slotStartHours = [8, 10, 12, 14, 16, 18];
  static const _weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  static const _months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

  late final List<DateTime> _days;
  late DateTime _day;
  int? _slotHour;
  bool _instant = false;

  static DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  static bool _slotOpen(DateTime day, int hour) =>
      DateTime(day.year, day.month, day.day, hour).isAfter(DateTime.now().add(const Duration(hours: 1)));

  static int? _firstSlotFor(DateTime day) {
    for (final h in _slotStartHours) {
      if (_slotOpen(day, h)) return h;
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    final today = _dateOnly(DateTime.now());
    _days = [for (var i = 0; i < 7; i++) today.add(Duration(days: i))]
        .where((d) => _slotStartHours.any((h) => _slotOpen(d, h)))
        .toList();
    _day = _days.first;
    _slotHour = _firstSlotFor(_day);
  }

  String _dayLabel(DateTime day) {
    final today = _dateOnly(DateTime.now());
    if (day == today) return 'Today';
    if (day == today.add(const Duration(days: 1))) return 'Tomorrow';
    return _weekdays[day.weekday - 1];
  }

  String _hourLabel(int hour) {
    final h = hour % 12 == 0 ? 12 : hour % 12;
    return '$h ${hour >= 12 ? 'PM' : 'AM'}';
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Select pickup time',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.navy),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.location_on_outlined, size: 16, color: AppColors.muted),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    widget.address.shortLine,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12, color: AppColors.muted),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _InstantPickupCard(
              selected: _instant,
              enabled: instantPickupOpen,
              onTap: () => setState(() => _instant = true),
            ),
            const SizedBox(height: 16),
            const Text(
              'Or schedule for later',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.muted),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 68,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _days.length,
                separatorBuilder: (_, _) => const SizedBox(width: 10),
                itemBuilder: (context, i) {
                  final d = _days[i];
                  final selected = !_instant && d == _day;
                  return _ChoiceBox(
                    selected: selected,
                    width: 70,
                    onTap: () => setState(() {
                      _instant = false;
                      _day = d;
                      if (_slotHour == null || !_slotOpen(d, _slotHour!)) _slotHour = _firstSlotFor(d);
                    }),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _dayLabel(d),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: selected ? Colors.white70 : AppColors.muted,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${d.day} ${_months[d.month - 1]}',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: selected ? Colors.white : AppColors.navy,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 14),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 3.4,
              children: [
                for (final h in _slotStartHours)
                  _ChoiceBox(
                    selected: !_instant && _slotHour == h,
                    enabled: _slotOpen(_day, h),
                    onTap: () => setState(() {
                      _instant = false;
                      _slotHour = h;
                    }),
                    child: Center(
                      child: Text(
                        '${_hourLabel(h)} – ${_hourLabel(h + 2)}',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: !_instant && _slotHour == h ? Colors.white : AppColors.navy,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 18),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.navy,
                minimumSize: const Size.fromHeight(52),
              ),
              onPressed: !_instant && _slotHour == null
                  ? null
                  : () => Navigator.of(context).pop<PickupChoice>(
                        _instant
                            ? (at: DateTime.now().add(instantPickupLead), instant: true)
                            : (at: DateTime(_day.year, _day.month, _day.day, _slotHour!), instant: false),
                      ),
              child: Text(_instant ? 'Book instant pickup' : 'Confirm & continue'),
            ),
          ],
        ),
      ),
    );
  }
}

class _InstantPickupCard extends StatelessWidget {
  const _InstantPickupCard({required this.selected, required this.enabled, required this.onTap});

  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final fg = selected ? Colors.white : AppColors.navy;
    return Opacity(
      opacity: enabled ? 1 : 0.5,
      child: Material(
        color: selected ? AppColors.navy : const Color(0xFFFFF1E6),
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: enabled ? onTap : null,
          borderRadius: BorderRadius.circular(16),
          child: Ink(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: selected ? AppColors.navy : AppColors.accentOrange.withValues(alpha: 0.4)),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: selected ? Colors.white : AppColors.accentOrange,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.bolt_rounded, color: selected ? AppColors.accentOrange : Colors.white),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Instant pickup', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: fg)),
                      const SizedBox(height: 2),
                      Text(
                        enabled
                            ? 'Partner arrives within 60 minutes'
                            : 'Available 7 AM – 9 PM',
                        style: TextStyle(fontSize: 12, color: selected ? Colors.white70 : AppColors.muted),
                      ),
                    ],
                  ),
                ),
                Icon(
                  selected ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                  color: selected ? Colors.white : AppColors.muted,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ChoiceBox extends StatelessWidget {
  const _ChoiceBox({
    required this.selected,
    required this.onTap,
    required this.child,
    this.enabled = true,
    this.width,
  });

  final bool selected;
  final bool enabled;
  final VoidCallback onTap;
  final Widget child;
  final double? width;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1 : 0.45,
      child: Material(
        color: selected ? AppColors.navy : AppColors.mist,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: enabled ? onTap : null,
          borderRadius: BorderRadius.circular(14),
          child: SizedBox(width: width, child: child),
        ),
      ),
    );
  }
}
