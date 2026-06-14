class NearbyDriver {
  NearbyDriver({
    required this.id,
    required this.fullName,
    required this.lat,
    required this.lng,
    required this.distanceKm,
    required this.vehicleType,
    this.ratingAvg = 0,
    this.brand,
    this.model,
    this.plate,
  });

  final int id;
  final String fullName;
  final double lat;
  final double lng;
  final double distanceKm;
  final String vehicleType;
  final double ratingAvg;
  final String? brand;
  final String? model;
  final String? plate;

  factory NearbyDriver.fromJson(Map<String, dynamic> j) => NearbyDriver(
        id: j['id'] as int,
        fullName: j['full_name'] as String,
        lat: (j['current_lat'] as num).toDouble(),
        lng: (j['current_lng'] as num).toDouble(),
        distanceKm: double.tryParse('${j['distance_km'] ?? 0}') ?? 0,
        vehicleType: (j['vehicle_type'] ?? '') as String,
        ratingAvg: double.tryParse('${j['rating_avg'] ?? 0}') ?? 0,
        brand: j['brand'] as String?,
        model: j['model'] as String?,
        plate: j['plate'] as String?,
      );
}
