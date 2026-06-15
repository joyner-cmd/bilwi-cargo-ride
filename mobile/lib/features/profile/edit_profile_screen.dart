import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/di/services.dart';
import '../../core/network/api_client.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/user.dart';
import '../../state/auth_provider.dart';
import '../common/image_source_sheet.dart';
import '../common/photo_avatar.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late final Services _s;
  final _form = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _email;
  String? _photoUrl;
  bool _saving = false;
  bool _uploading = false;

  @override
  void initState() {
    super.initState();
    _s = context.read<Services>();
    final u = context.read<AuthProvider>().user;
    _name = TextEditingController(text: u?.fullName ?? '');
    _email = TextEditingController(text: u?.email ?? '');
    _photoUrl = u?.photoUrl;
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final src = await showImageSourceSheet(context);
    if (src == null) return;
    setState(() => _uploading = true);
    try {
      final res = await _s.uploads.pickAndUpload(source: src);
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
      final res = await _s.api.dio.patch('/users/me', data: {
        'fullName': _name.text.trim(),
        if (_email.text.trim().isNotEmpty) 'email': _email.text.trim(),
        if (_photoUrl != null) 'photoUrl': _photoUrl,
      });
      final updated = AppUser.fromJson(Map<String, dynamic>.from(res.data));
      if (!mounted) return;
      await context.read<AuthProvider>().updateUserLocal(updated);
      if (!mounted) return;
      _snack('Perfil actualizado', color: AppColors.exito);
      Navigator.pop(context);
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
        title: const Text('Editar perfil'),
        backgroundColor: AppColors.arena,
      ),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            const SizedBox(height: 8),
            Center(child: _photoEditor()),
            const SizedBox(height: 24),
            _label('Nombre completo'),
            TextFormField(
              controller: _name,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.badge_outlined),
                  hintText: 'Tu nombre'),
              validator: (v) =>
                  (v == null || v.trim().length < 3) ? 'Ingresa tu nombre' : null,
            ),
            const SizedBox(height: 14),
            _label('Correo (opcional)'),
            TextFormField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.email_outlined),
                  hintText: 'tucorreo@ejemplo.com'),
            ),
            const SizedBox(height: 28),
            FilledButton.icon(
              onPressed: _saving ? null : _save,
              icon: _saving
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.check),
              label: const Text('Guardar cambios'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _photoEditor() {
    final user = context.watch<AuthProvider>().user;
    final initial =
        (user?.fullName.isNotEmpty ?? false) ? user!.fullName[0] : '?';
    return GestureDetector(
      onTap: _uploading ? null : _pickPhoto,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.verdeAgua, width: 3),
              boxShadow: AppShadows.elevada,
            ),
            child: _uploading
                ? Container(
                    width: 120,
                    height: 120,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(
                        shape: BoxShape.circle, color: AppColors.arena),
                    child: const CircularProgressIndicator(),
                  )
                : PhotoAvatar(
                    photoUrl: _photoUrl,
                    fallbackInitial: initial,
                    size: 120,
                  ),
          ),
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.azulCaribe,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 3),
              ),
              child: const Icon(Icons.camera_alt,
                  color: Colors.white, size: 18),
            ),
          ),
        ],
      ),
    );
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 6, left: 4),
        child: Text(text,
            style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: AppColors.azulNoche,
                fontSize: 13)),
      );
}
