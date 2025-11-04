import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Api {
  static late final Dio _dio;
  static String? _token;

  /// Khởi tạo Dio
  static Future<void> init() async {
    await dotenv.load(fileName: ".env");

    final baseUrl = dotenv.env['API_BASE_URL'] ?? '';
    _dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        // 🔧 Luôn yêu cầu JSON
        headers: {'Accept': 'application/json', 'Content-Type': 'application/json'},
        validateStatus: (code) => code != null && code < 500,
        responseType: ResponseType.json, // 🔥 Ép kiểu trả về JSON
      ),
    );

    // ============================
    // 🧩 Interceptor bắt JSON sai định dạng
    // ============================
    _dio.interceptors.add(InterceptorsWrapper(
      onResponse: (res, handler) {
        if (res.data is String) {
          try {
            res.data = jsonDecode(res.data);
          } catch (_) {
            // giữ nguyên nếu không phải JSON
          }
        }
        return handler.next(res);
      },
    ));

    // Log interceptor (giữ nguyên)
    _dio.interceptors.add(LogInterceptor(
      request: true,
      requestHeader: true,
      requestBody: true,
      responseHeader: false,
      responseBody: true,
      error: true,
    ));

    // Tự động chèn token nếu có
    await loadToken();
  }

  // =====================
  //  TOKEN MANAGEMENT
  // =====================
  static const _key = 'token';

  static Future<void> setToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, token);
    _token = token;
    _dio.options.headers['Authorization'] = 'Bearer $token';
  }

  static Future<void> loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_key);
    if (saved != null && saved.isNotEmpty) {
      _token = saved;
      _dio.options.headers['Authorization'] = 'Bearer $saved';
      print('🔐 Token đã được load từ SharedPreferences');
    } else {
      print('⚠️ Không tìm thấy token khi load');
    }
  }

  static Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
    _token = null;
    _dio.options.headers.remove('Authorization');
    print('🚪 Token đã bị xoá');
  }

  // =====================
  // 📡 BASIC REQUESTS
  // =====================
  static Future<Response> get(String path, {Map<String, dynamic>? query}) =>
      _dio.get(path, queryParameters: query);

  static Future<Response> post(String path, dynamic data) =>
      _dio.post(path, data: data);

  static Future<Response> put(String path, dynamic data) =>
      _dio.put(path, data: data);

  static Future<Response> delete(String path) =>
      _dio.delete(path);

  // =====================
  //  ERROR FORMATTER
  // =====================
  static String handleError(DioException e) {
    if (e.response != null) {
      return "Lỗi ${e.response?.statusCode}: ${e.response?.data}";
    } else {
      return "Không thể kết nối tới server. Vui lòng thử lại.";
    }
  }
}
