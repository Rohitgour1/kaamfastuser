class QuoteResult {
  QuoteResult({
    required this.total,
    required this.subtotal,
    this.tax = 0,
    this.discount = 0,
    this.currency = 'INR',
    this.breakdown = const [],
    this.meta = const {},
  });

  factory QuoteResult.fromJson(Map<String, dynamic> json) {
    final lines = <Map<String, dynamic>>[];
    final raw = json['breakdown'] ?? json['lines'];
    if (raw is List) {
      for (final item in raw) {
        if (item is Map) lines.add(Map<String, dynamic>.from(item));
      }
    }
    final meta = json['meta'] is Map
        ? Map<String, dynamic>.from(json['meta'] as Map)
        : <String, dynamic>{};

    // Some APIs put fees on the root instead of meta.
    for (final key in _deliveryKeys) {
      if (!meta.containsKey(key) && json[key] != null) {
        meta[key] = json[key];
      }
    }

    return QuoteResult(
      total: _num(json['total']) ?? 0,
      subtotal: _num(json['subtotal']) ?? 0,
      tax: _num(json['tax']) ?? 0,
      discount: _num(json['discount']) ?? 0,
      currency: json['currency']?.toString() ?? 'INR',
      breakdown: lines,
      meta: meta,
    );
  }

  static const _deliveryKeys = [
    'delivery_fee',
    'pickup_fee',
    'pickup_delivery_fee',
    'shipping_fee',
    'delivery',
  ];

  final double total;
  final double subtotal;
  final double tax;
  final double discount;
  final String currency;
  final List<Map<String, dynamic>> breakdown;
  final Map<String, dynamic> meta;

  /// Pickup / delivery fee from meta or breakdown. 0 if API does not charge one.
  double get deliveryFee {
    for (final key in _deliveryKeys) {
      final value = _num(meta[key]);
      if (value != null && value > 0) return value;
    }
    for (final line in breakdown) {
      final label =
          '${line['label'] ?? line['name'] ?? line['type'] ?? ''}'.toLowerCase();
      if (label.contains('delivery') || label.contains('pickup')) {
        final value = _num(line['amount'] ?? line['value'] ?? line['price']);
        if (value != null && value != 0) return value;
      }
    }
    return 0;
  }
}

double? _num(dynamic value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString());
}
