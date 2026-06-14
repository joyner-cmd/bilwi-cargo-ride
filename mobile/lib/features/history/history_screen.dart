import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/di/services.dart';
import '../../core/network/api_client.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/format.dart';
import '../../data/models/trip.dart';
import '../trip/trip_tracking_screen.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  late final Services _s;
  List<Trip> _trips = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _s = context.read<Services>();
    _load();
  }

  Future<void> _load() async {
    try {
      _trips = await _s.trips.list();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(ApiClient.messageFrom(e))));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.arena,
      appBar: AppBar(
        title: const Text('Tus viajes'),
        backgroundColor: AppColors.arena,
        scrolledUnderElevation: 0,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _trips.isEmpty
              ? _empty()
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                    itemCount: _trips.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (_, i) => _tile(_trips[i]),
                  ),
                ),
    );
  }

  Widget _empty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 84,
              height: 84,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.verdeMenta,
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(Icons.directions_car_filled_outlined,
                  size: 40, color: AppColors.azulCaribe),
            ),
            const SizedBox(height: 16),
            const Text('Aun no tienes viajes',
                style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: AppColors.azulNoche)),
            const SizedBox(height: 4),
            const Text(
                'Cuando solicites tu primer viaje aparecera aqui tu historial.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.grisTexto)),
          ],
        ),
      ),
    );
  }

  Widget _tile(Trip t) {
    final color = t.status == 'completed'
        ? AppColors.exito
        : t.status == 'cancelled'
            ? AppColors.alerta
            : AppColors.advertencia;
    final bg = t.status == 'completed'
        ? AppColors.exitoSuave
        : t.status == 'cancelled'
            ? AppColors.alertaSuave
            : const Color(0xFFFFF8E1);
    return GestureDetector(
      onTap: () => Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => TripTrackingScreen(tripId: t.id))),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.borde),
          boxShadow: AppShadows.sutil,
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.verdeMenta,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(_iconForStatus(t.status),
                  color: AppColors.azulCaribe, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(t.serviceName,
                      style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: AppColors.azulNoche)),
                  const SizedBox(height: 2),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: bg,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(Trip.statusLabel(t.status),
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: color)),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(money(t.fareFinal ?? t.fareEstimated),
                    style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                        color: AppColors.azulNoche)),
                Text(km(t.distanceKm),
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.grisSuave)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  IconData _iconForStatus(String s) {
    switch (s) {
      case 'completed':
        return Icons.check_circle;
      case 'cancelled':
        return Icons.cancel;
      default:
        return Icons.directions_car;
    }
  }
}
