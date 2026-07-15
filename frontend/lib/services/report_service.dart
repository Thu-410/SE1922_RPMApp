import '../core/network/api_client.dart';
import '../models/dashboard_summary.dart';

class ReportService {
  const ReportService(this._api);
  final ApiClient _api;
  Future<Map<String, dynamic>> revenue(int year) async =>
      (await _api.get('/reports/revenue', query: {'year': year}))['data']
          as Map<String, dynamic>;
  Future<Map<String, dynamic>> debts() async =>
      (await _api.get('/reports/debts'))['data'] as Map<String, dynamic>;
  Future<Map<String, dynamic>> occupancy() async =>
      (await _api.get('/reports/occupancy'))['data'] as Map<String, dynamic>;
  List<MonthlyRevenue> revenueRows(Map<String, dynamic> data) =>
      (data['rows'] as List<dynamic>)
          .map((item) => MonthlyRevenue.fromJson(item as Map<String, dynamic>))
          .toList();
  List<DebtItem> debtRows(Map<String, dynamic> data) =>
      (data['rows'] as List<dynamic>)
          .map((item) => DebtItem.fromJson(item as Map<String, dynamic>))
          .toList();
  List<OccupancyRoom> occupancyRooms(Map<String, dynamic> data) =>
      (data['rooms'] as List<dynamic>)
          .map((item) => OccupancyRoom.fromJson(item as Map<String, dynamic>))
          .toList();
}
