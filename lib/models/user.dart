import 'package:kaamfast/common/app_constants.dart';

class UserModel {
  UserModel({
    required this.id,
    this.name,
    required this.phone,
    this.countryCode,
    this.email,
    this.status,
    this.referralCode,
    this.avatarUrl,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as int,
      name: json['name']?.toString(),
      phone: json['phone']?.toString() ?? '',
      countryCode: json['country_code']?.toString(),
      email: json['email']?.toString(),
      status: json['status']?.toString(),
      referralCode: json['referral_code']?.toString(),
      avatarUrl: json['avatar_url']?.toString(),
    );
  }

  final int id;
  final String? name;
  final String phone;
  final String? countryCode;
  final String? email;
  final String? status;
  final String? referralCode;
  final String? avatarUrl;

  bool get hasName => name != null && name!.trim().isNotEmpty;

  String get displayName => hasName ? name!.trim() : 'user';

  String get phoneLabel {
    final code = (countryCode != null && countryCode!.trim().isNotEmpty)
        ? countryCode!.trim()
        : AppConstants.defaultCountryCode;
    if (phone.trim().isEmpty) return code;
    return '$code $phone';
  }

  String? get photoUrl {
    final url = avatarUrl?.trim();
    if (url == null || url.isEmpty) return null;
    if (url.startsWith('http://') || url.startsWith('https://')) return url;
    final origin = Uri.parse(AppConstants.apiBaseUrl).origin;
    return url.startsWith('/') ? '$origin$url' : '$origin/$url';
  }
}
