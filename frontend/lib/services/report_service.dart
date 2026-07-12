import '../core/constants/api_constants.dart';
import '../core/network/api_client.dart';
import '../models/report_model.dart';

class ReportService {
  final ApiClient _apiClient;

  ReportService({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  Future<Map<String, dynamic>> getRevenueReport({
    int? month,
    int? year,
  }) async {
    final params = <String>[];

    if (month != null) params.add('month=$month');
    if (year != null) params.add('year=$year');

    final query = params.isEmpty ? '' : '?${params.join('&')}';

    final response = await _apiClient.get(
      '${ApiConstants.reports}/revenue$query',
    );

    final data = response['data'] ?? {};
    final List rows = data['rows'] ?? data['by_month'] ?? [];

    return {
      'total_revenue': data['total_revenue'] ??
          data['summary']?['paid_revenue'] ??
          0,
      'rows': rows
          .map((e) => MonthlyRevenueModel.fromJson(e))
          .toList(),
    };
  }

  Future<Map<String, dynamic>> getDebtReport({
    int? limit,
  }) async {
    final query = limit == null ? '' : '?limit=$limit';

    final response = await _apiClient.get(
      '${ApiConstants.reports}/debts$query',
    );

    final data = response['data'] ?? {};
    final List rows = data['rows'] ?? data['top_debts'] ?? [];

    final summary = Map<String, dynamic>.from(data['summary'] ?? {});

    if (!summary.containsKey('total_debt_amount') &&
        summary.containsKey('total_debt')) {
      summary['total_debt_amount'] = summary['total_debt'];
    }

    return {
      'summary': summary,
      'rows': rows
          .map((e) => DebtModel.fromJson(e))
          .toList(),
    };
  }

  Future<Map<String, dynamic>> getOccupancyReport() async {
    final response = await _apiClient.get(
      '${ApiConstants.reports}/occupancy',
    );

    final data = response['data'] ?? {};
    final List rooms = data['rooms'] ?? [];

    return {
      'summary': data['summary'] ?? {},
      'rooms': rooms
          .map((e) => OccupancyRoomModel.fromJson(e))
          .toList(),
    };
  }
}