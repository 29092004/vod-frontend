import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import '../config/api.dart';

class AuthService {
  // Kiểm tra mạng trước khi gọi API
  static Future<bool> _checkConnection() async {
    final result = await Connectivity().checkConnectivity();
    return result != ConnectivityResult.none;
  }

  // Đăng ký tài khoản
  static Future<Map<String, dynamic>> register(
      String email, String password) async {
    if (!await _checkConnection()) {
      return {'error': 'Không có kết nối mạng'};
    }

    try {
      final res = await Api.post('auth/register', {
        'email': email.trim(),
        'password': password.trim(),
      });

      // Tránh lỗi kiểu dữ liệu (Dio trả String)
      final data = res.data is Map
          ? res.data
          : (res.data is String ? {'message': res.data} : {'error': 'Phản hồi không hợp lệ'});

      return data;
    } on DioException catch (e) {
      return {'error': Api.handleError(e)};
    } catch (e) {
      return {'error': 'Lỗi không xác định: $e'};
    }
  }

  //  Đăng nhập
  static Future<Map<String, dynamic>> login(
      String email, String password) async {
    if (!await _checkConnection()) {
      return {'error': 'Không có kết nối mạng'};
    }

    try {
      final res = await Api.post('auth/login', {
        'email': email.trim(),
        'password': password.trim(),
      });

      //  Ép kiểu
      final data = res.data is Map
          ? res.data
          : (res.data is String ? {'message': res.data} : {'error': 'Phản hồi không hợp lệ'});

      //  Nếu có token thì lưu lại
      if (data['token'] != null && data['token'].toString().isNotEmpty) {
        await Api.setToken(data['token']);
      }

      return data;
    } on DioException catch (e) {
      return {'error': Api.handleError(e)};
    } catch (e) {
      return {'error': 'Lỗi không xác định: $e'};
    }
  }

  // 👤 Lấy thông tin người dùng (qua token)
  static Future<Map<String, dynamic>?> getMe() async {
    try {
      final res = await Api.get('auth/me');
      return res.data is Map ? res.data : null;
    } on DioException catch (e) {
      print(' Lỗi getMe: ${Api.handleError(e)}');
      return null;
    }
  }

  // 🚪 Đăng xuất
  static Future<void> logout() async {
    await Api.clearToken();
  }
}
