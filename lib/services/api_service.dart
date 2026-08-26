import 'dart:convert';
import 'package:exim_raw/models/raw_material.dart';
import 'package:exim_raw/models/order.dart';
import 'package:exim_raw/models/dalolatnoma.dart';
import 'package:exim_raw/models/partner.dart';
import 'package:exim_raw/models/product.dart';
import 'package:exim_raw/models/product_category.dart';
import 'package:exim_raw/models/tir_data.dart';
import 'package:exim_raw/models/invoice_data.dart';
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

  Future<List<Product>> getProducts({String search = '', int? categoryId, int? mainCategoryId}) async {
    final uri = Uri.parse('$baseUrl/api/products').replace(queryParameters: {
      if (search.isNotEmpty) 'search': search,
      if (categoryId != null) 'category_id': categoryId.toString(),
      if (mainCategoryId != null) 'main_category_id': mainCategoryId.toString(),
    });
    final res = await http.get(uri).timeout(_timeout);
    if (res.statusCode == 200) {
      return (jsonDecode(res.body) as List).map((e) => Product.fromJson(e)).toList();
    }
    throw Exception('Xato: ${res.statusCode}');
  }

  Future<List<ProductCategory>> getCategoryTree() async {
    final res = await http
        .get(Uri.parse('$baseUrl/api/products/categories'))
        .timeout(_timeout);
    if (res.statusCode == 200) {
      return (jsonDecode(res.body) as List)
          .map((e) => ProductCategory.fromJson(e as Map<String, dynamic>))
          .toList();
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


  Future<Map<String, dynamic>> getOrderDetail(int id) async {
    final res = await http.get(Uri.parse('$baseUrl/api/orders/$id')).timeout(_timeout);
    if (res.statusCode == 200) return jsonDecode(res.body);
    throw Exception('Xato: ${res.statusCode}');
  }

  Future<DalolatnomaData> getDalolatnomaData(int orderId) async {
    final res = await http.get(Uri.parse('$baseUrl/api/orders/$orderId/dalolatnoma-data')).timeout(_timeout);
    if (res.statusCode == 200) return DalolatnomaData.fromJson(jsonDecode(res.body));
    throw Exception(jsonDecode(res.body)['error'] ?? 'Xato: ${res.statusCode}');
  }

  Future<TirData> getTirData(int orderId) async {
    final res = await http
        .get(Uri.parse('$baseUrl/api/orders/$orderId/tir-data'))
        .timeout(_timeout);
    if (res.statusCode == 200) {
      return TirData.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
    }
    throw Exception('Xato: ${res.statusCode}');
  }

  Future<InvoiceData> getInvoiceData(int orderId) async {
    final res = await http
        .get(Uri.parse('$baseUrl/api/orders/$orderId/invoice-data'))
        .timeout(_timeout);
    if (res.statusCode == 200) {
      return InvoiceData.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
    }
    throw Exception('Xato: ${res.statusCode}');
  }

  // ─── PARTNERS ─────────────────────────────────────────────────────────────

  Future<List<PartnerModel>> getPartners() async {
    final res = await http.get(Uri.parse('$baseUrl/api/partners')).timeout(_timeout);
    if (res.statusCode == 200) {
      return (jsonDecode(res.body) as List).map((e) => PartnerModel.fromJson(e)).toList();
    }
    throw Exception('Xato: ${res.statusCode}');
  }

  Future<PartnerModel> createPartner(Map<String, dynamic> data) async {
    final res = await http.post(
      Uri.parse('$baseUrl/api/partners'),
      headers: _headers,
      body: jsonEncode(data),
    ).timeout(_timeout);
    if (res.statusCode == 200) return PartnerModel.fromJson(jsonDecode(res.body));
    throw Exception(jsonDecode(res.body)['error'] ?? 'Xato');
  }

  Future<PartnerModel> updatePartner(int id, Map<String, dynamic> data) async {
    final res = await http.put(
      Uri.parse('$baseUrl/api/partners/$id'),
      headers: _headers,
      body: jsonEncode(data),
    ).timeout(_timeout);
    if (res.statusCode == 200) return PartnerModel.fromJson(jsonDecode(res.body));
    throw Exception(jsonDecode(res.body)['error'] ?? 'Xato');
  }

  Future<void> deletePartner(int id) async {
    final res = await http.delete(Uri.parse('$baseUrl/api/partners/$id')).timeout(_timeout);
    if (res.statusCode != 200) throw Exception('Xato');
  }


  // ─── RAW MATERIALS CATALOG ───────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getRawMaterialsCatalog() async {
    final res = await http.get(Uri.parse('$baseUrl/api/raw-materials-catalog')).timeout(_timeout);
    if (res.statusCode == 200) return List<Map<String, dynamic>>.from(jsonDecode(res.body));
    throw Exception('Xato: ${res.statusCode}');
  }

  Future<Map<String, dynamic>> createRawMaterial(Map<String, dynamic> data) async {
    final res = await http.post(Uri.parse('$baseUrl/api/raw-materials-catalog'),
        headers: _headers, body: jsonEncode(data)).timeout(_timeout);
    if (res.statusCode == 200) return jsonDecode(res.body);
    throw Exception(jsonDecode(res.body)['error'] ?? 'Xato');
  }

  Future<void> deleteRawMaterial(int id) async {
    final res = await http.delete(Uri.parse('$baseUrl/api/raw-materials-catalog/$id')).timeout(_timeout);
    if (res.statusCode != 200) throw Exception('Xato');
  }

  // ─── MATERIAL INCOMES ────────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getMaterialIncomes({int? materialId}) async {
    final uri = Uri.parse('$baseUrl/api/material-incomes').replace(
        queryParameters: materialId != null ? {'material_id': materialId.toString()} : {});
    final res = await http.get(uri).timeout(_timeout);
    if (res.statusCode == 200) return List<Map<String, dynamic>>.from(jsonDecode(res.body));
    throw Exception('Xato: ${res.statusCode}');
  }

  Future<Map<String, dynamic>> createMaterialIncome(Map<String, dynamic> data) async {
    final res = await http.post(Uri.parse('$baseUrl/api/material-incomes'),
        headers: _headers, body: jsonEncode(data)).timeout(_timeout);
    if (res.statusCode == 200) return jsonDecode(res.body);
    throw Exception(jsonDecode(res.body)['error'] ?? 'Xato');
  }

  Future<void> deleteMaterialIncome(int id) async {
    final res = await http.delete(Uri.parse('$baseUrl/api/material-incomes/$id')).timeout(_timeout);
    if (res.statusCode != 200) throw Exception('Xato');
  }

  // ─── PRODUCT MATERIALS ───────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getProductMaterials(String barcode) async {
    final res = await http.get(Uri.parse('$baseUrl/api/product-materials/$barcode')).timeout(_timeout);
    if (res.statusCode == 200) return List<Map<String, dynamic>>.from(jsonDecode(res.body));
    throw Exception('Xato: ${res.statusCode}');
  }

  Future<List<Map<String, dynamic>>> getProductMaterialsByMaterial(int materialId) async {
    final res = await http.get(Uri.parse('$baseUrl/api/product-materials-by-material/$materialId')).timeout(_timeout);
    if (res.statusCode == 200) return List<Map<String, dynamic>>.from(jsonDecode(res.body));
    throw Exception('Xato: ${res.statusCode}');
  }

  Future<Map<String, dynamic>> getOrderExpenseReport(int orderId) async {
    final res = await http.get(Uri.parse('$baseUrl/api/orders/$orderId/expense-report')).timeout(_timeout);
    if (res.statusCode == 200) return jsonDecode(res.body);
    throw Exception('Xato: ${res.statusCode}');
  }

  Future<Map<String, dynamic>> calculateOrderExpensesWithDate(int orderId, {String? expenseDate}) async {
    final res = await http.post(
      Uri.parse('$baseUrl/api/orders/$orderId/calculate-expenses'),
      headers: _headers,
      body: jsonEncode(expenseDate != null ? {'expense_date': expenseDate} : {}),
    ).timeout(_timeout);
    if (res.statusCode == 200) return jsonDecode(res.body);
    throw Exception(jsonDecode(res.body)['error'] ?? 'Xato');
  }

  Future<Map<String, dynamic>> createProductMaterial(Map<String, dynamic> data) async {
    final res = await http.post(Uri.parse('$baseUrl/api/product-materials'),
        headers: _headers, body: jsonEncode(data)).timeout(_timeout);
    if (res.statusCode == 200) return jsonDecode(res.body);
    throw Exception(jsonDecode(res.body)['error'] ?? 'Xato');
  }

  Future<void> deleteProductMaterial(int id) async {
    final res = await http.delete(Uri.parse('$baseUrl/api/product-materials/$id')).timeout(_timeout);
    if (res.statusCode != 200) throw Exception('Xato');
  }

  // ─── EXPENSES ────────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> calculateOrderExpenses(int orderId) async {
    final res = await http.post(Uri.parse('$baseUrl/api/orders/$orderId/calculate-expenses'),
        headers: _headers).timeout(_timeout);
    if (res.statusCode == 200) return jsonDecode(res.body);
    throw Exception(jsonDecode(res.body)['error'] ?? 'Xato');
  }

  Future<List<Map<String, dynamic>>> getMaterialExpenses({int? materialId}) async {
    final uri = Uri.parse('$baseUrl/api/material-expenses').replace(
        queryParameters: materialId != null ? {'material_id': materialId.toString()} : {});
    final res = await http.get(uri).timeout(_timeout);
    if (res.statusCode == 200) return List<Map<String, dynamic>>.from(jsonDecode(res.body));
    throw Exception('Xato: ${res.statusCode}');
  }

}