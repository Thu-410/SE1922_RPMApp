import '../core/constants/api_constants.dart';
import '../core/network/api_client.dart';
import '../models/maintenance_model.dart';

class MaintenanceService {
  final ApiClient _apiClient;

  MaintenanceService({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  Future<List<MaintenanceRequestModel>> getMaintenanceRequests({
    String? status,
    String? keyword,
  }) async {
    final params = <String>[];

    if (status != null && status.isNotEmpty) {
      params.add('status=${Uri.encodeQueryComponent(status)}');
    }

    if (keyword != null && keyword.isNotEmpty) {
      params.add('keyword=${Uri.encodeQueryComponent(keyword)}');
    }

    final query = params.isEmpty ? '' : '?${params.join('&')}';

    final response = await _apiClient.get(
      '${ApiConstants.maintenanceRequests}$query',
    );

    final rawData = response['data'];

    final List data = rawData is Map<String, dynamic>
        ? (rawData['data'] ?? [])
        : (rawData ?? []);

    return data
        .map((e) => MaintenanceRequestModel.fromJson(e))
        .toList();
  }

  Future<MaintenanceRequestModel> getById(int id) async {
    final response = await _apiClient.get(
      '${ApiConstants.maintenanceRequests}/$id',
    );

    return MaintenanceRequestModel.fromJson(response['data']);
  }

  Future<MaintenanceRequestModel> create({
    required int roomId,
    required int tenantId,
    required String title,
    required String description,
    String? imageUrl,
  }) async {
    final response = await _apiClient.post(
      ApiConstants.maintenanceRequests,
      {
        'room_id': roomId,
        'tenant_id': tenantId,
        'title': title,
        'description': description,
        'image_url': imageUrl,
      },
    );

    return MaintenanceRequestModel.fromJson(response['data']);
  }

  Future<MaintenanceRequestModel> updateStatus({
    required int id,
    required String status,
    String? managerNote,
  }) async {
    final response = await _apiClient.put(
      '${ApiConstants.maintenanceRequests}/$id/status',
      {
        'status': status,
        'manager_note': managerNote,
      },
    );

    return MaintenanceRequestModel.fromJson(response['data']);
  }
}