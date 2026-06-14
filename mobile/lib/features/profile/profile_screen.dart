import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../state/auth_provider.dart';
import '../auth/login_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;
    return Scaffold(
      appBar: AppBar(title: const Text('Mi perfil')),
      body: user == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Center(
                  child: CircleAvatar(
                    radius: 48,
                    backgroundColor: AppColors.verdeAgua,
                    child: Text(
                      user.fullName.isNotEmpty ? user.fullName[0] : '?',
                      style: const TextStyle(fontSize: 36, color: AppColors.azulProfundo),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Center(
                  child: Text(user.fullName,
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                ),
                Center(
                  child: Text(user.isDriver ? 'Conductor' : 'Cliente',
                      style: const TextStyle(color: AppColors.grisTexto)),
                ),
                const SizedBox(height: 8),
                Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.star, color: AppColors.advertencia, size: 18),
                      const SizedBox(width: 4),
                      Text('${user.ratingAvg.toStringAsFixed(1)} (${user.ratingCount})',
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Card(
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.phone),
                        title: const Text('Telefono'),
                        subtitle: Text(user.phone),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.email),
                        title: const Text('Correo'),
                        subtitle: Text(user.email ?? 'Sin correo'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                OutlinedButton.icon(
                  icon: const Icon(Icons.logout, color: AppColors.alerta),
                  label: const Text('Cerrar sesion', style: TextStyle(color: AppColors.alerta)),
                  onPressed: () async {
                    await auth.logout();
                    if (context.mounted) {
                      Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(builder: (_) => const LoginScreen()),
                          (_) => false);
                    }
                  },
                ),
              ],
            ),
    );
  }
}
