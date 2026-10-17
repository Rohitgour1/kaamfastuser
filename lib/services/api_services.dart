import 'package:dio/dio.dart';
import 'package:kaamfast/common/address_format.dart';
import 'package:kaamfast/common/api_endpoints.dart';
import 'package:kaamfast/core/network/api_client.dart';
import 'package:kaamfast/models/address.dart';
import 'package:kaamfast/models/booking.dart';
import 'package:kaamfast/models/maps_config.dart';
import 'package:kaamfast/models/marketplace.dart';
import 'package:kaamfast/models/module.dart';
import 'package:kaamfast/models/service_request.dart';
import 'package:kaamfast/models/user.dart';
import 'package:kaamfast/services/location_service.dart';

class HomeService {
  HomeService(this._api);

  final ApiClient _api;

  Future<HomeData> fetch() async {
    final data = await _api.get(ApiEndpoints.home);
    final map = Map<String, dynamic>.from(data as Map);
    final modules = <ServiceModule>[];
    if (map['modules'] is List) {
      for (final item in map['modules'] as List) {
        if (item is Map)
          modules.add(ServiceModule.fromJson(Map<String, dynamic>.from(item)));
      }
    }
    final stats = map['stats'] is Map
        ? Map<String, dynamic>.from(map['stats'] as Map)
        : <String, dynamic>{};
    final user = map['user'] is Map
        ? UserModel.fromJson(Map<String, dynamic>.from(map['user'] as Map))
        : null;

    final marketplaceRaw = map['marketplace'] is Map
        ? Map<String, dynamic>.from(map['marketplace'] as Map)
        : <String, dynamic>{};
    List<MarketplacePost> parsePosts(dynamic raw) {
      final out = <MarketplacePost>[];
      if (raw is! List) return out;
      for (final item in raw) {
        if (item is Map) {
          out.add(MarketplacePost.fromJson(Map<String, dynamic>.from(item)));
        }
      }
      return out;
    }

    return HomeData(
      user: user,
      modules: modules,
      activeBookings: (stats['active_bookings'] as num?)?.toInt() ?? 0,
      walletBalance: (stats['wallet_balance'] is num)
          ? (stats['wallet_balance'] as num).toDouble()
          : double.tryParse('${stats['wallet_balance']}') ?? 0,
      unreadNotifications:
          (stats['unread_notifications'] as num?)?.toInt() ?? 0,
      marketplaceEnabled: marketplaceRaw['enabled'] != false,
      marketplaceSales: parsePosts(marketplaceRaw['sales']),
      marketplaceRequests: parsePosts(marketplaceRaw['requests']),
      marketplaceUnreadChats:
          (stats['marketplace_unread_chats'] as num?)?.toInt() ?? 0,
    );
  }
}

class HomeData {
  HomeData({
    this.user,
    required this.modules,
    required this.activeBookings,
    required this.walletBalance,
    required this.unreadNotifications,
    this.marketplaceEnabled = true,
    this.marketplaceSales = const [],
    this.marketplaceRequests = const [],
    this.marketplaceUnreadChats = 0,
  });

  final UserModel? user;
  final List<ServiceModule> modules;
  final int activeBookings;
  final double walletBalance;
  final int unreadNotifications;
  final bool marketplaceEnabled;
  final List<MarketplacePost> marketplaceSales;
  final List<MarketplacePost> marketplaceRequests;
  final int marketplaceUnreadChats;
}

class ModuleService {
  ModuleService(this._api);

  final ApiClient _api;

  Future<List<ServiceModule>> list() async {
    final data = await _api.get(ApiEndpoints.modules);
    final list = data is List ? data : (data is Map ? data['data'] : null);
    final modules = <ServiceModule>[];
    if (list is List) {
      for (final item in list) {
        if (item is Map)
          modules.add(ServiceModule.fromJson(Map<String, dynamic>.from(item)));
      }
    }
    return modules;
  }

  Future<ServiceModule> show(String slug) async {
    final data = await _api.get(ApiEndpoints.module(slug));
    return ServiceModule.fromJson(Map<String, dynamic>.from(data as Map));
  }

  Future<List<ServiceItem>> services(String slug) async {
    final data = await _api.get(ApiEndpoints.moduleServices(slug));
    final map = Map<String, dynamic>.from(data as Map);
    final list = map['services'];
    final items = <ServiceItem>[];
    if (list is List) {
      for (final item in list) {
        if (item is Map)
          items.add(ServiceItem.fromJson(Map<String, dynamic>.from(item)));
      }
    }
    return items;
  }
}

class BookingApi {
  BookingApi(this._api);

  final ApiClient _api;

  Future<Map<String, dynamic>> quote(Map<String, dynamic> body) async {
    final data = await _api.post(ApiEndpoints.bookingQuote, data: body);
    return Map<String, dynamic>.from(data as Map);
  }

  Future<List<Map<String, dynamic>>> coupons({String? moduleSlug}) async {
    final data = await _api.get(
      ApiEndpoints.coupons,
      query: {
        if (moduleSlug != null && moduleSlug.isNotEmpty)
          'module_slug': moduleSlug,
      },
    );
    final raw = data is List
        ? data
        : (data is Map ? (data['coupons'] ?? data['data']) : null);
    if (raw is! List) return [];
    return [
      for (final item in raw)
        if (item is Map) Map<String, dynamic>.from(item),
    ];
  }

  Future<Map<String, dynamic>> validateCoupon({
    required String code,
    required String moduleSlug,
    int? addressId,
    int? serviceId,
    List<Map<String, dynamic>>? items,
    double? subtotal,
  }) async {
    final data = await _api.post(
      ApiEndpoints.couponsValidate,
      data: {
        'code': code,
        'module_slug': moduleSlug,
        if (addressId != null) 'address_id': addressId,
        if (serviceId != null) 'service_id': serviceId,
        if (items != null && items.isNotEmpty) 'items': items,
        if (subtotal != null) 'subtotal': subtotal,
      },
    );
    return Map<String, dynamic>.from(data as Map);
  }

  Future<BookingModel> create(Map<String, dynamic> body) async {
    final data = await _api.post(ApiEndpoints.bookings, data: body);
    return BookingModel.fromJson(Map<String, dynamic>.from(data as Map));
  }

  Future<List<BookingModel>> list({String? status}) async {
    final data = await _api.get(
      ApiEndpoints.bookings,
      query: {if (status != null) 'status': status},
    );
    final list = data is Map ? data['data'] : data;
    final bookings = <BookingModel>[];
    if (list is List) {
      for (final item in list) {
        if (item is Map)
          bookings.add(BookingModel.fromJson(Map<String, dynamic>.from(item)));
      }
    }
    return bookings;
  }

  Future<BookingModel> show(int id) async {
    final data = await _api.get(ApiEndpoints.booking(id));
    return BookingModel.fromJson(Map<String, dynamic>.from(data as Map));
  }

  Future<BookingModel> confirm(int id) async {
    final data = await _api.post(ApiEndpoints.bookingConfirm(id));
    return BookingModel.fromJson(Map<String, dynamic>.from(data as Map));
  }

  Future<BookingModel> cancel(
    int id, {
    String? reason,
    int? cancelReasonId,
  }) async {
    final data = await _api.post(
      ApiEndpoints.bookingCancel(id),
      data: {
        if (reason != null && reason.isNotEmpty) 'reason': reason,
        if (cancelReasonId != null) 'cancel_reason_id': cancelReasonId,
      },
    );
    return BookingModel.fromJson(Map<String, dynamic>.from(data as Map));
  }

  Future<List<Map<String, dynamic>>> cancelReasons({
    String appliesTo = 'user',
  }) async {
    final data = await _api.get(
      ApiEndpoints.cancelReasons,
      query: {'applies_to': appliesTo},
    );
    final list = data is Map ? data['data'] : data;
    if (list is! List) return [];
    return list
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  Future<Map<String, dynamic>> pay(int id, String method) async {
    final data = await _api.post(
      ApiEndpoints.bookingPay(id),
      data: {'method': method},
    );
    return Map<String, dynamic>.from(data as Map);
  }

  Future<Map<String, dynamic>> confirmPayment(
    int paymentId, [
    Map<String, String>? payload,
  ]) async {
    final data = await _api.post(
      ApiEndpoints.paymentConfirm(paymentId),
      data: payload ?? {},
    );
    return Map<String, dynamic>.from(data as Map);
  }

  Future<Map<String, dynamic>> paymentConfig() async {
    final data = await _api.get(ApiEndpoints.paymentsConfig);
    return Map<String, dynamic>.from(data as Map);
  }

  Future<void> uploadMedia(int bookingId, String filePath) async {
    final form = FormData();
    form.fields.add(const MapEntry('kind', 'user_pickup'));
    form.files.add(
      MapEntry(
        'photos[]',
        await MultipartFile.fromFile(filePath, filename: 'pickup.jpg'),
      ),
    );
    await _api.postMultipart(ApiEndpoints.bookingMedia(bookingId), form);
  }

  Future<Map<String, dynamic>> tracking(int bookingId) async {
    final data = await _api.get(ApiEndpoints.bookingTracking(bookingId));
    return Map<String, dynamic>.from(data as Map);
  }

  Future<Map<String, dynamic>> searching(int bookingId) async {
    final data = await _api.get(ApiEndpoints.bookingSearching(bookingId));
    return Map<String, dynamic>.from(data as Map);
  }

  Future<Map<String, dynamic>> bookingChat(int bookingId) async {
    final data = await _api.get(ApiEndpoints.bookingChat(bookingId));
    return Map<String, dynamic>.from(data as Map);
  }

  Future<Map<String, dynamic>> sendBookingChat(
    int bookingId,
    String body,
  ) async {
    final data = await _api.post(
      ApiEndpoints.bookingChatMessages(bookingId),
      data: {'body': body},
    );
    return Map<String, dynamic>.from(data as Map);
  }

  Future<void> review(
    int id, {
    required int rating,
    String? comment,
    String targetType = 'service',
  }) async {
    await _api.post(
      ApiEndpoints.bookingReviews(id),
      data: {'rating': rating, 'comment': comment, 'target_type': targetType},
    );
  }

  Future<List<Map<String, dynamic>>> reviews(int id) async {
    final data = await _api.get(ApiEndpoints.bookingReviews(id));
    if (data is! List) return const [];
    return [
      for (final item in data)
        if (item is Map) Map<String, dynamic>.from(item),
    ];
  }
}

class AddressApi {
  AddressApi(this._api);

  final ApiClient _api;

  Future<List<dynamic>> list() async {
    final data = await _api.get(ApiEndpoints.addresses);
    return data is List ? data : [];
  }

  Future<Map<String, dynamic>> create(Map<String, dynamic> body) async {
    final data = await _api.post(ApiEndpoints.addresses, data: body);
    return Map<String, dynamic>.from(data as Map);
  }

  Future<Map<String, dynamic>> update(int id, Map<String, dynamic> body) async {
    final data = await _api.put(ApiEndpoints.address(id), data: body);
    return Map<String, dynamic>.from(data as Map);
  }

  Future<AddressModel> savePlace(
    PlaceResult place, {
    String label = 'Home',
    bool isDefault = false,
  }) async {
    final created = await create(
      place.toAddressBody(label: label, isDefault: isDefault),
    );
    return AddressModel.fromJson(created);
  }

  Future<List<AddressModel>> listRepaired(LocationService location) async {
    final raw = await list();
    final items = raw
        .whereType<Map>()
        .map((e) => AddressModel.fromJson(Map<String, dynamic>.from(e)))
        .toList();
    final repaired = <AddressModel>[];
    for (final item in items) {
      if (!AddressFormat.looksLikeCoordinates(item.line1) ||
          item.latitude == null ||
          item.longitude == null) {
        repaired.add(item);
        continue;
      }
      try {
        final place = await location.reverseGeocode(
          item.latitude!,
          item.longitude!,
        );
        final updated = await update(item.id, {
          'line1': place.storageLine1,
          'city': place.city.trim().isNotEmpty
              ? place.city
              : (item.city.isNotEmpty ? item.city : 'Indore'),
          'state': place.state ?? item.state,
          'pincode': place.pincode ?? item.pincode,
          'latitude': place.latitude,
          'longitude': place.longitude,
        });
        repaired.add(AddressModel.fromJson(updated));
      } catch (_) {
        repaired.add(item);
      }
    }
    return repaired;
  }

  Future<void> delete(int id) async {
    await _api.delete(ApiEndpoints.address(id));
  }
}

class WalletApi {
  WalletApi(this._api);

  final ApiClient _api;

  Future<Map<String, dynamic>> me() async {
    final data = await _api.get(ApiEndpoints.wallet);
    return Map<String, dynamic>.from(data as Map);
  }

  Future<List<dynamic>> transactions() async {
    final data = await _api.get(ApiEndpoints.walletTransactions);
    if (data is Map && data['data'] is List) return data['data'] as List;
    return [];
  }

  Future<Map<String, dynamic>> topup(double amount) async {
    final data = await _api.post(
      ApiEndpoints.walletTopup,
      data: {'amount': amount},
    );
    return Map<String, dynamic>.from(data as Map);
  }

  Future<Map<String, dynamic>> paymentConfig() async {
    final data = await _api.get(ApiEndpoints.paymentsConfig);
    return Map<String, dynamic>.from(data as Map);
  }

  Future<Map<String, dynamic>> confirmTopup(
    int topupId,
    Map<String, String> payload,
  ) async {
    final data = await _api.post(
      ApiEndpoints.walletTopupConfirm(topupId),
      data: payload,
    );
    return Map<String, dynamic>.from(data as Map);
  }

  Future<Map<String, dynamic>> withdraw({
    required double amount,
    required String upiId,
  }) async {
    final data = await _api.post(
      ApiEndpoints.walletWithdraw,
      data: {
        'amount': amount,
        'upi_id': upiId,
      },
    );
    return Map<String, dynamic>.from(data as Map);
  }

  Future<Map<String, dynamic>> bankAccount() async {
    final data = await _api.get(ApiEndpoints.walletBankAccount);
    if (data is Map) return Map<String, dynamic>.from(data);
    return {};
  }

  Future<Map<String, dynamic>> updateBankAccount({
    required String accountHolderName,
    required String accountNumber,
    required String ifscCode,
  }) async {
    final data = await _api.put(
      ApiEndpoints.walletBankAccount,
      data: {
        'account_holder_name': accountHolderName,
        'account_number': accountNumber,
        'ifsc_code': ifscCode,
      },
    );
    return Map<String, dynamic>.from(data as Map);
  }
}

class SupportApi {
  SupportApi(this._api);

  final ApiClient _api;

  Future<List<dynamic>> tickets() async {
    final data = await _api.get(ApiEndpoints.supportTickets);
    if (data is Map && data['data'] is List) return data['data'] as List;
    return data is List ? data : [];
  }

  Future<Map<String, dynamic>> createTicket({
    required String subject,
    required String message,
    String? category,
    int? bookingId,
  }) async {
    final data = await _api.post(
      ApiEndpoints.supportTickets,
      data: {
        'subject': subject,
        'message': message,
        'category': ?category,
        'booking_id': ?bookingId,
      },
    );
    return Map<String, dynamic>.from(data as Map);
  }

  Future<Map<String, dynamic>> config() async {
    try {
      final data = await _api.get(ApiEndpoints.supportConfig);
      if (data is Map) return Map<String, dynamic>.from(data);
    } catch (_) {}
    return {};
  }

  Future<Map<String, dynamic>> chat() async {
    final data = await _api.get(ApiEndpoints.supportChat);
    return Map<String, dynamic>.from(data as Map);
  }

  Future<void> sendChat(String message) async {
    await _api.post(
      ApiEndpoints.supportChatMessages,
      data: {'message': message},
    );
  }

  Future<void> markChatRead() async {
    try {
      await _api.post(ApiEndpoints.supportChatRead);
    } catch (_) {}
  }
}

class ProfileApi {
  ProfileApi(this._api);

  final ApiClient _api;

  Future<Map<String, dynamic>> update({String? name, String? email}) async {
    final data = await _api.put(
      ApiEndpoints.profile,
      data: {if (name != null) 'name': name, if (email != null) 'email': email},
    );
    return Map<String, dynamic>.from(data as Map);
  }

  Future<Map<String, dynamic>> uploadAvatar(String filePath) async {
    final form = FormData();
    form.files.add(
      MapEntry(
        'avatar',
        await MultipartFile.fromFile(filePath, filename: 'avatar.jpg'),
      ),
    );
    final data = await _api.postMultipart(ApiEndpoints.profileAvatar, form);
    if (data is Map && data['user'] is Map) {
      final nested = data['user'] as Map;
      if (nested['data'] is Map) {
        return Map<String, dynamic>.from(nested['data'] as Map);
      }
      return Map<String, dynamic>.from(nested);
    }
    if (data is Map && data['data'] is Map) {
      return Map<String, dynamic>.from(data['data'] as Map);
    }
    return Map<String, dynamic>.from(data as Map);
  }

  Future<void> registerDeviceToken(String token) async {
    await _api.post(ApiEndpoints.deviceToken, data: {'fcm_token': token});
  }
}

class ReferralApi {
  ReferralApi(this._api);

  final ApiClient _api;

  Future<Map<String, dynamic>> summary() async {
    final data = await _api.get(ApiEndpoints.referral);
    return Map<String, dynamic>.from(data as Map);
  }

  Future<Map<String, dynamic>> apply(String code) async {
    final data = await _api.post(
      ApiEndpoints.referralApply,
      data: {'referral_code': code},
    );
    if (data is Map) return Map<String, dynamic>.from(data);
    return {};
  }

  Future<Map<String, dynamic>> wallet() async {
    final data = await _api.get(ApiEndpoints.referralTransactions);
    return Map<String, dynamic>.from(data as Map);
  }

  Future<List<Map<String, dynamic>>> rewards() async {
    final data = await _api.get(ApiEndpoints.referralRewards);
    final list = data is Map ? data['data'] : data;
    final items = <Map<String, dynamic>>[];
    if (list is List) {
      for (final item in list) {
        if (item is Map) items.add(Map<String, dynamic>.from(item));
      }
    }
    return items;
  }
}

class NotificationApi {
  NotificationApi(this._api);

  final ApiClient _api;

  Future<List<Map<String, dynamic>>> list() async {
    final data = await _api.get(ApiEndpoints.notifications);
    final list = data is Map ? data['data'] : data;
    final items = <Map<String, dynamic>>[];
    if (list is List) {
      for (final item in list) {
        if (item is Map) items.add(Map<String, dynamic>.from(item));
      }
    }
    return items;
  }

  Future<void> markRead(int id) async {
    await _api.post(ApiEndpoints.notificationRead(id));
  }

  Future<void> markAllRead() async {
    await _api.post(ApiEndpoints.notificationsReadAll);
  }
}

class VehicleApi {
  VehicleApi(this._api);

  final ApiClient _api;

  Future<List<Map<String, dynamic>>> list() async {
    // The endpoint is /api/v1/vehicles
    final data = await _api.get('/vehicles');
    final list = data is Map ? data['data'] : data;
    final items = <Map<String, dynamic>>[];
    if (list is List) {
      for (final item in list) {
        if (item is Map) items.add(Map<String, dynamic>.from(item));
      }
    }
    return items;
  }
}

class MarketplaceApi {
  MarketplaceApi(this._api);

  final ApiClient _api;
  MarketplaceConfig? _cachedConfig;

  Future<MarketplaceConfig> config({bool force = false}) async {
    if (!force && _cachedConfig != null) return _cachedConfig!;
    final data = await _api.get(ApiEndpoints.marketplaceConfig);
    final config = MarketplaceConfig.fromJson(
      Map<String, dynamic>.from(data as Map),
    );
    _cachedConfig = config;
    return config;
  }

  Future<MarketplacePage<MarketplacePost>> posts({
    String? type,
    bool mine = false,
    String? search,
    String? category,
    String? city,
    int page = 1,
    int perPage = 20,
  }) async {
    final data = await _api.get(
      ApiEndpoints.marketplacePosts,
      query: {
        if (type != null && type.isNotEmpty) 'type': type,
        if (mine) 'mine': 1,
        if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
        if (category != null && category.isNotEmpty) 'category': category,
        if (city != null && city.trim().isNotEmpty) 'city': city.trim(),
        'page': page,
        'per_page': perPage,
      },
    );
    return _parsePostPage(data);
  }

  Future<MarketplacePost> show(int id) async {
    final data = await _api.get(ApiEndpoints.marketplacePost(id));
    return MarketplacePost.fromJson(Map<String, dynamic>.from(data as Map));
  }

  Future<MarketplacePost> create({
    required String type,
    required String title,
    String? description,
    double? price,
    String? condition,
    String? category,
    String? city,
    String? area,
    String? pincode,
    List<String> imagePaths = const [],
  }) async {
    final form = await _postForm(
      type: type,
      title: title,
      description: description,
      price: price,
      condition: condition,
      category: category,
      city: city,
      area: area,
      pincode: pincode,
      imagePaths: imagePaths,
    );
    final data = await _api.postMultipart(ApiEndpoints.marketplacePosts, form);
    return MarketplacePost.fromJson(Map<String, dynamic>.from(data as Map));
  }

  Future<MarketplacePost> update(
    int id, {
    required String title,
    String? description,
    double? price,
    String? condition,
    String? category,
    String? city,
    String? area,
    String? pincode,
    List<String> imagePaths = const [],
  }) async {
    final form = await _postForm(
      title: title,
      description: description,
      price: price,
      condition: condition,
      category: category,
      city: city,
      area: area,
      pincode: pincode,
      imagePaths: imagePaths,
    );
    final data = await _api.postMultipart(
      ApiEndpoints.marketplacePost(id),
      form,
    );
    return MarketplacePost.fromJson(Map<String, dynamic>.from(data as Map));
  }

  Future<MarketplacePost> updateStatus(int id, String status) async {
    final data = await _api.post(
      ApiEndpoints.marketplacePostStatus(id),
      data: {'status': status},
    );
    return MarketplacePost.fromJson(Map<String, dynamic>.from(data as Map));
  }

  Future<void> deleteImage(int postId, int imageId) async {
    await _api.delete(ApiEndpoints.marketplacePostImage(postId, imageId));
  }

  Future<MarketplaceChat> startChat(int postId) async {
    final data = await _api.post(ApiEndpoints.marketplacePostChats(postId));
    return MarketplaceChat.fromJson(Map<String, dynamic>.from(data as Map));
  }

  Future<MarketplacePage<MarketplaceChat>> chats({
    int page = 1,
    int perPage = 20,
  }) async {
    final data = await _api.get(
      ApiEndpoints.marketplaceChats,
      query: {'page': page, 'per_page': perPage},
    );
    final map = Map<String, dynamic>.from(data as Map);
    final rows = <MarketplaceChat>[];
    final list = map['data'];
    if (list is List) {
      for (final item in list) {
        if (item is Map) {
          rows.add(MarketplaceChat.fromJson(Map<String, dynamic>.from(item)));
        }
      }
    }
    final meta = map['meta'] is Map
        ? Map<String, dynamic>.from(map['meta'] as Map)
        : <String, dynamic>{};
    return MarketplacePage<MarketplaceChat>(
      items: rows,
      currentPage: (meta['current_page'] as num?)?.toInt() ?? page,
      lastPage: (meta['last_page'] as num?)?.toInt() ?? 1,
      perPage: (meta['per_page'] as num?)?.toInt() ?? perPage,
      total: (meta['total'] as num?)?.toInt() ?? rows.length,
      unreadChats: (meta['unread_chats'] as num?)?.toInt() ?? 0,
    );
  }

  Future<({MarketplaceChat chat, List<MarketplaceMessage> messages, int unread})>
  chatThread(int chatId, {int? afterId}) async {
    final data = await _api.get(
      ApiEndpoints.marketplaceChat(chatId),
      query: {if (afterId != null) 'after_id': afterId},
    );
    final map = Map<String, dynamic>.from(data as Map);
    final chat = MarketplaceChat.fromJson(
      Map<String, dynamic>.from((map['chat'] as Map?) ?? map),
    );
    final messages = <MarketplaceMessage>[];
    if (map['messages'] is List) {
      for (final item in map['messages'] as List) {
        if (item is Map) {
          messages.add(
            MarketplaceMessage.fromJson(Map<String, dynamic>.from(item)),
          );
        }
      }
    }
    return (
      chat: chat,
      messages: messages,
      unread: (map['unread_count'] as num?)?.toInt() ?? 0,
    );
  }

  Future<MarketplaceMessage> sendMessage(int chatId, String message) async {
    final data = await _api.post(
      ApiEndpoints.marketplaceChatMessages(chatId),
      data: {'message': message},
    );
    if (data is Map) {
      return MarketplaceMessage.fromJson(Map<String, dynamic>.from(data));
    }
    return MarketplaceMessage(
      id: 0,
      body: message,
      senderId: 0,
      isMine: true,
    );
  }

  Future<void> markRead(int chatId) async {
    await _api.post(ApiEndpoints.marketplaceChatRead(chatId));
  }

  Future<void> closeChat(int chatId) async {
    await _api.post(ApiEndpoints.marketplaceChatClose(chatId));
  }

  Future<FormData> _postForm({
    String? type,
    required String title,
    String? description,
    double? price,
    String? condition,
    String? category,
    String? city,
    String? area,
    String? pincode,
    List<String> imagePaths = const [],
  }) async {
    final map = <String, dynamic>{
      if (type != null) 'type': type,
      'title': title,
      if (description != null) 'description': description,
      if (price != null) 'price': price,
      if (condition != null && condition.isNotEmpty) 'condition': condition,
      if (category != null && category.isNotEmpty) 'category': category,
      if (city != null && city.isNotEmpty) 'city': city,
      if (area != null && area.isNotEmpty) 'area': area,
      if (pincode != null && pincode.isNotEmpty) 'pincode': pincode,
    };
    final files = <MapEntry<String, MultipartFile>>[];
    for (var i = 0; i < imagePaths.length; i++) {
      final path = imagePaths[i];
      final name = path.split(RegExp(r'[\\/]')).last;
      files.add(
        MapEntry(
          'images[]',
          await MultipartFile.fromFile(path, filename: name),
        ),
      );
    }
    final form = FormData.fromMap(map);
    form.files.addAll(files);
    return form;
  }

  MarketplacePage<MarketplacePost> _parsePostPage(dynamic data) {
    final map = data is Map
        ? Map<String, dynamic>.from(data)
        : <String, dynamic>{};
    final rows = <MarketplacePost>[];
    final list = map['data'] ?? (data is List ? data : null);
    if (list is List) {
      for (final item in list) {
        if (item is Map) {
          rows.add(MarketplacePost.fromJson(Map<String, dynamic>.from(item)));
        }
      }
    }
    final meta = map['meta'] is Map
        ? Map<String, dynamic>.from(map['meta'] as Map)
        : <String, dynamic>{};
    return MarketplacePage<MarketplacePost>(
      items: rows,
      currentPage: (meta['current_page'] as num?)?.toInt() ?? 1,
      lastPage: (meta['last_page'] as num?)?.toInt() ?? 1,
      perPage: (meta['per_page'] as num?)?.toInt() ?? 20,
      total: (meta['total'] as num?)?.toInt() ?? rows.length,
    );
  }
}

class ServiceRequestApi {
  ServiceRequestApi(this._api);

  final ApiClient _api;

  Future<ServiceRequestItem> create({
    required String title,
    String? description,
    int? serviceModuleId,
    String? city,
    String? area,
    String? pincode,
  }) async {
    final data = await _api.post(
      ApiEndpoints.serviceRequests,
      data: {
        'title': title,
        if (description != null && description.trim().isNotEmpty)
          'description': description.trim(),
        if (serviceModuleId != null) 'service_module_id': serviceModuleId,
        if (city != null && city.trim().isNotEmpty) 'city': city.trim(),
        if (area != null && area.trim().isNotEmpty) 'area': area.trim(),
        if (pincode != null && pincode.trim().isNotEmpty)
          'pincode': pincode.trim(),
      },
    );
    return ServiceRequestItem.fromJson(Map<String, dynamic>.from(data as Map));
  }

  Future<({List<ServiceRequestItem> items, int currentPage, int lastPage, int total})>
  list({int page = 1}) async {
    final data = await _api.get(
      ApiEndpoints.serviceRequests,
      query: {'page': page},
    );
    final map = data is Map
        ? Map<String, dynamic>.from(data)
        : <String, dynamic>{};
    final rows = <ServiceRequestItem>[];
    final list = map['data'] ?? (data is List ? data : null);
    if (list is List) {
      for (final item in list) {
        if (item is Map) {
          rows.add(
            ServiceRequestItem.fromJson(Map<String, dynamic>.from(item)),
          );
        }
      }
    }
    final meta = map['meta'] is Map
        ? Map<String, dynamic>.from(map['meta'] as Map)
        : <String, dynamic>{};
    return (
      items: rows,
      currentPage: (meta['current_page'] as num?)?.toInt() ?? page,
      lastPage: (meta['last_page'] as num?)?.toInt() ?? 1,
      total: (meta['total'] as num?)?.toInt() ?? rows.length,
    );
  }

  Future<ServiceRequestItem> show(int id) async {
    final data = await _api.get(ApiEndpoints.serviceRequest(id));
    return ServiceRequestItem.fromJson(Map<String, dynamic>.from(data as Map));
  }
}
