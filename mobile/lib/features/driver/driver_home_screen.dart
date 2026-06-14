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
import '../../core/utils/format.dart';
import '../../core/utils/location.dart';
import '../../data/models/trip.dart';
import '../../state/auth_provider.dart';
import '../history/history_screen.dart';
import '../profile/profile_screen.dart';
import '../trip/trip_tracking_screen.dart';

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
    return Scaffold(
      appBar: AppBar(
        title: Text('Hola, ${user?.fullName.split(' ').first ?? ''}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const HistoryScreen())),
          ),
          IconButton(
            icon: const Icon(Icons.account_circle),
            onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ProfileScreen())),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(child: _buildMap()),
          _buildPanel(),
        ],
      ),
    );
  }

  Widget _buildMap() {
    return FlutterMap(
      mapController: _map,
      options: MapOptions(initialCenter: _center, initialZoom: 14),
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
            child: Icon(
              Icons.local_taxi,
              size: 38,
              color: _available ? AppColors.exito : AppColors.grisTexto,
            ),
          ),
        ]),
      ],
    );
  }

  Widget _buildPanel() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
      ),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const Icon(Icons.power_settings_new, color: AppColors.azulCaribe),
                const SizedBox(width: 8),
                const Text('Disponible para viajes',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                const Spacer(),
                Switch(value: _available, onChanged: _toggle),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _stat('Viajes hoy', '$_todayTrips', Icons.directions_car),
                _stat('Ganancias', money(_todayEarnings), Icons.account_balance_wallet),
                _stat(
                  'Estado',
                  _available ? 'En linea' : 'Offline',
                  Icons.circle,
                  color: _available ? AppColors.exito : AppColors.grisTexto,
                ),
              ],
            ),
            const SizedBox(height: 14),
            if (_activeTrip != null) _activeBanner(),
            if (_incoming.isEmpty && _activeTrip == null)
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.arena,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _available
                      ? 'Esperando solicitudes... mantente cerca.'
                      : 'Activa tu disponibilidad para recibir viajes.',
                  style: const TextStyle(color: AppColors.grisTexto),
                  textAlign: TextAlign.center,
                ),
              ),
            ..._incoming.map(_requestCard),
          ],
        ),
      ),
    );
  }

  Widget _activeBanner() {
    final t = _activeTrip!;
    return Card(
      color: AppColors.verdeAgua.withValues(alpha: .3),
      child: ListTile(
        leading: const Icon(Icons.directions_car, color: AppColors.azulCaribe),
        title: Text('Viaje activo: ${Trip.statusLabel(t.status)}'),
        subtitle: Text(t.clientName ?? '-'),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () => Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => TripTrackingScreen(tripId: t.id))),
      ),
    );
  }

  Widget _requestCard(_IncomingRequest r) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Text(r.service,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const Spacer(),
                Text(money(r.fare),
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, color: AppColors.azulCaribe)),
              ],
            ),
            const SizedBox(height: 6),
            Text('${km(r.distanceKm)}  •  ${r.origin} → ${r.dest}',
                style: const TextStyle(fontSize: 12.5, color: AppColors.grisTexto)),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () =>
                        setState(() => _incoming.removeWhere((x) => x.tripId == r.tripId)),
                    child: const Text('Rechazar'),
                  ),
                ),
                const SizedBox(width: 8),
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
      ),
    );
  }

  Widget _stat(String label, String value, IconData icon, {Color? color}) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.arena,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: color ?? AppColors.azulCaribe, size: 22),
            const SizedBox(height: 4),
            Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
            Text(label, style: const TextStyle(fontSize: 11, color: AppColors.grisTexto)),
          ],
        ),
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
