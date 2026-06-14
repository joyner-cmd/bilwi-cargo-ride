import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../../core/config/app_config.dart';
import '../../core/di/services.dart';
import '../../core/network/api_client.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/format.dart';
import '../../data/models/trip.dart';
import '../../state/auth_provider.dart';
import '../chat/chat_screen.dart';

class TripTrackingScreen extends StatefulWidget {
  const TripTrackingScreen({super.key, required this.tripId});
  final int tripId;

  @override
  State<TripTrackingScreen> createState() => _TripTrackingScreenState();
}

class _TripTrackingScreenState extends State<TripTrackingScreen> {
  late final Services _s;
  final _map = MapController();
  Trip? _trip;
  LatLng? _driverPos;
  bool _rated = false;

  @override
  void initState() {
    super.initState();
    _s = context.read<Services>();
    _load();
    _s.socket.joinTrip(widget.tripId);
    _s.socket.on('trip:status', _onStatus);
    _s.socket.on('driver:location', _onDriverLoc);
  }

  @override
  void dispose() {
    _s.socket.off('trip:status');
    _s.socket.off('driver:location');
    _s.socket.leaveTrip(widget.tripId);
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final t = await _s.trips.detail(widget.tripId);
      if (mounted) setState(() => _trip = t);
    } catch (e) {
      _snack(ApiClient.messageFrom(e));
    }
  }

  void _onStatus(dynamic data) {
    if (data is Map && data['trip'] != null) {
      final t = Trip.fromJson(Map<String, dynamic>.from(data['trip']));
      if (mounted) setState(() => _trip = t);
      if (t.status == 'completed' && !_rated) _askRating();
    } else {
      _load();
    }
  }

  void _onDriverLoc(dynamic data) {
    if (data is Map && data['lat'] != null) {
      setState(() => _driverPos =
          LatLng((data['lat'] as num).toDouble(), (data['lng'] as num).toDouble()));
    }
  }

  Future<void> _cancel() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Cancelar viaje'),
        content: const Text('Seguro que deseas cancelar esta solicitud?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('No')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Si, cancelar')),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await _s.trips.cancel(widget.tripId, reason: 'Cancelado por el cliente');
      if (mounted) Navigator.pop(context);
    } catch (e) {
      _snack(ApiClient.messageFrom(e));
    }
  }

  Future<void> _sos() async {
    try {
      await _s.trips.reportIncident(
        tripId: widget.tripId,
        type: 'sos',
        description: 'Boton SOS activado',
        lat: _trip?.originLat,
        lng: _trip?.originLng,
      );
      _snack('Alerta SOS enviada. Mantente a salvo.', color: AppColors.exito);
    } catch (e) {
      _snack(ApiClient.messageFrom(e));
    }
  }

  Future<void> _askRating() async {
    _rated = true;
    int stars = 5;
    final comment = TextEditingController();
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: const Text('Califica tu viaje'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (i) {
                  return IconButton(
                    icon: Icon(i < stars ? Icons.star : Icons.star_border,
                        color: AppColors.advertencia, size: 32),
                    onPressed: () => setLocal(() => stars = i + 1),
                  );
                }),
              ),
              TextField(
                controller: comment,
                decoration: const InputDecoration(hintText: 'Comentario (opcional)'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Mas tarde'),
            ),
            FilledButton(
              onPressed: () async {
                try {
                  await _s.trips.rate(widget.tripId, stars, comment: comment.text);
                } catch (_) {}
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: const Text('Enviar'),
            ),
          ],
        ),
      ),
    );
  }

  void _snack(String m, {Color color = AppColors.alerta}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(m), backgroundColor: color));
  }

  @override
  Widget build(BuildContext context) {
    final t = _trip;
    final isDriver = context.read<AuthProvider>().user?.isDriver ?? false;
    return Scaffold(
      appBar: AppBar(
        title: Text(t == null ? 'Viaje' : Trip.statusLabel(t.status)),
        actions: [
          IconButton(
            icon: const Icon(Icons.warning_amber_rounded),
            tooltip: 'SOS',
            color: Colors.amberAccent,
            onPressed: _sos,
          ),
        ],
      ),
      body: t == null
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(child: _buildMap(t)),
                _buildInfo(t, isDriver),
              ],
            ),
    );
  }

  Widget _buildMap(Trip t) {
    final origin = LatLng(t.originLat, t.originLng);
    final dest = LatLng(t.destLat, t.destLng);
    return FlutterMap(
      mapController: _map,
      options: MapOptions(initialCenter: origin, initialZoom: 14),
      children: [
        TileLayer(
          urlTemplate: AppConfig.mapTileUrl,
          userAgentPackageName: AppConfig.mapUserAgent,
        ),
        PolylineLayer(polylines: [
          Polyline(points: [origin, dest], strokeWidth: 4, color: AppColors.azulCaribe.withValues(alpha: .6)),
        ]),
        MarkerLayer(markers: [
          Marker(point: origin, child: const Icon(Icons.my_location, color: AppColors.azulCaribe, size: 32)),
          Marker(point: dest, child: const Icon(Icons.location_on, color: AppColors.alerta, size: 38)),
          if (_driverPos != null)
            Marker(point: _driverPos!, width: 46, height: 46, child: const Icon(Icons.local_taxi, color: AppColors.exito, size: 34)),
        ]),
      ],
    );
  }

  Widget _buildInfo(Trip t, bool isDriver) {
    final who = isDriver ? t.clientName : t.driverName;
    final phone = isDriver ? t.clientPhone : t.driverPhone;
    return Container(
      width: double.infinity,
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _statusDot(t.status),
                const SizedBox(width: 8),
                Text(Trip.statusLabel(t.status),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const Spacer(),
                Text(money(t.fareFinal ?? t.fareEstimated),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.azulCaribe)),
              ],
            ),
            const Divider(height: 20),
            if (who != null)
              Row(
                children: [
                  const CircleAvatar(child: Icon(Icons.person)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(who, style: const TextStyle(fontWeight: FontWeight.w600)),
                        Text(
                          [t.vehicleType, t.vehiclePlate].where((e) => e != null).join('  '),
                          style: const TextStyle(fontSize: 12, color: AppColors.grisTexto),
                        ),
                      ],
                    ),
                  ),
                  if (phone != null)
                    IconButton(
                      icon: const Icon(Icons.chat, color: AppColors.azulCaribe),
                      onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                          builder: (_) => ChatScreen(tripId: t.id))),
                    ),
                ],
              )
            else
              const Text('Buscando conductor disponible...',
                  style: TextStyle(color: AppColors.grisTexto)),
            const SizedBox(height: 12),
            if (t.isActive && !isDriver)
              OutlinedButton.icon(
                onPressed: _cancel,
                icon: const Icon(Icons.close),
                label: const Text('Cancelar viaje'),
                style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.alerta, minimumSize: const Size.fromHeight(46)),
              ),
            if (t.status == 'completed')
              FilledButton.icon(
                onPressed: _askRating,
                icon: const Icon(Icons.star),
                label: const Text('Calificar'),
              ),
          ],
        ),
      ),
    );
  }

  Widget _statusDot(String status) {
    final color = status == 'completed'
        ? AppColors.exito
        : status == 'cancelled'
            ? AppColors.alerta
            : AppColors.advertencia;
    return Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle));
  }
}
