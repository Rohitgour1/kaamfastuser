import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:kaamfast/core/theme/app_theme.dart';
import 'package:kaamfast/models/booking.dart';
import 'package:kaamfast/services/api_services.dart';
import 'package:kaamfast/services/live_sync.dart';
import 'package:kaamfast/widgets/app_header.dart';
import 'package:provider/provider.dart';

class TrackingScreen extends StatefulWidget {
  const TrackingScreen({super.key});

  @override
  State<TrackingScreen> createState() => _TrackingScreenState();
}

class _TrackingScreenState extends State<TrackingScreen> {
  List<BookingModel> _active = [];
  bool _loading = true;
  String? _error;
  int _lastTick = -1;

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
      final api = context.read<BookingApi>();
      final items = await api.list();
      if (!mounted) return;
      setState(() {
        _active = items.where((b) {
          final s = b.status.toLowerCase();
          return s != 'completed' && s != 'cancelled' && s != 'canceled';
        }).toList();
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
      case 'in_progress':
      case 'assigned':
      case 'started':
        return Colors.orange.shade800;
      case 'confirmed':
        return AppColors.navy;
      default:
        return AppColors.muted;
    }
  }

  String _when(BookingModel booking) {
    final raw = booking.scheduledAt ?? booking.createdAt;
    if (raw == null || raw.isEmpty) return '';
    final parsed = DateTime.tryParse(raw);
    if (parsed == null) return raw;
    return DateFormat('dd MMM, hh:mm a').format(parsed.toLocal());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            const AppHeader(),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: Row(
                children: [
                  const Text(
                    'Track orders',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: AppColors.navy,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    _active.isEmpty ? '' : '${_active.length} active',
                    style: const TextStyle(color: AppColors.muted, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(_error!),
                          const SizedBox(height: 12),
                          FilledButton(onPressed: _load, child: const Text('Retry')),
                        ],
                      ),
                    )
                  : _active.isEmpty
                  ? _EmptyTracking(onBrowse: () => context.go('/home'))
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                        itemCount: _active.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final booking = _active[index];
                          return Material(
                            color: AppColors.sky,
                            borderRadius: BorderRadius.circular(18),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(18),
                              onTap: () => context.push('/tracking/${booking.id}'),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          booking.status.replaceAll('_', ' ').toUpperCase(),
                                          style: TextStyle(
                                            color: _statusColor(booking.status),
                                            fontSize: 11,
                                            fontWeight: FontWeight.w800,
                                            letterSpacing: 0.6,
                                          ),
                                        ),
                                        const Spacer(),
                                        Text(
                                          '₹${(booking.total ?? 0).toStringAsFixed(0)}',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w800,
                                            color: AppColors.navy,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      booking.moduleName ?? 'Service',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 16,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      booking.bookingNumber,
                                      style: const TextStyle(fontWeight: FontWeight.w700),
                                    ),
                                    if (_when(booking).isNotEmpty)
                                      Text(
                                        _when(booking),
                                        style: const TextStyle(fontSize: 12, color: AppColors.muted),
                                      ),
                                    const SizedBox(height: 6),
                                    Text(
                                      booking.addressLine ?? 'Address on file',
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(fontSize: 12, color: AppColors.muted),
                                    ),
                                    if (booking.partnerName != null) ...[
                                      const SizedBox(height: 6),
                                      Text(
                                        'Partner: ${booking.partnerName}',
                                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                                      ),
                                    ],
                                    const SizedBox(height: 10),
                                    const Row(
                                      children: [
                                        Text(
                                          'Live tracking, OTP & details',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.navy,
                                          ),
                                        ),
                                        Spacer(),
                                        Icon(Icons.chevron_right, color: AppColors.navy),
                                      ],
                                    ),
                                  ],
                                ),
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

class _EmptyTracking extends StatelessWidget {
  const _EmptyTracking({required this.onBrowse});
  final VoidCallback onBrowse;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('No active bookings to track'),
          const SizedBox(height: 12),
          FilledButton(onPressed: onBrowse, child: const Text('Browse services')),
        ],
      ),
    );
  }
}
