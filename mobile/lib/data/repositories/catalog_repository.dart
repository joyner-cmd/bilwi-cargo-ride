import 'dart:convert';
import '../../core/network/api_client.dart';
import '../../core/storage/local_store.dart';
import '../models/service_type.dart';

class FareQuote {
  FareQuote({
    required this.distanceKm,
    required this.durationMin,
    required this.fareEstimated,
    required this.fareMin,
    required this.surge,
  });
  final double distanceKm;
  final int durationMin;
  final int fareEstimated;
  final double fareMin;
  final double surge;

  factory FareQuote.fromJson(Map<String, dynamic> j) => FareQuote(
        distanceKm: (j['distanceKm'] as num).toDouble(),
        durationMin: j['durationMin'] as int,
        fareEstimated: j['fareEstimated'] as int,
        fareMin: (j['fareMin'] as num).toDouble(),
        surge: (j['surge'] as num).toDouble(),
      );
}

class CatalogRepository {
  CatalogRepository(this._api, this._store);
  final ApiClient _api;
  final LocalStore _store;

  /// Lista de servicios. Usa cache local si no hay red (modo bajo consumo).
  Future<List<ServiceType>> services() async {
    try {
      final res = await _api.dio.get('/services');
      final list = (res.data['services'] as List)
          .map((e) => ServiceType.fromJson(e))
          .toList();
      await _store.setServicesCache(jsonEncode(res.data['services']));
      return list;
    } catch (e) {
      final cached = _store.servicesCache;
      if (cached != null) {
        return (jsonDecode(cached) as List)
            .map((e) => ServiceType.fromJson(e))
            .toList();
      }
      rethrow;
    }
  }

  Future<FareQuote> quote({
    required int serviceTypeId,
    required double originLat,
    required double originLng,
    required double destLat,
    required double destLng,
    String? cargoSize,
  }) async {
    final res = await _api.dio.post('/services/quote', data: {
      'serviceTypeId': serviceTypeId,
      'originLat': originLat,
      'originLng': originLng,
      'destLat': destLat,
      'destLng': destLng,
      if (cargoSize != null) 'cargoSize': cargoSize,
    });
    return FareQuote.fromJson(res.data);
  }
}
