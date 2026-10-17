class MarketplaceImage {
  MarketplaceImage({
    required this.id,
    required this.url,
    this.sortOrder = 0,
  });

  factory MarketplaceImage.fromJson(Map<String, dynamic> json) {
    return MarketplaceImage(
      id: (json['id'] as num?)?.toInt() ?? 0,
      url: json['url']?.toString() ?? '',
      sortOrder: (json['sort_order'] as num?)?.toInt() ?? 0,
    );
  }

  final int id;
  final String url;
  final int sortOrder;
}

class MarketplaceUser {
  MarketplaceUser({
    required this.id,
    this.name,
    this.phone,
  });

  factory MarketplaceUser.fromJson(Map<String, dynamic> json) {
    return MarketplaceUser(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: json['name']?.toString(),
      phone: json['phone']?.toString(),
    );
  }

  final int id;
  final String? name;
  final String? phone;

  String get displayName {
    final n = name?.trim();
    if (n == null || n.isEmpty) return 'User';
    return n;
  }
}

class MarketplacePost {
  MarketplacePost({
    required this.id,
    required this.type,
    required this.title,
    this.description,
    this.price,
    this.condition,
    this.category,
    this.city,
    this.area,
    this.pincode,
    this.status = 'active',
    this.coverUrl,
    this.images = const [],
    this.user,
    this.isMine = false,
    this.createdAt,
    this.closedAt,
  });

  factory MarketplacePost.fromJson(Map<String, dynamic> json) {
    final images = <MarketplaceImage>[];
    if (json['images'] is List) {
      for (final item in json['images'] as List) {
        if (item is Map) {
          images.add(MarketplaceImage.fromJson(Map<String, dynamic>.from(item)));
        }
      }
    }
    return MarketplacePost(
      id: (json['id'] as num?)?.toInt() ?? 0,
      type: json['type']?.toString() ?? 'sale',
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString(),
      price: (json['price'] is num)
          ? (json['price'] as num).toDouble()
          : double.tryParse('${json['price']}'),
      condition: json['condition']?.toString(),
      category: json['category']?.toString(),
      city: json['city']?.toString(),
      area: json['area']?.toString(),
      pincode: json['pincode']?.toString(),
      status: json['status']?.toString() ?? 'active',
      coverUrl: json['cover_url']?.toString(),
      images: images,
      user: json['user'] is Map
          ? MarketplaceUser.fromJson(Map<String, dynamic>.from(json['user'] as Map))
          : null,
      isMine: json['is_mine'] == true,
      createdAt: json['created_at']?.toString(),
      closedAt: json['closed_at']?.toString(),
    );
  }

  final int id;
  final String type;
  final String title;
  final String? description;
  final double? price;
  final String? condition;
  final String? category;
  final String? city;
  final String? area;
  final String? pincode;
  final String status;
  final String? coverUrl;
  final List<MarketplaceImage> images;
  final MarketplaceUser? user;
  final bool isMine;
  final String? createdAt;
  final String? closedAt;

  bool get isSale => type == 'sale';
  bool get isRequest => type == 'request';
  bool get isActive => status == 'active';

  String get locationLabel {
    final parts = [area, city].whereType<String>().where((e) => e.trim().isNotEmpty);
    return parts.join(', ');
  }

  String get priceLabel {
    if (price == null) {
      return isRequest ? 'Budget not set' : 'Price on request';
    }
    final formatted = price!.toStringAsFixed(price! % 1 == 0 ? 0 : 2);
    return isRequest ? 'Budget ₹$formatted' : '₹$formatted';
  }
}

class MarketplaceConfig {
  MarketplaceConfig({
    this.categories = const [],
    this.conditions = const [],
    this.types = const [],
    this.saleStatuses = const [],
    this.requestStatuses = const [],
    this.maxImages = 8,
  });

  factory MarketplaceConfig.fromJson(Map<String, dynamic> json) {
    List<Map<String, String>> mapList(dynamic raw) {
      final out = <Map<String, String>>[];
      if (raw is! List) return out;
      for (final item in raw) {
        if (item is Map) {
          out.add({
            'value': item['value']?.toString() ?? '',
            'label': item['label']?.toString() ?? item['value']?.toString() ?? '',
          });
        } else if (item != null) {
          final text = item.toString();
          out.add({'value': text, 'label': text});
        }
      }
      return out;
    }

    final statuses = json['statuses'] is Map
        ? Map<String, dynamic>.from(json['statuses'] as Map)
        : <String, dynamic>{};

    return MarketplaceConfig(
      categories: (json['categories'] is List)
          ? (json['categories'] as List).map((e) => e.toString()).toList()
          : const [],
      conditions: mapList(json['conditions']),
      types: mapList(json['types']),
      saleStatuses: mapList(statuses['sale']),
      requestStatuses: mapList(statuses['request']),
      maxImages: (json['max_images'] as num?)?.toInt() ?? 8,
    );
  }

  final List<String> categories;
  final List<Map<String, String>> conditions;
  final List<Map<String, String>> types;
  final List<Map<String, String>> saleStatuses;
  final List<Map<String, String>> requestStatuses;
  final int maxImages;
}

class MarketplaceMessage {
  MarketplaceMessage({
    required this.id,
    required this.body,
    required this.senderId,
    this.senderName,
    this.isMine = false,
    this.readAt,
    this.createdAt,
  });

  factory MarketplaceMessage.fromJson(Map<String, dynamic> json) {
    final sender = json['sender'] is Map
        ? Map<String, dynamic>.from(json['sender'] as Map)
        : null;
    return MarketplaceMessage(
      id: (json['id'] as num?)?.toInt() ?? 0,
      body: (json['body'] ?? json['message'])?.toString() ?? '',
      senderId: (json['sender_id'] as num?)?.toInt() ?? 0,
      senderName: sender?['name']?.toString(),
      isMine: json['is_mine'] == true,
      readAt: json['read_at']?.toString(),
      createdAt: json['created_at']?.toString(),
    );
  }

  final int id;
  final String body;
  final int senderId;
  final String? senderName;
  final bool isMine;
  final String? readAt;
  final String? createdAt;
}

class MarketplaceChat {
  MarketplaceChat({
    required this.id,
    this.status = 'open',
    this.lastMessageAt,
    this.lastMessage,
    this.post,
    this.otherUser,
    this.isOwner = false,
    this.unreadCount = 0,
  });

  factory MarketplaceChat.fromJson(Map<String, dynamic> json) {
    MarketplaceMessage? last;
    final rawLast = json['last_message'];
    if (rawLast is Map) {
      last = MarketplaceMessage.fromJson(Map<String, dynamic>.from(rawLast));
    }

    MarketplacePost? post;
    final rawPost = json['post'];
    if (rawPost is Map) {
      post = MarketplacePost.fromJson(Map<String, dynamic>.from(rawPost));
    }

    return MarketplaceChat(
      id: (json['id'] as num?)?.toInt() ?? 0,
      status: json['status']?.toString() ?? 'open',
      lastMessageAt: json['last_message_at']?.toString(),
      lastMessage: last,
      post: post,
      otherUser: json['other_user'] is Map
          ? MarketplaceUser.fromJson(
              Map<String, dynamic>.from(json['other_user'] as Map),
            )
          : null,
      isOwner: json['is_owner'] == true,
      unreadCount: (json['unread_count'] as num?)?.toInt() ?? 0,
    );
  }

  final int id;
  final String status;
  final String? lastMessageAt;
  final MarketplaceMessage? lastMessage;
  final MarketplacePost? post;
  final MarketplaceUser? otherUser;
  final bool isOwner;
  final int unreadCount;

  bool get isClosed => status == 'closed';
}

class MarketplacePage<T> {
  MarketplacePage({
    required this.items,
    this.currentPage = 1,
    this.lastPage = 1,
    this.perPage = 20,
    this.total = 0,
    this.unreadChats = 0,
  });

  final List<T> items;
  final int currentPage;
  final int lastPage;
  final int perPage;
  final int total;
  final int unreadChats;

  bool get hasMore => currentPage < lastPage;
}
