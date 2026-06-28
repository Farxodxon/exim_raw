import 'dart:convert';
import 'package:exim_raw/models/raw_material.dart';
import 'package:exim_raw/models/order.dart';
import 'package:exim_raw/models/product.dart';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = 'https://exim-raw-api.onrender.com';
  static const _timeout = Duration(seconds: 30);

  Map<String, String> get _headers => {'Content-Type': 'application/json'};

  // ─── RAW MATERIALS ───────────────────────────────────────────────────────────

  Future<List<RawMaterial>> getRawMaterialsList() async {
    final res = await http.get(Uri.parse('$baseUrl/api/raw-materials')).timeout(_timeout);
    if (res.statusCode == 200) {
      return (jsonDecode(res.body) as List).map((e) => RawMaterial.fromJson(e)).toList();
    }
    throw Exception('Xato: ${res.statusCode}');
  }

  // ─── PRODUCTS ────────────────────────────────────────────────────────────────

  Future<List<Product>> getProducts({String search = '', String category = ''}) async {
    final uri = Uri.parse('$baseUrl/api/products').replace(queryParameters: {
      if (search.isNotEmpty) 'search': search,
      if (category.isNotEmpty) 'category': category,
    });
    final res = await http.get(uri).timeout(_timeout);
    if (res.statusCode == 200) {
      return (jsonDecode(res.body) as List).map((e) => Product.fromJson(e)).toList();
    }
    throw Exception('Xato: ${res.statusCode}');
  }

  Future<List<String>> getCategories() async {
    final res = await http
        .get(Uri.parse('$baseUrl/api/products/categories'))
        .timeout(_timeout);
    if (res.statusCode == 200) {
      return List<String>.from(jsonDecode(res.body));
    }
    throw Exception('Xato: ${res.statusCode}');
  }

  Future<Product> createProduct(Map<String, dynamic> data) async {
    final res = await http.post(
      Uri.parse('$baseUrl/api/products'),
      headers: _headers,
      body: jsonEncode(data),
    ).timeout(_timeout);
    if (res.statusCode == 200) return Product.fromJson(jsonDecode(res.body));
    final err = jsonDecode(res.body)['error'] ?? 'Xato';
    throw Exception(err);
  }

  Future<Product> updateProduct(int id, Map<String, dynamic> data) async {
    final res = await http.put(
      Uri.parse('$baseUrl/api/products/$id'),
      headers: _headers,
      body: jsonEncode(data),
    ).timeout(_timeout);
    if (res.statusCode == 200) return Product.fromJson(jsonDecode(res.body));
    final err = jsonDecode(res.body)['error'] ?? 'Xato';
    throw Exception(err);
  }

  Future<void> deleteProduct(int id) async {
    final res = await http
        .delete(Uri.parse('$baseUrl/api/products/$id'))
        .timeout(_timeout);
    if (res.statusCode != 200) {
      final err = jsonDecode(res.body)['error'] ?? 'Xato';
      throw Exception(err);
    }
  }

  // ─── ORDERS ──────────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> checkBarcodes(List<String> barcodes) async {
    final res = await http.post(
      Uri.parse('$baseUrl/api/orders/check'),
      headers: _headers,
      body: jsonEncode({'barcodes': barcodes}),
    ).timeout(_timeout);
    if (res.statusCode == 200) return jsonDecode(res.body);
    throw Exception('Xato: ${res.statusCode}');
  }

  // ─── ORDERS ──────────────────────────────────────────────────────────────────

  Future<List<OrderModel>> getOrders() async {
    final res = await http.get(Uri.parse('$baseUrl/api/orders')).timeout(_timeout);
    if (res.statusCode == 200) {
      return (jsonDecode(res.body) as List).map((e) => OrderModel.fromJson(e)).toList();
    }
    throw Exception('Xato: ${res.statusCode}');
  }

  Future<OrderModel> createOrder(Map<String, dynamic> data) async {
    final res = await http.post(
      Uri.parse('$baseUrl/api/orders'),
      headers: _headers,
      body: jsonEncode(data),
    ).timeout(_timeout);
    if (res.statusCode == 200) return OrderModel.fromJson(jsonDecode(res.body));
    throw Exception(jsonDecode(res.body)['error'] ?? 'Xato');
  }

  Future<void> saveOrderItems(int orderId, List<Map<String, dynamic>> items) async {
    final res = await http.post(
      Uri.parse('$baseUrl/api/orders/$orderId/items'),
      headers: _headers,
      body: jsonEncode({'items': items}),
    ).timeout(_timeout);
    if (res.statusCode != 200) {
      throw Exception(jsonDecode(res.body)['error'] ?? 'Xato');
    }
  }

  Future<void> deleteOrder(int id) async {
    final res = await http.delete(Uri.parse('$baseUrl/api/orders/$id')).timeout(_timeout);
    if (res.statusCode != 200) throw Exception('Xato');
  }

}