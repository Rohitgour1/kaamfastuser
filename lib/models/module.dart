class ServiceModule {
  ServiceModule({
    required this.id,
    required this.name,
    required this.slug,
    this.description,
    this.iconUrl,
    this.bannerUrl,
    this.backgroundUrl,
    this.pricingType,
    this.services = const [],
    this.categories = const [],
  });

  factory ServiceModule.fromJson(Map<String, dynamic> json) {
    final services = <ServiceItem>[];
    final raw = json['services'];
    if (raw is List) {
      for (final item in raw) {
        if (item is Map) {
          services.add(ServiceItem.fromJson(Map<String, dynamic>.from(item)));
        }
      }
    }

    final categories = <ServiceCategory>[];
    final rawCats = json['categories'];
    if (rawCats is List) {
      for (final item in rawCats) {
        if (item is Map) {
          categories.add(
            ServiceCategory.fromJson(Map<String, dynamic>.from(item)),
          );
        }
      }
    }

    return ServiceModule(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: (json['name'] ?? json['display_name'] ?? '').toString(),
      slug: json['slug']?.toString() ?? '',
      description: json['short_description']?.toString() ??
          json['description']?.toString() ??
          json['long_description']?.toString(),
      iconUrl: json['icon_url']?.toString() ?? json['icon']?.toString(),
      bannerUrl: json['banner_url']?.toString() ?? json['banner']?.toString(),
      backgroundUrl: json['background_url']?.toString() ??
          json['background']?.toString(),
      pricingType: json['pricing_type']?.toString(),
      services: services,
      categories: categories,
    );
  }

  final int id;
  final String name;
  final String slug;
  final String? description;
  final String? iconUrl;
  final String? bannerUrl;
  final String? backgroundUrl;

  String? get heroUrl {
    final banner = bannerUrl?.trim();
    if (banner != null && banner.isNotEmpty) return banner;
    final background = backgroundUrl?.trim();
    if (background != null && background.isNotEmpty) return background;
    return null;
  }

  final String? pricingType;
  final List<ServiceItem> services;
  final List<ServiceCategory> categories;
}

class ServiceCategory {
  ServiceCategory({
    required this.id,
    required this.name,
    this.slug,
    this.description,
    this.iconUrl,
    this.imageUrl,
    this.services = const [],
  });

  factory ServiceCategory.fromJson(Map<String, dynamic> json) {
    final services = <ServiceItem>[];
    final raw = json['services'];
    if (raw is List) {
      for (final item in raw) {
        if (item is Map) {
          services.add(ServiceItem.fromJson(Map<String, dynamic>.from(item)));
        }
      }
    }

    return ServiceCategory(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: json['name']?.toString() ?? '',
      slug: json['slug']?.toString(),
      description: json['description']?.toString(),
      iconUrl: json['icon_url']?.toString() ?? json['icon']?.toString(),
      imageUrl: json['image_url']?.toString() ?? json['image']?.toString(),
      services: services,
    );
  }

  final int id;
  final String name;
  final String? slug;
  final String? description;
  final String? iconUrl;
  final String? imageUrl;
  final List<ServiceItem> services;

  String? get coverUrl {
    final image = imageUrl?.trim();
    if (image != null && image.isNotEmpty) return image;
    final icon = iconUrl?.trim();
    if (icon != null && icon.isNotEmpty) return icon;
    for (final s in services) {
      final url = s.imageUrl?.trim();
      if (url != null && url.isNotEmpty) return url;
    }
    return null;
  }

  double? get startingPrice {
    double? min;
    for (final s in services) {
      final p = s.basePrice;
      if (p == null) continue;
      if (min == null || p < min) min = p;
    }
    return min;
  }
}

class ServiceItem {
  ServiceItem({
    required this.id,
    required this.name,
    this.slug,
    this.sku,
    this.basePrice,
    this.unit,
    this.imageUrl,
    this.description,
    this.categoryId,
    this.categoryName,
    this.categorySlug,
    this.addons = const [],
  });

  factory ServiceItem.fromJson(Map<String, dynamic> json) {
    final category = json['category'];
    Map<String, dynamic>? catMap;
    if (category is Map) {
      catMap = Map<String, dynamic>.from(category);
    }

    final addons = <ServiceAddon>[];
    final rawAddons = json['addons'];
    if (rawAddons is List) {
      for (final item in rawAddons) {
        if (item is Map) {
          addons.add(ServiceAddon.fromJson(Map<String, dynamic>.from(item)));
        }
      }
      addons.sort((a, b) => a.displayOrder.compareTo(b.displayOrder));
    }

    return ServiceItem(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: json['name']?.toString() ?? '',
      slug: json['slug']?.toString(),
      sku: json['sku']?.toString(),
      basePrice: _toDouble(
        json['base_price'] ??
            json['price'] ??
            json['unit_price'] ??
            json['price_per_unit'] ??
            json['amount'],
      ),
      unit: json['unit']?.toString(),
      imageUrl: json['image_url']?.toString() ?? json['image']?.toString(),
      description: json['description']?.toString(),
      categoryId: (catMap?['id'] as num?)?.toInt() ??
          (json['service_category_id'] as num?)?.toInt(),
      categoryName: catMap?['name']?.toString() ??
          json['category_name']?.toString(),
      categorySlug: catMap?['slug']?.toString() ??
          json['category_slug']?.toString(),
      addons: addons,
    );
  }

  final int id;
  final String name;
  final String? slug;
  final String? sku;
  final double? basePrice;
  final String? unit;
  final String? imageUrl;
  final String? description;
  final int? categoryId;
  final String? categoryName;
  final String? categorySlug;
  final List<ServiceAddon> addons;

  /// Match home tile / selected service (e.g. "Blanket Care" → category "Blanket").
  bool matchesSelectedCategory(String? selected) {
    final raw = selected?.trim();
    if (raw == null || raw.isEmpty) return true;

    final sel = _categoryKey(raw);
    final cat = _categoryKey(categoryName ?? '');
    final slugKey = _categoryKey(categorySlug ?? '');
    if (sel.isEmpty) return true;

    if (cat.isNotEmpty && (sel == cat || sel.startsWith(cat))) return true;
    if (slugKey.isNotEmpty && (sel == slugKey || sel.startsWith(slugKey))) {
      return true;
    }

    // Fallback: item name itself (e.g. service "Blanket" under wrong category)
    final itemKey = _categoryKey(name);
    if (itemKey.isNotEmpty && (sel == itemKey || sel.startsWith(itemKey))) {
      return true;
    }
    return false;
  }
}

class ServiceAddon {
  ServiceAddon({
    required this.id,
    required this.code,
    required this.name,
    required this.amount,
    this.isQuantityBased = true,
    this.displayOrder = 0,
    this.serviceAddonId,
  });

  factory ServiceAddon.fromJson(Map<String, dynamic> json) {
    return ServiceAddon(
      id: (json['id'] as num?)?.toInt() ?? 0,
      code: json['code']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      amount: _toDouble(json['amount']) ?? 0,
      isQuantityBased: json['is_quantity_based'] != false,
      displayOrder: (json['display_order'] as num?)?.toInt() ?? 0,
      serviceAddonId: (json['service_addon_id'] as num?)?.toInt(),
    );
  }

  final int id;
  final String code;
  final String name;
  final double amount;
  final bool isQuantityBased;
  final int displayOrder;
  final int? serviceAddonId;

  String get priceLabel {
    final price = amount % 1 == 0
        ? amount.toStringAsFixed(0)
        : amount.toStringAsFixed(2);
    return isQuantityBased ? '+ ₹$price each' : '+ ₹$price';
  }
}

String _categoryKey(String value) {
  var t = value.toLowerCase().trim();
  t = t.replaceAll(RegExp(r'\s*&\s*'), 'and');
  t = t.replaceAll(RegExp(r'[^a-z0-9]+'), '');
  if (t.endsWith('care') && t.length > 4) {
    t = t.substring(0, t.length - 4);
  }
  if (t.endsWith('cleaning') && t.length > 8) {
    // keep "shoecleaning" / "drycleaning" as-is for slug match
  }
  return t;
}

double? _toDouble(dynamic value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString());
}
