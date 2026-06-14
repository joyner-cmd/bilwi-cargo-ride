class ServiceType {
  ServiceType({
    required this.id,
    required this.code,
    required this.name,
    required this.description,
    required this.vehicleType,
    required this.baseFare,
    required this.minFare,
    required this.allowsStops,
  });

  final int id;
  final String code;
  final String name;
  final String description;
  final String vehicleType;
  final double baseFare;
  final double minFare;
  final bool allowsStops;

  /// Imagen local asociada (assets/images/<code>.jpg).
  String get assetImage => 'assets/images/$code.jpg';

  factory ServiceType.fromJson(Map<String, dynamic> j) => ServiceType(
        id: j['id'] as int,
        code: j['code'] as String,
        name: j['name'] as String,
        description: (j['description'] ?? '') as String,
        vehicleType: j['vehicle_type'] as String,
        baseFare: double.tryParse('${j['base_fare']}') ?? 0,
        minFare: double.tryParse('${j['min_fare']}') ?? 0,
        allowsStops: j['allows_stops'] == true,
      );
}
