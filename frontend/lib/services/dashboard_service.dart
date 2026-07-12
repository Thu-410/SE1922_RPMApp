import '../core/constants/api_constants.dart';
import '../core/network/api_client.dart';
import '../models/dashboard_summary_model.dart';
import '../models/maintenance_model.dart';
import '../models/report_model.dart';

class DashboardService {
  final ApiClient _apiClient;

  DashboardService({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  Future<DashboardSummaryModel> getSummary() async {
    final response = await _apiClient.get('${ApiConstants.dashboard}/summary');
    return DashboardSummaryModel.fromJson(response['data'] ?? {});
  }

  Future<List<MonthlyRevenueModel>> getRevenueOverview({int? year}) async {
    final query = year == null ? '' : '?year=$year';
    final response = await _apiClient.get(
      '${ApiConstants.dashboard}/revenue-overview$query',
    );

    final rawData = response['data'];

    final List data = rawData is Map<String, dynamic>
        ? (rawData['months'] ?? rawData['rows'] ?? [])
        : (rawData ?? []);

    return data
        .map((e) => MonthlyRevenueModel.fromJson(e))
        .toList();
  }

  Future<List<MaintenanceRequestModel>> getRecentMaintenance({
    int limit = 5,
  }) async {
    final response = await _apiClient.get(
      '${ApiConstants.dashboard}/recent-maintenance?limit=$limit',
    );

    final List data = response['data'] ?? [];

    return data
        .map((e) => MaintenanceRequestModel.fromJson(e))
        .toList();
  }
}