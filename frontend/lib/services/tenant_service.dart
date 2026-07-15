import '../core/network/api_client.dart';
import '../models/tenant.dart';

class TenantService {
  const TenantService(this.apiClient);
  final ApiClient apiClient;
  Future<List<Tenant>> list({String? status}) async =>
      ((await apiClient.get(
                '/tenants',
                query: {
                  if (status != null && status.isNotEmpty) 'status': status,
                },
              ))['data']
              as List)
          .map((e) => Tenant.fromJson(e as Map<String, dynamic>))
          .toList();
  Future<Tenant> detail(int id) async => Tenant.fromJson(
    (await apiClient.get('/tenants/$id'))['data'] as Map<String, dynamic>,
  );
  Future<Tenant> create(Map<String, dynamic> body) async => Tenant.fromJson(
    (await apiClient.post('/tenants', body: body))['data']
        as Map<String, dynamic>,
  );
  Future<Tenant> update(int id, Map<String, dynamic> body) async =>
      Tenant.fromJson(
        (await apiClient.put('/tenants/$id', body: body))['data']
            as Map<String, dynamic>,
      );
  Future<void> remove(int id) => apiClient.delete('/tenants/$id');
}
