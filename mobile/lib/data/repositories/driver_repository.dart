import '../../core/network/api_client.dart';

class DriverRepository {
  DriverRepository(this._api);
  final ApiClient _api;

  Future<Map<String, dynamic>> me() async {
    final res = await _api.dio.get('/drivers/me');
    return Map<String, dynamic>.from(res.data ?? {});
  }

  Future<bool> setAvailability(bool available) async {
    final res = await _api.dio
        .patch('/drivers/me/availability', data: {'available': available});
    return res.data['is_available'] == true;
  }

  Future<void> updateLocation(double lat, double lng) async {
    await _api.dio.post('/drivers/me/location', data: {'lat': lat, 'lng': lng});
  }

  Future<List<Map<String, dynamic>>> myVehicles() async {
    final res = await _api.dio.get('/vehicles/me');
    return (res.data['vehicles'] as List).cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>> addVehicle(Map<String, dynamic> data) async {
    final res = await _api.dio.post('/vehicles', data: data);
    return Map<String, dynamic>.from(res.data);
  }

  Future<Map<String, dynamic>> updateVehicle(
      int id, Map<String, dynamic> data) async {
    final res = await _api.dio.patch('/vehicles/$id', data: data);
    return Map<String, dynamic>.from(res.data);
  }

  Future<void> deleteVehicle(int id) async {
    await _api.dio.delete('/vehicles/$id');
  }
}
