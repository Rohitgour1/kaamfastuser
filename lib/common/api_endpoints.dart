/// All backend API paths in one place.
/// Paths are relative to [AppConstants.apiBaseUrl].
class ApiEndpoints {
  ApiEndpoints._();

  // ── Auth ─────────────────────────────────────────────────────────────
  static const String sendOtp = '/auth/send-otp';
  static const String verifyOtp = '/auth/verify-otp';
  static const String me = '/auth/me';
  static const String logout = '/auth/logout';

  // ── Home / Modules ───────────────────────────────────────────────────
  static const String home = '/home';
  static const String modules = '/modules';

  static String module(String slug) => '/modules/$slug';
  static String moduleServices(String slug) => '/modules/$slug/services';

  // ── Bookings / Payments ──────────────────────────────────────────────
  static const String bookings = '/bookings';
  static const String bookingQuote = '/bookings/quote';
  static const String coupons = '/coupons';
  static const String couponsValidate = '/coupons/validate';

  static String booking(int id) => '/bookings/$id';
  static String bookingConfirm(int id) => '/bookings/$id/confirm';
  static String bookingCancel(int id) => '/bookings/$id/cancel';
  static String bookingPay(int id) => '/bookings/$id/pay';
  static String bookingReviews(int id) => '/bookings/$id/reviews';
  static String bookingMedia(int id) => '/bookings/$id/media';
  static String bookingTracking(int id) => '/bookings/$id/tracking';
  static String bookingSearching(int id) => '/bookings/$id/searching';
  static String bookingChat(int id) => '/bookings/$id/chat';
  static String bookingChatMessages(int id) => '/bookings/$id/chat/messages';
  static const String cancelReasons = '/cancel-reasons';
  static String paymentConfirm(int paymentId) => '/payments/$paymentId/confirm';
  static const String paymentsConfig = '/payments/config';

  // ── Addresses ────────────────────────────────────────────────────────
  static const String addresses = '/addresses';
  static String address(int id) => '/addresses/$id';

  // ── Wallet ───────────────────────────────────────────────────────────
  static const String wallet = '/wallet';
  static const String walletTransactions = '/wallet/transactions';
  static const String walletTopup = '/wallet/topup';
  static const String walletWithdraw = '/wallet/withdraw';
  static const String walletBankAccount = '/wallet/bank-account';

  static String walletTopupConfirm(int id) => '/wallet/topup/$id/confirm';

  // ── Profile ──────────────────────────────────────────────────────────
  static const String profile = '/profile';
  static const String profileAvatar = '/profile/avatar';
  static const String deviceToken = '/device-token';

  // ── Notifications ────────────────────────────────────────────────────
  static const String notifications = '/notifications';
  static const String notificationsReadAll = '/notifications/read-all';

  static String notificationRead(int id) => '/notifications/$id/read';

  // ── Support ──────────────────────────────────────────────────────────
  static const String supportTickets = '/support/tickets';
  static String supportTicket(int id) => '/support/tickets/$id';
  static String supportTicketMessages(int id) =>
      '/support/tickets/$id/messages';
  static const String supportChat = '/support/chat';
  static const String supportChatMessages = '/support/chat/messages';
  static const String supportChatRead = '/support/chat/read';
  static const String supportConfig = '/support/config';

  // ── Maps ─────────────────────────────────────────────────────────────
  static const String mapsConfig = '/maps/config';

  // ── Referral ─────────────────────────────────────────────────────────
  static const String referral = '/referral';
  static const String referralApply = '/referral/apply';
  static const String referralRewards = '/referral/rewards';
  static const String referralTransactions = '/referral/transactions';

  // ── Marketplace ──────────────────────────────────────────────────────
  static const String marketplaceConfig = '/marketplace/config';
  static const String marketplacePosts = '/marketplace/posts';
  static const String marketplaceChats = '/marketplace/chats';

  static String marketplacePost(int id) => '/marketplace/posts/$id';
  static String marketplacePostStatus(int id) => '/marketplace/posts/$id/status';
  static String marketplacePostChats(int id) => '/marketplace/posts/$id/chats';
  static String marketplacePostImage(int id, int imageId) =>
      '/marketplace/posts/$id/images/$imageId';
  static String marketplaceChat(int id) => '/marketplace/chats/$id';
  static String marketplaceChatMessages(int id) =>
      '/marketplace/chats/$id/messages';
  static String marketplaceChatRead(int id) => '/marketplace/chats/$id/read';
  static String marketplaceChatClose(int id) => '/marketplace/chats/$id/close';

  // ── Service suggestions / requests ───────────────────────────────────
  static const String serviceRequests = '/service-requests';
  static String serviceRequest(int id) => '/service-requests/$id';
}
