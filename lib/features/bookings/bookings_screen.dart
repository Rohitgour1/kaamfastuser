import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:kaamfast/core/theme/app_theme.dart';
import 'package:kaamfast/models/booking.dart';
import 'package:kaamfast/services/api_services.dart';
import 'package:kaamfast/services/live_sync.dart';
import 'package:kaamfast/widgets/app_header.dart';
import 'package:provider/provider.dart';

class BookingsScreen extends StatefulWidget {
  const BookingsScreen({super.key});

  @override
  State<BookingsScreen> createState() => _BookingsScreenState();
}

class _BookingsScreenState extends State<BookingsScreen> {
  List<BookingModel> _items = [];
  bool _loading = true;
  String? _error;
  String _filter = 'all';
  int _lastTick = -1;

  static const _filters = [
    ('all', 'All'),
    ('pending', 'Pending'),
    ('confirmed', 'Confirmed'),
    ('assigned', 'Assigned'),
    ('in_progress', 'In progress'),
    ('completed', 'Completed'),
    ('cancelled', 'Cancelled'),
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final tick = context.watch<LiveSync>().tick;
    if (_lastTick != -1 && tick != _lastTick) {
      _load();
    }
    _lastTick = tick;
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final items = await context.read<BookingApi>().list(
        status: _filter == 'all' ? null : _filter,
      );
      if (!mounted) return;
      setState(() {
        _items = items;
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

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return Colors.green.shade700;
      case 'cancelled':
      case 'canceled':
        return Colors.red.shade700;
      case 'in_progress':
      case 'assigned':
      case 'en_route':
      case 'arrived':
        return Colors.orange.shade800;
      case 'confirmed':
        return AppColors.teal;
      default:
        return AppColors.navy;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            const AppHeader(showBack: true),
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 4, 16, 0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Orders',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: AppColors.navy,
                  ),
                ),
              ),
            ),
          SizedBox(
            height: 48,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              children: [
                for (final f in _filters)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(f.$2),
                      selected: _filter == f.$1,
                      onSelected: (_) {
                        setState(() => _filter = f.$1);
                        _load();
                      },
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _load,
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                  ? ListView(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text(_error!),
                        ),
                      ],
                    )
                  : _items.isEmpty
                  ? ListView(
                      children: const [
                        SizedBox(height: 120),
                        Center(child: Text('No bookings for this filter.')),
                      ],
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: _items.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final booking = _items[index];
                        return Card(
                          child: ListTile(
                            onTap: () =>
                                context.push('/bookings/${booking.id}'),
                            title: Text(
                              booking.bookingNumber,
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            subtitle: Text(
                              '${booking.moduleName ?? 'Service'} · ${booking.status}'
                              '${booking.paymentStatus != null ? ' · ${booking.paymentStatus}' : ''}',
                            ),
                            trailing: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '₹${(booking.total ?? 0).toStringAsFixed(0)}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.teal,
                                  ),
                                ),
                                Text(
                                  booking.status,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: _statusColor(booking.status),
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ),
        ],
        ),
      ),
    );
  }
}
