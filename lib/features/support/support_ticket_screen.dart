import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:kaamfast/core/theme/app_theme.dart';
import 'package:kaamfast/models/booking.dart';
import 'package:kaamfast/services/api_services.dart';
import 'package:provider/provider.dart';

class SupportTicketScreen extends StatefulWidget {
  const SupportTicketScreen({super.key});

  @override
  State<SupportTicketScreen> createState() => _SupportTicketScreenState();
}

class _SupportTicketScreenState extends State<SupportTicketScreen> {
  final _subject = TextEditingController();
  final _message = TextEditingController();
  List<dynamic> _tickets = [];
  List<BookingModel> _bookings = [];
  bool _loading = true;
  bool _sending = false;
  bool _relatedToOrder = false;
  int? _bookingId;
  int _formEpoch = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _subject.dispose();
    _message.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final supportApi = context.read<SupportApi>();
      final bookingApi = context.read<BookingApi>();
      final tickets = await supportApi.tickets();
      final bookings = await bookingApi.list();
      if (!mounted) return;
      setState(() {
        _tickets = tickets;
        _bookings = bookings;
        if (_bookingId != null && !_bookings.any((b) => b.id == _bookingId)) {
          _bookingId = null;
        }
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  Future<void> _createTicket() async {
    if (_message.text.trim().isEmpty) return;
    if (_relatedToOrder && _bookingId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select the order this ticket is about.')),
      );
      return;
    }

    final booking = _relatedToOrder
        ? _bookings.where((b) => b.id == _bookingId).firstOrNull
        : null;
    var subject = _subject.text.trim();
    if (subject.isEmpty) {
      subject = booking == null
          ? 'General support'
          : 'Issue with ${booking.bookingNumber}';
    }

    setState(() => _sending = true);
    final api = context.read<SupportApi>();
    try {
      await api.createTicket(
            subject: subject,
            message: _message.text.trim(),
            category: booking == null ? 'general' : 'order',
            bookingId: booking?.id,
          );
      _subject.clear();
      _message.clear();
      setState(() {
        _relatedToOrder = false;
        _bookingId = null;
        _formEpoch++;
      });
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ticket submitted')),
        );
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  String _formatWhen(String? raw) {
    if (raw == null || raw.isEmpty) return '';
    final parsed = DateTime.tryParse(raw);
    if (parsed == null) return raw;
    return DateFormat('dd MMM yyyy, hh:mm a').format(parsed.toLocal());
  }

  String _bookingLabel(BookingModel booking) {
    final parts = [
      booking.bookingNumber.isNotEmpty ? booking.bookingNumber : '#${booking.id}',
      if ((booking.moduleName ?? '').isNotEmpty) booking.moduleName,
      if (booking.status.isNotEmpty) booking.status.replaceAll('_', ' '),
    ];
    return parts.join(' · ');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Support ticket')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  const Text(
                    'What is this about?',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _TypeChip(
                          label: 'General support',
                          selected: !_relatedToOrder,
                          onTap: () => setState(() {
                            _relatedToOrder = false;
                            _bookingId = null;
                          }),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _TypeChip(
                          label: 'Related to an order',
                          selected: _relatedToOrder,
                          onTap: () => setState(() => _relatedToOrder = true),
                        ),
                      ),
                    ],
                  ),
                  if (_relatedToOrder) ...[
                    const SizedBox(height: 14),
                    const Text(
                      'Select order',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 8),
                    if (_bookings.isEmpty)
                      const Text(
                        'No orders yet. You can still raise general support.',
                        style: TextStyle(color: AppColors.muted),
                      )
                    else
                      DropdownButtonFormField<int>(
                        key: ValueKey('booking-$_formEpoch-$_bookingId'),
                        initialValue: _bookingId,
                        isExpanded: true,
                        decoration: const InputDecoration(hintText: 'Choose an order'),
                        items: [
                          for (final booking in _bookings)
                            DropdownMenuItem(
                              value: booking.id,
                              child: Text(
                                _bookingLabel(booking),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                        ],
                        onChanged: (value) => setState(() => _bookingId = value),
                      ),
                  ],
                  const SizedBox(height: 16),
                  TextField(
                    controller: _subject,
                    decoration: const InputDecoration(labelText: 'Subject (optional)'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _message,
                    decoration: const InputDecoration(labelText: 'Message'),
                    maxLines: 4,
                  ),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: _sending ? null : _createTicket,
                    child: Text(_sending ? 'Submitting...' : 'Submit ticket'),
                  ),
                  const SizedBox(height: 28),
                  const Text(
                    'Your tickets',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
                  ),
                  const SizedBox(height: 8),
                  if (_tickets.isEmpty)
                    const Text('No tickets yet', style: TextStyle(color: AppColors.muted))
                  else
                    ..._tickets.map((t) {
                      if (t is! Map) return const SizedBox.shrink();
                      final status = '${t['status'] ?? ''}';
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          title: Text(
                            '${t['subject'] ?? 'Ticket'}',
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          subtitle: Text(
                            [
                              if (status.isNotEmpty) status,
                              _formatWhen(t['created_at']?.toString()),
                            ].where((e) => e.toString().isNotEmpty).join(' · '),
                          ),
                        ),
                      );
                    }),
                ],
              ),
            ),
    );
  }
}

class _TypeChip extends StatelessWidget {
  const _TypeChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.navy : Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: selected ? AppColors.navy : AppColors.line),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: selected ? Colors.white : AppColors.navy,
            ),
          ),
        ),
      ),
    );
  }
}
