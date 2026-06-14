import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/di/services.dart';
import '../../core/network/api_client.dart';
import '../../core/theme/app_colors.dart';
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
      appBar: AppBar(title: const Text('Historial')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _trips.isEmpty
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: Text('Aun no tienes viajes. Solicita el primero!',
                        textAlign: TextAlign.center),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(12),
                    itemCount: _trips.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (_, i) => _tile(_trips[i]),
                  ),
                ),
    );
  }

  Widget _tile(Trip t) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.verdeAgua.withValues(alpha: .4),
          child: Icon(_iconForStatus(t.status), color: AppColors.azulCaribe),
        ),
        title: Text(t.serviceName, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(
          '${Trip.statusLabel(t.status)} • ${km(t.distanceKm)}',
          style: const TextStyle(fontSize: 12.5),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(money(t.fareFinal ?? t.fareEstimated),
                style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        onTap: () => Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => TripTrackingScreen(tripId: t.id))),
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

// Mantengo el import de intl por si se quiere mostrar fecha luego.
// ignore: unused_element
String _fmtDate(DateTime d) => DateFormat('dd MMM, HH:mm', 'es').format(d);
