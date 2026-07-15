import '../core/network/api_client.dart';
import '../models/dashboard_summary.dart';
import '../models/maintenance_request.dart';

class DashboardService {
  const DashboardService(this._api);
  final ApiClient _api;
  Future<DashboardSummary> summary() async => DashboardSummary.fromJson(
    (await _api.get('/dashboard/summary'))['data'] as Map<String, dynamic>,
  );
  Future<List<MonthlyRevenue>> revenueOverview({int? year}) async =>
      ((await _api.get(
                '/dashboard/revenue-overview',
                query: year == null ? null : {'year': year},
              ))['data']
              as List<dynamic>)
          .map((item) => MonthlyRevenue.fromJson(item as Map<String, dynamic>))
          .toList();
  Future<List<MaintenanceRequest>> recentMaintenance() async =>
      ((await _api.get('/dashboard/recent-maintenance'))['data']
              as List<dynamic>)
          .map(
            (item) => MaintenanceRequest.fromJson(item as Map<String, dynamic>),
          )
          .toList();
}
