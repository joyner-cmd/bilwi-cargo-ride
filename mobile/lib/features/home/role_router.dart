import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../state/auth_provider.dart';
import '../client/client_home_screen.dart';
import '../driver/driver_home_screen.dart';
import '../auth/login_screen.dart';

/// Decide la pantalla principal segun el rol del usuario autenticado.
class RoleRouter extends StatelessWidget {
  const RoleRouter({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    if (user == null) return const LoginScreen();
    if (user.isDriver) return const DriverHomeScreen();
    return const ClientHomeScreen();
  }
}
