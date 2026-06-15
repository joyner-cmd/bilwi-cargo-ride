import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../state/auth_provider.dart';
import '../auth/login_screen.dart';
import '../common/photo_avatar.dart';
import '../driver/my_vehicles_screen.dart';
import 'edit_profile_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;
    return Scaffold(
      backgroundColor: AppColors.arena,
      body: user == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(0, 0, 0, 100),
              children: [
                _hero(user.photoUrl, user.fullName, user.isDriver,
                    user.ratingAvg, user.ratingCount),
                Transform.translate(
                  offset: const Offset(0, -28),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      children: [
                        _infoCard([
                          _actionRow(
                              icon: Icons.edit_outlined,
                              title: 'Editar perfil',
                              subtitle: 'Cambia tu foto, nombre o correo',
                              onTap: () => Navigator.of(context).push(
                                  MaterialPageRoute(
                                      builder: (_) =>
                                          const EditProfileScreen()))),
                          if (user.isDriver)
                            _actionRow(
                                icon: Icons.local_shipping_outlined,
                                title: 'Mis vehiculos',
                                subtitle:
                                    'Registra tus vehiculos y servicios',
                                onTap: () => Navigator.of(context).push(
                                    MaterialPageRoute(
                                        builder: (_) =>
                                            const MyVehiclesScreen()))),
                          _row(Icons.phone, 'Telefono', user.phone,
                              showDivider: true),
                          _row(Icons.email, 'Correo',
                              user.email ?? 'Sin correo',
                              showDivider: false),
                        ]),
                        const SizedBox(height: 14),
                        _infoCard([
                          _actionRow(
                              icon: Icons.shield_outlined,
                              title: 'Seguridad y SOS',
                              subtitle:
                                  'Boton de emergencia disponible en viaje',
                              onTap: () {}),
                          _actionRow(
                              icon: Icons.help_outline,
                              title: 'Ayuda y soporte',
                              subtitle: 'Reporta problemas o sugerencias',
                              onTap: () {}),
                          _actionRow(
                              icon: Icons.info_outline,
                              title: 'Acerca de',
                              subtitle: 'Version 1.0.4',
                              onTap: () {},
                              showDivider: false),
                        ]),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.logout,
                                color: AppColors.alerta),
                            label: const Text('Cerrar sesion',
                                style: TextStyle(
                                    color: AppColors.alerta,
                                    fontWeight: FontWeight.w700)),
                            style: OutlinedButton.styleFrom(
                                side: const BorderSide(
                                    color: AppColors.alertaSuave)),
                            onPressed: () async {
                              await auth.logout();
                              if (context.mounted) {
                                Navigator.of(context).pushAndRemoveUntil(
                                    MaterialPageRoute(
                                        builder: (_) => const LoginScreen()),
                                    (_) => false);
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _hero(String? photoUrl, String name, bool isDriver, double rating,
      int count) {
    final initial = name.isNotEmpty ? name[0] : '?';
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 56, 20, 56),
      decoration: const BoxDecoration(
        gradient: AppColors.gradienteHero,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
      ),
      child: Column(
        children: [
          Container(
            width: 96,
            height: 96,
            padding: const EdgeInsets.all(3),
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: AppShadows.elevada,
            ),
            child: PhotoAvatar(
              photoUrl: photoUrl,
              fallbackInitial: initial,
              size: 90,
            ),
          ),
          const SizedBox(height: 12),
          Text(name,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: .18),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(isDriver ? 'Conductor' : 'Cliente',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600)),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.star_rounded,
                  color: AppColors.advertencia, size: 20),
              const SizedBox(width: 4),
              Text('${rating.toStringAsFixed(1)} ($count)',
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 13)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _infoCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppShadows.sutil,
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(children: children),
    );
  }

  Widget _row(IconData icon, String label, String value,
      {bool showDivider = false}) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.verdeMenta,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: AppColors.azulCaribe, size: 18),
              ),
              const SizedBox(width: 12),
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
          ),
        ),
        if (showDivider)
          const Divider(
              height: 1, color: AppColors.borde, indent: 14, endIndent: 14),
      ],
    );
  }

  Widget _actionRow({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool showDivider = true,
  }) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.verdeMenta,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: AppColors.azulCaribe, size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              color: AppColors.azulNoche)),
                      Text(subtitle,
                          style: const TextStyle(
                              fontSize: 12, color: AppColors.grisTexto)),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: AppColors.grisSuave),
              ],
            ),
          ),
        ),
        if (showDivider)
          const Divider(
              height: 1, color: AppColors.borde, indent: 14, endIndent: 14),
      ],
    );
  }
}
