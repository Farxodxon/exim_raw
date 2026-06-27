import 'dart:convert';
import 'package:exim_raw/models/raw_material.dart';
import 'package:http/http.dart' as http;

class ApiService {
  // Render dagi backend URL
  static const String baseUrl = 'https://exim-raw-api.onrender.com';

  /// GET /api/raw-materials
  Future<List<dynamic>> getRawMaterials() async {
    final response = await http.get(Uri.parse('$baseUrl/api/raw-materials'));
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load raw materials: ${response.statusCode}');
    }
  }

  /// POST /api/raw-materials
  Future<Map<String, dynamic>> addRawMaterial(Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/raw-materials'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(data),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to add raw material: ${response.statusCode}');
    }
  }

  /// GET /health – test uchun
  Future<Map<String, dynamic>> healthCheck() async {
    final response = await http.get(Uri.parse('$baseUrl/health'));
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Health check failed');
    }
  }

  /// GET /api/raw-materials (RawMaterial list)
  Future<List<RawMaterial>> getRawMaterialsList() async {
    final response = await http.get(Uri.parse('$baseUrl/api/raw-materials'));
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((item) => RawMaterial.fromJson(item)).toList();
    } else {
      throw Exception('Failed to load raw materials: ${response.statusCode}');
    }
  }

  /// POST /api/orders/check - shtrix kodlarni tekshirish
  Future<Map<String, dynamic>> checkBarcodes(List<String> barcodes) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/orders/check'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'barcodes': barcodes}),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to check barcodes: ${response.statusCode}');
    }
  }
}