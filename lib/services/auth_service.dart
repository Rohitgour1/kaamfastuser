import 'package:kaamfast/common/api_endpoints.dart';
import 'package:kaamfast/common/app_constants.dart';
import 'package:kaamfast/core/network/api_client.dart';
import 'package:kaamfast/core/storage/token_storage.dart';
import 'package:kaamfast/models/user.dart';

class AuthService {
  AuthService(this._api, this._tokens);

  final ApiClient _api;
  final TokenStorage _tokens;

  Future<Map<String, dynamic>> sendOtp(
    String phone, {
    String countryCode = AppConstants.defaultCountryCode,
  }) async {
    final data = await _api.post(ApiEndpoints.sendOtp, data: {
      'phone': phone,
      'country_code': countryCode,
    });
    return Map<String, dynamic>.from(data as Map);
  }

  Future<UserModel> verifyOtp(
    String phone,
    String otp, {
    String countryCode = AppConstants.defaultCountryCode,
    String? referralCode,
  }) async {
    final data = await _api.post(ApiEndpoints.verifyOtp, data: {
      'phone': phone,
      'otp': otp,
      'country_code': countryCode,
      if (referralCode != null && referralCode.isNotEmpty) 'referral_code': referralCode,
      'terms_accepted': true,
      'terms_version': AppConstants.legalVersion,
    });
    final map = Map<String, dynamic>.from(data as Map);
    final token = map['token']?.toString();
    if (token == null || token.isEmpty) {
      throw Exception('Token missing from login response');
    }
    await _tokens.write(token);
    return UserModel.fromJson(Map<String, dynamic>.from(map['user'] as Map));
  }

  Future<UserModel> me() async {
    final data = await _api.get(ApiEndpoints.me);
    return UserModel.fromJson(Map<String, dynamic>.from(data as Map));
  }

  Future<void> logout() async {
    try {
      await _api.post(ApiEndpoints.logout);
    } catch (_) {
      // ignore network logout failures
    }
    await _tokens.clear();
  }

  Future<bool> hasToken() async {
    final token = await _tokens.read();
    return token != null && token.isNotEmpty;
  }
}
