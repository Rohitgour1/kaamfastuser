import 'package:flutter/material.dart';
import 'package:kaamfast/core/theme/app_theme.dart';
import 'package:kaamfast/services/api_services.dart';
import 'package:provider/provider.dart';

/// Code field plus a tappable list of active coupons for this service.
class CouponApplyCard extends StatefulWidget {
  const CouponApplyCard({
    super.key,
    required this.moduleSlug,
    required this.appliedCode,
    required this.onChanged,
    this.addressId,
    this.serviceId,
    this.items,
    this.subtotal,
    this.busy = false,
  });

  final String moduleSlug;
  final String? appliedCode;
  final Future<void> Function(String? code) onChanged;
  final int? addressId;
  final int? serviceId;
  final List<Map<String, dynamic>>? items;
  final double? subtotal;
  final bool busy;

  @override
  State<CouponApplyCard> createState() => _CouponApplyCardState();
}

class _CouponApplyCardState extends State<CouponApplyCard> {
  final _code = TextEditingController();
  List<Map<String, dynamic>> _offers = [];
  bool _loading = true;
  bool _applying = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final offers = await context.read<BookingApi>().coupons(moduleSlug: widget.moduleSlug);
      if (!mounted) return;
      setState(() {
        _offers = offers;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  Future<void> _apply(String raw) async {
    final code = raw.trim().toUpperCase();
    if (code.isEmpty || _applying) return;
    setState(() {
      _applying = true;
      _error = null;
    });
    try {
      await context.read<BookingApi>().validateCoupon(
        code: code,
        moduleSlug: widget.moduleSlug,
        addressId: widget.addressId,
        serviceId: widget.serviceId,
        items: widget.items,
        subtotal: widget.subtotal,
      );
      await widget.onChanged(code);
      if (!mounted) return;
      _code.clear();
      setState(() => _applying = false);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _applying = false;
        _error = '$e';
      });
    }
  }

  Future<void> _remove() async {
    setState(() => _error = null);
    await widget.onChanged(null);
  }

  String _offerLabel(Map<String, dynamic> offer) {
    final type = offer['discount_type']?.toString();
    final value = offer['discount_value'];
    final amount = value is num ? value.toDouble() : double.tryParse('$value') ?? 0;
    if (type == 'percentage') {
      final max = offer['max_discount'];
      final cap = max == null ? '' : ' · up to ₹${_money(max)}';
      return '${amount.toStringAsFixed(0)}% off$cap';
    }
    return '₹${_money(amount)} off';
  }

  String _money(dynamic value) {
    final amount = value is num ? value.toDouble() : double.tryParse('$value') ?? 0;
    return amount.toStringAsFixed(amount.truncateToDouble() == amount ? 0 : 2);
  }

  @override
  Widget build(BuildContext context) {
    final applied = widget.appliedCode?.trim();
    final busy = widget.busy || _applying;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.sky,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.local_offer_outlined, color: AppColors.navy, size: 20),
              SizedBox(width: 8),
              Text('Apply coupon', style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.navy)),
            ],
          ),
          const SizedBox(height: 10),
          if (applied != null && applied.isNotEmpty) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.success.withValues(alpha: 0.4)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle, color: AppColors.success, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '$applied applied',
                      style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.navy),
                    ),
                  ),
                  TextButton(onPressed: busy ? null : _remove, child: const Text('Remove')),
                ],
              ),
            ),
            const SizedBox(height: 10),
          ],
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _code,
                  textCapitalization: TextCapitalization.characters,
                  textInputAction: TextInputAction.done,
                  enabled: !busy,
                  onSubmitted: _apply,
                  decoration: const InputDecoration(
                    hintText: 'Enter coupon code',
                    filled: true,
                    fillColor: Colors.white,
                    isDense: true,
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: busy ? null : () => _apply(_code.text),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.navy,
                  minimumSize: const Size(84, 48),
                ),
                child: Text(busy ? '…' : 'Apply'),
              ),
            ],
          ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(_error!, style: const TextStyle(color: AppColors.danger, fontSize: 12)),
          ],
          if (_loading)
            const Padding(
              padding: EdgeInsets.only(top: 12),
              child: LinearProgressIndicator(minHeight: 2),
            )
          else if (_offers.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Text(
              'Available coupons',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: AppColors.muted),
            ),
            const SizedBox(height: 8),
            for (final offer in _offers) ...[
              _OfferTile(
                code: offer['code']?.toString() ?? '',
                title: (offer['name']?.toString().isNotEmpty == true)
                    ? offer['name'].toString()
                    : (offer['code']?.toString() ?? 'Coupon'),
                subtitle: [
                  _offerLabel(offer),
                  if ((offer['description']?.toString() ?? '').isNotEmpty) offer['description'].toString(),
                  if (((offer['min_order'] is num ? (offer['min_order'] as num).toDouble() : double.tryParse('${offer['min_order']}') ?? 0)) > 0)
                    'Min order ₹${_money(offer['min_order'])}',
                ].join(' · '),
                selected: applied != null && applied.toUpperCase() == (offer['code']?.toString() ?? '').toUpperCase(),
                onApply: busy ? null : () => _apply(offer['code']?.toString() ?? ''),
              ),
              const SizedBox(height: 8),
            ],
          ],
        ],
      ),
    );
  }
}

class _OfferTile extends StatelessWidget {
  const _OfferTile({
    required this.code,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onApply,
  });

  final String code;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback? onApply;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: selected ? null : onApply,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(code, style: const TextStyle(fontWeight: FontWeight.w800, letterSpacing: 0.6, color: AppColors.navy)),
                    const SizedBox(height: 2),
                    Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                    if (subtitle.isNotEmpty)
                      Text(subtitle, style: const TextStyle(fontSize: 12, color: AppColors.muted, height: 1.3)),
                  ],
                ),
              ),
              TextButton(
                onPressed: selected ? null : onApply,
                child: Text(selected ? 'Applied' : 'Apply'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
