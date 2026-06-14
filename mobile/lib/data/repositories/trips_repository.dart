import '../../core/network/api_client.dart';
import '../models/trip.dart';
import '../models/nearby_driver.dart';

class TripsRepository {
  TripsRepository(this._api);
  final ApiClient _api;

  Future<List<NearbyDriver>> nearby({
    required double lat,
    required double lng,
    String? vehicleType,
  }) async {
    final res = await _api.dio.get('/drivers/nearby', queryParameters: {
      'lat': lat,
      'lng': lng,
      if (vehicleType != null) 'vehicleType': vehicleType,
    });
    return (res.data['drivers'] as List)
        .map((e) => NearbyDriver.fromJson(e))
        .toList();
  }

  Future<Trip> request(Map<String, dynamic> body) async {
    final res = await _api.dio.post('/trips', data: body);
    return Trip.fromJson(res.data['trip']);
  }

  Future<Trip> detail(int id) async {
    final res = await _api.dio.get('/trips/$id');
    return Trip.fromJson(res.data);
  }

  Future<List<Trip>> list({String? status}) async {
    final res = await _api.dio.get('/trips',
        queryParameters: status != null ? {'status': status} : null);
    return (res.data['trips'] as List).map((e) => Trip.fromJson(e)).toList();
  }

  Future<Trip> _action(int id, String action) async {
    final res = await _api.dio.post('/trips/$id/$action');
    return Trip.fromJson(res.data);
  }

  Future<Trip> accept(int id) => _action(id, 'accept');
  Future<Trip> arrived(int id) => _action(id, 'arrived');
  Future<Trip> start(int id) => _action(id, 'start');
  Future<Trip> complete(int id) => _action(id, 'complete');

  Future<Trip> cancel(int id, {String? reason}) async {
    final res = await _api.dio.post('/trips/$id/cancel', data: {'reason': reason});
    return Trip.fromJson(res.data);
  }

  Future<void> rate(int tripId, int stars, {String? comment}) async {
    await _api.dio.post('/ratings', data: {
      'tripId': tripId,
      'stars': stars,
      if (comment != null && comment.isNotEmpty) 'comment': comment,
    });
  }

  Future<void> reportIncident({
    int? tripId,
    required String type,
    String? description,
    double? lat,
    double? lng,
  }) async {
    await _api.dio.post('/incidents', data: {
      if (tripId != null) 'tripId': tripId,
      'type': type,
      if (description != null) 'description': description,
      if (lat != null) 'lat': lat,
      if (lng != null) 'lng': lng,
    });
  }
}
