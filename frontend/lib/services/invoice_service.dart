import '../core/network/api_client.dart';
import '../models/invoice.dart';

class InvoiceService {
  InvoiceService(this._api);
  final ApiClient _api;

  Future<List<Invoice>> getInvoices({int page = 1, int limit = 50}) async {
    final response = await _api.get(
      '/invoices',
      query: {'page': page, 'limit': limit},
    );
    return (response['data'] as List<dynamic>)
        .map((item) => Invoice.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<Invoice> getInvoice(int id) async {
    final response = await _api.get('/invoices/$id');
    return Invoice.fromJson(response['data'] as Map<String, dynamic>);
  }

  Future<Map<String, dynamic>> previewInvoice(Map<String, dynamic> body) async {
    final response = await _api.post('/invoices/preview', body: body);
    return response['data'] as Map<String, dynamic>;
  }

  Future<Invoice> createInvoice(Map<String, dynamic> body) async {
    final response = await _api.post('/invoices', body: body);
    return Invoice.fromJson(response['data'] as Map<String, dynamic>);
  }

  Future<Invoice> updateInvoice(int id, Map<String, dynamic> body) async {
    final response = await _api.put('/invoices/$id', body: body);
    return Invoice.fromJson(response['data'] as Map<String, dynamic>);
  }

  Future<Invoice> cancelInvoice(int id, String reason) async {
    final response = await _api.put(
      '/invoices/$id/cancel',
      body: {'reason': reason},
    );
    return Invoice.fromJson(response['data'] as Map<String, dynamic>);
  }

  Future<List<Invoice>> getMyInvoices() async {
    final response = await _api.get('/tenants/me/invoices');
    return (response['data'] as List<dynamic>)
        .map((item) => Invoice.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<Invoice> getMyInvoice(int id) async {
    final response = await _api.get('/tenants/me/invoices/$id');
    return Invoice.fromJson(response['data'] as Map<String, dynamic>);
  }
}
