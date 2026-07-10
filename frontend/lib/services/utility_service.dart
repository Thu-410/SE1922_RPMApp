import '../core/network/api_client.dart';
import '../models/service_price.dart';
import '../models/utility_reading.dart';
import '../models/room_option.dart';

class UtilityService {
  UtilityService(this._api);
  final ApiClient _api;

  Future<List<UtilityReading>> getReadings({int page = 1, int limit = 50}) async {
    final response = await _api.get('/utility-readings', query: {'page': page, 'limit': limit});
    return (response['data'] as List<dynamic>)
        .map((item) => UtilityReading.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<ServicePrice> getCurrentPrice() async {
    final response = await _api.get('/service-prices/current');
    return ServicePrice.fromJson(response['data'] as Map<String, dynamic>);
  }

  Future<List<RoomOption>> getRoomOptions() async {
    final response = await _api.get('/utility-readings/room-options');
    return (response['data'] as List<dynamic>)
        .map((item) => RoomOption.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<UtilityReading> createReading(Map<String, dynamic> body) async {
    final response = await _api.post('/utility-readings', body: body);
    return UtilityReading.fromJson(response['data'] as Map<String, dynamic>);
  }

  Future<UtilityReading> updateReading(int id, Map<String, dynamic> body) async {
    final response = await _api.put('/utility-readings/$id', body: body);
    return UtilityReading.fromJson(response['data'] as Map<String, dynamic>);
  }

  Future<void> deleteReading(int id) async => _api.delete('/utility-readings/$id');

  Future<ServicePrice> updatePrice(int id, Map<String, dynamic> body) async {
    final response = await _api.put('/service-prices/$id', body: body);
    return ServicePrice.fromJson(response['data'] as Map<String, dynamic>);
  }
}
