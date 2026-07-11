import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/tenant_model.dart';

class TenantService {
  static const String baseUrl = 'http://localhost:3000/api/tenants';

  Future<List<Tenant>> getAllTenants() async {
    final response = await http.get(Uri.parse(baseUrl));

    if (response.statusCode == 200) {
      final body = jsonDecode(response.body);
      final List data = body['data'];
      return data.map((json) => Tenant.fromJson(json)).toList();
    } else {
      throw Exception('Khong lay duoc danh sach tenant (${response.statusCode})');
    }
  }

  Future<Tenant> getTenantById(int id) async {
    final response = await http.get(Uri.parse('$baseUrl/$id'));

    if (response.statusCode == 200) {
      final body = jsonDecode(response.body);
      return Tenant.fromJson(body['data']);
    } else {
      throw Exception('Khong tim thay tenant');
    }
  }

  Future<void> createTenant(Tenant tenant) async {
    final response = await http.post(
      Uri.parse(baseUrl),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(tenant.toJson()),
    );

    if (response.statusCode != 201) {
      final body = jsonDecode(response.body);
      throw Exception(body['message'] ?? 'Tao tenant that bai');
    }
  }

  Future<void> updateTenant(int id, Tenant tenant) async {
    final response = await http.put(
      Uri.parse('$baseUrl/$id'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(tenant.toJson()),
    );

    if (response.statusCode != 200) {
      final body = jsonDecode(response.body);
      throw Exception(body['message'] ?? 'Cap nhat tenant that bai');
    }
  }

  Future<void> deleteTenant(int id) async {
    final response = await http.delete(Uri.parse('$baseUrl/$id'));

    if (response.statusCode != 200) {
      throw Exception('Xoa tenant that bai');
    }
  }
}