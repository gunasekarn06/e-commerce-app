import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/product_model.dart';

class ApiService {
  static const String baseUrl = 'http://127.0.0.1:8000/api';

  // ============= USER APIs =============

  static Future<Map<String, dynamic>> loginUser({
    required String email,
    required String password,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/login/'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'email': email, 'password': password}),
          )
          .timeout(const Duration(seconds: 10));

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'data': data};
      } else {
        return {
          'success': false,
          'error': data['error'] ?? 'Login failed. Please try again.',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Network error. Please check your connection.',
      };
    }
  }

  static Future<Map<String, dynamic>> registerUser({
    required String fullName,
    required String email,
    required String password,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/users/create/'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'full_name': fullName,
              'email': email,
              'password': password,
            }),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 201) {
        return {'success': true, 'data': jsonDecode(response.body)};
      }
      return {'success': false};
    } catch (_) {
      return {'success': false};
    }
  }

  // ============= PRODUCT APIs =============

  static Future<List<Product>> getProducts({String? category}) async {
    try {
      String url = '$baseUrl/products/';
      if (category != null && category.isNotEmpty) url += '?category=$category';

      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => Product.fromJson(json)).toList();
      }
    } catch (_) {}
    return [];
  }

  static Future<List<Product>> getAllProductsAdmin() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/admin/products/'));
      if (response.statusCode == 200) {
        List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => Product.fromJson(json)).toList();
      }
    } catch (_) {}
    return [];
  }

  static Future<Product?> getProductDetail(int id) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/products/$id/'));
      if (response.statusCode == 200) {
        return Product.fromJson(jsonDecode(response.body));
      }
    } catch (_) {}
    return null;
  }

  static Future<bool> softDeleteProduct(int id) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/admin/products/soft-delete/$id/'),
      );
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> restoreProduct(int id) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/admin/products/restore/$id/'),
      );
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}
