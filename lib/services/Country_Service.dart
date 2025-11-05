import 'package:dio/dio.dart';
import '../config/api.dart';
import '../models/Country.dart';

class CountryService {
  static const String _endpoint = "/country";

  /// 🔹 Lấy toàn bộ quốc gia
  static Future<List<Country>> getAll() async {
    try {
      final response = await Api.get(_endpoint);
      final data = response.data is Map && response.data.containsKey('data')
          ? response.data['data']
          : response.data;
      return List<Country>.from((data as List).map((e) => Country.fromJson(e)));
    } catch (e) {
      throw Exception("Lỗi tải danh sách quốc gia: $e");
    }
  }

  /// 🔹 Lấy quốc gia theo ID
  static Future<Country?> getById(int id) async {
    try {
      final response = await Api.get("$_endpoint/$id");
      final data = response.data is Map && response.data.containsKey('data')
          ? response.data['data']
          : response.data;
      return Country.fromJson(data);
    } catch (e) {
      throw Exception("Lỗi tải quốc gia theo ID: $e");
    }
  }

  /// 🔹 Thêm quốc gia mới
  static Future<bool> create(Country country) async {
    try {
      final response = await Api.post(_endpoint, country.toJson());
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      throw Exception("Lỗi thêm quốc gia: $e");
    }
  }

  /// 🔹 Cập nhật quốc gia
  static Future<bool> update(int id, Country country) async {
    try {
      final response = await Api.put("$_endpoint/$id", country.toJson());
      return response.statusCode == 200;
    } catch (e) {
      throw Exception("Lỗi cập nhật quốc gia: $e");
    }
  }

  /// 🔹 Xóa quốc gia
  static Future<bool> delete(int id) async {
    try {
      final response = await Api.delete("$_endpoint/$id");
      return response.statusCode == 200;
    } catch (e) {
      throw Exception("Lỗi xóa quốc gia: $e");
    }
  }
}
