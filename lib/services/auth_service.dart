import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../config/api.dart';

class AuthService {
  static final GoogleSignIn _googleSignIn = GoogleSignIn();

  // 👉 Kiểm tra kết nối
  static Future<bool> _checkConnection() async {
    final result = await Connectivity().checkConnectivity();
    return result != ConnectivityResult.none;
  }

  // 👉 Đăng ký
  static Future<Map<String, dynamic>> register(String email, String password) async {
    if (!await _checkConnection()) return {'error': 'Không có kết nối mạng'};

    try {
      final res = await Api.post('auth/register', {
        'email': email.trim(),
        'password': password.trim(),
      });

      dynamic data = res.data;
      if (data is String) data = jsonDecode(data);
      if (data is Map) return Map<String, dynamic>.from(data);

      return {'error': 'Phản hồi không hợp lệ'};
    } on DioException catch (e) {
      return {'error': Api.handleError(e)};
    }
  }

  // 👉 Đăng nhập thường
  static Future<Map<String, dynamic>> login(String email, String password) async {
    if (!await _checkConnection()) return {'error': 'Không có kết nối mạng'};

    try {
      // ❗ Xóa token cũ trước khi login
      await Api.clearToken();

      final res = await Api.post('auth/login', {
        'email': email.trim(),
        'password': password.trim(),
      });

      dynamic data = res.data;
      if (data is String) data = jsonDecode(data);
      if (data is! Map) return {'error': 'Phản hồi không hợp lệ từ server'};

      // Lưu token
      final token = data['token']?.toString();
      if (token != null && token.isNotEmpty) {
        await Api.setToken(token);
      }

      return Map<String, dynamic>.from(data);
    } on DioException catch (e) {
      return {'error': Api.handleError(e)};
    }
  }

  //  Đăng nhập Google
  static Future<Map<String, dynamic>> signInWithGoogle() async {
    if (!await _checkConnection()) return {'error': 'Không có kết nối mạng'};

    try {
      await Api.clearToken();
      try {
        await _googleSignIn.signOut();
        await _googleSignIn.disconnect();
      } catch (_) {}

      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return {'error': 'Người dùng hủy đăng nhập Google'};

      final res = await Api.post('auth/google', {
        'email': googleUser.email,
        'name': googleUser.displayName ?? '',
        'avatar': googleUser.photoUrl ?? '',
      });

      dynamic data = res.data;
      if (data is String) data = jsonDecode(data);
      if (data is! Map) return {'error': 'Phản hồi không hợp lệ từ server'};

      // Lưu token
      final token = data['token']?.toString();
      if (token != null && token.isNotEmpty) {
        await Api.setToken(token);
      }

      return Map<String, dynamic>.from(data);
    } on DioException catch (e) {
      return {'error': Api.handleError(e)};
    }
  }


  //  Lấy user qua token
  static Future<Map<String, dynamic>?> getMe() async {
    try {
      final res = await Api.get('auth/me');
      dynamic data = res.data;

      if (data is String) data = jsonDecode(data);
      if (data is Map) return Map<String, dynamic>.from(data);

      return null;
    } on DioException {
      return null;
    }
  }

  //  Login tự động
  static Future<bool> tryAutoLogin() async {
    await Api.loadToken();
    final me = await getMe();
    return me != null && me['user'] != null;
  }

  //  Đăng xuất (xoá token + Google)
  static Future<void> logout() async {
    await Api.clearToken();

    try {
      final isSignedIn = await _googleSignIn.isSignedIn();
      if (isSignedIn) await _googleSignIn.signOut();
    } catch (e) {
      print(' Google signOut error: $e');
    }
  }
}
