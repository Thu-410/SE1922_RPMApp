import '../core/network/api_client.dart';
import '../models/maintenance_request.dart';

class MaintenanceService {
  const MaintenanceService(this._api);
  final ApiClient _api;
  Future<List<MaintenanceRequest>> list({String? status}) async {
    final response = await _api.get(
      '/maintenance-requests',
      query: status == null ? null : {'status': status},
    );
    return (response['data'] as List<dynamic>)
        .map(
          (item) => MaintenanceRequest.fromJson(item as Map<String, dynamic>),
        )
        .toList();
  }

  Future<MaintenanceRequest> getById(int id) async {
    final response = await _api.get('/maintenance-requests/$id');
    return MaintenanceRequest.fromJson(
      response['data'] as Map<String, dynamic>,
    );
  }

  Future<MaintenanceRequest> create({
    required String title,
    required String description,
    required String issueType,
    String? imageUrl,
  }) async {
    final response = await _api.post(
      '/maintenance-requests',
      body: {
        'title': title,
        'description': description,
        'issue_type': issueType,
        if (imageUrl?.isNotEmpty == true) 'image_url': imageUrl,
      },
    );
    return MaintenanceRequest.fromJson(
      response['data'] as Map<String, dynamic>,
    );
  }

  Future<MaintenanceRequest> updateStatus(
    int id,
    String status,
    String note,
  ) async {
    final response = await _api.put(
      '/maintenance-requests/$id/status',
      body: {'status': status, 'manager_note': note},
    );
    return MaintenanceRequest.fromJson(
      response['data'] as Map<String, dynamic>,
    );
  }
}
