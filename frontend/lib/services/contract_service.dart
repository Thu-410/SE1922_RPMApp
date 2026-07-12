import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/contract_model.dart';

class ContractService {
  static const String baseUrl = 'http://localhost:3000/api/contracts';

  Future<List<Contract>> getAllContracts() async {
    final response = await http.get(Uri.parse(baseUrl));

    if (response.statusCode == 200) {
      final body = jsonDecode(response.body);
      final List data = body['data'];
      return data.map((json) => Contract.fromJson(json)).toList();
    } else {
      throw Exception('Khong lay duoc danh sach hop dong (${response.statusCode})');
    }
  }

  Future<Contract> getContractById(int id) async {
    final response = await http.get(Uri.parse('$baseUrl/$id'));

    if (response.statusCode == 200) {
      final body = jsonDecode(response.body);
      return Contract.fromJson(body['data']);
    } else {
      throw Exception('Khong tim thay hop dong');
    }
  }

  Future<void> createContract(Contract contract) async {
    final response = await http.post(
      Uri.parse(baseUrl),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(contract.toJson()),
    );

    if (response.statusCode != 201) {
      final body = jsonDecode(response.body);
      throw Exception(body['message'] ?? 'Tao hop dong that bai');
    }
  }

  Future<void> extendContract(int id, String newEndDate) async {
    final response = await http.put(
      Uri.parse('$baseUrl/$id/extend'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'end_date': newEndDate}),
    );

    if (response.statusCode != 200) {
      final body = jsonDecode(response.body);
      throw Exception(body['message'] ?? 'Gia han that bai');
    }
  }

  Future<void> terminateContract(int id) async {
    final response = await http.put(Uri.parse('$baseUrl/$id/terminate'));

    if (response.statusCode != 200) {
      final body = jsonDecode(response.body);
      throw Exception(body['message'] ?? 'Ket thuc hop dong that bai');
    }
  }
}