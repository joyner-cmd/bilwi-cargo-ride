import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../../core/config/app_config.dart';
import '../../core/di/services.dart';
import '../../core/network/api_client.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/format.dart';
import '../../data/models/message.dart';
import '../../data/models/trip.dart';
import '../../state/auth_provider.dart';

class TripTrackingScreen extends StatefulWidget {
  const TripTrackingScreen({super.key, required this.tripId});
  final int tripId;

  @override
  State<TripTrackingScreen> createState() => _TripTrackingScreenState();
}

class _TripTrackingScreenState extends State<TripTrackingScreen>
    with SingleTickerProviderStateMixin {
  late final Services _s;
  late final TabController _tabs;
  final _map = MapController();
  final _chatInput = TextEditingController();
  final _chatScroll = ScrollController();

  Trip? _trip;
  LatLng? _driverPos;
  List<ChatMessage> _messages = [];
  int? _meId;
  bool _rated = false;
  bool _unread = false;

  @override
  void initState() {
    super.initState();
    _s = context.read<Services>();
    _meId = context.read<AuthProvider>().user?.id;
    _tabs = TabController(length: 2, vsync: this);
    _tabs.addListener(() {
      if (_tabs.index == 1 && _unread) setState(() => _unread = false);
    });

    _s.socket.joinTrip(widget.tripId);
    _s.socket.on('trip:status', _onStatus);
    _s.socket.on('driver:location', _onDriverLoc);
    _s.socket.on('chat:message', _onChat);

    _load();
    _loadChat();
  }

  @override
  void dispose() {
    _s.socket.off('trip:status');
    _s.socket.off('driver:location');
    _s.socket.off('chat:message');
    _s.socket.leaveTrip(widget.tripId);
    _tabs.dispose();
    _chatInput.dispose();
    _chatScroll.dispose();
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

  Future<void> _loadChat() async {
    try {
      final list = await _s.messages.history(widget.tripId);
      if (mounted) setState(() => _messages = list);
      _scrollChatDown();
    } catch (_) {/* sin red */}
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
      setState(() => _driverPos = LatLng(
            (data['lat'] as num).toDouble(),
            (data['lng'] as num).toDouble(),
          ));
    }
  }

  void _onChat(dynamic data) {
    if (data is Map) {
      final m = ChatMessage.fromJson(Map<String, dynamic>.from(data));
      setState(() {
        _messages.add(m);
        if (_tabs.index != 1 && m.senderId != _meId) _unread = true;
      });
      _scrollChatDown();
    }
  }

  void _scrollChatDown() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_chatScroll.hasClients) {
        _chatScroll.animateTo(
          _chatScroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 240),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendChat() async {
    final text = _chatInput.text.trim();
    if (text.isEmpty) return;
    _chatInput.clear();
    try {
      await _s.messages.send(widget.tripId, text);
    } catch (e) {
      _snack(ApiClient.messageFrom(e));
    }
  }

  Future<void> _cancel() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Cancelar viaje'),
        content: const Text('Seguro que deseas cancelar esta solicitud?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('No')),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Si, cancelar')),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await _s.trips.cancel(widget.tripId, reason: 'Cancelado por el usuario');
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

  Future<void> _driverAction(Future<Trip> Function() fn) async {
    try {
      final t = await fn();
      if (mounted) setState(() => _trip = t);
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
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
                decoration:
                    const InputDecoration(hintText: 'Comentario (opcional)'),
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Mas tarde')),
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
      backgroundColor: AppColors.arena,
      body: t == null
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                Positioned.fill(child: _buildMap(t)),
                _topBar(t),
                _bottomPanel(t, isDriver),
              ],
            ),
    );
  }

  // ---------- Map ----------
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
          Polyline(
            points: [origin, dest],
            strokeWidth: 4,
            color: AppColors.azulCaribe.withValues(alpha: .55),
          ),
        ]),
        MarkerLayer(markers: [
          Marker(point: origin, width: 44, height: 44, child: _originPin()),
          Marker(
              point: dest,
              width: 46,
              height: 60,
              alignment: Alignment.topCenter,
              child: const Icon(Icons.location_on,
                  color: AppColors.alerta, size: 44)),
          if (_driverPos != null)
            Marker(
              point: _driverPos!,
              width: 46,
              height: 46,
              child: _driverPin(),
            ),
        ]),
      ],
    );
  }

  Widget _originPin() => Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.azulCaribe.withValues(alpha: .18),
              shape: BoxShape.circle,
            ),
          ),
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.azulCaribe, width: 3),
            ),
          ),
        ],
      );

  Widget _driverPin() => Container(
        decoration: BoxDecoration(
          color: AppColors.exito,
          shape: BoxShape.circle,
          boxShadow: const [
            BoxShadow(
                color: Color(0x55000000), blurRadius: 6, offset: Offset(0, 2))
          ],
          border: Border.all(color: Colors.white, width: 3),
        ),
        child: const Icon(Icons.local_taxi, color: Colors.white, size: 22),
      );

  // ---------- Top bar (back + status + SOS) ----------
  Widget _topBar(Trip t) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
        child: Row(
          children: [
            _roundBtn(Icons.arrow_back, () => Navigator.pop(context)),
            const SizedBox(width: 10),
            Expanded(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: AppShadows.sutil,
                ),
                child: Row(
                  children: [
                    _statusDot(t.status),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(Trip.statusLabel(t.status),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              color: AppColors.azulNoche)),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 10),
            _roundBtn(
              Icons.warning_amber_rounded,
              _sos,
              bg: AppColors.alerta,
              fg: Colors.white,
            ),
          ],
        ),
      ),
    );
  }

  Widget _roundBtn(IconData icon, VoidCallback onTap,
      {Color bg = Colors.white, Color fg = AppColors.azulNoche}) {
    return Material(
      color: bg,
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
          child: Icon(icon, color: fg),
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
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 18,
          height: 18,
          decoration: BoxDecoration(
              color: color.withValues(alpha: .25), shape: BoxShape.circle),
        ),
        Container(
          width: 10,
          height: 10,
          decoration:
              BoxDecoration(color: color, shape: BoxShape.circle),
        ),
      ],
    );
  }

  // ---------- Bottom panel with tabs (Detalles + Chat) ----------
  Widget _bottomPanel(Trip t, bool isDriver) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        height: MediaQuery.of(context).size.height * 0.55,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          boxShadow: AppShadows.elevada,
        ),
        child: Column(
          children: [
            const SizedBox(height: 10),
            Container(
              width: 42,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.borde,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 8),
            _tabBar(),
            Expanded(
              child: TabBarView(
                controller: _tabs,
                children: [
                  _detailsTab(t, isDriver),
                  _chatTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tabBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.arena,
          borderRadius: BorderRadius.circular(14),
        ),
        child: TabBar(
          controller: _tabs,
          indicator: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: AppShadows.sutil,
          ),
          indicatorPadding: const EdgeInsets.all(4),
          labelColor: AppColors.azulNoche,
          unselectedLabelColor: AppColors.grisTexto,
          labelStyle:
              const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
          dividerColor: Colors.transparent,
          tabs: [
            const Tab(text: 'Detalles', height: 44),
            Tab(
              height: 44,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Chat'),
                  if (_unread) ...[
                    const SizedBox(width: 6),
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                          color: AppColors.alerta, shape: BoxShape.circle),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------- Tab 1: Details ----------
  Widget _detailsTab(Trip t, bool isDriver) {
    final who = isDriver ? t.clientName : t.driverName;
    final phone = isDriver ? t.clientPhone : t.driverPhone;
    final fare = money(t.fareFinal ?? t.fareEstimated);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        // Fare hero row
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: AppColors.gradienteMarca,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Row(
            children: [
              const Icon(Icons.account_balance_wallet,
                  color: Colors.white, size: 28),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(t.serviceName,
                      style: TextStyle(
                          color: Colors.white.withValues(alpha: .85),
                          fontSize: 12)),
                  Text(fare,
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 22)),
                ],
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: .18),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(t.paymentMethod.toUpperCase(),
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w700)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Counterpart card
        if (who != null) _counterpartCard(who, phone, t, isDriver),
        if (who == null)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.verdeMenta,
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Row(
              children: [
                SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: AppColors.azulCaribe),
                ),
                SizedBox(width: 14),
                Expanded(
                  child: Text(
                    'Buscando conductor disponible cerca de ti...',
                    style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppColors.azulNoche),
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 14),

        // Route info
        _routeCard(t),

        const SizedBox(height: 18),

        // Actions (depend on role + status)
        ..._actions(t, isDriver),
      ],
    );
  }

  Widget _counterpartCard(
      String who, String? phone, Trip t, bool isDriver) {
    return Container(
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
            width: 52,
            height: 52,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              gradient: AppColors.gradienteMarca,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              who.isNotEmpty ? who[0].toUpperCase() : '?',
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 20),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(who,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppColors.azulNoche,
                        fontSize: 15)),
                const SizedBox(height: 2),
                Text(
                  [
                    t.vehicleType,
                    t.vehiclePlate,
                  ].where((e) => e != null && e.isNotEmpty).join(' • '),
                  style: const TextStyle(
                      color: AppColors.grisTexto, fontSize: 12),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Llamar',
            icon: const Icon(Icons.phone, color: AppColors.exito),
            onPressed: phone == null
                ? null
                : () => _snack('Llama a $phone', color: AppColors.azulCaribe),
          ),
          IconButton(
            tooltip: 'Chat',
            icon: const Icon(Icons.chat_bubble, color: AppColors.azulCaribe),
            onPressed: () => _tabs.animateTo(1),
          ),
        ],
      ),
    );
  }

  Widget _routeCard(Trip t) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.borde),
      ),
      child: Column(
        children: [
          _routeRow(
            Icons.trip_origin,
            AppColors.azulCaribe,
            'Origen',
            t.originAddress ?? 'Punto de origen',
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 4),
            child: Row(children: [
              SizedBox(width: 7),
              SizedBox(
                width: 2,
                height: 18,
                child: ColoredBox(color: AppColors.borde),
              )
            ]),
          ),
          _routeRow(
            Icons.place,
            AppColors.alerta,
            'Destino',
            t.destAddress ?? 'Punto de destino',
          ),
          const Divider(height: 24, color: AppColors.borde),
          Row(
            children: [
              _miniInfo(Icons.route, km(t.distanceKm), 'Distancia'),
              const SizedBox(width: 8),
              _miniInfo(Icons.schedule, minutes(t.durationMin), 'Tiempo'),
              const SizedBox(width: 8),
              _miniInfo(Icons.payments, money(t.fareEstimated), 'Estimado'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _routeRow(IconData icon, Color color, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: const TextStyle(
                      fontSize: 11, color: AppColors.grisSuave)),
              Text(value,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppColors.azulNoche)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _miniInfo(IconData icon, String value, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.arena,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: AppColors.azulCaribe, size: 16),
            const SizedBox(height: 2),
            Text(value,
                style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppColors.azulNoche,
                    fontSize: 13)),
            Text(label,
                style: const TextStyle(
                    color: AppColors.grisSuave, fontSize: 10.5)),
          ],
        ),
      ),
    );
  }

  List<Widget> _actions(Trip t, bool isDriver) {
    final actions = <Widget>[];
    // Driver progression
    if (isDriver) {
      switch (t.status) {
        case 'accepted':
          actions.add(_primaryButton('Llegue al cliente', Icons.where_to_vote,
              () => _driverAction(() => _s.trips.arrived(widget.tripId))));
          break;
        case 'arrived':
          actions.add(_primaryButton('Iniciar viaje', Icons.play_arrow,
              () => _driverAction(() => _s.trips.start(widget.tripId))));
          break;
        case 'in_progress':
          actions.add(_primaryButton('Finalizar viaje', Icons.flag,
              () => _driverAction(() => _s.trips.complete(widget.tripId))));
          break;
      }
    }
    // Cancel
    if (t.isActive) {
      actions.add(const SizedBox(height: 10));
      actions.add(SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: _cancel,
          icon: const Icon(Icons.close, color: AppColors.alerta),
          label: const Text('Cancelar viaje',
              style: TextStyle(
                  color: AppColors.alerta, fontWeight: FontWeight.w700)),
          style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppColors.alertaSuave)),
        ),
      ));
    }
    // Rate after completion
    if (t.status == 'completed') {
      actions.add(_primaryButton(
          'Calificar viaje', Icons.star, _askRating));
    }
    return actions;
  }

  Widget _primaryButton(String text, IconData icon, VoidCallback onTap) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        onPressed: onTap,
        icon: Icon(icon),
        label: Text(text),
      ),
    );
  }

  // ---------- Tab 2: Chat ----------
  Widget _chatTab() {
    return Column(
      children: [
        Expanded(
          child: _messages.isEmpty
              ? _chatEmpty()
              : ListView.builder(
                  controller: _chatScroll,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  itemCount: _messages.length,
                  itemBuilder: (_, i) => _bubble(_messages[i]),
                ),
        ),
        _chatInputBar(),
      ],
    );
  }

  Widget _chatEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 60,
              height: 60,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.verdeMenta,
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Icon(Icons.chat_bubble_outline,
                  color: AppColors.azulCaribe, size: 28),
            ),
            const SizedBox(height: 12),
            const Text('Aun no hay mensajes',
                style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppColors.azulNoche)),
            const SizedBox(height: 4),
            const Text(
              'Escribe el primer mensaje para coordinar el viaje.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.grisTexto, fontSize: 12.5),
            ),
          ],
        ),
      ),
    );
  }

  Widget _bubble(ChatMessage m) {
    final mine = m.senderId == _meId;
    final time = m.createdAt != null ? DateFormat('HH:mm').format(m.createdAt!) : '';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Align(
        alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
        child: Column(
          crossAxisAlignment:
              mine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Container(
              constraints: const BoxConstraints(maxWidth: 280),
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: mine ? AppColors.azulCaribe : AppColors.arena,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: Radius.circular(mine ? 18 : 4),
                  bottomRight: Radius.circular(mine ? 4 : 18),
                ),
              ),
              child: Text(
                m.body ?? '',
                style: TextStyle(
                  color: mine ? Colors.white : AppColors.azulNoche,
                  fontSize: 14,
                ),
              ),
            ),
            if (time.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 2, left: 4, right: 4),
                child: Text(time,
                    style: const TextStyle(
                        color: AppColors.grisSuave, fontSize: 10.5)),
              ),
          ],
        ),
      ),
    );
  }

  Widget _chatInputBar() {
    return Container(
      padding: EdgeInsets.fromLTRB(
          12, 8, 8, 12 + MediaQuery.of(context).viewInsets.bottom),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.borde)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _chatInput,
              textInputAction: TextInputAction.send,
              minLines: 1,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Escribe un mensaje...',
                filled: true,
                fillColor: AppColors.arena,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 12),
              ),
              onSubmitted: (_) => _sendChat(),
            ),
          ),
          const SizedBox(width: 8),
          Material(
            color: AppColors.azulCaribe,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: _sendChat,
              child: const Padding(
                padding: EdgeInsets.all(12),
                child: Icon(Icons.send, color: Colors.white, size: 20),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
