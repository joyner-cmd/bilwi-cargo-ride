double? _d(dynamic v) => v == null ? null : double.tryParse('$v');

class Trip {
  Trip({
    required this.id,
    required this.status,
    required this.serviceName,
    required this.originLat,
    required this.originLng,
    required this.destLat,
    required this.destLng,
    this.originAddress,
    this.destAddress,
    this.distanceKm,
    this.durationMin,
    this.fareEstimated,
    this.fareFinal,
    this.paymentMethod = 'cash',
    this.clientName,
    this.clientPhone,
    this.clientRating,
    this.driverName,
    this.driverPhone,
    this.driverId,
    this.clientId,
    this.driverRating,
    this.vehicleType,
    this.vehiclePlate,
  });

  final int id;
  final String status;
  final String serviceName;
  final double originLat;
  final double originLng;
  final double destLat;
  final double destLng;
  final String? originAddress;
  final String? destAddress;
  final double? distanceKm;
  final double? durationMin;
  final double? fareEstimated;
  final double? fareFinal;
  final String paymentMethod;
  final String? clientName;
  final String? clientPhone;
  final double? clientRating;
  final String? driverName;
  final String? driverPhone;
  final int? driverId;
  final int? clientId;
  final double? driverRating;
  final String? vehicleType;
  final String? vehiclePlate;

  bool get isActive =>
      !['completed', 'cancelled'].contains(status);

  factory Trip.fromJson(Map<String, dynamic> j) => Trip(
        id: j['id'] as int,
        status: j['status'] as String,
        serviceName: (j['service_name'] ?? 'Servicio') as String,
        originLat: (j['origin_lat'] as num).toDouble(),
        originLng: (j['origin_lng'] as num).toDouble(),
        destLat: (j['dest_lat'] as num).toDouble(),
        destLng: (j['dest_lng'] as num).toDouble(),
        originAddress: j['origin_address'] as String?,
        destAddress: j['dest_address'] as String?,
        distanceKm: _d(j['distance_km']),
        durationMin: _d(j['duration_min']),
        fareEstimated: _d(j['fare_estimated']),
        fareFinal: _d(j['fare_final']),
        paymentMethod: (j['payment_method'] ?? 'cash') as String,
        clientName: j['client_name'] as String?,
        clientPhone: j['client_phone'] as String?,
        clientRating: _d(j['client_rating']),
        driverName: j['driver_name'] as String?,
        driverPhone: j['driver_phone'] as String?,
        driverId: j['driver_id'] as int?,
        clientId: j['client_id'] as int?,
        driverRating: _d(j['driver_rating']),
        vehicleType: j['vehicle_type'] as String?,
        vehiclePlate: j['vehicle_plate'] as String?,
      );

  static String statusLabel(String s) {
    switch (s) {
      case 'requested':
        return 'Buscando conductor';
      case 'accepted':
        return 'Conductor en camino';
      case 'arrived':
        return 'Conductor llego';
      case 'in_progress':
        return 'En viaje';
      case 'completed':
        return 'Completado';
      case 'cancelled':
        return 'Cancelado';
      default:
        return s;
    }
  }
}
