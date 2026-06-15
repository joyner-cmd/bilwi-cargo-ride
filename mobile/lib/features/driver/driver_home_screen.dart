import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../../core/config/app_config.dart';
import '../../core/di/services.dart';
import '../../core/network/api_client.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/format.dart';
import '../../core/utils/location.dart';
import '../../data/models/trip.dart';
import '../../state/auth_provider.dart';
import '../common/stat_tile.dart';
import '../history/history_screen.dart';
import '../profile/profile_screen.dart';
import '../trip/trip_tracking_screen.dart';
import 'my_vehicles_screen.dart';

class DriverHomeScreen extends StatefulWidget {
  const DriverHomeScreen({super.key});

  @override
  State<DriverHomeScreen> createState() => _DriverHomeScreenState();
}

class _DriverHomeScreenState extends State<DriverHomeScreen> {
  late final Services _s;
  final _map = MapController();
  LatLng _center = const LatLng(AppConfig.bilwiLat, AppConfig.bilwiLng);

  bool _available = false;
  int _todayTrips = 0;
  num _todayEarnings = 0;
  double _rating = 0;
  final List<_IncomingRequest> _incoming = [];
  Trip? _activeTrip;

  StreamSubscription<Position>? _gpsSub;

  @override
  void initState() {
    super.initState();
    _s = context.read<Services>();
    _init();
  }

  Future<void> _init() async {
    final gps = await LocationHelper.current();
    if (gps != null) {
      _center = gps;
      _map.move(gps, 14.5);
    }
    try {
      final me = await _s.driver.me();
      _available = me['is_available'] == true;
      if (_available) _startTracking();
    } catch (_) {}

    _loadActiveAndStats();

    _s.socket.on('trip:new', (data) {
      if (data is Map && data['tripId'] != null) {
        final r = _IncomingRequest(
          tripId: (data['tripId'] as num).toInt(),
          service: '${data['service']}',
          fare: (data['fareEstimated'] as num?)?.toInt() ?? 0,
          distanceKm: (data['distanceKm'] as num?)?.toDouble() ?? 0,
          origin: '${data['origin'] ?? ''}',
          dest: '${data['dest'] ?? ''}',
        );
        if (!_incoming.any((x) => x.tripId == r.tripId)) {
          setState(() => _incoming.add(r));
        }
      }
    });

    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _gpsSub?.cancel();
    _s.socket.off('trip:new');
    super.dispose();
  }

  Future<void> _loadActiveAndStats() async {
    try {
      // Capturamos el rating actual antes del await (evita context post-await).
      _rating = context.read<AuthProvider>().user?.ratingAvg ?? 0;
      final trips = await _s.trips.list();

      _activeTrip = trips.firstWhere(
        (t) => t.isActive,
        orElse: () => Trip(
          id: -1, status: 'none', serviceName: '', originLat: 0, originLng: 0,
          destLat: 0, destLng: 0,
        ),
      );
      if (_activeTrip!.id == -1) _activeTrip = null;

      var trips_ = 0;
      num earn = 0;
      for (final t in trips) {
        if (t.status == 'completed') {
          trips_++;
          earn += t.fareFinal ?? t.fareEstimated ?? 0;
        }
      }
      _todayTrips = trips_;
      _todayEarnings = earn;
      if (mounted) setState(() {});
    } catch (_) {}
  }

  Future<void> _toggle(bool v) async {
    try {
      final r = await _s.driver.setAvailability(v);
      setState(() => _available = r);
      if (r) {
        _startTracking();
      } else {
        _gpsSub?.cancel();
        _gpsSub = null;
      }
    } catch (e) {
      _snack(ApiClient.messageFrom(e));
    }
  }

  void _startTracking() {
    _gpsSub?.cancel();
    _gpsSub = LocationHelper.stream().listen((pos) {
      _center = LatLng(pos.latitude, pos.longitude);
      _s.socket.sendLocation(
        pos.latitude,
        pos.longitude,
        tripId: _activeTrip?.id,
      );
    });
  }

  Future<void> _accept(_IncomingRequest r) async {
    try {
      final t = await _s.trips.accept(r.tripId);
      setState(() {
        _incoming.removeWhere((x) => x.tripId == r.tripId);
        _activeTrip = t;
      });
      if (!mounted) return;
      Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => TripTrackingScreen(tripId: t.id)));
      _loadActiveAndStats();
    } catch (e) {
      _snack(ApiClient.messageFrom(e));
    }
  }

  void _snack(String m) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(m), backgroundColor: AppColors.alerta));
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final firstName = (user?.fullName ?? '').split(' ').first;
    return Scaffold(
      backgroundColor: AppColors.arena,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _header(firstName),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                children: [
                  _availabilityCard(),
                  const SizedBox(height: 14),
                  _statsRow(),
                  const SizedBox(height: 14),
                  _mapPreview(),
                  const SizedBox(height: 14),
                  if (_activeTrip != null) _activeTripBanner(),
                  if (_activeTrip != null) const SizedBox(height: 14),
                  _requestsSection(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _header(String name) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              gradient: AppColors.gradienteMarca,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(
              name.isNotEmpty ? name[0].toUpperCase() : 'C',
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 18),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Hola, $name',
                    style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: AppColors.azulNoche)),
                const Text('Listo para ganar hoy',
                    style: TextStyle(
                        fontSize: 12, color: AppColors.grisTexto)),
              ],
            ),
          ),
          _headerButton(
            icon: Icons.local_shipping_outlined,
            onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const MyVehiclesScreen())),
          ),
          const SizedBox(width: 8),
          _headerButton(
            icon: Icons.receipt_long_outlined,
            onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const HistoryScreen())),
          ),
          const SizedBox(width: 8),
          _headerButton(
            icon: Icons.person_outline,
            onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ProfileScreen())),
          ),
        ],
      ),
    );
  }

  Widget _headerButton({required IconData icon, required VoidCallback onTap}) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.borde),
          ),
          child: Icon(icon, color: AppColors.azulNoche, size: 20),
        ),
      ),
    );
  }

  Widget _availabilityCard() {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 16, 16),
      decoration: BoxDecoration(
        gradient: _available
            ? AppColors.gradienteMarca
            : const LinearGradient(
                colors: [Color(0xFF3D4A55), Color(0xFF2A3441)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(22),
        boxShadow: AppShadows.elevada,
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: .18),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              _available ? Icons.flash_on : Icons.power_settings_new,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _available ? 'Estas en linea' : 'Fuera de servicio',
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 17),
                ),
                Text(
                  _available
                      ? 'Recibiendo solicitudes en Bilwi'
                      : 'Activa para empezar a ganar',
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: .8), fontSize: 12),
                ),
              ],
            ),
          ),
          Switch(
            value: _available,
            onChanged: _toggle,
            activeColor: Colors.white,
            activeTrackColor: AppColors.turquesa,
            inactiveThumbColor: Colors.white,
            inactiveTrackColor: Colors.white.withValues(alpha: .2),
          ),
        ],
      ),
    );
  }

  Widget _statsRow() {
    return Row(
      children: [
        Expanded(
            child: StatTile(
                icon: Icons.directions_car_filled,
                value: '$_todayTrips',
                label: 'Viajes hoy')),
        const SizedBox(width: 10),
        Expanded(
            child: StatTile(
                icon: Icons.account_balance_wallet,
                value: money(_todayEarnings),
                label: 'Ganado',
                tint: AppColors.exito)),
        const SizedBox(width: 10),
        Expanded(
            child: StatTile(
                icon: Icons.star_rounded,
                value: _rating.toStringAsFixed(1),
                label: 'Calificacion',
                tint: AppColors.advertencia)),
      ],
    );
  }

  Widget _mapPreview() {
    return Container(
      height: 180,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borde),
        boxShadow: AppShadows.sutil,
      ),
      clipBehavior: Clip.antiAlias,
      child: FlutterMap(
        mapController: _map,
        options: MapOptions(
          initialCenter: _center,
          initialZoom: 13.5,
          interactionOptions:
              const InteractionOptions(flags: InteractiveFlag.none),
        ),
        children: [
          TileLayer(
            urlTemplate: AppConfig.mapTileUrl,
            userAgentPackageName: AppConfig.mapUserAgent,
          ),
          MarkerLayer(markers: [
            Marker(
              point: _center,
              width: 50,
              height: 50,
              child: Container(
                decoration: BoxDecoration(
                  color: _available ? AppColors.exito : AppColors.grisSuave,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
                  boxShadow: const [
                    BoxShadow(
                        color: Color(0x55000000),
                        blurRadius: 6,
                        offset: Offset(0, 2))
                  ],
                ),
                child: const Icon(Icons.local_taxi,
                    color: Colors.white, size: 22),
              ),
            ),
          ]),
        ],
      ),
    );
  }

  Widget _activeTripBanner() {
    final t = _activeTrip!;
    return GestureDetector(
      onTap: () => Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => TripTrackingScreen(tripId: t.id))),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.exitoSuave,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.exito.withValues(alpha: .3)),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.exito,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.directions_car, color: Colors.white),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Viaje activo • ${Trip.statusLabel(t.status)}',
                      style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: AppColors.azulNoche)),
                  Text(t.clientName ?? '-',
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.grisTexto)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.exito),
          ],
        ),
      ),
    );
  }

  Widget _requestsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text('Solicitudes',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.azulNoche)),
            const SizedBox(width: 8),
            if (_incoming.isNotEmpty)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.azulCaribe,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text('${_incoming.length}',
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 11)),
              ),
          ],
        ),
        const SizedBox(height: 10),
        if (_incoming.isEmpty && _activeTrip == null)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.borde),
            ),
            child: Column(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.verdeMenta,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(Icons.notifications_active_outlined,
                      color: AppColors.azulCaribe, size: 28),
                ),
                const SizedBox(height: 12),
                Text(
                  _available
                      ? 'Esperando solicitudes...'
                      : 'Activa tu disponibilidad',
                  style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AppColors.azulNoche,
                      fontSize: 14),
                ),
                const SizedBox(height: 2),
                Text(
                  _available
                      ? 'Mantente cerca de zonas de alta demanda'
                      : 'Solo recibes solicitudes cuando estas en linea',
                  style: const TextStyle(
                      color: AppColors.grisTexto, fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ..._incoming.map(_requestCard),
      ],
    );
  }

  Widget _requestCard(_IncomingRequest r) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.borde),
        boxShadow: AppShadows.sutil,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.azulCaribe.withValues(alpha: .12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(r.service,
                    style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.azulCaribe)),
              ),
              const Spacer(),
              Text(money(r.fare),
                  style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 17,
                      color: AppColors.azulNoche)),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.trip_origin,
                  size: 14, color: AppColors.azulCaribe),
              const SizedBox(width: 6),
              Expanded(
                child: Text(r.origin.isEmpty ? 'Origen' : r.origin,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 12.5, color: AppColors.grisTexto)),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.only(left: 6),
            child: SizedBox(
              height: 10,
              child: VerticalDivider(
                  color: AppColors.borde, thickness: 1, width: 8),
            ),
          ),
          Row(
            children: [
              const Icon(Icons.place, size: 14, color: AppColors.alerta),
              const SizedBox(width: 6),
              Expanded(
                child: Text(r.dest.isEmpty ? 'Destino' : r.dest,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 12.5, color: AppColors.grisTexto)),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.arena,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(km(r.distanceKm),
                    style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.azulNoche)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => setState(() =>
                      _incoming.removeWhere((x) => x.tripId == r.tripId)),
                  child: const Text('Rechazar'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton(
                  onPressed: () => _accept(r),
                  child: const Text('Aceptar'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _IncomingRequest {
  _IncomingRequest({
    required this.tripId,
    required this.service,
    required this.fare,
    required this.distanceKm,
    required this.origin,
    required this.dest,
  });
  final int tripId;
  final String service;
  final int fare;
  final double distanceKm;
  final String origin;
  final String dest;
}
