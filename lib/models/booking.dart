import 'package:kaamfast/common/address_format.dart';

class BookingModel {
  BookingModel({
    required this.id,
    required this.bookingNumber,
    required this.status,
    this.paymentStatus,
    this.total,
    this.currency = 'INR',
    this.moduleName,
    this.moduleSlug,
    this.partnerName,
    this.scheduledAt,
    this.createdAt,
    this.items = const [],
    this.notes,
    this.meta = const {},
    this.legs = const [],
    this.addressLine,
    this.dropAddressLineOverride,
    this.cancelReason,
    this.photos = const [],
  });

  factory BookingModel.fromJson(Map<String, dynamic> json) {
    final module = json['module'];
    final partner = json['partner'];
    final items = <BookingItemModel>[];
    if (json['items'] is List) {
      for (final item in json['items'] as List) {
        if (item is Map<String, dynamic>) {
          items.add(BookingItemModel.fromJson(item));
        } else if (item is Map) {
          items.add(BookingItemModel.fromJson(Map<String, dynamic>.from(item)));
        }
      }
    }
    final legs = <BookingLegModel>[];
    if (json['legs'] is List) {
      for (final leg in json['legs'] as List) {
        if (leg is Map<String, dynamic>) {
          legs.add(BookingLegModel.fromJson(leg));
        } else if (leg is Map) {
          legs.add(BookingLegModel.fromJson(Map<String, dynamic>.from(leg)));
        }
      }
    }
    final photos = <BookingPhotoModel>[];
    final photoSource = json['photos'] ?? json['laundry_complete_photos'];
    if (photoSource is List) {
      for (final item in photoSource) {
        if (item is Map) {
          final map = Map<String, dynamic>.from(item);
          final url = map['url']?.toString();
          if (url != null && url.isNotEmpty) {
            photos.add(BookingPhotoModel.fromJson(map));
          }
        }
      }
    }
    final meta = json['meta'] is Map
        ? Map<String, dynamic>.from(json['meta'] as Map)
        : <String, dynamic>{};
    String? addressLine;
    final address = json['address'];
    if (address is Map) {
      addressLine = AddressFormat.humanLine(
        line1: address['line1']?.toString(),
        city: address['city']?.toString(),
        pincode: address['pincode']?.toString(),
      );
    }
    String? dropLine;
    final dropAddress = json['drop_address'];
    if (dropAddress is Map) {
      dropLine = AddressFormat.humanLine(
        line1: dropAddress['line1']?.toString(),
        city: dropAddress['city']?.toString(),
        pincode: dropAddress['pincode']?.toString(),
      );
    }

    return BookingModel(
      id: json['id'] as int,
      bookingNumber: json['booking_number']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      paymentStatus: json['payment_status']?.toString(),
      total: _num(json['total']),
      currency: json['currency']?.toString() ?? 'INR',
      moduleName: module is Map ? module['name']?.toString() : null,
      moduleSlug: module is Map ? module['slug']?.toString() : null,
      partnerName: partner is Map ? partner['name']?.toString() : null,
      scheduledAt: json['scheduled_at']?.toString(),
      createdAt: json['created_at']?.toString(),
      items: items,
      notes: json['notes']?.toString(),
      meta: meta,
      legs: legs,
      addressLine: addressLine,
      dropAddressLineOverride: dropLine,
      cancelReason: json['cancel_reason']?.toString() ?? meta['cancel_reason']?.toString(),
      photos: photos,
    );
  }

  final int id;
  final String bookingNumber;
  final String status;
  final String? paymentStatus;
  final double? total;
  final String currency;
  final String? moduleName;
  final String? moduleSlug;
  final String? partnerName;
  final String? scheduledAt;
  final String? createdAt;
  final List<BookingItemModel> items;
  final String? notes;
  final Map<String, dynamic> meta;
  final List<BookingLegModel> legs;
  final String? addressLine;
  final String? dropAddressLineOverride;
  final String? cancelReason;
  final List<BookingPhotoModel> photos;

  String? get dropAddressLine {
    if (dropAddressLineOverride != null && dropAddressLineOverride!.isNotEmpty) {
      return dropAddressLineOverride;
    }
    final drop = meta['drop_address'];
    if (drop is! Map) return null;
    return AddressFormat.humanLine(
      line1: drop['line1']?.toString(),
      city: drop['city']?.toString(),
      pincode: drop['pincode']?.toString(),
    );
  }
}

class BookingItemModel {
  BookingItemModel({
    required this.id,
    required this.name,
    this.quantity = 1,
    this.amount,
  });

  factory BookingItemModel.fromJson(Map<String, dynamic> json) {
    return BookingItemModel(
      id: json['id'] as int? ?? 0,
      name: json['name']?.toString() ?? '',
      quantity: _num(json['quantity']) ?? 1,
      amount: _num(json['amount']),
    );
  }

  final int id;
  final String name;
  final double quantity;
  final double? amount;
}

class BookingLegModel {
  BookingLegModel({
    required this.id,
    this.legType,
    this.label,
    this.status,
    this.partnerName,
  });

  factory BookingLegModel.fromJson(Map<String, dynamic> json) {
    final partner = json['partner'];
    return BookingLegModel(
      id: json['id'] as int? ?? 0,
      legType: json['leg_type']?.toString(),
      label: json['label']?.toString(),
      status: json['status']?.toString(),
      partnerName: partner is Map ? partner['name']?.toString() : null,
    );
  }

  final int id;
  final String? legType;
  final String? label;
  final String? status;
  final String? partnerName;
}

class BookingPhotoModel {
  BookingPhotoModel({required this.url, this.id, this.kind});

  factory BookingPhotoModel.fromJson(Map<String, dynamic> json) {
    return BookingPhotoModel(
      id: json['id'] is int ? json['id'] as int : int.tryParse('${json['id']}'),
      kind: json['kind']?.toString(),
      url: json['url']?.toString() ?? '',
    );
  }

  final int? id;
  final String? kind;
  final String url;
}

double? _num(dynamic value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString());
}
