class Vehicle {
  Vehicle({
    required this.id,
    required this.name,
    required this.basePrice,
    required this.pricePerKm,
    required this.minutesPerKm,
  });

  factory Vehicle.fromJson(Map<String, dynamic> json) {
    return Vehicle(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: json['name']?.toString() ?? '',
      basePrice: _toDouble(json['base_price']),
      pricePerKm: _toDouble(json['price_per_km']),
      minutesPerKm: (json['minutes_per_km'] as num?)?.toInt() ??
          int.tryParse('${json['minutes_per_km']}') ??
          2,
    );
  }

  final int id;
  final String name;
  final double basePrice;
  final double pricePerKm;
  final int minutesPerKm;
}

double _toDouble(dynamic value) {
  if (value == null) return 0;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString()) ?? 0;
}
