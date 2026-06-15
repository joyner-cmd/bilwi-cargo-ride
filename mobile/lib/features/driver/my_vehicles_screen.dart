import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/config/app_config.dart';
import '../../core/di/services.dart';
import '../../core/network/api_client.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../common/photo_avatar.dart';
import 'add_vehicle_screen.dart';

class MyVehiclesScreen extends StatefulWidget {
  const MyVehiclesScreen({super.key});

  @override
  State<MyVehiclesScreen> createState() => _MyVehiclesScreenState();
}

class _MyVehiclesScreenState extends State<MyVehiclesScreen> {
  late final Services _s;
  List<Map<String, dynamic>> _vehicles = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _s = context.read<Services>();
    _load();
  }

  Future<void> _load() async {
    try {
      _vehicles = await _s.driver.myVehicles();
    } catch (e) {
      if (mounted) _snack(ApiClient.messageFrom(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _add() async {
    final created = await Navigator.of(context).push<bool>(
        MaterialPageRoute(builder: (_) => const AddVehicleScreen()));
    if (created == true) _load();
  }

  Future<void> _edit(Map<String, dynamic> v) async {
    final updated = await Navigator.of(context).push<bool>(MaterialPageRoute(
        builder: (_) => AddVehicleScreen(existing: v)));
    if (updated == true) _load();
  }

  Future<void> _delete(int id) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Eliminar vehiculo'),
        content: const Text('Esta accion no se puede deshacer.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar')),
          FilledButton(
              style: FilledButton.styleFrom(backgroundColor: AppColors.alerta),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Eliminar')),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await _s.driver.deleteVehicle(id);
      _load();
    } catch (e) {
      if (mounted) _snack(ApiClient.messageFrom(e));
    }
  }

  void _snack(String m, {Color color = AppColors.alerta}) {
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(m), backgroundColor: color));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.arena,
      appBar: AppBar(
        title: const Text('Mis vehiculos'),
        backgroundColor: AppColors.arena,
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.azulCaribe,
        foregroundColor: Colors.white,
        onPressed: _add,
        icon: const Icon(Icons.add),
        label: const Text('Nuevo'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _vehicles.isEmpty
              ? _empty()
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                    itemCount: _vehicles.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (_, i) => _vehicleCard(_vehicles[i]),
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
              child: const Icon(Icons.local_shipping_outlined,
                  size: 40, color: AppColors.azulCaribe),
            ),
            const SizedBox(height: 16),
            const Text('Aun no tienes vehiculos',
                style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: AppColors.azulNoche)),
            const SizedBox(height: 4),
            const Text(
              'Registra tu primer vehiculo para empezar a recibir solicitudes.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.grisTexto),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _add,
              icon: const Icon(Icons.add),
              label: const Text('Agregar vehiculo'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _vehicleCard(Map<String, dynamic> v) {
    final services = (v['services_offered'] as List?)?.cast<String>() ?? [];
    final status = (v['status'] ?? 'pending') as String;
    final customPerKm = v['custom_per_km'];
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borde),
        boxShadow: AppShadows.sutil,
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AspectRatio(
            aspectRatio: 16 / 9,
            child: Container(
              decoration: const BoxDecoration(color: AppColors.arena),
              child: PhotoImage(
                photoUrl: v['photo_url'] as String?,
                borderRadius: 0,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            [v['brand'], v['model']]
                                .where((e) =>
                                    e != null && '$e'.isNotEmpty)
                                .join(' '),
                            style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 17,
                                color: AppColors.azulNoche),
                          ),
                          if (v['plate'] != null && '${v['plate']}'.isNotEmpty)
                            Container(
                              margin: const EdgeInsets.only(top: 4),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppColors.arena,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text('${v['plate']}',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.azulNoche,
                                      fontSize: 12)),
                            ),
                        ],
                      ),
                    ),
                    _statusBadge(status),
                  ],
                ),
                if (services.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: services
                        .map((s) => _serviceBadge(s))
                        .toList(growable: false),
                  ),
                ],
                if (customPerKm != null) ...[
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Icon(Icons.attach_money,
                          size: 16, color: AppColors.azulCaribe),
                      const SizedBox(width: 4),
                      Text(
                        '${AppConfig.currency}${(customPerKm is num ? customPerKm : num.tryParse('$customPerKm') ?? 0).toStringAsFixed(0)}/km personalizado',
                        style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: AppColors.azulNoche),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _edit(v),
                        icon: const Icon(Icons.edit, size: 18),
                        label: const Text('Editar'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.delete_outline,
                          color: AppColors.alerta),
                      onPressed: () => _delete(v['id'] as int),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusBadge(String status) {
    final cfg = {
      'approved': (AppColors.exito, AppColors.exitoSuave, 'Aprobado'),
      'pending': (AppColors.advertencia, const Color(0xFFFFF8E1), 'En revision'),
      'rejected': (AppColors.alerta, AppColors.alertaSuave, 'Rechazado'),
    }[status] ?? (AppColors.grisTexto, AppColors.arena, status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: cfg.$2,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(cfg.$3,
          style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: cfg.$1)),
    );
  }

  Widget _serviceBadge(String code) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.verdeMenta,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(code,
          style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.azulCaribe)),
    );
  }
}
