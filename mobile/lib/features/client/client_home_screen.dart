import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../../core/config/app_config.dart';
import '../../core/di/services.dart';
import '../../core/network/api_client.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/format.dart';
import '../../core/utils/location.dart';
import '../../data/models/nearby_driver.dart';
import '../../data/models/service_type.dart';
import '../../data/repositories/catalog_repository.dart';
import '../../state/auth_provider.dart';
import '../common/info_chip.dart';
import '../common/service_hero_card.dart';
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
    } catch (_) {/* sin red, el mapa sigue usable */}
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
      if (mounted) setState(() => _quote = q);
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
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(m), backgroundColor: AppColors.alerta));
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
    final firstName = (user?.fullName ?? '').split(' ').first;
    return Scaffold(
      backgroundColor: AppColors.arena,
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                Positioned.fill(child: _buildMap()),
                _topGreeting(firstName),
                _bottomPanel(),
              ],
            ),
    );
  }

  Widget _topGreeting(String firstName) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: AppShadows.sutil,
              ),
              child: Row(
                children: [
                  const Icon(Icons.waving_hand,
                      color: AppColors.advertencia, size: 18),
                  const SizedBox(width: 8),
                  Text('Hola, $firstName',
                      style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: AppColors.azulNoche)),
                ],
              ),
            ),
            const Spacer(),
            _circleButton(
              icon: Icons.gps_fixed,
              onTap: () async {
                final gps = await LocationHelper.current();
                if (gps != null) {
                  setState(() => _origin = gps);
                  _map.move(gps, 15);
                  _loadNearby();
                } else {
                  _snack('Activa el GPS y concede permiso de ubicacion');
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _circleButton({required IconData icon, required VoidCallback onTap}) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            boxShadow: AppShadows.sutil,
          ),
          child: Icon(icon, color: AppColors.azulCaribe),
        ),
      ),
    );
  }

  Widget _buildMap() {
    return FlutterMap(
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
        if (_dest != null)
          PolylineLayer(polylines: [
            Polyline(
              points: [_origin, _dest!],
              strokeWidth: 4,
              color: AppColors.azulCaribe.withValues(alpha: .55),
            ),
          ]),
        MarkerLayer(markers: [
          Marker(
            point: _origin,
            width: 46,
            height: 46,
            child: _originPin(),
          ),
          if (_dest != null)
            Marker(
              point: _dest!,
              width: 46,
              height: 60,
              alignment: Alignment.topCenter,
              child: const Icon(Icons.location_on,
                  color: AppColors.alerta, size: 44),
            ),
          ..._drivers.map((d) => Marker(
                point: LatLng(d.lat, d.lng),
                width: 42,
                height: 42,
                child: _driverPin(),
              )),
        ]),
      ],
    );
  }

  Widget _originPin() {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: AppColors.azulCaribe.withValues(alpha: .18),
            shape: BoxShape.circle,
          ),
        ),
        Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.azulCaribe, width: 3),
          ),
        ),
      ],
    );
  }

  Widget _driverPin() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.exito,
        shape: BoxShape.circle,
        boxShadow: const [
          BoxShadow(color: Color(0x55000000), blurRadius: 6, offset: Offset(0, 2))
        ],
        border: Border.all(color: Colors.white, width: 2),
      ),
      child: const Icon(Icons.local_taxi, color: Colors.white, size: 20),
    );
  }

  Widget _bottomPanel() {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          boxShadow: AppShadows.elevada,
        ),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.borde,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  const Expanded(
                    child: Text('¿A donde vamos?',
                        style: TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.w800,
                            color: AppColors.azulNoche)),
                  ),
                  _liveBadge(),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                _dest == null
                    ? 'Toca el mapa para marcar tu destino'
                    : '${_drivers.length} conductor(es) cerca de ti',
                style: const TextStyle(
                    fontSize: 12.5, color: AppColors.grisTexto),
              ),
              const SizedBox(height: 14),
              SizedBox(
                height: 178,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _services.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (_, i) {
                    final s = _services[i];
                    return ServiceHeroCard(
                      service: s,
                      selected: _selected?.id == s.id,
                      fromPrice: money(s.minFare),
                      onTap: () => _onSelectService(s),
                    );
                  },
                ),
              ),
              const SizedBox(height: 14),
              if (_quote != null) _quoteChips(),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: (_dest == null || _requesting) ? null : _request,
                  icon: _requesting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.send_rounded),
                  label: Text(
                    _dest == null
                        ? 'Marca tu destino en el mapa'
                        : _quote == null
                            ? 'Solicitar ${_selected?.name ?? ''}'
                            : 'Solicitar • ${money(_quote!.fareEstimated)}',
                    style: const TextStyle(letterSpacing: 0.3),
                  ),
                ),
              ),
              const SizedBox(height: 70), // espacio para el bottom nav
            ],
          ),
        ),
      ),
    );
  }

  Widget _liveBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.exitoSuave,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
                color: AppColors.exito, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          const Text('En vivo',
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.exito)),
        ],
      ),
    );
  }

  Widget _quoteChips() {
    final q = _quote!;
    return Row(
      children: [
        Expanded(
            child: InfoChip(
                icon: Icons.attach_money,
                value: money(q.fareEstimated),
                label: 'Tarifa')),
        const SizedBox(width: 10),
        Expanded(
            child: InfoChip(
                icon: Icons.route, value: km(q.distanceKm), label: 'Distancia')),
        const SizedBox(width: 10),
        Expanded(
            child: InfoChip(
                icon: Icons.schedule,
                value: minutes(q.durationMin),
                label: 'Tiempo')),
        if (q.surge > 1) ...[
          const SizedBox(width: 10),
          Expanded(
            child: InfoChip(
              icon: Icons.trending_up,
              value: 'x${q.surge.toStringAsFixed(1)}',
              label: 'Demanda',
              tint: AppColors.advertencia,
            ),
          ),
        ],
      ],
    );
  }
}
