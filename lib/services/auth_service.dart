import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../config/api.dart';

class AuthService {
  static final GoogleSignIn _googleSignIn = GoogleSignIn();

  // 🔹 Kiểm tra kết nối mạng
  static Future<bool> _checkConnection() async {
    final result = await Connectivity().checkConnectivity();
    return result != ConnectivityResult.none;
  }
  //  Đăng ký tài khoản
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
    } catch (e) {
      return {'error': 'Lỗi không xác định: $e'};
    }
  }

  // Đăng nhập bằng email & mật khẩu
  static Future<Map<String, dynamic>> login(String email, String password) async {
    if (!await _checkConnection()) return {'error': 'Không có kết nối mạng'};
    try {
      final res = await Api.post('auth/login', {
        'email': email.trim(),
        'password': password.trim(),
      });
      dynamic data = res.data;
      if (data is String) data = jsonDecode(data);
      if (data is! Map) return {'error': 'Phản hồi không hợp lệ từ máy chủ'};
      final mapData = Map<String, dynamic>.from(data);
      final token = mapData['token']?.toString() ?? '';
      if (token.isNotEmpty) await Api.setToken(token);
      return mapData;
    } on DioException catch (e) {
      return {'error': Api.handleError(e)};
    } catch (e) {
      return {'error': 'Lỗi không xác định: $e'};
    }
  }

  //  Đăng nhập bằng Google
  static Future<Map<String, dynamic>> signInWithGoogle() async {
    if (!await _checkConnection()) return {'error': 'Không có kết nối mạng'};
    try {
      final googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        return {'error': 'Người dùng đã hủy đăng nhập Google'};
      }
      //  Gửi thông tin người dùng đến backend
      final res = await Api.post('auth/google', {
        'email': googleUser.email,
        'name': googleUser.displayName ?? '',
        'avatar': googleUser.photoUrl ?? '',
      });
      dynamic data = res.data;
      if (data is String) data = jsonDecode(data);
      if (data is! Map) return {'error': 'Phản hồi không hợp lệ từ máy chủ'};
      final mapData = Map<String, dynamic>.from(data);
      //  Lưu token
      final token = mapData['token']?.toString() ?? '';
      if (token.isNotEmpty) await Api.setToken(token);
      final me = await getMe();
      if (me != null && me['user'] != null) {
        mapData['user'] = me['user'];
      }
      return mapData;
    } on DioException catch (e) {
      return {'error': Api.handleError(e)};
    } catch (e) {
      return {'error': 'Lỗi Google Sign-In: $e'};
    }
  }

  // Lấy thông tin người dùng qua token
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

  // Đăng xuất
  static Future<void> logout() async {
    try {
      await Api.clearToken();
      await _googleSignIn.signOut();
      await _googleSignIn.disconnect();

    } catch (e) {
      print(' Lỗi khi đăng xuất: $e');
    }
  }
}
