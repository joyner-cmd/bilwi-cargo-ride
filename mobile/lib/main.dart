import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/di/services.dart';
import 'core/theme/app_theme.dart';
import 'state/auth_provider.dart';
import 'features/splash/splash_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final services = await Services.init();
  runApp(BilwiCargoApp(services: services));
}

class BilwiCargoApp extends StatelessWidget {
  const BilwiCargoApp({super.key, required this.services});
  final Services services;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<Services>.value(value: services),
        ChangeNotifierProvider(create: (_) => AuthProvider(services)..bootstrap()),
      ],
      child: MaterialApp(
        title: 'Bilwi Cargo & Ride',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        home: const SplashScreen(),
      ),
    );
  }
}
