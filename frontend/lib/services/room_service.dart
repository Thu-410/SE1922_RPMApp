import 'dart:convert';
import 'dart:typed_data';

import '../core/network/api_client.dart';
import '../models/room.dart';

class RoomService {
  const RoomService(this.apiClient);
  final ApiClient apiClient;

  Future<List<Room>> list({String? status}) async {
    final response = await apiClient.get(
      '/rooms',
      query: {if (status != null && status.isNotEmpty) 'status': status},
    );
    return (response['data'] as List<dynamic>? ?? [])
        .map((item) => Room.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<Room> detail(int id) async => Room.fromJson(
    (await apiClient.get('/rooms/$id'))['data'] as Map<String, dynamic>,
  );

  Future<Room> create(Map<String, dynamic> body) async => Room.fromJson(
    (await apiClient.post('/rooms', body: body))['data']
        as Map<String, dynamic>,
  );

  Future<Room> update(int id, Map<String, dynamic> body) async => Room.fromJson(
    (await apiClient.put('/rooms/$id', body: body))['data']
        as Map<String, dynamic>,
  );

  Future<Room> updateStatus(int id, String status) async => Room.fromJson(
    (await apiClient.put('/rooms/$id/status', body: {'status': status}))['data']
        as Map<String, dynamic>,
  );

  Future<void> delete(int id) => apiClient.delete('/rooms/$id');

  Future<String> uploadImage(Uint8List bytes, String mimeType) async {
    final response = await apiClient.post(
      '/rooms/images',
      body: {'mime_type': mimeType, 'data': base64Encode(bytes)},
    );
    return (response['data'] as Map<String, dynamic>)['url'].toString();
  }
}
