import 'package:kaamfast/common/address_format.dart';

class AddressModel {
  AddressModel({
    required this.id,
    this.label,
    this.name,
    this.phone,
    required this.line1,
    this.line2,
    this.landmark,
    required this.city,
    this.state,
    this.pincode,
    this.latitude,
    this.longitude,
    this.isDefault = false,
  });

  factory AddressModel.fromJson(Map<String, dynamic> json) {
    return AddressModel(
      id: json['id'] as int,
      label: json['label']?.toString(),
      name: json['name']?.toString(),
      phone: json['phone']?.toString(),
      line1: json['line1']?.toString() ?? '',
      line2: json['line2']?.toString(),
      landmark: json['landmark']?.toString(),
      city: json['city']?.toString() ?? '',
      state: json['state']?.toString(),
      pincode: json['pincode']?.toString(),
      latitude: _toDouble(json['latitude']),
      longitude: _toDouble(json['longitude']),
      isDefault: json['is_default'] == true,
    );
  }

  final int id;
  final String? label;
  final String? name;
  final String? phone;
  final String line1;
  final String? line2;
  final String? landmark;
  final String city;
  final String? state;
  final String? pincode;
  final double? latitude;
  final double? longitude;
  final bool isDefault;

  String get shortLine => AddressFormat.humanLine(
        line1: line1,
        formatted: line2,
        city: city,
        pincode: pincode,
      );
}

double? _toDouble(dynamic value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString());
}
