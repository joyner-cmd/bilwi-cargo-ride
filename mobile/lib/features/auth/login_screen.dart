import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/network/api_client.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../state/auth_provider.dart';
import '../common/app_logo.dart';
import '../home/role_router.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _form = GlobalKey<FormState>();
  final _phone = TextEditingController(text: '+505');
  final _password = TextEditingController();
  bool _loading = false;
  bool _obscure = true;

  @override
  void dispose() {
    _phone.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await context
          .read<AuthProvider>()
          .login(_phone.text.trim(), _password.text);
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const RoleRouter()));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(ApiClient.messageFrom(e)),
          backgroundColor: AppColors.alerta));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _fillDemo(String phone) {
    _phone.text = phone;
    _password.text = 'demo1234';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.arena,
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _hero(),
              Transform.translate(
                offset: const Offset(0, -28),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(22, 24, 22, 22),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: AppShadows.elevada,
                    ),
                    child: Form(
                      key: _form,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text('Inicia sesion',
                              style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.azulNoche)),
                          const SizedBox(height: 2),
                          const Text(
                            'Bienvenido de vuelta. Movamos Bilwi.',
                            style: TextStyle(
                                color: AppColors.grisTexto, fontSize: 13),
                          ),
                          const SizedBox(height: 22),
                          TextFormField(
                            controller: _phone,
                            keyboardType: TextInputType.phone,
                            decoration: const InputDecoration(
                                labelText: 'Telefono',
                                prefixIcon: Icon(Icons.phone)),
                            validator: (v) =>
                                (v == null || v.trim().length < 8)
                                    ? 'Telefono invalido'
                                    : null,
                          ),
                          const SizedBox(height: 14),
                          TextFormField(
                            controller: _password,
                            obscureText: _obscure,
                            decoration: InputDecoration(
                              labelText: 'Contrasena',
                              prefixIcon: const Icon(Icons.lock),
                              suffixIcon: IconButton(
                                icon: Icon(_obscure
                                    ? Icons.visibility
                                    : Icons.visibility_off),
                                onPressed: () =>
                                    setState(() => _obscure = !_obscure),
                              ),
                            ),
                            validator: (v) => (v == null || v.length < 6)
                                ? 'Minimo 6 caracteres'
                                : null,
                          ),
                          const SizedBox(height: 22),
                          FilledButton(
                            onPressed: _loading ? null : _submit,
                            child: _loading
                                ? const SizedBox(
                                    height: 22,
                                    width: 22,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2, color: Colors.white))
                                : const Text('Entrar'),
                          ),
                          const SizedBox(height: 10),
                          Center(
                            child: TextButton(
                              onPressed: () => Navigator.of(context).push(
                                  MaterialPageRoute(
                                      builder: (_) => const RegisterScreen())),
                              child: const Text('Crear cuenta nueva',
                                  style: TextStyle(
                                      fontWeight: FontWeight.w600)),
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Row(
                            children: [
                              Expanded(child: Divider(color: AppColors.borde)),
                              Padding(
                                padding:
                                    EdgeInsets.symmetric(horizontal: 10),
                                child: Text('demo rapido',
                                    style: TextStyle(
                                        fontSize: 11,
                                        color: AppColors.grisSuave,
                                        fontWeight: FontWeight.w600)),
                              ),
                              Expanded(child: Divider(color: AppColors.borde)),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: _demoButton(
                                    icon: Icons.person,
                                    label: 'Cliente',
                                    onTap: () => _fillDemo('+50588880001')),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _demoButton(
                                    icon: Icons.local_taxi,
                                    label: 'Conductor',
                                    onTap: () => _fillDemo('+50588880002')),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _hero() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 56),
      decoration: const BoxDecoration(
        gradient: AppColors.gradienteHero,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(36)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 12),
          const AppLogo(size: 80, light: true),
          const SizedBox(height: 14),
          const Text(
            'Bilwi Cargo & Ride',
            style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5),
          ),
          const SizedBox(height: 4),
          Text(
            'Transporte y acarreos en Puerto Cabezas',
            style: TextStyle(
                color: Colors.white.withValues(alpha: .85), fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _demoButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Material(
      color: AppColors.verdeMenta,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Column(
            children: [
              Icon(icon, color: AppColors.azulCaribe, size: 22),
              const SizedBox(height: 4),
              Text(label,
                  style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AppColors.azulNoche,
                      fontSize: 13)),
            ],
          ),
        ),
      ),
    );
  }
}
