import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../../core/config/app_config.dart';
import '../../core/di/services.dart';
import '../../core/network/api_client.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/format.dart';
import '../../core/utils/location.dart';
import '../../data/models/nearby_driver.dart';
import '../../data/models/service_type.dart';
import '../../data/repositories/catalog_repository.dart';
import '../../state/auth_provider.dart';
import '../history/history_screen.dart';
import '../profile/profile_screen.dart';
import '../trip/trip_tracking_screen.dart';

class ClientHomeScreen extends StatefulWidget {
  const ClientHomeScreen({super.key});

  @override
  State<ClientHomeScreen> createState() => _ClientHomeScreenState();
}

class _ClientHomeScreenState extends State<ClientHomeScreen> {
  final _map = MapController();
  late final Services _s;

  LatLng _origin = const LatLng(AppConfig.bilwiLat, AppConfig.bilwiLng);
  LatLng? _dest;
  List<ServiceType> _services = [];
  ServiceType? _selected;
  List<NearbyDriver> _drivers = [];
  FareQuote? _quote;
  bool _loading = true;
  bool _requesting = false;

  @override
  void initState() {
    super.initState();
    _s = context.read<Services>();
    _init();
  }

  Future<void> _init() async {
    final gps = await LocationHelper.current();
    if (gps != null) _origin = gps;
    try {
      final list = await _s.catalog.services();
      _services = list;
      _selected = list.isNotEmpty ? list.first : null;
      await _loadNearby();
    } catch (e) {
      _snack(ApiClient.messageFrom(e));
    }
    if (mounted) setState(() => _loading = false);
    _map.move(_origin, 14.5);
  }

  Future<void> _loadNearby() async {
    try {
      _drivers = await _s.trips.nearby(
        lat: _origin.latitude,
        lng: _origin.longitude,
        vehicleType: _selected?.vehicleType,
      );
      if (mounted) setState(() {});
    } catch (_) {/* sin conexion: el mapa sigue usable */}
  }

  Future<void> _getQuote() async {
    if (_dest == null || _selected == null) return;
    try {
      final q = await _s.catalog.quote(
        serviceTypeId: _selected!.id,
        originLat: _origin.latitude,
        originLng: _origin.longitude,
        destLat: _dest!.latitude,
        destLng: _dest!.longitude,
      );
      setState(() => _quote = q);
    } catch (e) {
      _snack(ApiClient.messageFrom(e));
    }
  }

  Future<void> _request() async {
    if (_dest == null || _selected == null) return;
    setState(() => _requesting = true);
    try {
      final trip = await _s.trips.request({
        'serviceTypeId': _selected!.id,
        'originLat': _origin.latitude,
        'originLng': _origin.longitude,
        'originAddress': 'Origen seleccionado',
        'destLat': _dest!.latitude,
        'destLng': _dest!.longitude,
        'destAddress': 'Destino seleccionado',
        'paymentMethod': 'cash',
      });
      if (!mounted) return;
      Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => TripTrackingScreen(tripId: trip.id)));
    } catch (e) {
      _snack(ApiClient.messageFrom(e));
    } finally {
      if (mounted) setState(() => _requesting = false);
    }
  }

  void _snack(String m) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(m), backgroundColor: AppColors.alerta));
  }

  void _onSelectService(ServiceType s) {
    setState(() {
      _selected = s;
      _quote = null;
    });
    _loadNearby();
    if (_dest != null) _getQuote();
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bilwi Cargo & Ride'),
        actions: [
          IconButton(
            tooltip: 'Historial',
            icon: const Icon(Icons.history),
            onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const HistoryScreen())),
          ),
          IconButton(
            tooltip: 'Perfil',
            icon: const Icon(Icons.account_circle),
            onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ProfileScreen())),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(child: _buildMap()),
                _buildPanel(user?.fullName ?? ''),
              ],
            ),
    );
  }

  Widget _buildMap() {
    return Stack(
      children: [
        FlutterMap(
          mapController: _map,
          options: MapOptions(
            initialCenter: _origin,
            initialZoom: 14.5,
            onTap: (_, p) {
              setState(() {
                _dest = p;
                _quote = null;
              });
              _getQuote();
            },
          ),
          children: [
            TileLayer(
              urlTemplate: AppConfig.mapTileUrl,
              userAgentPackageName: AppConfig.mapUserAgent,
            ),
            MarkerLayer(markers: [
              Marker(
                point: _origin,
                width: 44,
                height: 44,
                child: const Icon(Icons.my_location, color: AppColors.azulCaribe, size: 34),
              ),
              if (_dest != null)
                Marker(
                  point: _dest!,
                  width: 44,
                  height: 44,
                  child: const Icon(Icons.location_on, color: AppColors.alerta, size: 40),
                ),
              ..._drivers.map((d) => Marker(
                    point: LatLng(d.lat, d.lng),
                    width: 40,
                    height: 40,
                    child: const Icon(Icons.local_taxi, color: AppColors.exito, size: 28),
                  )),
            ]),
          ],
        ),
        Positioned(
          right: 12,
          bottom: 12,
          child: Column(
            children: [
              FloatingActionButton.small(
                heroTag: 'gps',
                backgroundColor: Colors.white,
                onPressed: () async {
                  final gps = await LocationHelper.current();
                  if (gps != null) {
                    setState(() => _origin = gps);
                    _map.move(gps, 15);
                    _loadNearby();
                  } else {
                    _snack('Activa el GPS y concede permiso de ubicacion');
                  }
                },
                child: const Icon(Icons.gps_fixed, color: AppColors.azulCaribe),
              ),
            ],
          ),
        ),
        Positioned(
          left: 12,
          top: 12,
          child: Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Text(
                _dest == null
                    ? 'Toca el mapa para marcar tu destino'
                    : '${_drivers.length} conductor(es) cerca',
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12.5),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPanel(String name) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
      ),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Que necesitas mover, $name?',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 10),
            SizedBox(
              height: 104,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _services.length,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (_, i) => _serviceCard(_services[i]),
              ),
            ),
            const SizedBox(height: 12),
            if (_quote != null) _quoteRow(),
            const SizedBox(height: 10),
            FilledButton.icon(
              onPressed: (_dest == null || _requesting) ? null : _request,
              icon: _requesting
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.send),
              label: Text(_dest == null
                  ? 'Marca tu destino en el mapa'
                  : 'Solicitar ${_selected?.name ?? ''}'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _serviceCard(ServiceType s) {
    final sel = _selected?.id == s.id;
    return GestureDetector(
      onTap: () => _onSelectService(s),
      child: Container(
        width: 130,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: sel ? AppColors.azulCaribe : const Color(0xFFE0E6EA),
              width: sel ? 2 : 1),
          color: sel ? AppColors.verdeAgua.withValues(alpha: .18) : Colors.white,
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Image.asset(s.assetImage, fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) =>
                      Container(color: AppColors.arena, child: const Icon(Icons.local_shipping))),
            ),
            Padding(
              padding: const EdgeInsets.all(6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(s.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12.5)),
                  Text('desde ${money(s.minFare)}',
                      style: const TextStyle(fontSize: 11, color: AppColors.grisTexto)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _quoteRow() {
    final q = _quote!;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.arena,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          _metric(Icons.attach_money, money(q.fareEstimated), 'Tarifa'),
          _metric(Icons.route, km(q.distanceKm), 'Distancia'),
          _metric(Icons.schedule, minutes(q.durationMin), 'Tiempo'),
          if (q.surge > 1) _metric(Icons.trending_up, 'x${q.surge}', 'Demanda'),
        ],
      ),
    );
  }

  Widget _metric(IconData icon, String value, String label) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: AppColors.azulCaribe, size: 20),
          const SizedBox(height: 2),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
          Text(label, style: const TextStyle(fontSize: 11, color: AppColors.grisTexto)),
        ],
      ),
    );
  }
}
