class ServiceRequestModule {
  ServiceRequestModule({
    required this.id,
    this.name,
    this.slug,
  });

  factory ServiceRequestModule.fromJson(Map<String, dynamic> json) {
    return ServiceRequestModule(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: json['name']?.toString(),
      slug: json['slug']?.toString(),
    );
  }

  final int id;
  final String? name;
  final String? slug;
}

class ServiceRequestItem {
  ServiceRequestItem({
    required this.id,
    required this.title,
    this.description,
    this.status = 'pending',
    this.statusLabel,
    this.city,
    this.area,
    this.pincode,
    this.module,
    this.adminNotes,
    this.createdAt,
  });

  factory ServiceRequestItem.fromJson(Map<String, dynamic> json) {
    return ServiceRequestItem(
      id: (json['id'] as num?)?.toInt() ?? 0,
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString(),
      status: json['status']?.toString() ?? 'pending',
      statusLabel: json['status_label']?.toString(),
      city: json['city']?.toString(),
      area: json['area']?.toString(),
      pincode: json['pincode']?.toString(),
      module: json['module'] is Map
          ? ServiceRequestModule.fromJson(
              Map<String, dynamic>.from(json['module'] as Map),
            )
          : null,
      adminNotes: json['admin_notes']?.toString(),
      createdAt: json['created_at']?.toString(),
    );
  }

  final int id;
  final String title;
  final String? description;
  final String status;
  final String? statusLabel;
  final String? city;
  final String? area;
  final String? pincode;
  final ServiceRequestModule? module;
  final String? adminNotes;
  final String? createdAt;

  String get displayStatus {
    final label = statusLabel?.trim();
    if (label != null && label.isNotEmpty) return label;
    if (status.isEmpty) return 'Pending';
    return status[0].toUpperCase() + status.substring(1);
  }

  bool get showAdminNotes =>
      status != 'pending' &&
      adminNotes != null &&
      adminNotes!.trim().isNotEmpty;
}
