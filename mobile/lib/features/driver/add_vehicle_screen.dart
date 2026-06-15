import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/di/services.dart';
import '../../core/network/api_client.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/service_type.dart';
import '../common/image_source_sheet.dart';
import '../common/photo_avatar.dart';

class AddVehicleScreen extends StatefulWidget {
  const AddVehicleScreen({super.key, this.existing});
  final Map<String, dynamic>? existing;

  @override
  State<AddVehicleScreen> createState() => _AddVehicleScreenState();
}

class _AddVehicleScreenState extends State<AddVehicleScreen> {
  late final Services _s;
  final _form = GlobalKey<FormState>();

  String? _photoUrl;
  bool _uploading = false;
  bool _saving = false;
  String _type = 'camioneta';
  late final TextEditingController _brand;
  late final TextEditingController _model;
  late final TextEditingController _plate;
  late final TextEditingController _year;
  late final TextEditingController _color;
  late final TextEditingController _capacity;
  late final TextEditingController _customPerKm;
  final Set<String> _services = {};
  List<ServiceType> _allServices = [];

  static const _types = [
    ('moto', 'Moto'),
    ('particular', 'Particular'),
    ('camioneta', 'Camioneta'),
    ('acarreo', 'Acarreo'),
    ('camion_pequeno', 'Camion pequeno'),
    ('camion_mediano', 'Camion mediano'),
  ];

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    _s = context.read<Services>();
    final v = widget.existing;
    _photoUrl = v?['photo_url'] as String?;
    _type = (v?['type'] as String?) ?? 'camioneta';
    _brand = TextEditingController(text: v?['brand']?.toString() ?? '');
    _model = TextEditingController(text: v?['model']?.toString() ?? '');
    _plate = TextEditingController(text: v?['plate']?.toString() ?? '');
    _year = TextEditingController(text: v?['year']?.toString() ?? '');
    _color = TextEditingController(text: v?['color']?.toString() ?? '');
    _capacity =
        TextEditingController(text: v?['capacity_kg']?.toString() ?? '');
    _customPerKm =
        TextEditingController(text: v?['custom_per_km']?.toString() ?? '');
    final off = (v?['services_offered'] as List?)?.cast<String>() ?? [];
    _services.addAll(off);
    _loadServices();
  }

  @override
  void dispose() {
    _brand.dispose();
    _model.dispose();
    _plate.dispose();
    _year.dispose();
    _color.dispose();
    _capacity.dispose();
    _customPerKm.dispose();
    super.dispose();
  }

  Future<void> _loadServices() async {
    try {
      _allServices = await _s.catalog.services();
      if (mounted) setState(() {});
    } catch (_) {}
  }

  Future<void> _pickPhoto() async {
    final src = await showImageSourceSheet(context);
    if (src == null) return;
    setState(() => _uploading = true);
    try {
      final res = await _s.uploads.pickAndUpload(source: src, maxWidth: 1200);
      if (res != null && mounted) setState(() => _photoUrl = res.url);
    } catch (e) {
      if (mounted) _snack(ApiClient.messageFrom(e));
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final body = {
        'type': _type,
        if (_brand.text.trim().isNotEmpty) 'brand': _brand.text.trim(),
        if (_model.text.trim().isNotEmpty) 'model': _model.text.trim(),
        if (_plate.text.trim().isNotEmpty) 'plate': _plate.text.trim(),
        if (_year.text.trim().isNotEmpty) 'year': _year.text.trim(),
        if (_color.text.trim().isNotEmpty) 'color': _color.text.trim(),
        if (_capacity.text.trim().isNotEmpty)
          'capacityKg': _capacity.text.trim(),
        if (_photoUrl != null) 'photoUrl': _photoUrl,
        'servicesOffered': _services.toList(),
        if (_customPerKm.text.trim().isNotEmpty)
          'customPerKm': _customPerKm.text.trim(),
      };
      if (_isEdit) {
        await _s.driver.updateVehicle(widget.existing!['id'] as int, body);
      } else {
        await _s.driver.addVehicle(body);
      }
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (mounted) _snack(ApiClient.messageFrom(e));
    } finally {
      if (mounted) setState(() => _saving = false);
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
        title: Text(_isEdit ? 'Editar vehiculo' : 'Nuevo vehiculo'),
        backgroundColor: AppColors.arena,
      ),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            _photoCard(),
            const SizedBox(height: 18),
            _label('Tipo de vehiculo'),
            _typePicker(),
            const SizedBox(height: 18),
            _label('Datos del vehiculo'),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.borde),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _brand,
                          decoration: const InputDecoration(labelText: 'Marca'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextFormField(
                          controller: _model,
                          decoration: const InputDecoration(labelText: 'Modelo'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _plate,
                          textCapitalization: TextCapitalization.characters,
                          decoration: const InputDecoration(labelText: 'Placa'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextFormField(
                          controller: _year,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'Año'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _color,
                          decoration: const InputDecoration(labelText: 'Color'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextFormField(
                          controller: _capacity,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                              labelText: 'Capacidad (kg)'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            _label('¿Que servicios ofreces con este vehiculo?'),
            _servicesPicker(),
            const SizedBox(height: 18),
            _label('Precio por kilometro (opcional)'),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.borde),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextFormField(
                    controller: _customPerKm,
                    keyboardType: const TextInputType.numberWithOptions(
                        decimal: true),
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.attach_money),
                      labelText: 'Cordobas por km (ej. 18)',
                      hintText: 'Dejar vacio para usar la tarifa por defecto',
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Si lo defines, sera el precio sugerido cuando tomes solicitudes.',
                    style:
                        TextStyle(fontSize: 11.5, color: AppColors.grisTexto),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 26),
            FilledButton.icon(
              onPressed: _saving ? null : _save,
              icon: _saving
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.check),
              label: Text(_isEdit ? 'Guardar cambios' : 'Registrar vehiculo'),
            ),
            if (!_isEdit) ...[
              const SizedBox(height: 8),
              const Text(
                'Tu vehiculo quedara "En revision" hasta que admin lo apruebe.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 11.5, color: AppColors.grisTexto),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _photoCard() {
    return GestureDetector(
      onTap: _uploading ? null : _pickPhoto,
      child: Container(
        height: 180,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: AppColors.borde,
              width: 1,
              style: BorderStyle.solid),
          boxShadow: AppShadows.sutil,
        ),
        clipBehavior: Clip.antiAlias,
        child: _uploading
            ? const Center(child: CircularProgressIndicator())
            : Stack(
                fit: StackFit.expand,
                children: [
                  if (_photoUrl != null)
                    PhotoImage(photoUrl: _photoUrl, borderRadius: 0)
                  else
                    Container(
                      color: AppColors.arena,
                      alignment: Alignment.center,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 56,
                            height: 56,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: AppColors.verdeMenta,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Icon(Icons.add_a_photo,
                                color: AppColors.azulCaribe, size: 28),
                          ),
                          const SizedBox(height: 10),
                          const Text('Agrega foto del vehiculo',
                              style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.azulNoche)),
                          const Text('Aumenta la confianza de los clientes',
                              style: TextStyle(
                                  color: AppColors.grisTexto,
                                  fontSize: 12)),
                        ],
                      ),
                    ),
                  if (_photoUrl != null)
                    Positioned(
                      right: 10,
                      bottom: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: .6),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.camera_alt,
                                color: Colors.white, size: 14),
                            SizedBox(width: 4),
                            Text('Cambiar',
                                style: TextStyle(
                                    color: Colors.white, fontSize: 11.5)),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
      ),
    );
  }

  Widget _typePicker() {
    return SizedBox(
      height: 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _types.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final (code, label) = _types[i];
          final sel = _type == code;
          return ChoiceChip(
            label: Text(label),
            selected: sel,
            onSelected: (_) => setState(() => _type = code),
            selectedColor: AppColors.azulCaribe,
            backgroundColor: Colors.white,
            side: const BorderSide(color: AppColors.borde),
            labelStyle: TextStyle(
              color: sel ? Colors.white : AppColors.azulNoche,
              fontWeight: FontWeight.w600,
            ),
          );
        },
      ),
    );
  }

  Widget _servicesPicker() {
    if (_allServices.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.borde),
        ),
        child: const Text('Cargando servicios...',
            style: TextStyle(color: AppColors.grisTexto)),
      );
    }
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.borde),
      ),
      child: Column(
        children: _allServices.map((s) {
          final on = _services.contains(s.code);
          return CheckboxListTile(
            value: on,
            onChanged: (v) => setState(() {
              if (v == true) {
                _services.add(s.code);
              } else {
                _services.remove(s.code);
              }
            }),
            title: Text(s.name,
                style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppColors.azulNoche)),
            subtitle: Text(s.description,
                style: const TextStyle(
                    fontSize: 12, color: AppColors.grisTexto)),
            controlAffinity: ListTileControlAffinity.leading,
            activeColor: AppColors.azulCaribe,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 6, vertical: 0),
            dense: true,
          );
        }).toList(),
      ),
    );
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8, left: 4),
        child: Text(text,
            style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: AppColors.azulNoche,
                fontSize: 14)),
      );
}
