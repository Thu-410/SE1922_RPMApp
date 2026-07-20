import '../core/network/api_client.dart';
import '../models/contract.dart';

class ContractService {
  const ContractService(this.apiClient);
  final ApiClient apiClient;
  Future<List<RentalContract>> list({String? status, int? tenantId}) async =>
      ((await apiClient.get(
                '/contracts',
                query: {
                  if (status != null && status.isNotEmpty) 'status': status,
                  if (tenantId != null) 'tenant_id': tenantId,
                },
              ))['data']
              as List)
          .map((e) => RentalContract.fromJson(e as Map<String, dynamic>))
          .toList();
  Future<RentalContract> detail(int id) async => RentalContract.fromJson(
    (await apiClient.get('/contracts/$id'))['data'] as Map<String, dynamic>,
  );
  Future<RentalContract> create(Map<String, dynamic> body) async =>
      RentalContract.fromJson(
        (await apiClient.post('/contracts', body: body))['data']
            as Map<String, dynamic>,
      );
  Future<RentalContract> extend(int id, String endDate) async =>
      RentalContract.fromJson(
        (await apiClient.put(
              '/contracts/$id/extend',
              body: {'new_end_date': endDate},
            ))['data']
            as Map<String, dynamic>,
      );

  Future<RentalContract> activate(int id) async => RentalContract.fromJson(
    (await apiClient.put('/contracts/$id/activate'))['data']
        as Map<String, dynamic>,
  );
  Future<RentalContract> terminate(int id) async => RentalContract.fromJson(
    (await apiClient.put('/contracts/$id/terminate'))['data']
        as Map<String, dynamic>,
  );
}
