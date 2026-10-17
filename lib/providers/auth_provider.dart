import 'package:flutter/foundation.dart';
import 'package:kaamfast/models/user.dart';
import 'package:kaamfast/services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  AuthProvider(this._auth);

  final AuthService _auth;

  UserModel? user;
  bool loading = true;
  bool bootstrapped = false;
  String? error;

  bool get isLoggedIn => user != null;

  bool get needsProfile => user != null && !user!.hasName;

  Future<void> bootstrap() async {
    loading = true;
    notifyListeners();
    try {
      if (await _auth.hasToken()) {
        user = await _auth.me();
      }
    } catch (_) {
      await _auth.logout();
      user = null;
    } finally {
      loading = false;
      bootstrapped = true;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>> sendOtp(String phone) async {
    error = null;
    notifyListeners();
    try {
      return await _auth.sendOtp(phone);
    } catch (e) {
      error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> verifyOtp(
    String phone,
    String otp, {
    String? referralCode,
  }) async {
    error = null;
    notifyListeners();
    try {
      user = await _auth.verifyOtp(phone, otp, referralCode: referralCode);
      notifyListeners();
    } catch (e) {
      error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> logout() async {
    await _auth.logout();
    user = null;
    notifyListeners();
  }

  void updateUser(UserModel next) {
    user = next;
    notifyListeners();
  }
}
