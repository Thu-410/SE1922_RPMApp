import '../core/network/api_client.dart';
import '../models/payment.dart';

class PaymentService {
  PaymentService(this._api);
  final ApiClient _api;

  Future<List<Payment>> getPayments({int page = 1, int limit = 50}) async {
    final response = await _api.get('/payments', query: {'page': page, 'limit': limit});
    return (response['data'] as List<dynamic>)
        .map((item) => Payment.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<Payment> confirmPayment(int invoiceId, Map<String, dynamic> body) async {
    final response = await _api.post('/invoices/$invoiceId/payments', body: body);
    return Payment.fromJson(response['data'] as Map<String, dynamic>);
  }
}
